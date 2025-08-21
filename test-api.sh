#!/bin/bash

API_URL="http://localhost:8080/api"
echo "Testing User Portal API..."

# Test health endpoint
echo "1. Testing health endpoint..."
curl -s "$API_URL/health" | jq '.'
echo ""

# Test user registration
echo "2. Testing user registration..."
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser123",
    "email": "test@example.com",
    "password": "securepassword123"
  }')
echo "$REGISTER_RESPONSE" | jq '.'
echo ""

# Test user login
echo "3. Testing user login..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser123",
    "password": "securepassword123"
  }')
echo "$LOGIN_RESPONSE" | jq '.'

# Extract token for further tests
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')
echo "Extracted token: ${TOKEN:0:50}..."
echo ""

# Test profile endpoint
echo "4. Testing profile endpoint..."
curl -s -X GET "$API_URL/auth/profile" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo ""

# Test profile update
echo "5. Testing profile update..."
curl -s -X PUT "$API_URL/auth/profile" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email": "updated@example.com"}' | jq '.'
echo ""

# Test logout
echo "6. Testing logout..."
curl -s -X POST "$API_URL/auth/logout" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo ""

# Test accessing profile after logout (should fail)
echo "7. Testing profile access after logout (should fail)..."
curl -s -X GET "$API_URL/auth/profile" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo ""

echo "API testing completed!"