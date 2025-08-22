// Rule management operations
import ballerina/sql;
import ballerina/uuid;

// ===== RULE OPERATIONS =====

public function createRule(string apiKeyId, string name, string? description, string ruleType, json ruleConfig, boolean isActive = true) returns Rule|error {
    string ruleId = uuid:createType1AsString();
    string configJson = ruleConfig.toJsonString();
    
    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO rules (id, api_key_id, name, description, rule_type, rule_config, is_active)
        VALUES (${ruleId}, ${apiKeyId}, ${name}, ${description}, ${ruleType}, ${configJson}, ${isActive})
    `);
    
    if result.affectedRowCount == 1 {
        return getRuleById(ruleId);
    }
    
    return error("Failed to create rule");
}

public function getRuleById(string ruleId) returns Rule|error {
    record {|
        string id;
        string api_key_id;
        string name;
        string? description;
        string rule_type;
        string rule_config;
        boolean is_active;
        string created_at;
        string updated_at;
    |}|sql:Error result = dbClient->queryRow(`
        SELECT id, api_key_id, name, description, rule_type, rule_config, is_active, created_at, updated_at
        FROM rules WHERE id = ${ruleId}
    `);
    
    if result is sql:Error {
        return error("Rule not found");
    }
    
    json configJson = check result.rule_config.fromJsonString();
    
    return {
        id: result.id,
        api_key_id: result.api_key_id,
        name: result.name,
        description: result.description,
        rule_type: result.rule_type,
        rule_config: configJson,
        is_active: result.is_active,
        created_at: result.created_at,
        updated_at: result.updated_at
    };
}

public function getRulesByApiKeyId(string apiKeyId) returns Rule[]|error {
    stream<record {|
        string id;
        string api_key_id;
        string name;
        string? description;
        string rule_type;
        string rule_config;
        boolean is_active;
        string created_at;
        string updated_at;
    |}, sql:Error?> resultStream = dbClient->query(`
        SELECT id, api_key_id, name, description, rule_type, rule_config, is_active, created_at, updated_at
        FROM rules WHERE api_key_id = ${apiKeyId}
        ORDER BY created_at DESC
    `);
    
    Rule[] rules = [];
    check from var row in resultStream
        do {
            json configJson = check row.rule_config.fromJsonString();
            rules.push({
                id: row.id,
                api_key_id: row.api_key_id,
                name: row.name,
                description: row.description,
                rule_type: row.rule_type,
                rule_config: configJson,
                is_active: row.is_active,
                created_at: row.created_at,
                updated_at: row.updated_at
            });
        };
    
    return rules;
}

public function updateRule(string ruleId, string? name, string? description, json? ruleConfig, boolean? isActive) returns Rule|error {
    // Use individual update statements for simplicity
    if name is string {
        _ = check dbClient->execute(`
            UPDATE rules SET name = ${name}, updated_at = CURRENT_TIMESTAMP WHERE id = ${ruleId}
        `);
    }
    
    if description is string {
        _ = check dbClient->execute(`
            UPDATE rules SET description = ${description}, updated_at = CURRENT_TIMESTAMP WHERE id = ${ruleId}
        `);
    }
    
    if ruleConfig is json {
        string configJson = ruleConfig.toJsonString();
        _ = check dbClient->execute(`
            UPDATE rules SET rule_config = ${configJson}, updated_at = CURRENT_TIMESTAMP WHERE id = ${ruleId}
        `);
    }
    
    if isActive is boolean {
        _ = check dbClient->execute(`
            UPDATE rules SET is_active = ${isActive}, updated_at = CURRENT_TIMESTAMP WHERE id = ${ruleId}
        `);
    }
    
    return getRuleById(ruleId);
}

public function deleteRule(string ruleId, string apiKeyId) returns boolean|error {
    sql:ExecutionResult result = check dbClient->execute(`
        DELETE FROM rules WHERE id = ${ruleId} AND api_key_id = ${apiKeyId}
    `);
    
    return result.affectedRowCount > 0;
}

public function validateRuleOwnership(string ruleId, string userId) returns boolean|error {
    record {|string user_id;|}|sql:Error result = dbClient->queryRow(`
        SELECT ak.user_id 
        FROM rules r 
        JOIN api_keys ak ON r.api_key_id = ak.id 
        WHERE r.id = ${ruleId}
    `);
    
    if result is sql:Error {
        return false;
    }
    
    return result.user_id == userId;
}

// Get all rules for a user (across all their API keys)
public function getRulesByUserId(string userId) returns Rule[]|error {
    stream<record {|
        string id;
        string api_key_id;
        string name;
        string? description;
        string rule_type;
        string rule_config;
        boolean is_active;
        string created_at;
        string updated_at;
    |}, sql:Error?> resultStream = dbClient->query(`
        SELECT r.id, r.api_key_id, r.name, r.description, r.rule_type, r.rule_config, r.is_active, r.created_at, r.updated_at
        FROM rules r
        JOIN api_keys ak ON r.api_key_id = ak.id
        WHERE ak.user_id = ${userId}
        ORDER BY r.created_at DESC
    `);
    
    Rule[] rules = [];
    check from var row in resultStream
        do {
            json configJson = check row.rule_config.fromJsonString();
            rules.push({
                id: row.id,
                api_key_id: row.api_key_id,
                name: row.name,
                description: row.description,
                rule_type: row.rule_type,
                rule_config: configJson,
                is_active: row.is_active,
                created_at: row.created_at,
                updated_at: row.updated_at
            });
        };
    
    return rules;
}