@echo off
echo Testing API Key Management System
echo ===================================

set API_URL=http://localhost:8080/api
set USERNAME=testuser
set PASSWORD=password123
set EMAIL=test@example.com

echo.
echo 1. Registering test user...
curl -s -X POST %API_URL%/auth/register ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"%USERNAME%\",\"email\":\"%EMAIL%\",\"password\":\"%PASSWORD%\"}"

echo.
echo.
echo 2. Logging in to get JWT token...
for /f "tokens=*" %%i in ('curl -s -X POST %API_URL%/auth/login -H "Content-Type: application/json" -d "{\"username\":\"%USERNAME%\",\"password\":\"%PASSWORD%\"}" ^| jq -r .token') do set JWT_TOKEN=%%i

echo JWT Token: %JWT_TOKEN%

echo.
echo 3. Creating first API key...
curl -s -X POST %API_URL%/apikeys ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer %JWT_TOKEN%" ^
  -d "{\"name\":\"Development Key\",\"description\":\"For development testing\",\"rules\":[\"read\",\"write\"]}"

echo.
echo.
echo 4. Creating second API key...
curl -s -X POST %API_URL%/apikeys ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer %JWT_TOKEN%" ^
  -d "{\"name\":\"Production Key\",\"description\":\"For production use\",\"rules\":[\"read\"]}"

echo.
echo.
echo 5. Creating third API key...
curl -s -X POST %API_URL%/apikeys ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer %JWT_TOKEN%" ^
  -d "{\"name\":\"Analytics Key\",\"description\":\"For analytics dashboard\",\"rules\":[\"read\",\"analytics\"]}"

echo.
echo.
echo 6. Trying to create fourth API key (should fail)...
curl -s -X POST %API_URL%/apikeys ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer %JWT_TOKEN%" ^
  -d "{\"name\":\"Extra Key\",\"description\":\"This should fail\",\"rules\":[\"read\"]}"

echo.
echo.
echo 7. Listing all API keys...
curl -s -X GET %API_URL%/apikeys ^
  -H "Authorization: Bearer %JWT_TOKEN%"

echo.
echo.
echo 8. Testing API key validation (you'll need to copy an API key from step 3, 4, or 5)...
echo Please copy an API key from above and run:
echo curl -s -X POST %API_URL%/apikeys/validate -H "Content-Type: application/json" -d "{\"apiKey\":\"YOUR_API_KEY_HERE\"}"

echo.
echo API Key Management Test Complete!
pause