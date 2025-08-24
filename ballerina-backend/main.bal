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

    resource function put apikeys/[string keyId]/rules(http:Request req, @http:Payload UpdateApiKeyRulesRequest payload) returns http:Response {
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
        
        // Verify the API key belongs to the user and is not revoked
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
        
        if apiKey.status == "revoked" {
            res.statusCode = 400;
            res.setJsonPayload({"error": "Cannot update rules for revoked API key"});
            return res;
        }
        
        // Update rules
        error? updateResult = updateApiKeyRules(keyId, userId, payload.rules);
        if updateResult is error {
            log:printError("Failed to update API key rules", updateResult);
            res.statusCode = 500;
            res.setJsonPayload({"error": "Failed to update API key rules"});
            return res;
        }
        
        // Get updated API key data
        ApiKey|error updatedKey = getApiKeyById(keyId);
        if updatedKey is error {
            res.statusCode = 500;
            res.setJsonPayload({"error": "Failed to retrieve updated API key"});
            return res;
        }
        
        log:printInfo("API key rules updated successfully for key: " + keyId);
        res.setJsonPayload({
            "message": "API key rules updated successfully",
            "apiKey": toApiKeyResponse(updatedKey)
        });
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
}    // 
===== PUBLIC API ENDPOINTS (API KEY AUTHENTICATION) =====
    
    // Get all users - requires 'read' permission
    resource function get users(http:Request req) returns http:Response {
        http:Response res = new;
        
        [ApiKey, boolean]|error validation = validateApiKeyFromRequest(req);
        if validation is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": validation.message()});
            return res;
        }
        
        [ApiKey, boolean] [apiKey, _] = validation;
        
        // Check if API key has 'read' permission
        if !apiKey.rules.indexOf("read") is int {
            res.statusCode = 403;
            res.setJsonPayload({"error": "API key does not have 'read' permission"});
            return res;
        }
        
        res.setJsonPayload({
            "users": sampleUsers,
            "count": sampleUsers.length(),
            "api_key_used": apiKey.name
        });
        return res;
    }
    
    // Get user by ID - requires 'read' permission
    resource function get users/[string userId](http:Request req) returns http:Response {
        http:Response res = new;
        
        [ApiKey, boolean]|error validation = validateApiKeyFromRequest(req);
        if validation is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": validation.message()});
            return res;
        }
        
        [ApiKey, boolean] [apiKey, _] = validation;
        
        // Check permissions
        if !apiKey.rules.indexOf("read") is int {
            res.statusCode = 403;
            res.setJsonPayload({"error": "API key does not have 'read' permission"});
            return res;
        }
        
        // Find user
        UserData? foundUser = ();
        foreach UserData user in sampleUsers {
            if user.id == userId {
                foundUser = user;
                break;
            }
        }
        
        if foundUser is () {
            res.statusCode = 404;
            res.setJsonPayload({"error": "User not found"});
            return res;
        }
        
        res.setJsonPayload({
            "user": foundUser,
            "api_key_used": apiKey.name
        });
        return res;
    }
    
    // Get all projects - requires 'read' permission
    resource function get projects(http:Request req) returns http:Response {
        http:Response res = new;
        
        [ApiKey, boolean]|error validation = validateApiKeyFromRequest(req);
        if validation is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": validation.message()});
            return res;
        }
        
        [ApiKey, boolean] [apiKey, _] = validation;
        
        // Check permissions
        if !apiKey.rules.indexOf("read") is int {
            res.statusCode = 403;
            res.setJsonPayload({"error": "API key does not have 'read' permission"});
            return res;
        }
        
        res.setJsonPayload({
            "projects": sampleProjects,
            "count": sampleProjects.length(),
            "api_key_used": apiKey.name
        });
        return res;
    }
    
    // Create new project - requires 'write' permission
    resource function post projects(http:Request req, @http:Payload json payload) returns http:Response {
        http:Response res = new;
        
        [ApiKey, boolean]|error validation = validateApiKeyFromRequest(req);
        if validation is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": validation.message()});
            return res;
        }
        
        [ApiKey, boolean] [apiKey, _] = validation;
        
        // Check permissions
        if !apiKey.rules.indexOf("write") is int {
            res.statusCode = 403;
            res.setJsonPayload({"error": "API key does not have 'write' permission"});
            return res;
        }
        
        // Validate input
        json|error nameField = payload.name;
        json|error descriptionField = payload.description;
        
        if nameField is error || descriptionField is error {
            res.statusCode = 400;
            res.setJsonPayload({"error": "Missing required fields: name, description"});
            return res;
        }
        
        string name = nameField.toString();
        string description = descriptionField.toString();
        
        if name.length() < 1 || name.length() > 100 {
            res.statusCode = 400;
            res.setJsonPayload({"error": "Project name must be between 1 and 100 characters"});
            return res;
        }
        
        // Create new project (in real app, this would save to database)
        string newId = (sampleProjects.length() + 1).toString();
        ProjectData newProject = {
            id: newId,
            name: name,
            description: description,
            status: "Planning",
            created_date: "2024-08-24"
        };
        
        res.statusCode = 201;
        res.setJsonPayload({
            "message": "Project created successfully",
            "project": newProject,
            "api_key_used": apiKey.name
        });
        return res;
    }
    
    // Get analytics data - requires 'analytics' permission
    resource function get analytics/summary(http:Request req) returns http:Response {
        http:Response res = new;
        
        [ApiKey, boolean]|error validation = validateApiKeyFromRequest(req);
        if validation is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": validation.message()});
            return res;
        }
        
        [ApiKey, boolean] [apiKey, _] = validation;
        
        // Check permissions
        if !apiKey.rules.indexOf("analytics") is int {
            res.statusCode = 403;
            res.setJsonPayload({"error": "API key does not have 'analytics' permission"});
            return res;
        }
        
        // Generate sample analytics data
        json analyticsData = {
            "total_users": sampleUsers.length(),
            "total_projects": sampleProjects.length(),
            "active_projects": 2,
            "completed_projects": 1,
            "departments": {
                "Engineering": 1,
                "Marketing": 1,
                "Sales": 1
            },
            "api_key_used": apiKey.name,
            "generated_at": "2024-08-24T10:30:00Z"
        };
        
        res.setJsonPayload(analyticsData);
        return res;
    }
    
    // Content moderation endpoint - requires 'moderate' permission
    resource function post moderate\-content/text/v1(http:Request req, @http:Payload json payload) returns http:Response {
        http:Response res = new;
        
        [ApiKey, boolean]|error validation = validateApiKeyFromRequest(req);
        if validation is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": validation.message()});
            return res;
        }
        
        [ApiKey, boolean] [apiKey, _] = validation;
        
        // Check permissions
        if !apiKey.rules.indexOf("moderate") is int {
            res.statusCode = 403;
            res.setJsonPayload({"error": "API key does not have 'moderate' permission"});
            return res;
        }
        
        // Validate input
        json|error textField = payload.text;
        if textField is error {
            res.statusCode = 400;
            res.setJsonPayload({"error": "Missing required field: text"});
            return res;
        }
        
        string text = textField.toString();
        if text.length() == 0 {
            res.statusCode = 400;
            res.setJsonPayload({"error": "Text cannot be empty"});
            return res;
        }
        
        if text.length() > 10000 {
            res.statusCode = 400;
            res.setJsonPayload({"error": "Text cannot exceed 10,000 characters"});
            return res;
        }
        
        // Simple content moderation logic (in real app, this would use ML models)
        string[] flaggedWords = ["spam", "hate", "violence", "inappropriate"];
        boolean flagged = false;
        string[] detectedIssues = [];
        
        string lowerText = text.toLowerAscii();
        foreach string word in flaggedWords {
            if lowerText.includes(word) {
                flagged = true;
                detectedIssues.push(word);
            }
        }
        
        // Calculate confidence score (mock)
        float confidence = flagged ? 0.85 : 0.95;
        
        res.setJsonPayload({
            "status": true,
            "result": {
                "flagged": flagged,
                "confidence": confidence,
                "categories": flagged ? detectedIssues : [],
                "severity": flagged ? "medium" : "none",
                "action_recommended": flagged ? "review" : "approve"
            },
            "metadata": {
                "text_length": text.length(),
                "processing_time_ms": 45,
                "model_version": "v1.2.3",
                "api_key_used": apiKey.name
            }
        });
        return res;
    }
    
    // API documentation endpoint - no authentication required
    resource function get docs() returns json {
        return {
            "api_version": "1.0.0",
            "description": "User Portal API - Manage users, projects, and analytics",
            "authentication": "API Key required (X-API-Key header or Authorization: ApiKey <key>)",
            "endpoints": {
                "GET /api/users": {
                    "description": "Get all users",
                    "permissions": ["read"],
                    "response": "Array of user objects"
                },
                "GET /api/users/{id}": {
                    "description": "Get user by ID",
                    "permissions": ["read"],
                    "response": "Single user object"
                },
                "GET /api/projects": {
                    "description": "Get all projects",
                    "permissions": ["read"],
                    "response": "Array of project objects"
                },
                "POST /api/projects": {
                    "description": "Create new project",
                    "permissions": ["write"],
                    "body": {"name": "string", "description": "string"},
                    "response": "Created project object"
                },
                "GET /api/analytics/summary": {
                    "description": "Get analytics summary",
                    "permissions": ["analytics"],
                    "response": "Analytics data object"
                }
            },
            "permissions": {
                "read": "Access to GET endpoints for users and projects",
                "write": "Access to POST/PUT/DELETE endpoints",
                "analytics": "Access to analytics endpoints"
            },
            "rate_limits": {
                "monthly_quota": 100,
                "quota_reset": "First day of each month"
            }
        };
    }