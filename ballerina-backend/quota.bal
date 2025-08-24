// Quota management system for API keys
import ballerina/time;

public function checkQuotaLimit(ApiKey apiKey) returns boolean {
    // For new API keys or if quota reset date is in the future, allow usage
    time:Utc currentTime = time:utcNow();
    
    // Try to parse the quota reset date
    time:Utc|error quotaResetTime = time:utcFromString(apiKey.quota_reset_date + "T00:00:00Z");
    if quotaResetTime is error {
        // If we can't parse the date, reset the quota and allow usage
        error? resetResult = resetMonthlyQuota(apiKey.id);
        return true; // Allow usage after reset
    }
    
    // If current time is past the reset date, reset the quota
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
    // Calculate next month's first day for new quota reset
    time:Utc currentTime = time:utcNow();
    time:Civil currentCivil = time:utcToCivil(currentTime);
    
    // Calculate next month correctly
    int nextYear = currentCivil.year;
    int nextMonth = currentCivil.month + 1;
    
    // Handle year rollover
    if nextMonth > 12 {
        nextMonth = 1;
        nextYear = nextYear + 1;
    }
    
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

// Function to fix existing API keys with incorrect quota reset dates
public function fixExistingApiKeyQuotas() returns error? {
    // Calculate correct next month date
    time:Utc currentTime = time:utcNow();
    time:Civil currentCivil = time:utcToCivil(currentTime);
    
    int nextYear = currentCivil.year;
    int nextMonth = currentCivil.month + 1;
    
    if nextMonth > 12 {
        nextMonth = 1;
        nextYear = nextYear + 1;
    }
    
    string correctResetDate = string `${nextYear}-${nextMonth < 10 ? "0" : ""}${nextMonth}-01`;
    
    // Reset all API keys that have quota reset dates in 2025 or have exceeded quotas
    _ = check dbClient->execute(`
        UPDATE api_keys 
        SET current_month_usage = 0, 
            quota_reset_date = ${correctResetDate},
            updated_at = CURRENT_TIMESTAMP
        WHERE quota_reset_date LIKE '2025%' OR current_month_usage >= monthly_quota
    `);
}

// Function to refresh quota status for all API keys
public function refreshAllApiKeyQuotas() returns error? {
    // Get all active API keys
    stream<record {|
        string id;
        string quota_reset_date;
        int current_month_usage;
        int monthly_quota;
    |}, sql:Error?> resultStream = dbClient->query(`
        SELECT id, quota_reset_date, current_month_usage, monthly_quota
        FROM api_keys WHERE status = 'active'
    `);
    
    time:Utc currentTime = time:utcNow();
    
    check from var row in resultStream
        do {
            // Check if quota needs reset for this key
            time:Utc|error quotaResetTime = time:utcFromString(row.quota_reset_date + "T00:00:00Z");
            if quotaResetTime is time:Utc {
                decimal timeDiff = time:utcDiffSeconds(currentTime, quotaResetTime);
                if timeDiff >= 0d {
                    // Reset quota for this key
                    error? resetResult = resetMonthlyQuota(row.id);
                    if resetResult is error {
                        // Log error but continue with other keys
                        continue;
                    }
                }
            }
        };
}