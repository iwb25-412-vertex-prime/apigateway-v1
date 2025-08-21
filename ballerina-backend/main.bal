import ballerina/http;
import ballerina/crypto;
import ballerina/log;

type User record {
    string id;
    string username;
    string email;
    string password;
};

map<User> users = {};



@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3001"],
        allowCredentials: true,
        allowHeaders: ["Authorization", "Content-Type"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /api on new http:Listener(8080) {

    resource function get health() returns json {
        return {"status": "healthy", "service": "userportal-auth"};
    }

    resource function post auth/register(@http:Payload json payload) returns http:Response {
        http:Response res = new;
        
        json|error usernameField = payload.username;
        json|error emailField = payload.email;
        json|error passwordField = payload.password;

        if usernameField is error || emailField is error || passwordField is error {
            res.statusCode = 400;
            res.setJsonPayload({"error": "Missing required fields"});
            return res;
        }

        string username = usernameField.toString();
        string email = emailField.toString();
        string password = passwordField.toString();

        // Check if user exists
        foreach User user in users {
            if user.username == username || user.email == email {
                res.statusCode = 409;
                res.setJsonPayload({"error": "User already exists"});
                return res;
            }
        }

        // Create user
        string userId = crypto:hashSha256(username.toBytes()).toBase16();
        User newUser = {
            id: userId,
            username: username,
            email: email,
            password: password
        };

        users[userId] = newUser;
        log:printInfo("User registered: " + username);

        res.statusCode = 201;
        res.setJsonPayload({"message": "User registered successfully"});
        return res;
    }

    resource function post auth/login(@http:Payload json payload) returns http:Response {
        http:Response res = new;
        
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
        User? foundUser = ();
        foreach User user in users {
            if user.username == username && user.password == password {
                foundUser = user;
                break;
            }
        }

        if foundUser is () {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid credentials"});
            return res;
        }

        // Create simple token
        string token = foundUser.id + "_" + foundUser.username;

        res.setJsonPayload({
            "token": token,
            "message": "Login successful",
            "user": {
                "id": foundUser.id,
                "username": foundUser.username,
                "email": foundUser.email
            }
        });
        return res;
    }

    resource function get auth/profile(http:Request req) returns http:Response {
        http:Response res = new;
        
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
        string[] parts = re`_`.split(token);
        
        if parts.length() != 2 {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid token"});
            return res;
        }

        User? user = users[parts[0]];
        if user is () {
            res.statusCode = 401;
            res.setJsonPayload({"error": "User not found"});
            return res;
        }

        res.setJsonPayload({
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "message": "Profile retrieved successfully"
        });
        return res;
    }

    resource function put auth/profile(http:Request req, @http:Payload json data) returns http:Response {
        http:Response res = new;
        
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
        string[] parts = re`_`.split(token);
        
        if parts.length() != 2 {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid token"});
            return res;
        }

        User? user = users[parts[0]];
        if user is () {
            res.statusCode = 401;
            res.setJsonPayload({"error": "User not found"});
            return res;
        }

        // Update email if provided
        json|error emailField = data.email;
        if emailField is string {
            user.email = emailField;
            users[user.id] = user;
        }

        res.setJsonPayload({
            "message": "Profile updated successfully",
            "user": {
                "id": user.id,
                "username": user.username,
                "email": user.email
            }
        });
        return res;
    }

    resource function post auth/logout() returns json {
        return {"message": "Logout successful"};
    }
}