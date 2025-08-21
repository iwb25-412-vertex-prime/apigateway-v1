import ballerina/http;
import ballerina/jwt;
import ballerina/crypto;
import ballerina/log;
import ballerina/time;

// JWT configuration
configurable string jwtSecret = "your-secret-key-change-this-in-production";
configurable int jwtExpiryTime = 3600; // 1 hour in seconds
configurable int port = 8080;

// CORS configuration for frontend
http:CorsConfig corsConfig = {
    allowOrigins: ["http://localhost:3000"],
    allowCredentials: true,
    allowHeaders: ["Authorization", "Content-Type"],
    allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
};

// JWT issuer configuration
jwt:IssuerConfig jwtIssuerConfig = {
    username: "ballerina",
    issuer: "userportal-auth",
    audience: ["userportal-frontend"],
    keyId: "key-1",
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

// JWT validator configuration
jwt:ValidatorConfig jwtValidatorConfig = {
    issuer: "userportal-auth",
    audience: ["userportal-frontend"],
    signatureConfig: {
        trustStoreConfig: {
            trustStore: {
                path: "resources/keystore.p12",
                password: "ballerina"
            },
            certAlias: "ballerina"
        }
    }
};

// User data type
type User record {
    string id;
    string username;
    string email;
    string password; // In production, this should be hashed
};

type LoginRequest record {
    string username;
    string password;
};

type LoginResponse record {
    string token;
    string message;
    User user;
};

type RegisterRequest record {
    string username;
    string email;
    string password;
};

// In-memory user store (replace with database in production)
map<User> users = {};

service /api on new http:Listener(port, config = {cors: corsConfig}) {

    // Health check endpoint
    resource function get health() returns json {
        return {
            status: "healthy",
            timestamp: time:utcNow(),
            service: "userportal-auth"
        };
    }

    // Register endpoint
    resource function post auth/register(RegisterRequest registerReq) returns http:Created|http:BadRequest|http:Conflict {
        // Check if user already exists
        foreach User user in users {
            if user.username == registerReq.username || user.email == registerReq.email {
                return http:CONFLICT;
            }
        }

        // Create new user
        string userId = crypto:hashSha256(registerReq.username.toBytes()).toBase16();
        User newUser = {
            id: userId,
            username: registerReq.username,
            email: registerReq.email,
            password: registerReq.password // In production, hash this password
        };

        users[userId] = newUser;
        log:printInfo("New user registered: " + registerReq.username);

        return http:CREATED;
    }

    // Login endpoint
    resource function post auth/login(LoginRequest loginReq) returns LoginResponse|http:Unauthorized|http:InternalServerError {
        // Find user
        User? foundUser = ();
        foreach User user in users {
            if user.username == loginReq.username && user.password == loginReq.password {
                foundUser = user;
                break;
            }
        }

        if foundUser is () {
            return http:UNAUTHORIZED;
        }

        // Generate JWT token
        jwt:Header header = {
            alg: jwt:RS256,
            typ: "JWT"
        };

        jwt:Payload payload = {
            sub: foundUser.id,
            iss: "userportal-auth",
            aud: ["userportal-frontend"],
            exp: time:utcNow()[0] + jwtExpiryTime,
            iat: time:utcNow()[0],
            username: foundUser.username,
            email: foundUser.email
        };

        string|jwt:Error token = jwt:issue(jwtIssuerConfig, payload, header);
        
        if token is jwt:Error {
            log:printError("Error generating JWT token", token);
            return http:INTERNAL_SERVER_ERROR;
        }

        User userResponse = {
            id: foundUser.id,
            username: foundUser.username,
            email: foundUser.email,
            password: "" // Don't send password back
        };

        return {
            token: token,
            message: "Login successful",
            user: userResponse
        };
    }

    // Protected endpoint - Get user profile
    @http:ResourceConfig {
        auth: [
            {
                jwtValidatorConfig: jwtValidatorConfig
            }
        ]
    }
    resource function get auth/profile(http:Request req) returns json|http:Unauthorized|http:InternalServerError {
        jwt:Payload|http:Unauthorized jwtPayload = getJwtPayload(req);
        
        if jwtPayload is http:Unauthorized {
            return jwtPayload;
        }

        string? userId = jwtPayload.sub;
        if userId is () {
            return http:UNAUTHORIZED;
        }

        User? user = users[userId];
        if user is () {
            return http:UNAUTHORIZED;
        }

        return {
            id: user.id,
            username: user.username,
            email: user.email,
            message: "Profile retrieved successfully"
        };
    }

    // Protected endpoint - Update user profile
    @http:ResourceConfig {
        auth: [
            {
                jwtValidatorConfig: jwtValidatorConfig
            }
        ]
    }
    resource function put auth/profile(http:Request req, json updateData) returns json|http:Unauthorized|http:BadRequest {
        jwt:Payload|http:Unauthorized jwtPayload = getJwtPayload(req);
        
        if jwtPayload is http:Unauthorized {
            return jwtPayload;
        }

        string? userId = jwtPayload.sub;
        if userId is () {
            return http:UNAUTHORIZED;
        }

        User? user = users[userId];
        if user is () {
            return http:UNAUTHORIZED;
        }

        // Update user data (basic implementation)
        if updateData.email is string {
            user.email = <string>updateData.email;
        }
        
        users[userId] = user;

        return {
            message: "Profile updated successfully",
            user: {
                id: user.id,
                username: user.username,
                email: user.email
            }
        };
    }

    // Logout endpoint (client-side token removal)
    resource function post auth/logout() returns json {
        return {
            message: "Logout successful. Please remove token from client storage."
        };
    }
}

// Helper function to extract JWT payload from request
function getJwtPayload(http:Request req) returns jwt:Payload|http:Unauthorized {
    string|http:HeaderNotFoundError authHeader = req.getHeader("Authorization");
    
    if authHeader is http:HeaderNotFoundError {
        return http:UNAUTHORIZED;
    }

    if !authHeader.startsWith("Bearer ") {
        return http:UNAUTHORIZED;
    }

    string token = authHeader.substring(7);
    jwt:Payload|jwt:Error payload = jwt:validate(token, jwtValidatorConfig);
    
    if payload is jwt:Error {
        log:printError("JWT validation failed", payload);
        return http:UNAUTHORIZED;
    }

    return payload;
}