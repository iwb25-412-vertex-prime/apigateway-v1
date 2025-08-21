@echo off
setlocal enabledelayedexpansion

set API_URL=http://localhost:8080/api
echo Testing User Portal API...
echo.

REM Test health endpoint
echo 1. Testing health endpoint...
curl -s "%API_URL%/health"
echo.
echo.

REM Test user registration
echo 2. Testing user registration...
curl -s -X POST "%API_URL%/auth/register" ^
  -H "Content-Type: application/json" ^
  -d "{\"username\": \"testuser123\", \"email\": \"test@example.com\", \"password\": \"securepassword123\"}"
echo.
echo.

REM Test user login
echo 3. Testing user login...
for /f "delims=" %%i in ('curl -s -X POST "%API_URL%/auth/login" -H "Content-Type: application/json" -d "{\"username\": \"testuser123\", \"password\": \"securepassword123\"}"') do set LOGIN_RESPONSE=%%i
echo !LOGIN_RESPONSE!
echo.

REM Note: Token extraction in batch is complex, so we'll use a placeholder
set TOKEN=placeholder_token
echo Using token for further tests...
echo.

REM Test profile endpoint
echo 4. Testing profile endpoint...
curl -s -X GET "%API_URL%/auth/profile" ^
  -H "Authorization: Bearer %TOKEN%"
echo.
echo.

REM Test logout
echo 5. Testing logout...
curl -s -X POST "%API_URL%/auth/logout" ^
  -H "Authorization: Bearer %TOKEN%"
echo.
echo.

echo API testing completed!
echo Note: For full testing with token extraction, use the bash script or test manually.
pause