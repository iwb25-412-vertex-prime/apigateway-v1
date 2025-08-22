import ballerina/http;
import ballerina/sql;
import ballerinax/java.jdbc;
import ballerina/crypto;
import ballerina/uuid;
import ballerina/time;
import ballerina/log;
import ballerina/regex;

// Configuration
configurable string jwtSecret = "your-super-secret-jwt-key-change-in-production-min-32-chars";
configurable int jwtExpiryTime = 3600;
configurable string jwtIssuer = "userportal-auth";
configurable string jwtAudience = "userportal-users";
configurable string dbPath = "database/userportal.db";

// Database connection - SQLite
jdbc:Client dbClient = check new (
    url = "jdbc:sqlite:" + dbPath,
    options = {
        properties: {"foreign_keys": "ON"}
    }
);

// User model
type User record {|
    string id;
    string username;
    string email;
    string password_hash;
    string created_at;
    string updated_at;
    boolean is_active;
|};

type UserResponse record {|
    string id;
    string username;
    string email;
    string created_at;
    string updated_at;
    boolean is_active;
|};

// API Key model
type ApiKey record {|
    string id;
    string user_id;
    string name;
    string key_hash;
    string description?;
    string[] rules;
    string status; // "active", "inactive", "revoked"
    int usage_count;
    string created_at;
    string updated_at;
|};

type ApiKeyResponse record {|
    string id;
    string name;
    string description?;
    string[] rules;
    string status;
    int usage_count;
    string created_at;
    string updated_at;
|};

type CreateApiKeyRequest record {|
    string name;
    string description?;
    string[] rules?;
|};

// Simple password hashing (for demo purposes)
function hashPassword(string password) returns string {
    return crypto:hashSha256((password + "salt123").toBytes()).toBase16();
}

function checkPassword(string password, string hash) returns boolean {
    string hashedInput = crypto:hashSha256((password + "salt123").toBytes()).toBase16();
    return hashedInput == hash;
}

// Simple secure token generation (using direct string concatenation for demo)
function generateToken(User user) returns string {
    int currentTime = <int>time:utcNow()[0];
    int expiryTime = currentTime + jwtExpiryTime;
    
    // Create a simple token with user info and expiry
    string tokenData = string `${user.id}|${user.username}|${user.email}|${expiryTime}`;
    string signature = crypto:hashSha256((tokenData + jwtSecret).toBytes()).toBase16();
    
    return string `${tokenData}|${signature}`;
}

function validateToken(string token) returns json|error {
    string[] parts = regex:split(token, "\\|");
    if parts.length() != 5 {
        return error("Invalid token format");
    }
    
    string userId = parts[0];
    string username = parts[1];
    string email = parts[2];
    string expStr = parts[3];
    string providedSignature = parts[4];
    
    // Reconstruct token data for signature verification
    string tokenData = string `${userId}|${username}|${email}|${expStr}`;
    string expectedSignature = crypto:hashSha256((tokenData + jwtSecret).toBytes()).toBase16();
    
    if expectedSignature != providedSignature {
        return error("Invalid token signature");
    }
    
    // Check expiry
    int exp = check int:fromString(expStr);
    int currentTime = <int>time:utcNow()[0];
    if exp < currentTime {
        return error("Token expired");
    }
    
    // Return as JSON
    json payload = {
        "userId": userId,
        "username": username,
        "email": email,
        "exp": exp,
        "iss": jwtIssuer,
        "aud": jwtAudience
    };
    
    return payload;
}

// Utility functions
function generateUserId() returns string {
    return uuid:createType1AsString();
}

function isValidEmail(string email) returns boolean {
    string emailPattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$";
    return regex:matches(email, emailPattern);
}

function isValidPassword(string password) returns boolean {
    return password.length() >= 8;
}

// Initialize database with schema
function initializeDatabase(jdbc:Client dbClient) returns error? {
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
    
    // Create api_keys table
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS api_keys (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            key_hash TEXT NOT NULL,
            description TEXT,
            rules TEXT, -- JSON array stored as string
            status TEXT DEFAULT 'active',
            usage_count INTEGER DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
    `);
    
    log:printInfo("Database schema initialized successfully!");
}

// Database operations
function createUser(string username, string email, string password) returns User|error {
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

function getUserByUsername(string username) returns User|error? {
    User|sql:Error result = dbClient->queryRow(`
        SELECT id, username, email, password_hash, created_at, updated_at, is_active
        FROM users WHERE username = ${username} AND is_active = 1
    `);
    
    if result is sql:NoRowsError {
        return ();
    }
    
    return result;
}

function getUserByEmail(string email) returns User|error? {
    User|sql:Error result = dbClient->queryRow(`
        SELECT id, username, email, password_hash, created_at, updated_at, is_active
        FROM users WHERE email = ${email} AND is_active = 1
    `);
    
    if result is sql:NoRowsError {
        return ();
    }
    
    return result;
}

function getUserById(string userId) returns User|error {
    return dbClient->queryRow(`
        SELECT id, username, email, password_hash, created_at, updated_at, is_active
        FROM users WHERE id = ${userId} AND is_active = 1
    `);
}

function storeJWTToken(string userId, string tokenHash) returns string|error {
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

function isTokenValid(string tokenHash) returns boolean|error {
    record {|string id;|}|sql:Error result = dbClient->queryRow(`
        SELECT id FROM jwt_tokens 
        WHERE token_hash = ${tokenHash} 
        AND is_revoked = 0 
        AND expires_at > CURRENT_TIMESTAMP
    `);
    
    return !(result is sql:NoRowsError || result is sql:Error);
}

function revokeToken(string tokenHash) returns boolean|error {
    sql:ExecutionResult result = check dbClient->execute(`
        UPDATE jwt_tokens SET is_revoked = 1
        WHERE token_hash = ${tokenHash}
    `);
    
    return result.affectedRowCount > 0;
}

// Convert User to UserResponse (remove sensitive data)
function toUserResponse(User user) returns UserResponse {
    return {
        id: user.id,
        username: user.username,
        email: user.email,
        created_at: user.created_at,
        updated_at: user.updated_at,
        is_active: user.is_active
    };
}

// API Key utility functions
function generateApiKey() returns string {
    // Generate a secure API key with prefix
    string randomPart = crypto:hashSha256(uuid:createType1AsString().toBytes()).toBase16().substring(0, 32);
    return string `ak_${randomPart}`;
}

function hashApiKey(string apiKey) returns string {
    return crypto:hashSha256((apiKey + jwtSecret).toBytes()).toBase16();
}

function toApiKeyResponse(ApiKey apiKey) returns ApiKeyResponse {
    return {
        id: apiKey.id,
        name: apiKey.name,
        description: apiKey.description,
        rules: apiKey.rules,
        status: apiKey.status,
        usage_count: apiKey.usage_count,
        created_at: apiKey.created_at,
        updated_at: apiKey.updated_at
    };
}

// API Key database operations
function createApiKey(string userId, string name, string? description, string[] rules) returns [ApiKey, string]|error {
    // Check if user already has 3 API keys
    int keyCount = check getApiKeyCountForUser(userId);
    if keyCount >= 3 {
        return error("Maximum of 3 API keys allowed per user");
    }
    
    string apiKeyId = generateUserId();
    string apiKey = generateApiKey();
    string keyHash = hashApiKey(apiKey);
    string rulesJson = rules.toJsonString();
    
    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO api_keys (id, user_id, name, key_hash, description, rules, status, usage_count)
        VALUES (${apiKeyId}, ${userId}, ${name}, ${keyHash}, ${description}, ${rulesJson}, 'active', 0)
    `);
    
    if result.affectedRowCount == 1 {
        ApiKey createdKey = check getApiKeyById(apiKeyId);
        return [createdKey, apiKey];
    }
    
    return error("Failed to create API key");
}

function getApiKeyCountForUser(string userId) returns int|error {
    record {|int count;|}|sql:Error result = dbClient->queryRow(`
        SELECT COUNT(*) as count FROM api_keys 
        WHERE user_id = ${userId} AND status != 'revoked'
    `);
    
    if result is sql:Error {
        return 0;
    }
    
    return result.count;
}

function getApiKeyById(string keyId) returns ApiKey|error {
    record {|
        string id;
        string user_id;
        string name;
        string key_hash;
        string? description;
        string rules;
        string status;
        int usage_count;
        string created_at;
        string updated_at;
    |}|sql:Error result = dbClient->queryRow(`
        SELECT id, user_id, name, key_hash, description, rules, status, usage_count, created_at, updated_at
        FROM api_keys WHERE id = ${keyId}
    `);
    
    if result is sql:Error {
        return error("API key not found");
    }
    
    json rulesJson = check result.rules.fromJsonString();
    string[] rulesArray = check rulesJson.cloneWithType();
    
    return {
        id: result.id,
        user_id: result.user_id,
        name: result.name,
        key_hash: result.key_hash,
        description: result.description,
        rules: rulesArray,
        status: result.status,
        usage_count: result.usage_count,
        created_at: result.created_at,
        updated_at: result.updated_at
    };
}

function getApiKeysByUserId(string userId) returns ApiKey[]|error {
    stream<record {|
        string id;
        string user_id;
        string name;
        string key_hash;
        string? description;
        string rules;
        string status;
        int usage_count;
        string created_at;
        string updated_at;
    |}, sql:Error?> resultStream = dbClient->query(`
        SELECT id, user_id, name, key_hash, description, rules, status, usage_count, created_at, updated_at
        FROM api_keys WHERE user_id = ${userId} AND status != 'revoked'
        ORDER BY created_at DESC
    `);
    
    ApiKey[] apiKeys = [];
    check from var row in resultStream
        do {
            json rulesJson = check row.rules.fromJsonString();
            string[] rulesArray = check rulesJson.cloneWithType();
            apiKeys.push({
                id: row.id,
                user_id: row.user_id,
                name: row.name,
                key_hash: row.key_hash,
                description: row.description,
                rules: rulesArray,
                status: row.status,
                usage_count: row.usage_count,
                created_at: row.created_at,
                updated_at: row.updated_at
            });
        };
    
    return apiKeys;
}

function validateApiKey(string apiKey) returns ApiKey|error {
    string keyHash = hashApiKey(apiKey);
    
    record {|
        string id;
        string user_id;
        string name;
        string key_hash;
        string? description;
        string rules;
        string status;
        int usage_count;
        string created_at;
        string updated_at;
    |}|sql:Error result = dbClient->queryRow(`
        SELECT id, user_id, name, key_hash, description, rules, status, usage_count, created_at, updated_at
        FROM api_keys WHERE key_hash = ${keyHash} AND status = 'active'
    `);
    
    if result is sql:Error {
        return error("Invalid API key");
    }
    
    json rulesJson = check result.rules.fromJsonString();
    string[] rulesArray = check rulesJson.cloneWithType();
    
    return {
        id: result.id,
        user_id: result.user_id,
        name: result.name,
        key_hash: result.key_hash,
        description: result.description,
        rules: rulesArray,
        status: result.status,
        usage_count: result.usage_count,
        created_at: result.created_at,
        updated_at: result.updated_at
    };
}

function incrementApiKeyUsage(string keyId) returns error? {
    _ = check dbClient->execute(`
        UPDATE api_keys 
        SET usage_count = usage_count + 1, updated_at = CURRENT_TIMESTAMP
        WHERE id = ${keyId}
    `);
}

function updateApiKeyStatus(string keyId, string status) returns error? {
    _ = check dbClient->execute(`
        UPDATE api_keys 
        SET status = ${status}, updated_at = CURRENT_TIMESTAMP
        WHERE id = ${keyId}
    `);
}

function deleteApiKey(string keyId, string userId) returns boolean|error {
    sql:ExecutionResult result = check dbClient->execute(`
        UPDATE api_keys 
        SET status = 'revoked', updated_at = CURRENT_TIMESTAMP
        WHERE id = ${keyId} AND user_id = ${userId}
    `);
    
    return result.affectedRowCount > 0;
}

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowCredentials: true,
        allowHeaders: ["Authorization", "Content-Type"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /api on new http:Listener(8080) {
    
    // Initialize database on service start
    function init() returns error? {
        error? initResult = initializeDatabase(dbClient);
        if initResult is error {
            log:printError("Failed to initialize database", initResult);
            return initResult;
        }
    }

    resource function get health() returns json {
        return {
            "status": "healthy", 
            "service": "userportal-auth",
            "timestamp": time:utcToString(time:utcNow())
        };
    }

    resource function post auth/register(@http:Payload json payload) returns http:Response {
        http:Response res = new;
        
        // Extract and validate input
        json|error usernameField = payload.username;
        json|error emailField = payload.email;
        json|error passwordField = payload.password;

        if usernameField is error || emailField is error || passwordField is error {
            res.statusCode = 400;
            res.setJsonPayload({"error": "Missing required fields: username, email, password"});
            return res;
        }

        string username = usernameField.toString();
        string email = emailField.toString();
        string password = passwordField.toString();

        // Validate input
        if username.length() < 3 || username.length() > 50 {
            res.statusCode = 400;
            res.setJsonPayload({"error": "Username must be between 3 and 50 characters"});
            return res;
        }

        if !isValidEmail(email) {
            res.statusCode = 400;
            res.setJsonPayload({"error": "Invalid email format"});
            return res;
        }

        if !isValidPassword(password) {
            res.statusCode = 400;
            res.setJsonPayload({"error": "Password must be at least 8 characters long"});
            return res;
        }

        // Check if user already exists
        User|error? existingUserByUsername = getUserByUsername(username);
        if existingUserByUsername is User {
            res.statusCode = 409;
            res.setJsonPayload({"error": "Username already exists"});
            return res;
        }

        User|error? existingUserByEmail = getUserByEmail(email);
        if existingUserByEmail is User {
            res.statusCode = 409;
            res.setJsonPayload({"error": "Email already exists"});
            return res;
        }

        // Create user
        User|error newUser = createUser(username, email, password);
        if newUser is error {
            log:printError("Failed to create user", newUser);
            res.statusCode = 500;
            res.setJsonPayload({"error": "Failed to create user"});
            return res;
        }

        log:printInfo("User registered successfully: " + username);
        res.statusCode = 201;
        res.setJsonPayload({
            "message": "User registered successfully",
            "user": toUserResponse(newUser)
        });
        return res;
    }

    resource function post auth/login(@http:Payload json payload) returns http:Response {
        http:Response res = new;
        
        // Extract input
        json|error usernameField = payload.username;
        json|error passwordField = payload.password;

        if usernameField is error || passwordField is error {
            res.statusCode = 400;
            res.setJsonPayload({"error": "Missing username or password"});
            return res;
        }

        string username = usernameField.toString();
        string password = passwordField.toString();

        // Find user
        User|error? user = getUserByUsername(username);
        if user is () || user is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid credentials"});
            return res;
        }

        // Verify password
        boolean passwordValid = checkPassword(password, user.password_hash);
        if !passwordValid {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid credentials"});
            return res;
        }

        // Generate token
        string token = generateToken(user);

        // Hash token for storage
        string tokenHash = crypto:hashSha256(token.toBytes()).toBase16();
        
        // Store token in database
        string|error tokenId = storeJWTToken(user.id, tokenHash);
        if tokenId is error {
            log:printError("Failed to store JWT token", tokenId);
            res.statusCode = 500;
            res.setJsonPayload({"error": "Failed to store token"});
            return res;
        }

        log:printInfo("User logged in successfully: " + username);
        res.setJsonPayload({
            "token": token,
            "message": "Login successful",
            "user": toUserResponse(user),
            "expiresIn": jwtExpiryTime
        });
        return res;
    }

    resource function get auth/profile(http:Request req) returns http:Response {
        http:Response res = new;
        
        // Get and validate authorization header
        string|http:HeaderNotFoundError authHeader = req.getHeader("Authorization");
        if authHeader is http:HeaderNotFoundError {
            res.statusCode = 401;
            res.setJsonPayload({"error": "No authorization header"});
            return res;
        }

        if !authHeader.startsWith("Bearer ") {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid authorization format"});
            return res;
        }

        string token = authHeader.substring(7);
        
        // Validate token
        json|error payload = validateToken(token);
        if payload is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid or expired token"});
            return res;
        }

        // Check if token exists in database and is not revoked
        string tokenHash = crypto:hashSha256(token.toBytes()).toBase16();
        boolean|error tokenValid = isTokenValid(tokenHash);
        if tokenValid is error || !tokenValid {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Token has been revoked or expired"});
            return res;
        }

        // Get user from token
        json|error userIdField = payload.userId;
        if userIdField is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid token claims"});
            return res;
        }

        string userId = userIdField.toString();
        User|error user = getUserById(userId);
        if user is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "User not found"});
            return res;
        }

        res.setJsonPayload({
            "user": toUserResponse(user),
            "message": "Profile retrieved successfully"
        });
        return res;
    }

    resource function post auth/logout(http:Request req) returns http:Response {
        http:Response res = new;
        
        // Get authorization header
        string|http:HeaderNotFoundError authHeader = req.getHeader("Authorization");
        if authHeader is http:HeaderNotFoundError {
            res.setJsonPayload({"message": "Logout successful"});
            return res;
        }

        if authHeader.startsWith("Bearer ") {
            string token = authHeader.substring(7);
            string tokenHash = crypto:hashSha256(token.toBytes()).toBase16();
            
            // Revoke token
            boolean|error revokeResult = revokeToken(tokenHash);
            if revokeResult is error {
                log:printError("Failed to revoke token", revokeResult);
            }
        }

        res.setJsonPayload({"message": "Logout successful"});
        return res;
    }

    // API Key Management Endpoints
    resource function post apikeys(http:Request req, @http:Payload CreateApiKeyRequest payload) returns http:Response {
        http:Response res = new;
        
        // Validate JWT token and get user
        json|error userPayload = validateTokenFromRequest(req);
        if userPayload is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid or expired token"});
            return res;
        }
        
        string|error userIdResult = extractUserId(userPayload);
        if userIdResult is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid token claims"});
            return res;
        }
        string userId = userIdResult;
        
        // Validate input
        if payload.name.length() < 1 || payload.name.length() > 100 {
            res.statusCode = 400;
            res.setJsonPayload({"error": "API key name must be between 1 and 100 characters"});
            return res;
        }
        
        string[] rules = payload.rules ?: [];
        
        // Create API key
        [ApiKey, string]|error result = createApiKey(userId, payload.name, payload.description, rules);
        if result is error {
            if result.message().includes("Maximum of 3 API keys") {
                res.statusCode = 400;
                res.setJsonPayload({"error": result.message()});
            } else {
                log:printError("Failed to create API key", result);
                res.statusCode = 500;
                res.setJsonPayload({"error": "Failed to create API key"});
            }
            return res;
        }
        
        [ApiKey, string] [apiKey, plainKey] = result;
        
        log:printInfo("API key created successfully for user: " + userId);
        res.statusCode = 201;
        res.setJsonPayload({
            "message": "API key created successfully",
            "apiKey": toApiKeyResponse(apiKey),
            "key": plainKey // Only returned once during creation
        });
        return res;
    }

    resource function get apikeys(http:Request req) returns http:Response {
        http:Response res = new;
        
        // Validate JWT token and get user
        json|error userPayload = validateTokenFromRequest(req);
        if userPayload is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid or expired token"});
            return res;
        }
        
        string|error userIdResult = extractUserId(userPayload);
        if userIdResult is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid token claims"});
            return res;
        }
        string userId = userIdResult;
        
        // Get user's API keys
        ApiKey[]|error apiKeys = getApiKeysByUserId(userId);
        if apiKeys is error {
            log:printError("Failed to get API keys", apiKeys);
            res.statusCode = 500;
            res.setJsonPayload({"error": "Failed to retrieve API keys"});
            return res;
        }
        
        ApiKeyResponse[] responseKeys = [];
        foreach ApiKey key in apiKeys {
            responseKeys.push(toApiKeyResponse(key));
        }
        
        res.setJsonPayload({
            "apiKeys": responseKeys,
            "count": responseKeys.length(),
            "maxAllowed": 3
        });
        return res;
    }

    resource function put apikeys/[string keyId]/status(http:Request req, @http:Payload json payload) returns http:Response {
        http:Response res = new;
        
        // Validate JWT token and get user
        json|error userPayload = validateTokenFromRequest(req);
        if userPayload is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid or expired token"});
            return res;
        }
        
        string|error userIdResult = extractUserId(userPayload);
        if userIdResult is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid token claims"});
            return res;
        }
        string userId = userIdResult;
        
        // Validate status
        json|error statusField = payload.status;
        if statusField is error {
            res.statusCode = 400;
            res.setJsonPayload({"error": "Status field is required"});
            return res;
        }
        
        string status = statusField.toString();
        if status != "active" && status != "inactive" {
            res.statusCode = 400;
            res.setJsonPayload({"error": "Status must be 'active' or 'inactive'"});
            return res;
        }
        
        // Verify the API key belongs to the user
        ApiKey|error apiKey = getApiKeyById(keyId);
        if apiKey is error {
            res.statusCode = 404;
            res.setJsonPayload({"error": "API key not found"});
            return res;
        }
        
        if apiKey.user_id != userId {
            res.statusCode = 403;
            res.setJsonPayload({"error": "Access denied"});
            return res;
        }
        
        // Update status
        error? updateResult = updateApiKeyStatus(keyId, status);
        if updateResult is error {
            log:printError("Failed to update API key status", updateResult);
            res.statusCode = 500;
            res.setJsonPayload({"error": "Failed to update API key status"});
            return res;
        }
        
        res.setJsonPayload({"message": "API key status updated successfully"});
        return res;
    }

    resource function delete apikeys/[string keyId](http:Request req) returns http:Response {
        http:Response res = new;
        
        // Validate JWT token and get user
        json|error userPayload = validateTokenFromRequest(req);
        if userPayload is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid or expired token"});
            return res;
        }
        
        string|error userIdResult = extractUserId(userPayload);
        if userIdResult is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid token claims"});
            return res;
        }
        string userId = userIdResult;
        
        // Delete (revoke) API key
        boolean|error deleteResult = deleteApiKey(keyId, userId);
        if deleteResult is error {
            log:printError("Failed to delete API key", deleteResult);
            res.statusCode = 500;
            res.setJsonPayload({"error": "Failed to delete API key"});
            return res;
        }
        
        if !deleteResult {
            res.statusCode = 404;
            res.setJsonPayload({"error": "API key not found or access denied"});
            return res;
        }
        
        res.setJsonPayload({"message": "API key deleted successfully"});
        return res;
    }

    // Helper endpoint to validate API key (for testing)
    resource function post apikeys/validate(@http:Payload json payload) returns http:Response {
        http:Response res = new;
        
        json|error keyField = payload.apiKey;
        if keyField is error {
            res.statusCode = 400;
            res.setJsonPayload({"error": "API key is required"});
            return res;
        }
        
        string apiKey = keyField.toString();
        
        ApiKey|error validationResult = validateApiKey(apiKey);
        if validationResult is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid API key"});
            return res;
        }
        
        // Increment usage count
        error? usageResult = incrementApiKeyUsage(validationResult.id);
        if usageResult is error {
            log:printError("Failed to increment API key usage", usageResult);
        }
        
        res.setJsonPayload({
            "valid": true,
            "apiKey": toApiKeyResponse(validationResult),
            "message": "API key is valid"
        });
        return res;
    }
}

// Helper function to extract user ID from token payload
function extractUserId(json payload) returns string|error {
    json|error userIdField = payload.userId;
    if userIdField is error {
        return error("Invalid token claims");
    }
    return userIdField.toString();
}

// Helper function to validate token from request
function validateTokenFromRequest(http:Request req) returns json|error {
    // Get and validate authorization header
    string|http:HeaderNotFoundError authHeader = req.getHeader("Authorization");
    if authHeader is http:HeaderNotFoundError {
        return error("No authorization header");
    }

    if !authHeader.startsWith("Bearer ") {
        return error("Invalid authorization format");
    }

    string token = authHeader.substring(7);
    
    // Validate token
    json|error payload = validateToken(token);
    if payload is error {
        return error("Invalid or expired token");
    }

    // Check if token exists in database and is not revoked
    string tokenHash = crypto:hashSha256(token.toBytes()).toBase16();
    boolean|error tokenValid = isTokenValid(tokenHash);
    if tokenValid is error || !tokenValid {
        return error("Token has been revoked or expired");
    }
    
    return payload;
}