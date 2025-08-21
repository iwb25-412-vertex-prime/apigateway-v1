import ballerina/sql;
import ballerinax/java.jdbc;
import ballerina/log;
import ballerina/file;

// Initialize database with schema
public function initializeDatabase(jdbc:Client dbClient) returns error? {
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
    
    // Create indexes
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)`);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)`);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active)`);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_jwt_tokens_user_id ON jwt_tokens(user_id)`);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_jwt_tokens_token_hash ON jwt_tokens(token_hash)`);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_jwt_tokens_expires_at ON jwt_tokens(expires_at)`);
    
    log:printInfo("Database schema initialized successfully!");
}