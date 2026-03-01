@echo off
REM Cleanup script to remove Ballerina backend
echo Removing Ballerina backend directory...
echo.
echo Please make sure VS Code, File Explorer, and any terminals are not accessing the ballerina-backend directory.
echo.
pause

echo Attempting to remove ballerina-backend directory...
rd /s /q ballerina-backend

if exist ballerina-backend (
    echo.
    echo Failed to remove directory. It may be locked by another process.
    echo Please close all programs that might be accessing it and try again.
    echo.
    pause
) else (
    echo.
    echo Successfully removed ballerina-backend directory!
    echo.
    echo All Ballerina-related files have been removed.
    echo The project now uses only Node.js backend.
    echo.
    pause
)
