// Data models and types for the application

// User model
public type User record {|
    string id;
    string username;
    string email;
    string password_hash;
    string created_at;
    string updated_at;
    boolean is_active;
|};

public type UserResponse record {|
    string id;
    string username;
    string email;
    string created_at;
    string updated_at;
    boolean is_active;
|};

// API Key model
public type ApiKey record {|
    string id;
    string user_id;
    string name;
    string key_hash;
    string description?;
    string[] rules;
    string status; // "active", "inactive", "revoked"
    int usage_count;
    int monthly_quota; // Monthly request limit (default 100)
    int current_month_usage; // Usage in current month
    string quota_reset_date; // When the monthly quota resets
    string created_at;
    string updated_at;
|};

public type ApiKeyResponse record {|
    string id;
    string name;
    string description?;
    string[] rules;
    string status;
    int usage_count;
    int monthly_quota;
    int current_month_usage;
    int remaining_quota;
    string quota_reset_date;
    string created_at;
    string updated_at;
|};

public type CreateApiKeyRequest record {|
    string name;
    string description?;
    string[] rules?;
|};

// Convert User to UserResponse (remove sensitive data)
public function toUserResponse(User user) returns UserResponse {
    return {
        id: user.id,
        username: user.username,
        email: user.email,
        created_at: user.created_at,
        updated_at: user.updated_at,
        is_active: user.is_active
    };
}

public function toApiKeyResponse(ApiKey apiKey) returns ApiKeyResponse {
    int remainingQuota = apiKey.monthly_quota - apiKey.current_month_usage;
    return {
        id: apiKey.id,
        name: apiKey.name,
        description: apiKey.description,
        rules: apiKey.rules,
        status: apiKey.status,
        usage_count: apiKey.usage_count,
        monthly_quota: apiKey.monthly_quota,
        current_month_usage: apiKey.current_month_usage,
        remaining_quota: remainingQuota < 0 ? 0 : remainingQuota,
        quota_reset_date: apiKey.quota_reset_date,
        created_at: apiKey.created_at,
        updated_at: apiKey.updated_at
    };
}