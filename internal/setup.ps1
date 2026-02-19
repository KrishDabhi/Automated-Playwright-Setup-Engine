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

Write-Host "`n[1/7] Initializing All-in-One Portable Engine..." -ForegroundColor Cyan

# 2. Identify System Configuration
Write-Host "[2/7] Detecting system configuration..." -ForegroundColor Cyan
$OSArch = $Env:PROCESSOR_ARCHITECTURE
$OSVersion = (Get-CimInstance Win32_OperatingSystem).Caption

# Validation Check
if ($OSArch -notin @("AMD64", "x86", "ARM64")) {
    Write-Host "CRITICAL ERROR: Unsupported Architecture: $OSArch" -ForegroundColor Red
    Write-Host "This engine only supports 64-bit (x64), 32-bit (x86), and ARM64 Windows systems." -ForegroundColor Yellow
    exit 1
}

Write-Host "  > OS: $OSVersion" -ForegroundColor Gray
Write-Host "  > Architecture: $OSArch" -ForegroundColor Gray

# 3. Hybrid Logic: Check for suitable Node.js
Write-Host "[3/7] Checking for compatible Node.js version..." -ForegroundColor Cyan
$UseSystemNode = $false
$SysNodeVersion = ""

try {
    $SysNodeVersion = node -v 2>$null
    if ($SysNodeVersion -match "^v(1[8-9]|2[0-2])\.") {
        Write-Host "  > Found compatible system Node ($SysNodeVersion)." -ForegroundColor Green
        $UseSystemNode = $true
    } else {
        if ($SysNodeVersion) {
            Write-Host "  > System Node ($SysNodeVersion) is not in the supported range (v18-v22)." -ForegroundColor Yellow
        } else {
            Write-Host "  > No system Node.js found." -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Host "  > Error checking system Node: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 4. Handle Node.js Engine
if ($UseSystemNode) {
    Write-Host "[4/7] DECISION: Reusing system Node.js for space efficiency." -ForegroundColor Green
} else {
    Write-Host "[4/7] DECISION: Using private, isolated Node.js engine." -ForegroundColor Yellow
    if (-not (Test-Path $NodeDir)) {
        $NodeVer = "v20.11.1" # Verified LTS
        $NodeZip = if ($OSArch -eq "AMD64") { "node-$NodeVer-win-x64.zip" } else { "node-$NodeVer-win-x86.zip" }
        $NodeUrl = "https://nodejs.org/dist/$NodeVer/$NodeZip"

        Write-Host "  > Private engine missing. Downloading Windows $OSArch build..." -ForegroundColor Yellow
        $ArchivePath = Join-Path $TempDir $NodeZip
        
        Write-Host "  > Fetching: $NodeUrl" -ForegroundColor Gray
        Invoke-WebRequest -Uri $NodeUrl -OutFile $ArchivePath
        
        Write-Host "  > Extracting engine components..." -ForegroundColor Yellow
        Expand-Archive -Path $ArchivePath -DestinationPath $TempDir
        
        $ExtractedFolder = Get-ChildItem -Path $TempDir -Directory | Where-Object { $_.Name -like "node-*" } | Select-Object -First 1
        Move-Item -Path $ExtractedFolder.FullName -Destination $NodeDir
        
        Remove-Item -Path $ArchivePath
        Remove-Item -Path $TempDir -Recurse
        Write-Host "  > Private engine successfully isolated in .\internal\node" -ForegroundColor Green
    } else {
        Write-Host "  > Using previously isolated internal Node engine." -ForegroundColor Green
    }
    
    # Session Path Override
    $Env:PATH = "$(Join-Path $NodeDir "");" + $Env:PATH
    Write-Host "  > Session PATH updated to prioritize internal engine." -ForegroundColor Gray
}

# 5. Playwright Configuration
Write-Host "[5/7] Configuring Playwright environment..." -ForegroundColor Cyan
$Env:PLAYWRIGHT_BROWSERS_PATH = $BrowserDir
Write-Host "  > Browser location forced to: .\internal\browsers" -ForegroundColor Gray

# 6. Bootstrap Dependencies & Browsers
Write-Host "[6/7] Verifying local dependencies and browsers..." -ForegroundColor Cyan
if (-not (Test-Path (Join-Path $ProjectDir "node_modules"))) {
    Write-Host "  > node_modules missing. Running npm install..." -ForegroundColor Yellow
    npm install
} else {
    Write-Host "  > node_modules found." -ForegroundColor Gray
}

if (-not (Test-Path $BrowserDir) -or (Get-ChildItem $BrowserDir).Count -eq 0) {
    Write-Host "  > Browsers missing. Fetching compatible Chromium builds..." -ForegroundColor Yellow
    npx playwright install chromium --with-deps
} else {
    Write-Host "  > Compatible browsers found in local cache." -ForegroundColor Gray
}

# 7. Execution
Write-Host "[7/7] Environment ready. Executing automation script..." -ForegroundColor Cyan
Write-Host "---" -ForegroundColor Gray
node runner.js "$TaskFile"
