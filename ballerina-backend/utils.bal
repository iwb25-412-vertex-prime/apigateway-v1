// Utility functions for validation and common operations
import ballerina/uuid;
import ballerina/regex;

// Utility functions
public function generateUserId() returns string {
    return uuid:createType1AsString();
}

public function isValidEmail(string email) returns boolean {
    string emailPattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$";
    return regex:matches(email, emailPattern);
}

public function isValidPassword(string password) returns boolean {
    return password.length() >= 8;
}