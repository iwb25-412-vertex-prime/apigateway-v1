# PowerShell script to fix API key quota issues
$baseUrl = "http://localhost:8080/api"

Write-Host "API Key Quota Fix Script" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
Write-Host ""

Write-Host "This script will help you reset your API key quotas if they're stuck." -ForegroundColor Yellow
Write-Host ""

# Get user credentials to login and get their API keys
$username = Read-Host "Enter your username"
$password = Read-Host "Enter your password" -AsSecureString
$passwordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

Write-Host ""
Write-Host "1. Logging in..." -ForegroundColor Cyan

try {
    $loginBody = @{
        username = $username
        password = $passwordText
    } | ConvertTo-Json
    
    $loginResponse = Invoke-WebRequest -Uri "$baseUrl/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
    $loginData = $loginResponse.Content | ConvertFrom-Json
    $token = $loginData.token
    Write-Host "✓ Login successful" -ForegroundColor Green
} catch {
    Write-Host "✗ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "2. Getting your API keys..." -ForegroundColor Cyan

try {
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    $keysResponse = Invoke-WebRequest -Uri "$baseUrl/apikeys" -Method GET -Headers $headers
    $keysData = $keysResponse.Content | ConvertFrom-Json
    
    Write-Host "✓ Found $($keysData.apiKeys.Count) API keys" -ForegroundColor Green
    
    foreach ($key in $keysData.apiKeys) {
        Write-Host ""
        Write-Host "API Key: $($key.name)" -ForegroundColor White
        Write-Host "  Status: $($key.status)" -ForegroundColor Gray
        Write-Host "  Usage: $($key.current_month_usage)/$($key.monthly_quota)" -ForegroundColor Gray
        Write-Host "  Remaining: $($key.remaining_quota)" -ForegroundColor Gray
        Write-Host "  Reset Date: $($key.quota_reset_date)" -ForegroundColor Gray
        
        # Check if quota is problematic
        if ($key.quota_reset_date -like "2025*" -or $key.current_month_usage -ge $key.monthly_quota) {
            Write-Host "  ⚠️  This key has quota issues!" -ForegroundColor Red
            
            # Try to update the key rules to trigger a refresh
            Write-Host "  Attempting to refresh quota..." -ForegroundColor Yellow
            
            try {
                $updateBody = @{
                    rules = $key.rules
                } | ConvertTo-Json
                
                $updateResponse = Invoke-WebRequest -Uri "$baseUrl/apikeys/$($key.id)/rules" -Method PUT -Body $updateBody -Headers $headers -ContentType "application/json"
                Write-Host "  ✓ Quota refresh attempted" -ForegroundColor Green
            } catch {
                Write-Host "  ✗ Failed to refresh quota" -ForegroundColor Red
            }
        } else {
            Write-Host "  ✓ Quota looks good" -ForegroundColor Green
        }
    }
    
} catch {
    Write-Host "✗ Failed to get API keys: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "3. Testing API key validation..." -ForegroundColor Cyan

if ($keysData.apiKeys.Count -gt 0) {
    $testKey = $keysData.apiKeys[0]
    Write-Host "Testing with key: $($testKey.name)" -ForegroundColor Gray
    
    # We can't get the actual API key value, so we'll just show the quota status
    try {
        $quotaResponse = Invoke-WebRequest -Uri "$baseUrl/apikeys/$($testKey.id)/quota" -Method GET -Headers $headers
        $quotaData = $quotaResponse.Content | ConvertFrom-Json
        
        Write-Host "✓ Quota Status:" -ForegroundColor Green
        Write-Host "  Monthly Quota: $($quotaData.monthlyQuota)" -ForegroundColor Gray
        Write-Host "  Current Usage: $($quotaData.currentMonthUsage)" -ForegroundColor Gray
        Write-Host "  Remaining: $($quotaData.remainingQuota)" -ForegroundColor Gray
        Write-Host "  Reset Date: $($quotaData.quotaResetDate)" -ForegroundColor Gray
        Write-Host "  Available: $($quotaData.quotaAvailable)" -ForegroundColor $(if ($quotaData.quotaAvailable) { "Green" } else { "Red" })
        
    } catch {
        Write-Host "✗ Failed to get quota status: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Quota Fix Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "If you're still having issues:" -ForegroundColor Yellow
Write-Host "1. Restart the Ballerina service (bal run)" -ForegroundColor White
Write-Host "2. Create a new API key with 'moderate' permission" -ForegroundColor White
Write-Host "3. The service now automatically fixes quota issues on startup" -ForegroundColor White