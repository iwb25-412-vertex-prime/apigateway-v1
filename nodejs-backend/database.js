// Database connection and operations
const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');
const config = require('./config');

// Ensure database directory exists
const dbDir = path.dirname(config.dbPath);
if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true });
}

// Initialize database connection
const db = new Database(config.dbPath);
db.pragma('foreign_keys = ON');

// Initialize database schema
function initializeDatabase() {
  console.log('Initializing database schema...');
  
  // Create users table
  db.exec(`
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
  db.exec(`
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
  
  // Create api_keys table
  db.exec(`
    CREATE TABLE IF NOT EXISTS api_keys (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      name TEXT NOT NULL,
      key_hash TEXT NOT NULL,
      description TEXT,
      rules TEXT,
      status TEXT DEFAULT 'active',
      usage_count INTEGER DEFAULT 0,
      monthly_quota INTEGER DEFAULT 100,
      current_month_usage INTEGER DEFAULT 0,
      quota_reset_date TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);
  
  // Create indexes for better performance
  db.exec(`CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)`);
  db.exec(`CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)`);
  db.exec(`CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active)`);
  db.exec(`CREATE INDEX IF NOT EXISTS idx_jwt_tokens_user_id ON jwt_tokens(user_id)`);
  db.exec(`CREATE INDEX IF NOT EXISTS idx_jwt_tokens_token_hash ON jwt_tokens(token_hash)`);
  db.exec(`CREATE INDEX IF NOT EXISTS idx_jwt_tokens_expires_at ON jwt_tokens(expires_at)`);
  db.exec(`CREATE INDEX IF NOT EXISTS idx_api_keys_user_id ON api_keys(user_id)`);
  db.exec(`CREATE INDEX IF NOT EXISTS idx_api_keys_key_hash ON api_keys(key_hash)`);
  db.exec(`CREATE INDEX IF NOT EXISTS idx_api_keys_status ON api_keys(status)`);
  
  console.log('Database schema initialized successfully!');
}

// ===== USER OPERATIONS =====

function createUser(username, email, passwordHash) {
  const { v4: uuidv4 } = require('uuid');
  const userId = uuidv4();
  
  const stmt = db.prepare(`
    INSERT INTO users (id, username, email, password_hash, is_active)
    VALUES (?, ?, ?, ?, 1)
  `);
  
  const result = stmt.run(userId, username, email, passwordHash);
  
  if (result.changes === 1) {
    return getUserById(userId);
  }
  
  throw new Error('Failed to create user');
}

function getUserByUsername(username) {
  const stmt = db.prepare(`
    SELECT id, username, email, password_hash, created_at, updated_at, is_active
    FROM users WHERE username = ? AND is_active = 1
  `);
  
  return stmt.get(username);
}

function getUserByEmail(email) {
  const stmt = db.prepare(`
    SELECT id, username, email, password_hash, created_at, updated_at, is_active
    FROM users WHERE email = ? AND is_active = 1
  `);
  
  return stmt.get(email);
}

function getUserById(userId) {
  const stmt = db.prepare(`
    SELECT id, username, email, password_hash, created_at, updated_at, is_active
    FROM users WHERE id = ? AND is_active = 1
  `);
  
  return stmt.get(userId);
}

// ===== TOKEN OPERATIONS =====

function storeJWTToken(userId, tokenHash, expiresAt) {
  const { v4: uuidv4 } = require('uuid');
  const tokenId = uuidv4();
  
  const stmt = db.prepare(`
    INSERT INTO jwt_tokens (id, user_id, token_hash, expires_at, is_revoked)
    VALUES (?, ?, ?, ?, 0)
  `);
  
  const result = stmt.run(tokenId, userId, tokenHash, expiresAt);
  
  if (result.changes === 1) {
    return tokenId;
  }
  
  throw new Error('Failed to store JWT token');
}

function isTokenValid(tokenHash) {
  const stmt = db.prepare(`
    SELECT id FROM jwt_tokens 
    WHERE token_hash = ? 
    AND is_revoked = 0 
    AND expires_at > datetime('now')
  `);
  
  const result = stmt.get(tokenHash);
  return result !== undefined;
}

function revokeToken(tokenHash) {
  const stmt = db.prepare(`
    UPDATE jwt_tokens SET is_revoked = 1
    WHERE token_hash = ?
  `);
  
  const result = stmt.run(tokenHash);
  return result.changes > 0;
}

module.exports = {
  db,
  initializeDatabase,
  createUser,
  getUserByUsername,
  getUserByEmail,
  getUserById,
  storeJWTToken,
  isTokenValid,
  revokeToken
};
