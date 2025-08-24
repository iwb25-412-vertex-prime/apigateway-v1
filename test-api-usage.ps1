# PowerShell script to demonstrate API key usage
$baseUrl = "http://localhost:8080/api"

Write-Host "API Key Usage Demo" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host ""

# You'll need to get an actual API key from the web interface first
$apiKey = Read-Host "Enter your API key (get one from http://localhost:3000/apikeys)"

if ([string]::IsNullOrEmpty($apiKey)) {
    Write-Host "No API key provided. Please create one first at http://localhost:3000/apikeys" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Testing API endpoints with your key..." -ForegroundColor Yellow
Write-Host ""

# Test 1: API Documentation (no auth required)
Write-Host "1. Getting API documentation..." -ForegroundColor Cyan
try {
    $docsResponse = Invoke-WebRequest -Uri "$baseUrl/docs" -Method GET
    $docs = $docsResponse.Content | ConvertFrom-Json
    Write-Host "✓ API Version: $($docs.api_version)" -ForegroundColor Green
    Write-Host "✓ Available endpoints: $($docs.endpoints.PSObject.Properties.Count)" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to get documentation: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 2: Get Users (requires 'read' permission)
Write-Host "2. Getting users list..." -ForegroundColor Cyan
try {
    $headers = @{
        "X-API-Key" = $apiKey
    }
    
    $usersResponse = Invoke-WebRequest -Uri "$baseUrl/users" -Method GET -Headers $headers
    $usersData = $usersResponse.Content | ConvertFrom-Json
    Write-Host "✓ Found $($usersData.count) users" -ForegroundColor Green
    Write-Host "✓ API key used: $($usersData.api_key_used)" -ForegroundColor Green
    
    # Show first user
    if ($usersData.users.Count -gt 0) {
        $firstUser = $usersData.users[0]
        Write-Host "  Sample user: $($firstUser.name) ($($firstUser.email))" -ForegroundColor Gray
    }
} catch {
    $errorResponse = $_.Exception.Response
    if ($errorResponse.StatusCode -eq 403) {
        Write-Host "✗ Permission denied: Your API key needs 'read' permission" -ForegroundColor Red
    } elseif ($errorResponse.StatusCode -eq 401) {
        Write-Host "✗ Authentication failed: Invalid API key" -ForegroundColor Red
    } else {
        Write-Host "✗ Failed to get users: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Test 3: Get Specific User (requires 'read' permission)
Write-Host "3. Getting specific user..." -ForegroundColor Cyan
try {
    $userResponse = Invoke-WebRequest -Uri "$baseUrl/users/1" -Method GET -Headers $headers
    $userData = $userResponse.Content | ConvertFrom-Json
    Write-Host "✓ User found: $($userData.user.name)" -ForegroundColor Green
    Write-Host "  Department: $($userData.user.department)" -ForegroundColor Gray
    Write-Host "  Role: $($userData.user.role)" -ForegroundColor Gray
} catch {
    $errorResponse = $_.Exception.Response
    if ($errorResponse.StatusCode -eq 403) {
        Write-Host "✗ Permission denied: Your API key needs 'read' permission" -ForegroundColor Red
    } else {
        Write-Host "✗ Failed to get user: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Test 4: Get Projects (requires 'read' permission)
Write-Host "4. Getting projects..." -ForegroundColor Cyan
try {
    $projectsResponse = Invoke-WebRequest -Uri "$baseUrl/projects" -Method GET -Headers $headers
    $projectsData = $projectsResponse.Content | ConvertFrom-Json
    Write-Host "✓ Found $($projectsData.count) projects" -ForegroundColor Green
    
    foreach ($project in $projectsData.projects) {
        Write-Host "  - $($project.name): $($project.status)" -ForegroundColor Gray
    }
} catch {
    $errorResponse = $_.Exception.Response
    if ($errorResponse.StatusCode -eq 403) {
        Write-Host "✗ Permission denied: Your API key needs 'read' permission" -ForegroundColor Red
    } else {
        Write-Host "✗ Failed to get projects: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Test 5: Create Project (requires 'write' permission)
Write-Host "5. Creating new project..." -ForegroundColor Cyan
try {
    $projectData = @{
        name = "Test Project $(Get-Random)"
        description = "Created via API key test"
    } | ConvertTo-Json
    
    $headers["Content-Type"] = "application/json"
    
    $createResponse = Invoke-WebRequest -Uri "$baseUrl/projects" -Method POST -Body $projectData -Headers $headers
    $createdProject = $createResponse.Content | ConvertFrom-Json
    Write-Host "✓ Project created: $($createdProject.project.name)" -ForegroundColor Green
    Write-Host "  ID: $($createdProject.project.id)" -ForegroundColor Gray
    Write-Host "  Status: $($createdProject.project.status)" -ForegroundColor Gray
} catch {
    $errorResponse = $_.Exception.Response
    if ($errorResponse.StatusCode -eq 403) {
        Write-Host "✗ Permission denied: Your API key needs 'write' permission" -ForegroundColor Red
    } else {
        Write-Host "✗ Failed to create project: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Test 6: Get Analytics (requires 'analytics' permission)
Write-Host "6. Getting analytics..." -ForegroundColor Cyan
try {
    $analyticsResponse = Invoke-WebRequest -Uri "$baseUrl/analytics/summary" -Method GET -Headers @{"X-API-Key" = $apiKey}
    $analyticsData = $analyticsResponse.Content | ConvertFrom-Json
    Write-Host "✓ Analytics retrieved successfully" -ForegroundColor Green
    Write-Host "  Total users: $($analyticsData.total_users)" -ForegroundColor Gray
    Write-Host "  Total projects: $($analyticsData.total_projects)" -ForegroundColor Gray
    Write-Host "  Active projects: $($analyticsData.active_projects)" -ForegroundColor Gray
} catch {
    $errorResponse = $_.Exception.Response
    if ($errorResponse.StatusCode -eq 403) {
        Write-Host "✗ Permission denied: Your API key needs 'analytics' permission" -ForegroundColor Red
    } else {
        Write-Host "✗ Failed to get analytics: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "API Key Usage Test Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "- Create API keys at: http://localhost:3000/apikeys" -ForegroundColor White
Write-Host "- API documentation: $baseUrl/docs" -ForegroundColor White
Write-Host "- Use X-API-Key header or Authorization: ApiKey <key>" -ForegroundColor White
Write-Host "- Each request counts toward your 100/month quota" -ForegroundColor White
Write-Host ""
Write-Host "Available permissions:" -ForegroundColor Cyan
Write-Host "- 'read': Access GET endpoints (users, projects)" -ForegroundColor White
Write-Host "- 'write': Access POST/PUT/DELETE endpoints" -ForegroundColor White
Write-Host "- 'analytics': Access analytics endpoints" -ForegroundColor White