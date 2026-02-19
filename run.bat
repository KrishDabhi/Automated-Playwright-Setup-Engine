@echo off
echo Starting Portable Playwright Engine...
cd internal && powershell -NoProfile -ExecutionPolicy Bypass -File "./setup.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ The engine encountered an error.
    pause
)
