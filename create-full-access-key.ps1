# PowerShell script to create a new API key with all permissions
$baseUrl = "http://localhost:8080/api"

Write-Host "Create Full Access API Key" -ForegroundColor Green
Write-Host "==========================" -ForegroundColor Green
Write-Host ""

# Get user credentials
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
Write-Host "2. Creating new API key with all permissions..." -ForegroundColor Cyan

try {
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $createBody = @{
        name = "Full Access Key - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        description = "API key with all permissions for content moderation, analytics, and data access"
        rules = @("read", "write", "moderate", "analytics")
    } | ConvertTo-Json
    
    $createResponse = Invoke-WebRequest -Uri "$baseUrl/apikeys" -Method POST -Body $createBody -Headers $headers
    $createData = $createResponse.Content | ConvertFrom-Json
    
    Write-Host "✓ API key created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🔑 Your new API key:" -ForegroundColor Yellow
    Write-Host $createData.key -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: Copy this key now! It won't be shown again." -ForegroundColor Red
    Write-Host ""
    Write-Host "Key details:" -ForegroundColor Cyan
    Write-Host "  Name: $($createData.apiKey.name)" -ForegroundColor Gray
    Write-Host "  Permissions: $($createData.apiKey.rules -join ', ')" -ForegroundColor Gray
    Write-Host "  Monthly quota: $($createData.apiKey.monthly_quota) requests" -ForegroundColor Gray
    Write-Host "  Status: $($createData.apiKey.status)" -ForegroundColor Gray
    
} catch {
    Write-Host "✗ Failed to create API key: $($_.Exception.Message)" -ForegroundColor Red
    
    # Try to get more error details
    try {
        $errorContent = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorContent)
        $errorBody = $reader.ReadToEnd() | ConvertFrom-Json
        Write-Host "Error details: $($errorBody.error)" -ForegroundColor Red
        
        if ($errorBody.error -like "*Maximum of 3 API keys*") {
            Write-Host ""
            Write-Host "You already have 3 API keys. Delete one first or use the update script:" -ForegroundColor Yellow
            Write-Host ".\update-api-key-permissions.ps1" -ForegroundColor White
        }
    } catch {
        # Ignore error parsing errors
    }
    exit 1
}

Write-Host ""
Write-Host "3. Testing the new API key..." -ForegroundColor Cyan

try {
    $testBody = @{
        text = "This is a test message for content moderation"
    } | ConvertTo-Json
    
    $testHeaders = @{
        "X-API-Key" = $createData.key
        "Content-Type" = "application/json"
    }
    
    $testResponse = Invoke-WebRequest -Uri "$baseUrl/moderate-content/text/v1" -Method POST -Body $testBody -Headers $testHeaders
    $testData = $testResponse.Content | ConvertFrom-Json
    
    Write-Host "✓ Content moderation test successful!" -ForegroundColor Green
    Write-Host "  Status: $($testData.status)" -ForegroundColor Gray
    Write-Host "  Flagged: $($testData.result.flagged)" -ForegroundColor Gray
    Write-Host "  Confidence: $($testData.result.confidence)" -ForegroundColor Gray
    
} catch {
    Write-Host "✗ Test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Example usage:" -ForegroundColor Cyan
Write-Host "curl -X POST http://localhost:8080/api/moderate-content/text/v1 \\" -ForegroundColor White
Write-Host "  -H `"X-API-Key: $($createData.key)`" \\" -ForegroundColor White
Write-Host "  -H `"Content-Type: application/json`" \\" -ForegroundColor White
Write-Host "  -d '{`"text`":`"Your content to moderate`"}'" -ForegroundColor White