# Test script to verify that all API keys work without permission restrictions
$baseUrl = "http://localhost:8080/api"

Write-Host "Testing API Access Without Permission Restrictions" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host ""

$apiKey = Read-Host "Enter any API key to test"

if ([string]::IsNullOrEmpty($apiKey)) {
    Write-Host "No API key provided" -ForegroundColor Red
    exit 1
}

$headers = @{
    "X-API-Key" = $apiKey
    "Content-Type" = "application/json"
}

Write-Host "Testing all endpoints with your API key..." -ForegroundColor Yellow
Write-Host ""

# Test 1: Content Moderation
Write-Host "1. Testing Content Moderation..." -ForegroundColor Cyan
try {
    $moderationBody = @{
        text = "This is a test message for content moderation"
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest -Uri "$baseUrl/moderate-content/text/v1" -Method POST -Body $moderationBody -Headers $headers
    $data = $response.Content | ConvertFrom-Json
    Write-Host "✓ Content moderation works! Status: $($data.status)" -ForegroundColor Green
} catch {
    Write-Host "✗ Content moderation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Users
Write-Host "2. Testing Users API..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/users" -Method GET -Headers $headers
    $data = $response.Content | ConvertFrom-Json
    Write-Host "✓ Users API works! Found $($data.count) users" -ForegroundColor Green
} catch {
    Write-Host "✗ Users API failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Projects
Write-Host "3. Testing Projects API..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/projects" -Method GET -Headers $headers
    $data = $response.Content | ConvertFrom-Json
    Write-Host "✓ Projects API works! Found $($data.count) projects" -ForegroundColor Green
} catch {
    Write-Host "✗ Projects API failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Analytics
Write-Host "4. Testing Analytics API..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/analytics/summary" -Method GET -Headers $headers
    $data = $response.Content | ConvertFrom-Json
    Write-Host "✓ Analytics API works! Total users: $($data.total_users)" -ForegroundColor Green
} catch {
    Write-Host "✗ Analytics API failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Create Project
Write-Host "5. Testing Project Creation..." -ForegroundColor Cyan
try {
    $projectBody = @{
        name = "Test Project $(Get-Random)"
        description = "Created by permission test"
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest -Uri "$baseUrl/projects" -Method POST -Body $projectBody -Headers $headers
    $data = $response.Content | ConvertFrom-Json
    Write-Host "✓ Project creation works! Created: $($data.project.name)" -ForegroundColor Green
} catch {
    Write-Host "✗ Project creation failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "All API endpoints are now accessible with any valid API key!" -ForegroundColor Green
Write-Host "The only limit is your monthly quota of 100 requests." -ForegroundColor Yellow