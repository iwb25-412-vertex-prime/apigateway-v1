#!/usr/bin/env pwsh

# Debug script to check what the API is returning for YOUR current user

Write-Host "Debugging Dashboard API Response..." -ForegroundColor Green

# Configuration
$baseUrl = "http://localhost:8080/api"

Write-Host "`nPlease enter your login credentials:" -ForegroundColor Yellow
$username = Read-Host "Username"
$password = Read-Host "Password" -AsSecureString
$passwordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

Write-Host "`n1. Testing login..." -ForegroundColor Yellow

$loginBody = @{
    username = $username
    password = $passwordText
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
    $token = $loginResponse.token
    Write-Host "✓ Login successful for user: $($loginResponse.user.username)" -ForegroundColor Green
    Write-Host "  User ID: $($loginResponse.user.id)" -ForegroundColor White
} catch {
    Write-Host "✗ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n2. Fetching API keys for your user..." -ForegroundColor Yellow

$headers = @{
    "Authorization" = "Bearer $token"
}

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/apikeys" -Method GET -Headers $headers
    
    Write-Host "`nAPI Keys Response:" -ForegroundColor Cyan
    Write-Host "  Total Keys: $($response.count)" -ForegroundColor White
    Write-Host "  Max Allowed: $($response.maxAllowed)" -ForegroundColor White
    
    if ($response.apiKeys -and $response.apiKeys.Count -gt 0) {
        Write-Host "`nYour API Keys:" -ForegroundColor Cyan
        $totalUsage = 0
        $monthlyUsage = 0
        $activeCount = 0
        
        $response.apiKeys | ForEach-Object {
            Write-Host "  Key: $($_.name)" -ForegroundColor White
            Write-Host "    ID: $($_.id)" -ForegroundColor Gray
            Write-Host "    Status: $($_.status)" -ForegroundColor White
            Write-Host "    Usage Count: $($_.usage_count)" -ForegroundColor White
            Write-Host "    Monthly Usage: $($_.current_month_usage)" -ForegroundColor White
            Write-Host "    Quota Reset: $($_.quota_reset_date)" -ForegroundColor White
            Write-Host ""
            
            $totalUsage += $_.usage_count
            $monthlyUsage += $_.current_month_usage
            if ($_.status -eq "active") { $activeCount++ }
        }
        
        Write-Host "Dashboard Should Show:" -ForegroundColor Green
        Write-Host "  Total API Keys: $($response.apiKeys.Count)" -ForegroundColor White
        Write-Host "  Active Keys: $activeCount" -ForegroundColor White
        Write-Host "  Total Requests: $totalUsage" -ForegroundColor White
        Write-Host "  This Month: $monthlyUsage" -ForegroundColor White
        
    } else {
        Write-Host "`n⚠ No API keys found for your user!" -ForegroundColor Yellow
        Write-Host "Create an API key first:" -ForegroundColor Cyan
        Write-Host "1. Go to the API Keys page in the dashboard" -ForegroundColor White
        Write-Host "2. Click 'Create API Key'" -ForegroundColor White
        Write-Host "3. Give it a name and create it" -ForegroundColor White
        Write-Host "4. Make some API calls to generate usage" -ForegroundColor White
    }
    
} catch {
    Write-Host "✗ Failed to fetch API keys: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
}

Write-Host "`n3. Next steps:" -ForegroundColor Yellow
Write-Host "1. Open browser dev tools (F12)" -ForegroundColor Cyan
Write-Host "2. Go to Console tab" -ForegroundColor Cyan
Write-Host "3. Refresh the dashboard page" -ForegroundColor Cyan
Write-Host "4. Look for debug logs starting with 'fetchStats called'" -ForegroundColor Cyan
Write-Host "5. Check if the API response matches what we see here" -ForegroundColor Cyan