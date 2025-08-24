# PowerShell script to test Content Moderation API
$baseUrl = "http://localhost:8080/api"

Write-Host "Content Moderation API Test" -ForegroundColor Green
Write-Host "===========================" -ForegroundColor Green
Write-Host ""

# Get API key from user
$apiKey = Read-Host "Enter your API key with 'moderate' permission (get one from http://localhost:3000/apikeys)"

if ([string]::IsNullOrEmpty($apiKey)) {
    Write-Host "No API key provided. Please create one with 'moderate' permission first." -ForegroundColor Red
    Write-Host "Visit: http://localhost:3000/apikeys" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Testing Content Moderation API..." -ForegroundColor Yellow
Write-Host ""

# Test cases
$testCases = @(
    @{
        name = "Clean Content"
        text = "This is a perfectly normal and appropriate message about our new product launch."
        expected = "should NOT be flagged"
    },
    @{
        name = "Spam Content"
        text = "This message contains spam keywords that should be detected by the system."
        expected = "should be flagged for spam"
    },
    @{
        name = "Inappropriate Content"
        text = "This message has inappropriate content that violates our community guidelines."
        expected = "should be flagged for inappropriate content"
    },
    @{
        name = "Empty Text"
        text = ""
        expected = "should return error for empty text"
    },
    @{
        name = "Long Text"
        text = "A" * 15000  # Exceeds 10,000 character limit
        expected = "should return error for text too long"
    }
)

$headers = @{
    "X-API-Key" = $apiKey
    "Content-Type" = "application/json"
}

foreach ($test in $testCases) {
    Write-Host "Test: $($test.name)" -ForegroundColor Cyan
    Write-Host "Expected: $($test.expected)" -ForegroundColor Gray
    
    try {
        $requestBody = @{
            text = $test.text
        } | ConvertTo-Json
        
        $response = Invoke-WebRequest -Uri "$baseUrl/moderate-content/text/v1" -Method POST -Body $requestBody -Headers $headers
        $data = $response.Content | ConvertFrom-Json
        
        if ($data.status -eq $true) {
            Write-Host "✓ Status: Success" -ForegroundColor Green
            
            if ($data.result) {
                $result = $data.result
                Write-Host "  Flagged: $($result.flagged)" -ForegroundColor $(if ($result.flagged) { "Red" } else { "Green" })
                Write-Host "  Confidence: $($result.confidence)" -ForegroundColor Gray
                Write-Host "  Severity: $($result.severity)" -ForegroundColor Gray
                Write-Host "  Action: $($result.action_recommended)" -ForegroundColor Gray
                
                if ($result.categories -and $result.categories.Count -gt 0) {
                    Write-Host "  Categories: $($result.categories -join ', ')" -ForegroundColor Yellow
                }
            }
            
            if ($data.metadata) {
                $meta = $data.metadata
                Write-Host "  Text Length: $($meta.text_length)" -ForegroundColor Gray
                Write-Host "  Processing Time: $($meta.processing_time_ms)ms" -ForegroundColor Gray
                Write-Host "  API Key Used: $($meta.api_key_used)" -ForegroundColor Gray
            }
        } else {
            Write-Host "✗ Unexpected response format" -ForegroundColor Red
        }
        
    } catch {
        $errorResponse = $_.Exception.Response
        if ($errorResponse) {
            $statusCode = [int]$errorResponse.StatusCode
            Write-Host "✗ HTTP $statusCode" -ForegroundColor Red
            
            try {
                $errorContent = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($errorContent)
                $errorBody = $reader.ReadToEnd() | ConvertFrom-Json
                Write-Host "  Error: $($errorBody.error)" -ForegroundColor Red
            } catch {
                Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "✗ Request failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
}

Write-Host "Content Moderation API Test Complete!" -ForegroundColor Green
Write-Host ""

# Show example curl command
Write-Host "Example curl command:" -ForegroundColor Cyan
Write-Host @"
curl -X POST http://localhost:8080/api/moderate-content/text/v1 \
  -H "X-API-Key: $apiKey" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Your text content to moderate goes here"
  }'
"@ -ForegroundColor White

Write-Host ""
Write-Host "API Documentation: See API_DOCUMENTATION.md for complete details" -ForegroundColor Yellow