@echo off
echo Starting Ballerina Backend and Next.js Frontend...

echo.
echo Starting Ballerina backend on port 8080...
start "Ballerina Backend" cmd /k "cd ballerina-backend && bal run"

echo.
echo Waiting 5 seconds for backend to start...
timeout /t 5 /nobreak > nul

echo.
echo Starting Next.js frontend on port 3000...
start "Next.js Frontend" cmd /k "cd userportal && npm run dev"

echo.
echo Both services are starting...
echo Backend: http://localhost:8080
echo Frontend: http://localhost:3000
echo.
echo Press any key to exit...
pause > nul