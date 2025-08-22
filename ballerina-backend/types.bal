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

// API Key model (without rules)
public type ApiKey record {|
    string id;
    string user_id;
    string name;
    string key_hash;
    string description?;
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
    string status;
    int usage_count;
    int monthly_quota;
    int current_month_usage;
    int remaining_quota;
    string quota_reset_date;
    string created_at;
    string updated_at;
    Rule[] rules?; // Rules will be loaded separately
|};

public type CreateApiKeyRequest record {|
    string name;
    string description?;
|};

// Rule model
public type Rule record {|
    string id;
    string api_key_id;
    string name;
    string description?;
    string rule_type; // "rate_limit", "ip_whitelist", "endpoint_access", "time_restriction"
    json rule_config; // JSON configuration for the rule
    boolean is_active;
    string created_at;
    string updated_at;
|};

public type RuleResponse record {|
    string id;
    string api_key_id;
    string name;
    string description?;
    string rule_type;
    json rule_config;
    boolean is_active;
    string created_at;
    string updated_at;
|};

public type CreateRuleRequest record {|
    string name;
    string description?;
    string rule_type;
    json rule_config;
    boolean is_active?;
|};

public type UpdateRuleRequest record {|
    string name?;
    string description?;
    json rule_config?;
    boolean is_active?;
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

public function toApiKeyResponse(ApiKey apiKey, Rule[]? rules = ()) returns ApiKeyResponse {
    int remainingQuota = apiKey.monthly_quota - apiKey.current_month_usage;
    return {
        id: apiKey.id,
        name: apiKey.name,
        description: apiKey.description,
        status: apiKey.status,
        usage_count: apiKey.usage_count,
        monthly_quota: apiKey.monthly_quota,
        current_month_usage: apiKey.current_month_usage,
        remaining_quota: remainingQuota < 0 ? 0 : remainingQuota,
        quota_reset_date: apiKey.quota_reset_date,
        created_at: apiKey.created_at,
        updated_at: apiKey.updated_at,
        rules: rules
    };
}

public function toRuleResponse(Rule rule) returns RuleResponse {
    return {
        id: rule.id,
        api_key_id: rule.api_key_id,
        name: rule.name,
        description: rule.description,
        rule_type: rule.rule_type,
        rule_config: rule.rule_config,
        is_active: rule.is_active,
        created_at: rule.created_at,
        updated_at: rule.updated_at
    };
}