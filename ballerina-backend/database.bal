// Database connection and operations
import ballerina/sql;
import ballerinax/java.jdbc;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;

// Configuration
configurable string dbPath = "database/userportal.db";

// Database connection - SQLite
public final jdbc:Client dbClient = check new (
    url = "jdbc:sqlite:" + dbPath,
    options = {
        properties: {"foreign_keys": "ON"}
    }
);

// Initialize database with schema
public function initializeDatabase() returns error? {
    log:printInfo("Initializing database schema...");
    
    // Create users table
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            username TEXT UNIQUE NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            is_active BOOLEAN DEFAULT 1
        )
    `);
    
    // Create jwt_tokens table
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS jwt_tokens (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            token_hash TEXT NOT NULL,
            expires_at DATETIME NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            is_revoked BOOLEAN DEFAULT 0,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
    `);
    
    // Create api_keys table (without rules column)
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS api_keys (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            key_hash TEXT NOT NULL,
            description TEXT,
            status TEXT DEFAULT 'active',
            usage_count INTEGER DEFAULT 0,
            monthly_quota INTEGER DEFAULT 100,
            current_month_usage INTEGER DEFAULT 0,
            quota_reset_date TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
    `);
    
    // Create rules table
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS rules (
            id TEXT PRIMARY KEY,
            api_key_id TEXT NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            rule_type TEXT NOT NULL, -- 'rate_limit', 'ip_whitelist', 'endpoint_access', 'time_restriction'
            rule_config TEXT NOT NULL, -- JSON configuration for the rule
            is_active BOOLEAN DEFAULT 1,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (api_key_id) REFERENCES api_keys(id) ON DELETE CASCADE
        )
    `);
    
    // Migrate existing api_keys table to add quota columns if they don't exist
    sql:ExecutionResult|sql:Error result1 = dbClient->execute(`
        ALTER TABLE api_keys ADD COLUMN monthly_quota INTEGER DEFAULT 100
    `);
    // Ignore error if column already exists
    
    sql:ExecutionResult|sql:Error result2 = dbClient->execute(`
        ALTER TABLE api_keys ADD COLUMN current_month_usage INTEGER DEFAULT 0
    `);
    // Ignore error if column already exists
    
    sql:ExecutionResult|sql:Error result3 = dbClient->execute(`
        ALTER TABLE api_keys ADD COLUMN quota_reset_date TEXT
    `);
    // Ignore error if column already exists
    
    // Remove rules column from existing api_keys table if it exists
    sql:ExecutionResult|sql:Error dropRulesColumn = dbClient->execute(`
        ALTER TABLE api_keys DROP COLUMN rules
    `);
    // Ignore error if column doesn't exist
    
    // Create indexes for better performance
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)`);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)`);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active)`);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_jwt_tokens_user_id ON jwt_tokens(user_id)`);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_jwt_tokens_token_hash ON jwt_tokens(token_hash)`);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_jwt_tokens_expires_at ON jwt_tokens(expires_at)`);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_api_keys_user_id ON api_keys(user_id)`);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_api_keys_key_hash ON api_keys(key_hash)`);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_api_keys_status ON api_keys(status)`);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_rules_api_key_id ON rules(api_key_id)`);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_rules_rule_type ON rules(rule_type)`);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_rules_is_active ON rules(is_active)`);
    
    log:printInfo("Database schema initialized successfully!");
}

// ===== USER OPERATIONS =====

public function createUser(string username, string email, string password) returns User|error {
    string hashedPassword = hashPassword(password);
    string userId = generateUserId();
    
    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO users (id, username, email, password_hash, is_active)
        VALUES (${userId}, ${username}, ${email}, ${hashedPassword}, 1)
    `);
    
    if result.affectedRowCount == 1 {
        return getUserById(userId);
    }
    
    return error("Failed to create user");
}

public function getUserByUsername(string username) returns User|error? {
    User|sql:Error result = dbClient->queryRow(`
        SELECT id, username, email, password_hash, created_at, updated_at, is_active
        FROM users WHERE username = ${username} AND is_active = 1
    `);
    
    if result is sql:NoRowsError {
        return ();
    }
    
    return result;
}

public function getUserByEmail(string email) returns User|error? {
    User|sql:Error result = dbClient->queryRow(`
        SELECT id, username, email, password_hash, created_at, updated_at, is_active
        FROM users WHERE email = ${email} AND is_active = 1
    `);
    
    if result is sql:NoRowsError {
        return ();
    }
    
    return result;
}

public function getUserById(string userId) returns User|error {
    return dbClient->queryRow(`
        SELECT id, username, email, password_hash, created_at, updated_at, is_active
        FROM users WHERE id = ${userId} AND is_active = 1
    `);
}

// ===== TOKEN OPERATIONS =====

public function storeJWTToken(string userId, string tokenHash) returns string|error {
    string tokenId = uuid:createType1AsString();
    time:Utc currentTime = time:utcNow();
    time:Utc expiryUtc = time:utcAddSeconds(currentTime, <decimal>jwtExpiryTime);
    string expiryString = time:utcToString(expiryUtc);
    
    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO jwt_tokens (id, user_id, token_hash, expires_at, is_revoked)
        VALUES (${tokenId}, ${userId}, ${tokenHash}, ${expiryString}, 0)
    `);
    
    if result.affectedRowCount == 1 {
        return tokenId;
    }
    
    return error("Failed to store JWT token");
}

public function isTokenValid(string tokenHash) returns boolean|error {
    record {|string id;|}|sql:Error result = dbClient->queryRow(`
        SELECT id FROM jwt_tokens 
        WHERE token_hash = ${tokenHash} 
        AND is_revoked = 0 
        AND expires_at > CURRENT_TIMESTAMP
    `);
    
    return !(result is sql:NoRowsError || result is sql:Error);
}

public function revokeToken(string tokenHash) returns boolean|error {
    sql:ExecutionResult result = check dbClient->execute(`
        UPDATE jwt_tokens SET is_revoked = 1
        WHERE token_hash = ${tokenHash}
    `);
    
    return result.affectedRowCount > 0;
}