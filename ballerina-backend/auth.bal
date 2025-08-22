// Authentication utilities and token management
import ballerina/crypto;
import ballerina/time;
import ballerina/regex;
import ballerina/http;

// Configuration
configurable string jwtSecret = "your-super-secret-jwt-key-change-in-production-min-32-chars";
configurable int jwtExpiryTime = 3600;
configurable string jwtIssuer = "userportal-auth";
configurable string jwtAudience = "userportal-users";

// Simple password hashing (for demo purposes)
public function hashPassword(string password) returns string {
    return crypto:hashSha256((password + "salt123").toBytes()).toBase16();
}

public function checkPassword(string password, string hash) returns boolean {
    string hashedInput = crypto:hashSha256((password + "salt123").toBytes()).toBase16();
    return hashedInput == hash;
}

// Simple secure token generation (using direct string concatenation for demo)
public function generateToken(User user) returns string {
    int currentTime = <int>time:utcNow()[0];
    int expiryTime = currentTime + jwtExpiryTime;
    
    // Create a simple token with user info and expiry
    string tokenData = string `${user.id}|${user.username}|${user.email}|${expiryTime}`;
    string signature = crypto:hashSha256((tokenData + jwtSecret).toBytes()).toBase16();
    
    return string `${tokenData}|${signature}`;
}

public function validateToken(string token) returns json|error {
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

// Helper function to extract user ID from token payload
public function extractUserId(json payload) returns string|error {
    json|error userIdField = payload.userId;
    if userIdField is error {
        return error("Invalid token claims");
    }
    return userIdField.toString();
}

// Helper function to validate token from request
public function validateTokenFromRequest(http:Request req) returns json|error {
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