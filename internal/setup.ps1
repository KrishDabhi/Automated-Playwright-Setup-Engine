# setup.ps1
# All-in-One Portable Playwright Engine (Internal Logic)

$ErrorActionPreference = "Stop"
$InternalDir = Get-Location
$ProjectDir = (Get-Item $InternalDir).Parent.FullName
$NodeDir = Join-Path $InternalDir "node"
$BrowserDir = Join-Path $InternalDir "browsers"
$TempDir = Join-Path $InternalDir "temp"
$TaskFile = Join-Path $ProjectDir "task.json"

# 1. Create Directories
if (-not (Test-Path $InternalDir)) { New-Item -ItemType Directory -Path $InternalDir | Out-Null }
if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }

Write-Host "--- Initializing All-in-One Portable Engine ---" -ForegroundColor Cyan

# 2. Hybrid Logic: Check System Node
$UseSystemNode = $false

try {
    $SysNodeVersion = node -v 2>$null
    if ($SysNodeVersion -match "^v(1[8-9]|2[0-2])\.") {
        Write-Host "INFO: Found compatible system Node ($SysNodeVersion). Reusing for space efficiency." -ForegroundColor Green
        $UseSystemNode = $true
    }
}
catch {
    # Node not found or error
}

# 3. Handle Portable Node.js
if (-not $UseSystemNode) {
    if (-not (Test-Path $NodeDir)) {
        $OSArch = $Env:PROCESSOR_ARCHITECTURE
        $NodeVer = "v20.11.1" # Verified LTS
        $NodeZip = if ($OSArch -eq "AMD64") { "node-$NodeVer-win-x64.zip" } else { "node-$NodeVer-win-x86.zip" }
        $NodeUrl = "https://nodejs.org/dist/$NodeVer/$NodeZip"

        Write-Host "INFO: System Node incompatible or missing. Downloading private engine (Windows $OSArch)..." -ForegroundColor Yellow
        $ArchivePath = Join-Path $TempDir $NodeZip
        
        Write-Host "DOWNLOAD: $NodeUrl" -ForegroundColor Gray
        Invoke-WebRequest -Uri $NodeUrl -OutFile $ArchivePath
        
        Write-Host "ACTION: Extracting..." -ForegroundColor Yellow
        Expand-Archive -Path $ArchivePath -DestinationPath $TempDir
        
        $ExtractedFolder = Get-ChildItem -Path $TempDir -Directory | Where-Object { $_.Name -like "node-*" } | Select-Object -First 1
        Move-Item -Path $ExtractedFolder.FullName -Destination $NodeDir
        
        Remove-Item -Path $ArchivePath
        Remove-Item -Path $TempDir -Recurse
        Write-Host "SUCCESS: Private engine isolated in .\internal\node" -ForegroundColor Green
    }
    else {
        Write-Host "INFO: Using previously isolated Node engine." -ForegroundColor Green
    }
    
    # Session Path Override
    $Env:PATH = "$NodeDir;" + $Env:PATH
}

# 4. Mandatory Playwright Redirection
$Env:PLAYWRIGHT_BROWSERS_PATH = $BrowserDir

# 5. Bootstrap Project Dependencies
if (-not (Test-Path (Join-Path $ProjectDir "node_modules"))) {
    Write-Host "ACTION: Setting up project dependencies (Local folder only)..." -ForegroundColor Yellow
    npm install
}

# 6. Bootstrap Playwright Browsers (Local)
if (-not (Test-Path $BrowserDir) -or (Get-ChildItem $BrowserDir).Count -eq 0) {
    Write-Host "ACTION: Fetching compatible browsers... (Stored in .\internal\browsers)" -ForegroundColor Yellow
    npx playwright install chromium --with-deps
}

# 7. Final Execution
Write-Host "READY: Environment loaded. Starting Runner..." -ForegroundColor Cyan
node runner.js "$TaskFile"
