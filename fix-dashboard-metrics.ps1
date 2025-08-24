#!/usr/bin/env pwsh

# Script to fix dashboard metrics issues

Write-Host "Fixing Dashboard Metrics Issues..." -ForegroundColor Green

# Configuration
$baseUrl = "http://localhost:8080/api"

Write-Host "`n1. Checking backend health..." -ForegroundColor Yellow

try {
    $healthResponse = Invoke-RestMethod -Uri "$baseUrl/health" -Method GET
    Write-Host "✓ Backend is running: $($healthResponse.status)" -ForegroundColor Green
} catch {
    Write-Host "✗ Backend is not accessible: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please start the backend first with: bal run" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n2. The backend automatically fixes quota issues on startup" -ForegroundColor Yellow
Write-Host "   - Resets API keys with incorrect quota dates" -ForegroundColor White
Write-Host "   - Fixes monthly usage counters" -ForegroundColor White
Write-Host "   - Updates quota reset dates to current month" -ForegroundColor White

Write-Host "`n3. Frontend improvements made:" -ForegroundColor Yellow
Write-Host "   ✓ Added proper error handling for API responses" -ForegroundColor Green
Write-Host "   ✓ Added loading states for metrics" -ForegroundColor Green
Write-Host "   ✓ Added auto-refresh every 30 seconds" -ForegroundColor Green
Write-Host "   ✓ Added manual refresh button" -ForegroundColor Green
Write-Host "   ✓ Added last updated timestamp" -ForegroundColor Green
Write-Host "   ✓ Fixed API response parsing" -ForegroundColor Green

Write-Host "`n4. Backend improvements made:" -ForegroundColor Yellow
Write-Host "   ✓ Added quota refresh before returning API key data" -ForegroundColor Green
Write-Host "   ✓ Improved quota reset logic" -ForegroundColor Green
Write-Host "   ✓ Added automatic quota fixes on service startup" -ForegroundColor Green
Write-Host "   ✓ Better error handling for quota operations" -ForegroundColor Green

Write-Host "`n=== Next Steps ===" -ForegroundColor Magenta
Write-Host "1. Restart the backend service:" -ForegroundColor White
Write-Host "   cd ballerina-backend && bal run" -ForegroundColor Cyan

Write-Host "`n2. Restart the frontend:" -ForegroundColor White
Write-Host "   cd userportal && npm run dev" -ForegroundColor Cyan

Write-Host "`n3. Test the dashboard:" -ForegroundColor White
Write-Host "   - Login to the dashboard" -ForegroundColor Cyan
Write-Host "   - Check that all metrics display correctly" -ForegroundColor Cyan
Write-Host "   - Use the refresh button to update data" -ForegroundColor Cyan
Write-Host "   - Make some API calls and verify counters increase" -ForegroundColor Cyan

Write-Host "`n4. Run the test script:" -ForegroundColor White
Write-Host "   .\test-dashboard-metrics.ps1" -ForegroundColor Cyan

Write-Host "`nFix completed! The dashboard metrics should now update properly." -ForegroundColor Green