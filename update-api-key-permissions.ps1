# PowerShell script to update API key permissions
$baseUrl = "http://localhost:8080/api"

Write-Host "API Key Permission Update Script" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
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
Write-Host "2. Getting your API keys..." -ForegroundColor Cyan

try {
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $keysResponse = Invoke-WebRequest -Uri "$baseUrl/apikeys" -Method GET -Headers $headers
    $keysData = $keysResponse.Content | ConvertFrom-Json
    
    Write-Host "✓ Found $($keysData.apiKeys.Count) API keys" -ForegroundColor Green
    Write-Host ""
    
    if ($keysData.apiKeys.Count -eq 0) {
        Write-Host "No API keys found. Please create one first at http://localhost:3000/apikeys" -ForegroundColor Yellow
        exit 0
    }
    
    # Show existing keys
    for ($i = 0; $i -lt $keysData.apiKeys.Count; $i++) {
        $key = $keysData.apiKeys[$i]
        Write-Host "[$($i + 1)] $($key.name)" -ForegroundColor White
        Write-Host "    Status: $($key.status)" -ForegroundColor Gray
        Write-Host "    Current permissions: $($key.rules -join ', ')" -ForegroundColor Gray
        Write-Host "    Has 'moderate' permission: $(if ($key.rules -contains 'moderate') { 'Yes' } else { 'No' })" -ForegroundColor $(if ($key.rules -contains 'moderate') { "Green" } else { "Red" })
        Write-Host ""
    }
    
} catch {
    Write-Host "✗ Failed to get API keys: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "3. Select API key to update..." -ForegroundColor Cyan
$selection = Read-Host "Enter the number of the API key to update (1-$($keysData.apiKeys.Count))"

try {
    $selectedIndex = [int]$selection - 1
    if ($selectedIndex -lt 0 -or $selectedIndex -ge $keysData.apiKeys.Count) {
        Write-Host "Invalid selection" -ForegroundColor Red
        exit 1
    }
    
    $selectedKey = $keysData.apiKeys[$selectedIndex]
    Write-Host "Selected: $($selectedKey.name)" -ForegroundColor Yellow
    
} catch {
    Write-Host "Invalid selection" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "4. Current permissions: $($selectedKey.rules -join ', ')" -ForegroundColor Gray

# Add 'moderate' permission if not already present
$newRules = $selectedKey.rules
if ($newRules -notcontains 'moderate') {
    $newRules += 'moderate'
    Write-Host "Adding 'moderate' permission..." -ForegroundColor Yellow
} else {
    Write-Host "'moderate' permission already exists!" -ForegroundColor Green
    Write-Host "Your API key should work for content moderation." -ForegroundColor Green
    exit 0
}

# Also ensure other common permissions are present
$recommendedPermissions = @('read', 'write', 'moderate', 'analytics')
foreach ($perm in $recommendedPermissions) {
    if ($newRules -notcontains $perm) {
        $addPerm = Read-Host "Add '$perm' permission? (y/n)"
        if ($addPerm -eq 'y' -or $addPerm -eq 'Y') {
            $newRules += $perm
        }
    }
}

Write-Host ""
Write-Host "New permissions will be: $($newRules -join ', ')" -ForegroundColor Cyan
$confirm = Read-Host "Update API key permissions? (y/n)"

if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "Update cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "5. Updating API key permissions..." -ForegroundColor Cyan

try {
    $updateBody = @{
        rules = $newRules
    } | ConvertTo-Json
    
    $updateResponse = Invoke-WebRequest -Uri "$baseUrl/apikeys/$($selectedKey.id)/rules" -Method PUT -Body $updateBody -Headers $headers
    $updateData = $updateResponse.Content | ConvertFrom-Json
    
    Write-Host "✓ API key permissions updated successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Updated permissions: $($updateData.apiKey.rules -join ', ')" -ForegroundColor Green
    
} catch {
    Write-Host "✗ Failed to update permissions: $($_.Exception.Message)" -ForegroundColor Red
    
    # Try to get more error details
    try {
        $errorContent = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorContent)
        $errorBody = $reader.ReadToEnd() | ConvertFrom-Json
        Write-Host "Error details: $($errorBody.error)" -ForegroundColor Red
    } catch {
        # Ignore error parsing errors
    }
    exit 1
}

Write-Host ""
Write-Host "6. Testing content moderation access..." -ForegroundColor Cyan

# We can't test with the actual API key since we don't have it, but we can check the updated permissions
try {
    $keysResponse2 = Invoke-WebRequest -Uri "$baseUrl/apikeys" -Method GET -Headers @{"Authorization" = "Bearer $token"}
    $keysData2 = $keysResponse2.Content | ConvertFrom-Json
    
    $updatedKey = $keysData2.apiKeys | Where-Object { $_.id -eq $selectedKey.id }
    
    if ($updatedKey.rules -contains 'moderate') {
        Write-Host "✓ API key now has 'moderate' permission!" -ForegroundColor Green
        Write-Host ""
        Write-Host "You can now use your API key for content moderation:" -ForegroundColor Cyan
        Write-Host "curl -X POST http://localhost:8080/api/moderate-content/text/v1 \\" -ForegroundColor White
        Write-Host "  -H `"X-API-Key: your_api_key_here`" \\" -ForegroundColor White
        Write-Host "  -H `"Content-Type: application/json`" \\" -ForegroundColor White
        Write-Host "  -d '{`"text`":`"Test message for moderation`"}'" -ForegroundColor White
    } else {
        Write-Host "✗ Something went wrong - 'moderate' permission not found" -ForegroundColor Red
    }
    
} catch {
    Write-Host "✗ Failed to verify update" -ForegroundColor Red
}

Write-Host ""
Write-Host "Permission Update Complete!" -ForegroundColor Green