#!/usr/bin/env pwsh

# Test script to verify dashboard metrics are updating correctly

Write-Host "Testing Dashboard Metrics Update..." -ForegroundColor Green

# Configuration
$baseUrl = "http://localhost:8080/api"
$frontendUrl = "http://localhost:3000"

# Test credentials
$username = "testuser"
$password = "testpass123"

Write-Host "`n1. Testing user authentication..." -ForegroundColor Yellow

# Login to get token
$loginBody = @{
    username = $username
    password = $password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
    $token = $loginResponse.token
    Write-Host "✓ Login successful" -ForegroundColor Green
} catch {
    Write-Host "✗ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure the backend is running and user exists" -ForegroundColor Yellow
    exit 1
}

# Headers for authenticated requests
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

Write-Host "`n2. Fetching current API key statistics..." -ForegroundColor Yellow

try {
    $apiKeysResponse = Invoke-RestMethod -Uri "$baseUrl/apikeys" -Method GET -Headers $headers
    $apiKeys = $apiKeysResponse.apiKeys
    
    Write-Host "Current Statistics:" -ForegroundColor Cyan
    Write-Host "  Total API Keys: $($apiKeys.Count)" -ForegroundColor White
    Write-Host "  Active Keys: $(($apiKeys | Where-Object { $_.status -eq 'active' }).Count)" -ForegroundColor White
    
    $totalUsage = ($apiKeys | Measure-Object -Property usage_count -Sum).Sum
    $monthlyUsage = ($apiKeys | Measure-Object -Property current_month_usage -Sum).Sum
    
    Write-Host "  Total Requests: $totalUsage" -ForegroundColor White
    Write-Host "  This Month Requests: $monthlyUsage" -ForegroundColor White
    
    Write-Host "`n✓ API key statistics retrieved successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to fetch API keys: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n3. Testing API key creation (if under limit)..." -ForegroundColor Yellow

if ($apiKeys.Count -lt 3) {
    $createKeyBody = @{
        name = "Dashboard Test Key $(Get-Date -Format 'HHmmss')"
        description = "Test key for dashboard metrics verification"
    } | ConvertTo-Json
    
    try {
        $createResponse = Invoke-RestMethod -Uri "$baseUrl/apikeys" -Method POST -Body $createKeyBody -Headers $headers
        Write-Host "✓ New API key created: $($createResponse.apiKey.name)" -ForegroundColor Green
        $newApiKey = $createResponse.key
    } catch {
        Write-Host "✗ Failed to create API key: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "⚠ Already at maximum API key limit (3)" -ForegroundColor Yellow
    $newApiKey = $apiKeys[0].key_preview  # Use existing key for testing
}

Write-Host "`n4. Testing API usage to increment counters..." -ForegroundColor Yellow

if ($newApiKey) {
    # Test API usage with the key
    $testHeaders = @{
        "X-API-Key" = $newApiKey
        "Content-Type" = "application/json"
    }
    
    $testBody = @{
        text = "This is a test message for dashboard metrics verification"
    } | ConvertTo-Json
    
    try {
        for ($i = 1; $i -le 3; $i++) {
            $testResponse = Invoke-RestMethod -Uri "$baseUrl/moderate-content/text/v1" -Method POST -Body $testBody -Headers $testHeaders
            Write-Host "  API call $i completed" -ForegroundColor White
            Start-Sleep -Seconds 1
        }
        Write-Host "✓ API usage test completed (3 requests made)" -ForegroundColor Green
    } catch {
        Write-Host "✗ API usage test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n5. Fetching updated statistics..." -ForegroundColor Yellow

try {
    Start-Sleep -Seconds 2  # Wait for database updates
    $updatedResponse = Invoke-RestMethod -Uri "$baseUrl/apikeys" -Method GET -Headers $headers
    $updatedApiKeys = $updatedResponse.apiKeys
    
    Write-Host "Updated Statistics:" -ForegroundColor Cyan
    Write-Host "  Total API Keys: $($updatedApiKeys.Count)" -ForegroundColor White
    Write-Host "  Active Keys: $(($updatedApiKeys | Where-Object { $_.status -eq 'active' }).Count)" -ForegroundColor White
    
    $newTotalUsage = ($updatedApiKeys | Measure-Object -Property usage_count -Sum).Sum
    $newMonthlyUsage = ($updatedApiKeys | Measure-Object -Property current_month_usage -Sum).Sum
    
    Write-Host "  Total Requests: $newTotalUsage" -ForegroundColor White
    Write-Host "  This Month Requests: $newMonthlyUsage" -ForegroundColor White
    
    # Check if metrics increased
    if ($newTotalUsage -gt $totalUsage) {
        Write-Host "✓ Total usage counter increased correctly" -ForegroundColor Green
    } else {
        Write-Host "⚠ Total usage counter did not increase" -ForegroundColor Yellow
    }
    
    if ($newMonthlyUsage -gt $monthlyUsage) {
        Write-Host "✓ Monthly usage counter increased correctly" -ForegroundColor Green
    } else {
        Write-Host "⚠ Monthly usage counter did not increase" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "✗ Failed to fetch updated statistics: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n6. Testing frontend dashboard access..." -ForegroundColor Yellow

try {
    $frontendResponse = Invoke-WebRequest -Uri $frontendUrl -Method GET -TimeoutSec 10
    if ($frontendResponse.StatusCode -eq 200) {
        Write-Host "✓ Frontend dashboard is accessible" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠ Frontend dashboard may not be running: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "  Make sure to run: npm run dev in the userportal directory" -ForegroundColor Cyan
}

Write-Host "`n=== Dashboard Metrics Test Summary ===" -ForegroundColor Magenta
Write-Host "1. Check the dashboard at: $frontendUrl" -ForegroundColor White
Write-Host "2. Verify that the metrics show current values" -ForegroundColor White
Write-Host "3. Use the refresh button to update statistics" -ForegroundColor White
Write-Host "4. Metrics should auto-refresh every 30 seconds" -ForegroundColor White

Write-Host "`nTest completed!" -ForegroundColor Green