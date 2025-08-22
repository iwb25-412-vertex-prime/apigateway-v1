// Main service file - clean and organized
import ballerina/http;
import ballerina/time;
import ballerina/log;
import ballerina/crypto;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000", "http://localhost:3001"],
        allowCredentials: true,
        allowHeaders: ["Authorization", "Content-Type"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /api on new http:Listener(8080) {
    
    // Initialize database on service start
    function init() returns error? {
        error? initResult = initializeDatabase();
        if initResult is error {
            log:printError("Failed to initialize database", initResult);
            return initResult;
        }
    }

    // ===== HEALTH CHECK =====
    resource function get health() returns json {
        return {
            "status": "healthy", 
            "service": "userportal-auth",
            "timestamp": time:utcToString(time:utcNow())
        };
    }

    // ===== AUTHENTICATION ENDPOINTS =====
    
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
        
        // Validate JWT token and get user
        json|error userPayload = validateTokenFromRequest(req);
        if userPayload is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid or expired token"});
            return res;
        }

        // Get user from token
        json|error userIdField = userPayload.userId;
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

    // ===== API KEY MANAGEMENT ENDPOINTS =====
    
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
        
        // Create API key
        [ApiKey, string]|error result = createApiKey(userId, payload.name, payload.description);
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
            // Get rules for this API key
            Rule[]|error rules = getRulesByApiKeyId(key.id);
            Rule[] keyRules = rules is error ? [] : rules;
            responseKeys.push(toApiKeyResponse(key, keyRules));
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
        
        [ApiKey, boolean]|error validationResult = validateApiKeyWithQuota(apiKey);
        if validationResult is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid API key"});
            return res;
        }
        
        [ApiKey, boolean] [validatedKey, quotaAvailable] = validationResult;
        
        if !quotaAvailable {
            res.statusCode = 429; // Too Many Requests
            res.setJsonPayload({
                "error": "Monthly quota exceeded",
                "message": "You have exceeded your monthly quota of 100 requests. Quota resets on: " + validatedKey.quota_reset_date,
                "apiKey": toApiKeyResponse(validatedKey)
            });
            return res;
        }
        
        // Increment usage count
        error? usageResult = incrementApiKeyUsage(validatedKey.id);
        if usageResult is error {
            log:printError("Failed to increment API key usage", usageResult);
        }
        
        // Get updated key data after incrementing usage
        ApiKey|error updatedKeyResult = getApiKeyById(validatedKey.id);
        ApiKey updatedKey = updatedKeyResult is error ? validatedKey : updatedKeyResult;
        
        res.setJsonPayload({
            "valid": true,
            "apiKey": toApiKeyResponse(updatedKey),
            "message": "API key is valid"
        });
        return res;
    }

    // Endpoint to check quota status without incrementing usage
    resource function get apikeys/[string keyId]/quota(http:Request req) returns http:Response {
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
        
        // Get API key and verify ownership
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
        
        // Check if quota needs reset
        boolean quotaAvailable = checkQuotaLimit(apiKey);
        
        // Get updated key data after potential quota reset
        ApiKey|error updatedKeyResult = getApiKeyById(keyId);
        ApiKey updatedKey = updatedKeyResult is error ? apiKey : updatedKeyResult;
        
        int remainingQuota = updatedKey.monthly_quota - updatedKey.current_month_usage;
        
        res.setJsonPayload({
            "keyId": keyId,
            "monthlyQuota": updatedKey.monthly_quota,
            "currentMonthUsage": updatedKey.current_month_usage,
            "remainingQuota": remainingQuota < 0 ? 0 : remainingQuota,
            "quotaResetDate": updatedKey.quota_reset_date,
            "quotaAvailable": quotaAvailable,
            "status": updatedKey.status
        });
        return res;
    }

    // ===== RULE MANAGEMENT ENDPOINTS =====
    
    // Create a new rule for an API key
    resource function post apikeys/[string keyId]/rules(http:Request req, @http:Payload CreateRuleRequest payload) returns http:Response {
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
        
        // Verify API key ownership
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
        
        // Validate input
        if payload.name.length() < 1 || payload.name.length() > 100 {
            res.statusCode = 400;
            res.setJsonPayload({"error": "Rule name must be between 1 and 100 characters"});
            return res;
        }
        
        string[] validRuleTypes = ["rate_limit", "ip_whitelist", "endpoint_access", "time_restriction"];
        if !validRuleTypes.some(function(string ruleType) returns boolean => ruleType == payload.rule_type) {
            res.statusCode = 400;
            res.setJsonPayload({"error": "Invalid rule type. Must be one of: " + string:'join(", ", ...validRuleTypes)});
            return res;
        }
        
        boolean isActive = payload.is_active ?: true;
        
        // Create rule
        Rule|error result = createRule(keyId, payload.name, payload.description, payload.rule_type, payload.rule_config, isActive);
        if result is error {
            log:printError("Failed to create rule", result);
            res.statusCode = 500;
            res.setJsonPayload({"error": "Failed to create rule"});
            return res;
        }
        
        log:printInfo("Rule created successfully for API key: " + keyId);
        res.statusCode = 201;
        res.setJsonPayload({
            "message": "Rule created successfully",
            "rule": toRuleResponse(result)
        });
        return res;
    }
    
    // Get all rules for an API key
    resource function get apikeys/[string keyId]/rules(http:Request req) returns http:Response {
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
        
        // Verify API key ownership
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
        
        // Get rules
        Rule[]|error rules = getRulesByApiKeyId(keyId);
        if rules is error {
            log:printError("Failed to get rules", rules);
            res.statusCode = 500;
            res.setJsonPayload({"error": "Failed to retrieve rules"});
            return res;
        }
        
        RuleResponse[] responseRules = [];
        foreach Rule rule in rules {
            responseRules.push(toRuleResponse(rule));
        }
        
        res.setJsonPayload({
            "rules": responseRules,
            "count": responseRules.length(),
            "apiKeyId": keyId
        });
        return res;
    }
    
    // Update a rule
    resource function put rules/[string ruleId](http:Request req, @http:Payload UpdateRuleRequest payload) returns http:Response {
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
        
        // Verify rule ownership
        boolean|error ownershipResult = validateRuleOwnership(ruleId, userId);
        if ownershipResult is error || !ownershipResult {
            res.statusCode = 403;
            res.setJsonPayload({"error": "Access denied or rule not found"});
            return res;
        }
        
        // Validate input
        if payload.name is string && (payload.name.length() < 1 || payload.name.length() > 100) {
            res.statusCode = 400;
            res.setJsonPayload({"error": "Rule name must be between 1 and 100 characters"});
            return res;
        }
        
        // Update rule
        Rule|error result = updateRule(ruleId, payload.name, payload.description, payload.rule_config, payload.is_active);
        if result is error {
            log:printError("Failed to update rule", result);
            res.statusCode = 500;
            res.setJsonPayload({"error": "Failed to update rule"});
            return res;
        }
        
        res.setJsonPayload({
            "message": "Rule updated successfully",
            "rule": toRuleResponse(result)
        });
        return res;
    }
    
    // Delete a rule
    resource function delete rules/[string ruleId](http:Request req) returns http:Response {
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
        
        // Get rule to verify ownership and get API key ID
        Rule|error rule = getRuleById(ruleId);
        if rule is error {
            res.statusCode = 404;
            res.setJsonPayload({"error": "Rule not found"});
            return res;
        }
        
        // Verify rule ownership
        boolean|error ownershipResult = validateRuleOwnership(ruleId, userId);
        if ownershipResult is error || !ownershipResult {
            res.statusCode = 403;
            res.setJsonPayload({"error": "Access denied"});
            return res;
        }
        
        // Delete rule
        boolean|error deleteResult = deleteRule(ruleId, rule.api_key_id);
        if deleteResult is error {
            log:printError("Failed to delete rule", deleteResult);
            res.statusCode = 500;
            res.setJsonPayload({"error": "Failed to delete rule"});
            return res;
        }
        
        if !deleteResult {
            res.statusCode = 404;
            res.setJsonPayload({"error": "Rule not found"});
            return res;
        }
        
        res.setJsonPayload({"message": "Rule deleted successfully"});
        return res;
    }
    
    // Get all rules for a user (across all API keys)
    resource function get rules(http:Request req) returns http:Response {
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
        
        // Get all rules for user
        Rule[]|error rules = getRulesByUserId(userId);
        if rules is error {
            log:printError("Failed to get rules", rules);
            res.statusCode = 500;
            res.setJsonPayload({"error": "Failed to retrieve rules"});
            return res;
        }
        
        RuleResponse[] responseRules = [];
        foreach Rule rule in rules {
            responseRules.push(toRuleResponse(rule));
        }
        
        res.setJsonPayload({
            "rules": responseRules,
            "count": responseRules.length()
        });
        return res;
    }
}