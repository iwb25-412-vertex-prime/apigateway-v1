// Public API endpoints that accept API key authentication
import ballerina/http;
import ballerina/log;

// Middleware to validate API key from request
public function validateApiKeyFromRequest(http:Request req) returns [ApiKey, boolean]|error {
    // Try to get API key from header first
    string|http:HeaderNotFoundError apiKeyHeader = req.getHeader("X-API-Key");
    string apiKey = "";
    
    if apiKeyHeader is string {
        apiKey = apiKeyHeader;
    } else {
        // Try to get from Authorization header as Bearer token
        string|http:HeaderNotFoundError authHeader = req.getHeader("Authorization");
        if authHeader is string && authHeader.startsWith("ApiKey ") {
            apiKey = authHeader.substring(7);
        } else {
            return error("API key not provided. Use X-API-Key header or Authorization: ApiKey <key>");
        }
    }
    
    if apiKey.length() == 0 {
        return error("API key is empty");
    }
    
    // Validate API key and check quota
    [ApiKey, boolean]|error validationResult = validateApiKeyWithQuota(apiKey);
    if validationResult is error {
        return error("Invalid API key: " + validationResult.message());
    }
    
    [ApiKey, boolean] [validatedKey, quotaAvailable] = validationResult;
    
    if !quotaAvailable {
        return error("Monthly quota exceeded. Quota resets on: " + validatedKey.quota_reset_date);
    }
    
    // Increment usage count
    error? usageResult = incrementApiKeyUsage(validatedKey.id);
    if usageResult is error {
        log:printError("Failed to increment API key usage", usageResult);
    }
    
    return [validatedKey, quotaAvailable];
}

// Sample data for demonstration
type UserData record {|
    string id;
    string name;
    string email;
    string department;
    string role;
|};

type ProjectData record {|
    string id;
    string name;
    string description;
    string status;
    string created_date;
|};

// Mock data
UserData[] sampleUsers = [
    {id: "1", name: "John Doe", email: "john@company.com", department: "Engineering", role: "Developer"},
    {id: "2", name: "Jane Smith", email: "jane@company.com", department: "Marketing", role: "Manager"},
    {id: "3", name: "Bob Wilson", email: "bob@company.com", department: "Sales", role: "Representative"}
];

ProjectData[] sampleProjects = [
    {id: "1", name: "Website Redesign", description: "Modernize company website", status: "In Progress", created_date: "2024-01-15"},
    {id: "2", name: "Mobile App", description: "Customer mobile application", status: "Planning", created_date: "2024-02-01"},
    {id: "3", name: "API Integration", description: "Third-party API integration", status: "Completed", created_date: "2024-01-01"}
];