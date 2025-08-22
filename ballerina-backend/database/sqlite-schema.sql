-- User Portal SQLite Database Schema
-- SQLite version of the database schema

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT 1
);

-- JWT tokens table for token management and revocation
CREATE TABLE IF NOT EXISTS jwt_tokens (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    token_hash TEXT NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_revoked BOOLEAN DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- API Keys table for API key management
CREATE TABLE IF NOT EXISTS api_keys (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    key_hash TEXT NOT NULL,
    description TEXT,
    rules TEXT, -- JSON array stored as string
    status TEXT DEFAULT 'active',
    usage_count INTEGER DEFAULT 0,
    monthly_quota INTEGER DEFAULT 100,
    current_month_usage INTEGER DEFAULT 0,
    quota_reset_date TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_jwt_tokens_user_id ON jwt_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_jwt_tokens_token_hash ON jwt_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_jwt_tokens_expires_at ON jwt_tokens(expires_at);
CREATE INDEX IF NOT EXISTS idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_key_hash ON api_keys(key_hash);
CREATE INDEX IF NOT EXISTS idx_api_keys_status ON api_keys(status);