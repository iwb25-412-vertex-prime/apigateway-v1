@echo off
echo Starting User Portal with SQLite...

REM Setup SQLite database
call setup-sqlite.bat

REM Start backend in a new window
echo Starting backend...
start "Backend Server" cmd /k "cd ballerina-backend && bal run"

REM Wait a moment for backend to start
timeout /t 5 /nobreak >nul

REM Start frontend in a new window
echo Starting frontend...
start "Frontend Server" cmd /k "cd userportal && npm install && npm run dev"

echo.
echo Both servers are starting...
echo Backend: http://localhost:8080
echo Frontend: http://localhost:3000
echo.
echo Press any key to close this window...
pause >nul