#!/bin/bash
# setup.sh
# All-in-One Portable Playwright Engine (Industry Grade)

set -e

INTERNAL_DIR=$(pwd)
PROJECT_DIR=$(dirname "$INTERNAL_DIR")
NODE_DIR="$INTERNAL_DIR/node"
BROWSER_DIR="$INTERNAL_DIR/browsers"
TEMP_DIR="$INTERNAL_DIR/temp"
TASK_FILE="$PROJECT_DIR/task.json"

# 1. Create Directories
mkdir -p "$INTERNAL_DIR"
mkdir -p "$TEMP_DIR"

echo -e "\n[1/7] Initializing All-in-One Portable Engine..."

# 2. Identify System Configuration
echo -e "[2/7] Detecting system configuration..."
OS_TYPE=$(uname -s)
ARCH=$(uname -m)
echo -e "  > OS: $OS_TYPE"
echo -e "  > Architecture: $ARCH"

# 3. Hybrid Logic: Check for suitable Node.js
echo -e "[3/7] Checking for compatible Node.js version..."
USE_SYSTEM_NODE=false
SYS_NODE_VER=""

if command -v node >/dev/null 2>&1; then
    SYS_NODE_VER=$(node -v)
    if [[ $SYS_NODE_VER =~ ^v(1[8-9]|2[0-2])\. ]]; then
        echo -e "  > Found compatible system Node ($SYS_NODE_VER)."
        USE_SYSTEM_NODE=true
    else
        echo -e "  > System Node ($SYS_NODE_VER) is not in the supported range (v18-v22)."
    fi
else
    echo -e "  > No system Node.js found."
fi

# 4. Handle Node.js Engine
if [ "$USE_SYSTEM_NODE" = true ]; then
    echo -e "[4/7] DECISION: Reusing system Node.js for space efficiency."
else
    echo -e "[4/7] DECISION: Using private, isolated Node.js engine."
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

        echo -e "  > Private engine missing. Downloading build for $OS_TYPE $ARCH..."
        echo -e "  > Fetching: $NODE_URL"
        curl -L "$NODE_URL" -o "$TEMP_DIR/$NODE_TAR"
        
        echo -e "  > Extracting engine components..."
        tar -xf "$TEMP_DIR/$NODE_TAR" -C "$TEMP_DIR"
        
        EXTRACTED_FOLDER=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "node-*" | head -n 1)
        mv "$EXTRACTED_FOLDER" "$NODE_DIR"
        
        rm "$TEMP_DIR/$NODE_TAR"
        rm -rf "$TEMP_DIR"
        echo -e "  > Private engine successfully isolated in ./internal/node"
    else
        echo -e "  > Using previously isolated internal Node engine."
    fi
    
    # Session Path Override
    export PATH="$NODE_DIR/bin:$PATH"
    echo -e "  > Session PATH updated to prioritize internal engine."
fi

# 5. Playwright Configuration
echo -e "[5/7] Configuring Playwright environment..."
export PLAYWRIGHT_BROWSERS_PATH="$BROWSER_DIR"
echo -e "  > Browser location forced to: ./internal/browsers"

# 6. Bootstrap Dependencies & Browsers
echo -e "[6/7] Verifying local dependencies and browsers..."
if [ ! -d "$PROJECT_DIR/node_modules" ]; then
    echo -e "  > node_modules missing. Running npm install..."
    npm install
else
    echo -e "  > node_modules found."
fi

if [ ! -d "$BROWSER_DIR" ] || [ -z "$(ls -A "$BROWSER_DIR")" ]; then
    echo -e "  > Browsers missing. Fetching compatible Chromium builds..."
    npx playwright install chromium --with-deps
else
    echo -e "  > Compatible browsers found in local cache."
fi

# 7. Execution
echo -e "[7/7] Environment ready. Executing automation script..."
echo -e "---"
node runner.js "$TASK_FILE"
