// Quota management system for API keys
import ballerina/time;

public function checkQuotaLimit(ApiKey apiKey) returns boolean {
    // Check if quota needs to be reset
    time:Utc|error quotaResetTime = time:utcFromString(apiKey.quota_reset_date);
    if quotaResetTime is error {
        return false; // If we can't parse the date, assume quota exceeded for safety
    }
    
    time:Utc currentTime = time:utcNow();
    
    // If current time is past the reset date, the quota should be reset
    decimal timeDiff = time:utcDiffSeconds(currentTime, quotaResetTime);
    if timeDiff >= 0d {
        // Reset quota for this key
        error? resetResult = resetMonthlyQuota(apiKey.id);
        if resetResult is error {
            return false; // If reset fails, assume quota exceeded for safety
        }
        return true; // After reset, quota is available
    }
    
    // Check if current usage is within quota
    return apiKey.current_month_usage < apiKey.monthly_quota;
}

public function resetMonthlyQuota(string keyId) returns error? {
    // Calculate next month's first day for new quota reset (simplified approach)
    time:Utc currentTime = time:utcNow();
    time:Civil currentCivil = time:utcToCivil(currentTime);
    
    // Simple string-based date calculation for next month
    int nextYear = currentCivil.month == 12 ? currentCivil.year + 1 : currentCivil.year;
    int nextMonth = currentCivil.month == 12 ? 1 : currentCivil.month + 1;
    string quotaResetDate = string `${nextYear}-${nextMonth < 10 ? "0" : ""}${nextMonth}-01`;
    
    _ = check dbClient->execute(`
        UPDATE api_keys 
        SET current_month_usage = 0, quota_reset_date = ${quotaResetDate}, updated_at = CURRENT_TIMESTAMP
        WHERE id = ${keyId}
    `);
}

public function validateApiKeyWithQuota(string apiKey) returns [ApiKey, boolean]|error {
    ApiKey validatedKey = check validateApiKey(apiKey);
    boolean quotaAvailable = checkQuotaLimit(validatedKey);
    return [validatedKey, quotaAvailable];
}