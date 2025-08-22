#!/bin/bash

echo "Testing API Key Management System"
echo "================================="

API_URL="http://localhost:8080/api"
USERNAME="testuser"
PASSWORD="password123"
EMAIL="test@example.com"

echo
echo "1. Registering test user..."
curl -s -X POST $API_URL/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}"

echo
echo
echo "2. Logging in to get JWT token..."
JWT_TOKEN=$(curl -s -X POST $API_URL/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}" | jq -r .token)

echo "JWT Token: $JWT_TOKEN"

echo
echo "3. Creating first API key..."
API_KEY_1=$(curl -s -X POST $API_URL/apikeys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d "{\"name\":\"Development Key\",\"description\":\"For development testing\",\"rules\":[\"read\",\"write\"]}")

echo "$API_KEY_1"

echo
echo "4. Creating second API key..."
curl -s -X POST $API_URL/apikeys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d "{\"name\":\"Production Key\",\"description\":\"For production use\",\"rules\":[\"read\"]}"

echo
echo
echo "5. Creating third API key..."
curl -s -X POST $API_URL/apikeys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d "{\"name\":\"Analytics Key\",\"description\":\"For analytics dashboard\",\"rules\":[\"read\",\"analytics\"]}"

echo
echo
echo "6. Trying to create fourth API key (should fail)..."
curl -s -X POST $API_URL/apikeys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d "{\"name\":\"Extra Key\",\"description\":\"This should fail\",\"rules\":[\"read\"]}"

echo
echo
echo "7. Listing all API keys..."
curl -s -X GET $API_URL/apikeys \
  -H "Authorization: Bearer $JWT_TOKEN"

echo
echo
echo "8. Testing API key validation..."
# Extract API key from the first creation response
EXTRACTED_KEY=$(echo "$API_KEY_1" | jq -r .key)
if [ "$EXTRACTED_KEY" != "null" ] && [ "$EXTRACTED_KEY" != "" ]; then
    echo "Testing with API key: $EXTRACTED_KEY"
    curl -s -X POST $API_URL/apikeys/validate \
      -H "Content-Type: application/json" \
      -d "{\"apiKey\":\"$EXTRACTED_KEY\"}"
else
    echo "Could not extract API key for validation test"
fi

echo
echo
echo "API Key Management Test Complete!"