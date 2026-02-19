@echo off
REM run.bat - Entry point for the Portable Playwright Engine
echo Starting Portable Engine...
cd internal && powershell -NoProfile -ExecutionPolicy Bypass -File "./setup.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo Errors occurred. Check log above.
    pause
)
