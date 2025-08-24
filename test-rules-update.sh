#!/bin/bash

echo "Testing API Key Rules Update Functionality"
echo "=========================================="

API_URL="http://localhost:8080/api"

echo
echo "1. Registering test user..."
curl -X POST $API_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "email": "test@example.com", "password": "password123"}'

echo
echo
echo "2. Logging in to get JWT token..."
JWT_TOKEN=$(curl -s -X POST $API_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "password123"}' | jq -r .token)

echo "Token: $JWT_TOKEN"

echo
echo "3. Creating API key with initial rules..."
API_KEY_ID=$(curl -s -X POST $API_URL/apikeys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"name": "Test Key", "description": "For testing rules update", "rules": ["no-spam-content", "no-adult-content"]}' | jq -r .apiKey.id)

echo "API Key ID: $API_KEY_ID"

echo
echo "4. Getting current API key details..."
curl -X GET $API_URL/apikeys \
  -H "Authorization: Bearer $JWT_TOKEN"

echo
echo
echo "5. Updating API key rules..."
curl -X PUT $API_URL/apikeys/$API_KEY_ID/rules \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"rules": ["no-spam-content", "no-adult-content", "no-hate-speech", "family-friendly-only"]}'

echo
echo
echo "6. Verifying updated rules..."
curl -X GET $API_URL/apikeys \
  -H "Authorization: Bearer $JWT_TOKEN"

echo
echo
echo "7. Testing with empty rules..."
curl -X PUT $API_URL/apikeys/$API_KEY_ID/rules \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"rules": []}'

echo
echo
echo "8. Verifying empty rules..."
curl -X GET $API_URL/apikeys \
  -H "Authorization: Bearer $JWT_TOKEN"

echo
echo
echo "Test completed!"