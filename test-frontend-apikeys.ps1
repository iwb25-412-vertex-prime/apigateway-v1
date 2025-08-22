# PowerShell script to test API key functionality
$baseUrl = "http://localhost:8080/api"

Write-Host "Testing API Key Management Frontend Integration..." -ForegroundColor Green
Write-Host ""

# Test user credentials
$username = "testuser_$(Get-Random)"
$email = "test_$(Get-Random)@example.com"
$password = "password123"

Write-Host "1. Registering test user..." -ForegroundColor Yellow
$registerBody = @{
    username = $username
    email = $email
    password = $password
} | ConvertTo-Json

try {
    $registerResponse = Invoke-WebRequest -Uri "$baseUrl/auth/register" -Method POST -Body $registerBody -ContentType "application/json"
    Write-Host "✓ User registered successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Registration failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "2. Logging in..." -ForegroundColor Yellow
$loginBody = @{
    username = $username
    password = $password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-WebRequest -Uri "$baseUrl/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
    $loginData = $loginResponse.Content | ConvertFrom-Json
    $token = $loginData.token
    Write-Host "✓ Login successful" -ForegroundColor Green
    Write-Host "  Token: $($token.Substring(0, 20))..." -ForegroundColor Gray
} catch {
    Write-Host "✗ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "3. Creating API keys..." -ForegroundColor Yellow

# Create first API key
$apiKey1Body = @{
    name = "Development Key"
    description = "For development testing"
    rules = @("read", "write")
} | ConvertTo-Json

try {
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $apiKey1Response = Invoke-WebRequest -Uri "$baseUrl/apikeys" -Method POST -Body $apiKey1Body -Headers $headers
    $apiKey1Data = $apiKey1Response.Content | ConvertFrom-Json
    Write-Host "✓ API Key 1 created: $($apiKey1Data.apiKey.name)" -ForegroundColor Green
    Write-Host "  Key: $($apiKey1Data.apiKey.key)" -ForegroundColor Gray
    $firstApiKeyId = $apiKey1Data.apiKey.id
} catch {
    Write-Host "✗ API Key 1 creation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Red
}

# Create second API key
$apiKey2Body = @{
    name = "Production Key"
    description = "For production use"
    rules = @("read", "analytics")
} | ConvertTo-Json

try {
    $apiKey2Response = Invoke-WebRequest -Uri "$baseUrl/apikeys" -Method POST -Body $apiKey2Body -Headers $headers
    $apiKey2Data = $apiKey2Response.Content | ConvertFrom-Json
    Write-Host "✓ API Key 2 created: $($apiKey2Data.apiKey.name)" -ForegroundColor Green
    Write-Host "  Key: $($apiKey2Data.apiKey.key)" -ForegroundColor Gray
} catch {
    Write-Host "✗ API Key 2 creation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Create third API key
$apiKey3Body = @{
    name = "Testing Key"
    description = "For automated testing"
    rules = @("read")
} | ConvertTo-Json

try {
    $apiKey3Response = Invoke-WebRequest -Uri "$baseUrl/apikeys" -Method POST -Body $apiKey3Body -Headers $headers
    $apiKey3Data = $apiKey3Response.Content | ConvertFrom-Json
    Write-Host "✓ API Key 3 created: $($apiKey3Data.apiKey.name)" -ForegroundColor Green
    Write-Host "  Key: $($apiKey3Data.apiKey.key)" -ForegroundColor Gray
} catch {
    Write-Host "✗ API Key 3 creation failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "4. Listing API keys..." -ForegroundColor Yellow

try {
    $listResponse = Invoke-WebRequest -Uri "$baseUrl/apikeys" -Method GET -Headers $headers
    $listData = $listResponse.Content | ConvertFrom-Json
    Write-Host "✓ API Keys retrieved successfully" -ForegroundColor Green
    Write-Host "  Total keys: $($listData.apiKeys.Count)" -ForegroundColor Gray
    
    foreach ($key in $listData.apiKeys) {
        Write-Host "  - $($key.name) ($($key.status)) - Usage: $($key.usage_count)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ Failed to list API keys: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "5. Testing API key status update..." -ForegroundColor Yellow

if ($firstApiKeyId) {
    try {
        $statusBody = @{
            status = "inactive"
        } | ConvertTo-Json
        
        $statusResponse = Invoke-WebRequest -Uri "$baseUrl/apikeys/$firstApiKeyId/status" -Method PUT -Body $statusBody -Headers $headers
        Write-Host "✓ API Key status updated to inactive" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to update API key status: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "6. Testing 4th API key creation (should fail)..." -ForegroundColor Yellow

$apiKey4Body = @{
    name = "Fourth Key (Should Fail)"
    description = "This should fail due to 3-key limit"
    rules = @("read")
} | ConvertTo-Json

try {
    $apiKey4Response = Invoke-WebRequest -Uri "$baseUrl/apikeys" -Method POST -Body $apiKey4Body -Headers $headers
    Write-Host "✗ 4th API Key creation should have failed but succeeded!" -ForegroundColor Red
} catch {
    Write-Host "✓ 4th API Key creation correctly failed (3-key limit enforced)" -ForegroundColor Green
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "API Key Management Test Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Frontend URLs to test:" -ForegroundColor Cyan
Write-Host "- Main Dashboard: http://localhost:3000" -ForegroundColor White
Write-Host "- API Key Management: http://localhost:3000/apikeys" -ForegroundColor White
Write-Host "- Authentication: http://localhost:3000/auth" -ForegroundColor White
Write-Host ""
Write-Host "Test Credentials:" -ForegroundColor Cyan
Write-Host "- Username: $username" -ForegroundColor White
Write-Host "- Email: $email" -ForegroundColor White
Write-Host "- Password: $password" -ForegroundColor White