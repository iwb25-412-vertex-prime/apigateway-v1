@echo off
REM Install Node.js dependencies
echo Installing Node.js dependencies...
cd nodejs-backend
call npm install
cd ..
echo Dependencies installed successfully!
pause
