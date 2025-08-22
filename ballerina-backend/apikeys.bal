// API Key management operations
import ballerina/sql;
import ballerina/time;
import ballerina/crypto;
import ballerina/uuid;

// API Key utility functions
public function generateApiKey() returns string {
    // Generate a secure API key with prefix
    string randomPart = crypto:hashSha256(uuid:createType1AsString().toBytes()).toBase16().substring(0, 32);
    return string `ak_${randomPart}`;
}

public function hashApiKey(string apiKey) returns string {
    return crypto:hashSha256((apiKey + jwtSecret).toBytes()).toBase16();
}

// ===== API KEY OPERATIONS =====

public function createApiKey(string userId, string name, string? description) returns [ApiKey, string]|error {
    // Check if user already has 3 API keys
    int keyCount = check getApiKeyCountForUser(userId);
    if keyCount >= 3 {
        return error("Maximum of 3 API keys allowed per user");
    }
    
    string apiKeyId = generateUserId();
    string apiKey = generateApiKey();
    string keyHash = hashApiKey(apiKey);
    
    // Calculate next month's first day for quota reset (simplified approach)
    time:Utc currentTime = time:utcNow();
    time:Civil currentCivil = time:utcToCivil(currentTime);
    
    // Simple string-based date calculation for next month
    int nextYear = currentCivil.month == 12 ? currentCivil.year + 1 : currentCivil.year;
    int nextMonth = currentCivil.month == 12 ? 1 : currentCivil.month + 1;
    string quotaResetDate = string `${nextYear}-${nextMonth < 10 ? "0" : ""}${nextMonth}-01`;
    
    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO api_keys (id, user_id, name, key_hash, description, status, usage_count, monthly_quota, current_month_usage, quota_reset_date)
        VALUES (${apiKeyId}, ${userId}, ${name}, ${keyHash}, ${description}, 'active', 0, 100, 0, ${quotaResetDate})
    `);
    
    if result.affectedRowCount == 1 {
        ApiKey createdKey = check getApiKeyById(apiKeyId);
        return [createdKey, apiKey];
    }
    
    return error("Failed to create API key");
}

public function getApiKeyCountForUser(string userId) returns int|error {
    record {|int count;|}|sql:Error result = dbClient->queryRow(`
        SELECT COUNT(*) as count FROM api_keys 
        WHERE user_id = ${userId} AND status != 'revoked'
    `);
    
    if result is sql:Error {
        return 0;
    }
    
    return result.count;
}

public function getApiKeyById(string keyId) returns ApiKey|error {
    record {|
        string id;
        string user_id;
        string name;
        string key_hash;
        string? description;
        string status;
        int usage_count;
        int monthly_quota;
        int current_month_usage;
        string quota_reset_date;
        string created_at;
        string updated_at;
    |}|sql:Error result = dbClient->queryRow(`
        SELECT id, user_id, name, key_hash, description, status, usage_count, monthly_quota, current_month_usage, quota_reset_date, created_at, updated_at
        FROM api_keys WHERE id = ${keyId}
    `);
    
    if result is sql:Error {
        return error("API key not found");
    }
    
    return {
        id: result.id,
        user_id: result.user_id,
        name: result.name,
        key_hash: result.key_hash,
        description: result.description,
        status: result.status,
        usage_count: result.usage_count,
        monthly_quota: result.monthly_quota,
        current_month_usage: result.current_month_usage,
        quota_reset_date: result.quota_reset_date,
        created_at: result.created_at,
        updated_at: result.updated_at
    };
}

public function getApiKeysByUserId(string userId) returns ApiKey[]|error {
    stream<record {|
        string id;
        string user_id;
        string name;
        string key_hash;
        string? description;
        string status;
        int usage_count;
        int monthly_quota;
        int current_month_usage;
        string quota_reset_date;
        string created_at;
        string updated_at;
    |}, sql:Error?> resultStream = dbClient->query(`
        SELECT id, user_id, name, key_hash, description, status, usage_count, monthly_quota, current_month_usage, quota_reset_date, created_at, updated_at
        FROM api_keys WHERE user_id = ${userId} AND status != 'revoked'
        ORDER BY created_at DESC
    `);
    
    ApiKey[] apiKeys = [];
    check from var row in resultStream
        do {
            apiKeys.push({
                id: row.id,
                user_id: row.user_id,
                name: row.name,
                key_hash: row.key_hash,
                description: row.description,
                status: row.status,
                usage_count: row.usage_count,
                monthly_quota: row.monthly_quota,
                current_month_usage: row.current_month_usage,
                quota_reset_date: row.quota_reset_date,
                created_at: row.created_at,
                updated_at: row.updated_at
            });
        };
    
    return apiKeys;
}

public function validateApiKey(string apiKey) returns ApiKey|error {
    string keyHash = hashApiKey(apiKey);
    
    record {|
        string id;
        string user_id;
        string name;
        string key_hash;
        string? description;
        string status;
        int usage_count;
        int monthly_quota;
        int current_month_usage;
        string quota_reset_date;
        string created_at;
        string updated_at;
    |}|sql:Error result = dbClient->queryRow(`
        SELECT id, user_id, name, key_hash, description, status, usage_count, monthly_quota, current_month_usage, quota_reset_date, created_at, updated_at
        FROM api_keys WHERE key_hash = ${keyHash} AND status = 'active'
    `);
    
    if result is sql:Error {
        return error("Invalid API key");
    }
    
    return {
        id: result.id,
        user_id: result.user_id,
        name: result.name,
        key_hash: result.key_hash,
        description: result.description,
        status: result.status,
        usage_count: result.usage_count,
        monthly_quota: result.monthly_quota,
        current_month_usage: result.current_month_usage,
        quota_reset_date: result.quota_reset_date,
        created_at: result.created_at,
        updated_at: result.updated_at
    };
}

public function incrementApiKeyUsage(string keyId) returns error? {
    _ = check dbClient->execute(`
        UPDATE api_keys 
        SET usage_count = usage_count + 1, current_month_usage = current_month_usage + 1, updated_at = CURRENT_TIMESTAMP
        WHERE id = ${keyId}
    `);
}

public function updateApiKeyStatus(string keyId, string status) returns error? {
    _ = check dbClient->execute(`
        UPDATE api_keys 
        SET status = ${status}, updated_at = CURRENT_TIMESTAMP
        WHERE id = ${keyId}
    `);
}

public function deleteApiKey(string keyId, string userId) returns boolean|error {
    sql:ExecutionResult result = check dbClient->execute(`
        UPDATE api_keys 
        SET status = 'revoked', updated_at = CURRENT_TIMESTAMP
        WHERE id = ${keyId} AND user_id = ${userId}
    `);
    
    return result.affectedRowCount > 0;
}