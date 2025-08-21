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
}