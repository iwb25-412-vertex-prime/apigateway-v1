@echo off
echo Testing backend startup...

cd ballerina-backend
echo Starting Ballerina service...
start /B bal run > backend.log 2>&1

echo Waiting for service to start...
timeout /t 5 /nobreak >nul

echo Testing health endpoint...
curl http://localhost:8080/api/health

echo.
echo Backend log:
type backend.log

pause