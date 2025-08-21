import ballerina/http;
import ballerina/sql;
import ballerina/mysql;
import ballerina/jwt;
import ballerina/crypto;
import ballerina/uuid;
import ballerina/time;
import ballerina/log;
import ballerina/regex;

// Configuration
configurable string jwtSecret = ?;
configurable int jwtExpiryTime = 3600;
configurable string jwtIssuer = "userportal-auth";
configurable string jwtAudience = "userportal-users";

configurable string dbHost = "localhost";
configurable int dbPort = 3306;
configurable string dbName = "userportal";
configurable string dbUsername = "root";
configurable string dbPassword = "password";

// Database connection
mysql:Client dbClient = check new (
    host = dbHost,
    port = dbPort,
    database = dbName,
    user = dbUsername,
    password = dbPassword
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

type JWTToken record {|
    string id;
    string user_id;
    string token_hash;
    string expires_at;
    string created_at;
    boolean is_revoked;
|};

// JWT configuration
jwt:IssuerConfig jwtIssuerConfig = {
    username: jwtIssuer,
    issuer: jwtIssuer,
    audience: [jwtAudience],
    expTime: jwtExpiryTime,
    signatureConfig: {
        config: {
            keyStore: {
                path: "resources/keystore.p12",
                password: "ballerina"
            },
            keyAlias: "ballerina",
            keyPassword: "ballerina"
        }
    }
};

// Password hashing using Java BCrypt
public function hashPassword(string password) returns string|error = @java:Method {
    'class: "org.mindrot.jbcrypt.BCrypt"
} external;

public function checkPassword(string password, string hash) returns boolean = @java:Method {
    'class: "org.mindrot.jbcrypt.BCrypt",
    name: "checkpw"
} external;

// Utility functions
function generateUserId() returns string {
    return uuid:createType1AsString();
}

function generateTokenId() returns string {
    return uuid:createType1AsString();
}

function isValidEmail(string email) returns boolean {
    string emailPattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$";
    return regex:matches(email, emailPattern);
}

function isValidPassword(string password) returns boolean {
    return password.length() >= 8;
}

// Database operations
function createUser(string username, string email, string password) returns User|error {
    // Hash password
    string hashedPassword = check hashPassword(password);
    string userId = generateUserId();
    
    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO users (id, username, email, password_hash, is_active)
        VALUES (${userId}, ${username}, ${email}, ${hashedPassword}, true)
    `);
    
    if result.affectedRowCount == 1 {
        return getUserById(userId);
    }
    
    return error("Failed to create user");
}

function getUserByUsername(string username) returns User|error? {
    User|sql:Error result = dbClient->queryRow(`
        SELECT id, username, email, password_hash, created_at, updated_at, is_active
        FROM users WHERE username = ${username} AND is_active = true
    `);
    
    if result is sql:NoRowsError {
        return ();
    }
    
    return result;
}

function getUserByEmail(string email) returns User|error? {
    User|sql:Error result = dbClient->queryRow(`
        SELECT id, username, email, password_hash, created_at, updated_at, is_active
        FROM users WHERE email = ${email} AND is_active = true
    `);
    
    if result is sql:NoRowsError {
        return ();
    }
    
    return result;
}

function getUserById(string userId) returns User|error {
    return dbClient->queryRow(`
        SELECT id, username, email, password_hash, created_at, updated_at, is_active
        FROM users WHERE id = ${userId} AND is_active = true
    `);
}

function updateUserEmail(string userId, string email) returns boolean|error {
    sql:ExecutionResult result = check dbClient->execute(`
        UPDATE users SET email = ${email}, updated_at = CURRENT_TIMESTAMP
        WHERE id = ${userId} AND is_active = true
    `);
    
    return result.affectedRowCount == 1;
}

function storeJWTToken(string userId, string tokenHash, int expiryTime) returns string|error {
    string tokenId = generateTokenId();
    time:Utc currentTime = time:utcNow();
    time:Utc expiryUtc = time:utcAddSeconds(currentTime, expiryTime);
    string expiryString = time:utcToString(expiryUtc);
    
    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO jwt_tokens (id, user_id, token_hash, expires_at, is_revoked)
        VALUES (${tokenId}, ${userId}, ${tokenHash}, ${expiryString}, false)
    `);
    
    if result.affectedRowCount == 1 {
        return tokenId;
    }
    
    return error("Failed to store JWT token");
}

function isTokenValid(string tokenHash) returns boolean|error {
    JWTToken|sql:Error result = dbClient->queryRow(`
        SELECT id, user_id, token_hash, expires_at, created_at, is_revoked
        FROM jwt_tokens 
        WHERE token_hash = ${tokenHash} 
        AND is_revoked = false 
        AND expires_at > CURRENT_TIMESTAMP
    `);
    
    return !(result is sql:NoRowsError || result is sql:Error);
}

function revokeToken(string tokenHash) returns boolean|error {
    sql:ExecutionResult result = check dbClient->execute(`
        UPDATE jwt_tokens SET is_revoked = true
        WHERE token_hash = ${tokenHash}
    `);
    
    return result.affectedRowCount > 0;
}

function cleanupExpiredTokens() returns error? {
    _ = check dbClient->execute(`
        DELETE FROM jwt_tokens 
        WHERE expires_at < CURRENT_TIMESTAMP OR is_revoked = true
    `);
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
        boolean|error passwordValid = checkPassword(password, user.password_hash);
        if passwordValid is error || !passwordValid {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid credentials"});
            return res;
        }

        // Generate JWT token
        jwt:IssuerConfig config = {
            ...jwtIssuerConfig,
            customClaims: {
                "userId": user.id,
                "username": user.username,
                "email": user.email
            }
        };

        string|jwt:Error jwtToken = jwt:issue(config);
        if jwtToken is jwt:Error {
            log:printError("Failed to generate JWT token", jwtToken);
            res.statusCode = 500;
            res.setJsonPayload({"error": "Failed to generate token"});
            return res;
        }

        // Hash token for storage
        string tokenHash = crypto:hashSha256(jwtToken.toBytes()).toBase16();
        
        // Store token in database
        string|error tokenId = storeJWTToken(user.id, tokenHash, jwtExpiryTime);
        if tokenId is error {
            log:printError("Failed to store JWT token", tokenId);
            res.statusCode = 500;
            res.setJsonPayload({"error": "Failed to store token"});
            return res;
        }

        log:printInfo("User logged in successfully: " + username);
        res.setJsonPayload({
            "token": jwtToken,
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
        
        // Validate JWT token
        jwt:Payload|jwt:Error payload = jwt:validate(token, {
            issuer: jwtIssuer,
            audience: jwtAudience,
            signatureConfig: jwtIssuerConfig.signatureConfig
        });

        if payload is jwt:Error {
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

        // Get user from token claims
        json|error userIdClaim = payload["userId"];
        if userIdClaim is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid token claims"});
            return res;
        }

        string userId = userIdClaim.toString();
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

    resource function put auth/profile(http:Request req, @http:Payload json data) returns http:Response {
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
        
        // Validate JWT token
        jwt:Payload|jwt:Error payload = jwt:validate(token, {
            issuer: jwtIssuer,
            audience: jwtAudience,
            signatureConfig: jwtIssuerConfig.signatureConfig
        });

        if payload is jwt:Error {
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

        // Get user from token claims
        json|error userIdClaim = payload["userId"];
        if userIdClaim is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid token claims"});
            return res;
        }

        string userId = userIdClaim.toString();
        User|error user = getUserById(userId);
        if user is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "User not found"});
            return res;
        }

        // Update email if provided
        json|error emailField = data.email;
        if emailField is string {
            string newEmail = emailField.toString();
            if !isValidEmail(newEmail) {
                res.statusCode = 400;
                res.setJsonPayload({"error": "Invalid email format"});
                return res;
            }

            // Check if email already exists
            User|error? existingUser = getUserByEmail(newEmail);
            if existingUser is User && existingUser.id != userId {
                res.statusCode = 409;
                res.setJsonPayload({"error": "Email already exists"});
                return res;
            }

            boolean|error updateResult = updateUserEmail(userId, newEmail);
            if updateResult is error || !updateResult {
                res.statusCode = 500;
                res.setJsonPayload({"error": "Failed to update profile"});
                return res;
            }

            // Get updated user
            user = check getUserById(userId);
        }

        res.setJsonPayload({
            "message": "Profile updated successfully",
            "user": toUserResponse(user)
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

    // Cleanup endpoint for expired tokens (can be called by a cron job)
    resource function post auth/cleanup() returns json {
        error? cleanupResult = cleanupExpiredTokens();
        if cleanupResult is error {
            log:printError("Failed to cleanup expired tokens", cleanupResult);
            return {"error": "Failed to cleanup expired tokens"};
        }
        return {"message": "Expired tokens cleaned up successfully"};
    }
}