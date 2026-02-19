#!/bin/bash
# setup.sh
# All-in-One Portable Playwright Engine (Internal Logic)

set -e

INTERNAL_DIR=$(pwd)
PROJECT_DIR=$(dirname "$INTERNAL_DIR")
NODE_DIR="$INTERNAL_DIR/node"
BROWSER_DIR="$INTERNAL_DIR/browsers"
TEMP_DIR="$INTERNAL_DIR/temp"
TASK_FILE="$PROJECT_DIR/task.json"

OS_TYPE=$(uname -s)
ARCH=$(uname -m)

echo -e "\n--- Initializing All-in-One Portable Engine ---"
echo -e "CONFIG: Detected OS: $OS_TYPE"
echo -e "CONFIG: Detected Arch: $ARCH"

# 1. Create Directories
mkdir -p "$INTERNAL_DIR"
mkdir -p "$TEMP_DIR"

# 2. Hybrid Logic: Check System Node
USE_SYSTEM_NODE=false

if command -v node >/dev/null 2>&1; then
    SYS_NODE_VER=$(node -v)
    if [[ $SYS_NODE_VER =~ ^v(1[8-9]|2[0-2])\. ]]; then
        echo -e "INFO: Found compatible system Node ($SYS_NODE_VER). Reusing for space efficiency."
        USE_SYSTEM_NODE=true
    else
        echo -e "INFO: System Node ($SYS_NODE_VER) is incompatible (v18-v22 required)."
    fi
else
    echo -e "INFO: No system Node.js found."
fi

# 3. Handle Portable Node.js
if [ "$USE_SYSTEM_NODE" = false ]; then
    if [ ! -d "$NODE_DIR" ]; then
        NODE_VER="v20.11.1" # Verified LTS
        
        if [ "$OS_TYPE" == "Darwin" ]; then
            if [ "$ARCH" == "arm64" ]; then
                NODE_TAR="node-$NODE_VER-darwin-arm64.tar.gz"
            else
                NODE_TAR="node-$NODE_VER-darwin-x64.tar.gz"
            fi
        elif [ "$OS_TYPE" == "Linux" ]; then
            NODE_TAR="node-$NODE_VER-linux-x64.tar.xz"
        else
            echo "ERROR: Unsupported OS: $OS_TYPE"
            exit 1
        fi
        
        NODE_URL="https://nodejs.org/dist/$NODE_VER/$NODE_TAR"

        echo -e "ACTION: Downloading private engine for isolated environment..."
        echo -e "FETCH: $NODE_URL"
        curl -L "$NODE_URL" -o "$TEMP_DIR/$NODE_TAR"
        
        echo -e "ACTION: Extracting components..."
        tar -xf "$TEMP_DIR/$NODE_TAR" -C "$TEMP_DIR"
        
        EXTRACTED_FOLDER=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "node-*" | head -n 1)
        mv "$EXTRACTED_FOLDER" "$NODE_DIR"
        
        rm "$TEMP_DIR/$NODE_TAR"
        rm -rf "$TEMP_DIR"
        echo -e "SUCCESS: Private engine isolated in ./internal/node"
    else
        echo -e "INFO: Using previously isolated private Node engine."
    fi
    
    # Session Path Override
    export PATH="$NODE_DIR/bin:$PATH"
fi

# 4. Mandatory Playwright Redirection
export PLAYWRIGHT_BROWSERS_PATH="$BROWSER_DIR"

# 5. Bootstrap Project Dependencies
if [ ! -d "$PROJECT_DIR/node_modules" ]; then
    echo -e "ACTION: Installing project dependencies locally..."
    npm install
fi

# 6. Bootstrap Playwright Browsers (Local)
if [ ! -d "$BROWSER_DIR" ] || [ -z "$(ls -A "$BROWSER_DIR")" ]; then
    echo -e "ACTION: Validating and fetching browsers locally..."
    npx playwright install chromium --with-deps
fi

# 7. Final Execution
echo -e "READY: Environment loaded. Starting Runner...\n"
node runner.js "$TASK_FILE"
