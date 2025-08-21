import ballerina/http;
import ballerina/crypto;
import ballerina/log;
import ballerina/time;

type User record {
    string id;
    string username;
    string email;
    string password;
};

type LoginRequest record {
    string username;
    string password;
};

type RegisterRequest record {
    string username;
    string email;
    string password;
};

map<User> users = {};

function addCorsHeaders(http:Response res) {
    res.setHeader("Access-Control-Allow-Origin", "http://localhost:3000");
    res.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type");
    res.setHeader("Access-Control-Allow-Credentials", "true");
}

function createToken(User user) returns string {
    return user.id + "_" + user.username;
}

function validateToken(string token) returns User|error {
    string[] parts = re`_`.split(token);
    if parts.length() != 2 {
        return error("Invalid token");
    }
    
    User? user = users[parts[0]];
    if user is () {
        return error("User not found");
    }
    
    return user;
}

service on new http:Listener(8080) {

    resource function get api/health() returns http:Response {
        http:Response res = new;
        addCorsHeaders(res);
        res.setJsonPayload({
            status: "healthy",
            timestamp: time:utcNow(),
            service: "userportal-auth"
        });
        return res;
    }

    resource function post api/auth/register(RegisterRequest req) returns http:Response {
        http:Response res = new;
        addCorsHeaders(res);

        foreach User user in users {
            if user.username == req.username || user.email == req.email {
                res.statusCode = 409;
                res.setJsonPayload({"error": "User already exists"});
                return res;
            }
        }

        string userId = crypto:hashSha256(req.username.toBytes()).toBase16();
        User newUser = {
            id: userId,
            username: req.username,
            email: req.email,
            password: req.password
        };

        users[userId] = newUser;
        log:printInfo("User registered: " + req.username);

        res.statusCode = 201;
        res.setJsonPayload({"message": "User registered successfully"});
        return res;
    }

    resource function post api/auth/login(LoginRequest req) returns http:Response {
        http:Response res = new;
        addCorsHeaders(res);

        User? foundUser = ();
        foreach User user in users {
            if user.username == req.username && user.password == req.password {
                foundUser = user;
                break;
            }
        }

        if foundUser is () {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid credentials"});
            return res;
        }

        string token = createToken(foundUser);

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

    resource function get api/auth/profile(http:Request req) returns http:Response {
        http:Response res = new;
        addCorsHeaders(res);

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
        User|error user = validateToken(token);

        if user is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid token"});
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

    resource function put api/auth/profile(http:Request req, json data) returns http:Response {
        http:Response res = new;
        addCorsHeaders(res);

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
        User|error user = validateToken(token);

        if user is error {
            res.statusCode = 401;
            res.setJsonPayload({"error": "Invalid token"});
            return res;
        }

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

    resource function post api/auth/logout() returns http:Response {
        http:Response res = new;
        addCorsHeaders(res);
        res.setJsonPayload({"message": "Logout successful"});
        return res;
    }

    resource function options [string... path]() returns http:Response {
        http:Response res = new;
        addCorsHeaders(res);
        res.statusCode = 200;
        return res;
    }
}