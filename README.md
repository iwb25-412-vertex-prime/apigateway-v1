# User Portal with Secure Authentication

A full-stack application with secure authentication using Ballerina backend, SQLite database, and Next.js frontend. Features password hashing, JWT-like tokens, database storage, and token revocation.

## Project Structure

```
├── ballerina-backend/          # Ballerina JWT authentication service
│   ├── main.bal               # Main service implementation
│   ├── Ballerina.toml         # Ballerina project configuration
│   ├── Config.toml            # Service configuration
│   ├── resources/             # Keystore and resources
│   └── README.md              # Backend documentation
├── userportal/                # Next.js frontend application
│   ├── app/                   # Next.js app directory
│   ├── components/            # React components
│   ├── hooks/                 # Custom React hooks
│   ├── lib/                   # Utility libraries
│   └── package.json           # Frontend dependencies
├── start-services.bat         # Windows startup script
├── start-services.sh          # Unix startup script
└── README.md                  # This file
```

## What's Implemented

This project includes a complete authentication and API key management system with the following components:

### ✅ Core Features Implemented

- **User Registration & Login System** - Complete user account management
- **JWT-like Token Authentication** - Secure token-based authentication
- **Password Security** - SHA256 hashing with salt for password protection
- **SQLite Database Integration** - Automatic database creation and management
- **API Key Management System** - Create, manage, and validate API keys (max 3 per user)
- **Token Revocation** - Secure logout with immediate token invalidation
- **Database Tables Auto-Creation** - Three tables created automatically:
  - `users` - User account information
  - `jwt_tokens` - Token tracking and revocation
  - `api_keys` - API key management with usage tracking

### ✅ Security Features

- **Secure Password Storage** - Never store plain text passwords
- **Token Signing & Validation** - Cryptographic token security
- **Database Token Tracking** - All tokens tracked for security auditing
- **API Key Limits** - Maximum 3 API keys per user
- **Input Validation** - Email format and password strength validation
- **CORS Protection** - Configured for frontend integration

### ✅ Frontend Components

- **React Authentication UI** - Login, register, and profile components
- **Auth Context Provider** - Global authentication state management
- **TypeScript Support** - Full type safety throughout
- **Tailwind CSS Styling** - Modern, responsive design
- **Token Expiry Handling** - Automatic cleanup and re-authentication

### ✅ Development Tools

- **Startup Scripts** - Easy service startup for Windows and Unix
- **Database Viewer Script** - Quick database inspection tools
- **API Testing Scripts** - Automated testing for API key functionality
- **Comprehensive Documentation** - Complete setup and usage guides

## How Authentication Works

### 🔐 Authentication Flow

The application implements a secure JWT-like authentication system with database token tracking:

1. **User Registration**:

   - User provides username, email, and password via `/api/auth/register`
   - Password is hashed using SHA256 with salt for security
   - User data stored in SQLite `users` table with UUID as primary key
   - Returns success message with user info (password excluded for security)

2. **User Login**:

   - User provides credentials via `/api/auth/login`
   - System verifies password against stored hash using salt comparison
   - Generates secure token containing user data and expiry timestamp
   - Token hash stored in `jwt_tokens` table for tracking and revocation
   - Returns token and user info to client for session management

3. **Protected Requests**:

   - Client includes token in `Authorization: Bearer <token>` header
   - Server validates token signature using secret key
   - Checks token expiry and database revocation status
   - Extracts user info from token payload for request processing
   - Rejects requests with invalid, expired, or revoked tokens

4. **Token Validation Process**:

   - Parse token into data and signature components
   - Verify signature matches expected hash of data + secret
   - Check expiry timestamp against current time
   - Query database to ensure token hasn't been revoked
   - Extract user information for authorized operations

5. **Logout & Token Revocation**:
   - Client sends logout request with current token
   - Server marks token as revoked in `jwt_tokens` table
   - Token becomes immediately invalid for all future requests
   - User must login again to obtain new valid token

### 🛡️ Security Features

- **Password Hashing**: SHA256 with salt (passwords never stored in plain text)
- **Token Signing**: Cryptographic signatures prevent token tampering
- **Token Expiry**: Tokens expire after 1 hour (configurable)
- **Token Revocation**: Logout immediately invalidates tokens
- **Database Tracking**: All tokens tracked for security auditing
- **Input Validation**: Email format and password strength validation
- **CORS Protection**: Configured for specific origins only

## � APIa Key Management System

The application includes a comprehensive API key management system that allows users to create, manage, and use API keys for programmatic access.

### Key Features

- **Limited Keys**: Each user can create up to 3 API keys maximum
- **Named Keys**: Each API key has a descriptive name for easy identification
- **Usage Tracking**: Track how many times each API key has been used
- **Rules System**: Define custom rules/permissions for each API key
- **Status Management**: Enable/disable API keys without deletion
- **Secure Generation**: Cryptographically secure API key generation with `ak_` prefix
- **Revocation**: Permanently revoke API keys when no longer needed

### API Key Structure

API keys follow the format: `ak_[32-character-hash]`

Example: `ak_a1b2c3d4e5f6789012345678901234567890abcd`

### API Key Properties

Each API key contains:

- **ID**: Unique identifier for the key
- **Name**: User-defined descriptive name (1-100 characters)
- **Description**: Optional detailed description
- **Rules**: Array of permission strings (e.g., ["read", "write", "analytics"])
- **Status**: "active", "inactive", or "revoked"
- **Usage Count**: Number of times the key has been used
- **Created/Updated**: Timestamps for audit trail

### API Key Endpoints

#### Create API Key

```bash
POST /api/apikeys
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "name": "Development Key",
  "description": "For development testing",
  "rules": ["read", "write"]
}
```

#### List User's API Keys

```bash
GET /api/apikeys
Authorization: Bearer <jwt_token>
```

#### Update API Key Status

```bash
PUT /api/apikeys/{keyId}/status
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "status": "inactive"  // or "active"
}
```

#### Delete API Key

```bash
DELETE /api/apikeys/{keyId}
Authorization: Bearer <jwt_token>
```

#### Validate API Key

```bash
POST /api/apikeys/validate
Content-Type: application/json

{
  "apiKey": "ak_your_api_key_here"
}
```

### Usage Examples

1. **Create a development API key:**

   ```bash
   curl -X POST http://localhost:8080/api/apikeys \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     -d '{
       "name": "Dev Environment",
       "description": "For local development",
       "rules": ["read", "write", "test"]
     }'
   ```

2. **List all your API keys:**

   ```bash
   curl -X GET http://localhost:8080/api/apikeys \
     -H "Authorization: Bearer YOUR_JWT_TOKEN"
   ```

3. **Disable an API key:**

   ```bash
   curl -X PUT http://localhost:8080/api/apikeys/KEY_ID/status \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     -d '{"status": "inactive"}'
   ```

4. **Test API key validity:**
   ```bash
   curl -X POST http://localhost:8080/api/apikeys/validate \
     -H "Content-Type: application/json" \
     -d '{"apiKey": "ak_a1b2c3d4e5f6789012345678901234567890abcd"}'
   ```

### Testing API Keys

Use the provided test scripts to test the API key functionality:

**Windows:**

```bash
test-apikeys.bat
```

**Unix/Linux/macOS:**

```bash
chmod +x test-apikeys.sh
./test-apikeys.sh
```

These scripts will:

1. Register a test user
2. Login to get a JWT token
3. Create 3 API keys (maximum allowed)
4. Try to create a 4th key (should fail)
5. List all API keys
6. Test API key validation

### 🗄️ Database Schema

The application uses SQLite database with three main tables for user management, token tracking, and API key management:

#### Users Table

Stores user account information with secure password hashing:

```sql
CREATE TABLE users (
    id TEXT PRIMARY KEY,              -- UUID for user identification
    username TEXT UNIQUE NOT NULL,    -- 3-50 characters, unique constraint
    email TEXT UNIQUE NOT NULL,       -- Validated email format, unique constraint
    password_hash TEXT NOT NULL,      -- SHA256 hashed password with salt
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,  -- Account creation time
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,  -- Last profile update
    is_active BOOLEAN DEFAULT 1       -- Account status (1=active, 0=disabled)
);
```

**Key Features:**

- UUID primary keys for security and scalability
- Unique constraints on username and email prevent duplicates
- Password never stored in plain text (SHA256 + salt)
- Timestamps for audit trail and account management
- Active status for account suspension without deletion

#### JWT Tokens Table

Tracks all issued tokens for security and revocation:

```sql
CREATE TABLE jwt_tokens (
    id TEXT PRIMARY KEY,              -- UUID for token record
    user_id TEXT NOT NULL,            -- Foreign key to users.id
    token_hash TEXT NOT NULL,         -- SHA256 hash of full token
    expires_at DATETIME NOT NULL,     -- Token expiration timestamp
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,  -- Token issue time
    is_revoked BOOLEAN DEFAULT 0,     -- Revocation status (0=active, 1=revoked)
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

**Key Features:**

- Foreign key relationship ensures data integrity
- Token hash stored (not full token) for security
- Expiration tracking for automatic cleanup
- Revocation flag for immediate token invalidation
- Cascade delete removes tokens when user is deleted

#### API Keys Table

Manages user API keys for programmatic access:

```sql
CREATE TABLE api_keys (
    id TEXT PRIMARY KEY,              -- UUID for API key record
    user_id TEXT NOT NULL,            -- Foreign key to users.id
    name TEXT NOT NULL,               -- User-defined name for the key
    key_hash TEXT NOT NULL,           -- SHA256 hash of the API key
    description TEXT,                 -- Optional description
    rules TEXT,                       -- JSON array of permission rules
    status TEXT DEFAULT 'active',     -- Status: active, inactive, revoked
    usage_count INTEGER DEFAULT 0,    -- Number of times key has been used
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,  -- Key creation time
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,  -- Last modification time
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

**Key Features:**

- Foreign key relationship ensures data integrity
- API key hash stored (not plain key) for security
- JSON rules array for flexible permission system
- Usage tracking for monitoring and analytics
- Status management for key lifecycle
- Cascade delete removes keys when user is deleted

#### Database Indexes

Automatic indexes are created for optimal query performance:

```sql
-- Automatic indexes on PRIMARY KEY and UNIQUE constraints
-- Additional indexes for common queries:
CREATE INDEX idx_jwt_tokens_user_id ON jwt_tokens(user_id);
CREATE INDEX idx_jwt_tokens_expires_at ON jwt_tokens(expires_at);
CREATE INDEX idx_jwt_tokens_is_revoked ON jwt_tokens(is_revoked);
CREATE INDEX idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX idx_api_keys_status ON api_keys(status);
CREATE INDEX idx_api_keys_key_hash ON api_keys(key_hash);
```

### 🔍 Token Structure

Tokens use a simple but secure format:

```
<user_data>|<signature>
```

Where:

- `user_data`: `userId|username|email|expiry_timestamp`
- `signature`: SHA256 hash of (user_data + secret_key)

Example token parts:

- Data: `123e4567-e89b-12d3-a456-426614174000|john|john@example.com|1640995200`
- Signature: `a1b2c3d4e5f6...` (SHA256 hash)

## Features

### Backend (Ballerina)

- **Secure Authentication**: Custom JWT-like tokens with cryptographic signing
- **Password Security**: SHA256 password hashing with salt
- **SQLite Database**: Lightweight, file-based database for development
- **Token Management**: Database tracking of all issued tokens
- **Token Revocation**: Immediate token invalidation on logout
- **API Key Management**: Create, manage, and validate API keys (up to 3 per user)
- **Input Validation**: Email format and password strength validation
- **Protected Endpoints**: Token validation for secure routes
- **CORS Support**: Configured for frontend integration
- **Auto-initialization**: Database schema created automatically

### Frontend (Next.js)

- **React Authentication**: Components for login/register/profile
- **Auth Context**: Global authentication state management
- **Token Expiry Handling**: Automatic token expiration detection
- **TypeScript Support**: Full type safety
- **Tailwind CSS**: Modern styling
- **Secure Storage**: Token expiry tracking and cleanup

## Prerequisites

- **Ballerina**: Swan Lake (2201.10.0 or later)
- **Node.js**: 18.x or later
- **Java**: 11 or later (for Ballerina)
- **SQLite**: Included with Ballerina (no separate installation needed)

## Quick Start

### Step 1: Start Services (Database auto-creates)

**Option 1: Use Startup Scripts**

**Windows:**

```bash
start-services.bat
```

**Unix/Linux/macOS:**

```bash
./start-services.sh
```

**Option 2: Manual Setup**

1. **Start the Ballerina backend:**

   ```bash
   cd ballerina-backend
   bal run
   ```

2. **Start the Next.js frontend:**

   ```bash
   cd userportal
   npm install
   npm run dev
   ```

3. **Access the application:**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8080
   - Auth page: http://localhost:3000/auth

## API Endpoints

### Public Endpoints

- `GET /api/health` - Health check
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `POST /api/apikeys/validate` - Validate API key

### Protected Endpoints (Require JWT Token)

- `GET /api/auth/profile` - Get user profile
- `PUT /api/auth/profile` - Update user profile
- `POST /api/apikeys` - Create new API key
- `GET /api/apikeys` - List user's API keys
- `PUT /api/apikeys/{keyId}/status` - Update API key status
- `DELETE /api/apikeys/{keyId}` - Delete (revoke) API key

## Usage Examples

### 1. Register a new user

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }'
```

### 2. Login

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'
```

### 3. Access protected endpoint

```bash
curl -X GET http://localhost:8080/api/auth/profile \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 4. Create API key

```bash
curl -X POST http://localhost:8080/api/apikeys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "name": "Development Key",
    "description": "For development testing",
    "rules": ["read", "write"]
  }'
```

### 5. List API keys

```bash
curl -X GET http://localhost:8080/api/apikeys \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 6. Validate API key

```bash
curl -X POST http://localhost:8080/api/apikeys/validate \
  -H "Content-Type: application/json" \
  -d '{
    "apiKey": "ak_your_api_key_here"
  }'
```

## Frontend Components

### AuthProvider

Provides authentication context throughout the app.

### useAuth Hook

Custom hook for managing authentication state:

```typescript
const { user, login, logout, register, isAuthenticated } = useAuth();
```

### Components

- `LoginForm` - User login interface
- `RegisterForm` - User registration interface
- `UserProfile` - User profile management

## Configuration

### Backend Configuration (Config.toml)

```toml
[userportal.auth_service]
jwtSecret = "your-super-secret-jwt-key"
jwtExpiryTime = 3600
port = 8080
```

## 🔍 Viewing and Managing the Database

The SQLite database is located at `ballerina-backend/database/userportal.db` and contains three main tables that were automatically created when the backend started:

### Database Tables Created

The application automatically creates the following tables:

1. **`users`** - Stores user account information
2. **`jwt_tokens`** - Tracks issued JWT tokens for security
3. **`api_keys`** - Manages user API keys for programmatic access

### Quick Database Access

**Windows (PowerShell):**

```powershell
.\view-database.bat
```

**Or directly with SQLite3:**

```powershell
sqlite3 "ballerina-backend\database\userportal.db" ".tables"
```

**View table contents:**

```powershell
sqlite3 "ballerina-backend\database\userportal.db" "SELECT * FROM users;"
sqlite3 "ballerina-backend\database\userportal.db" "SELECT * FROM jwt_tokens;"
sqlite3 "ballerina-backend\database\userportal.db" "SELECT * FROM api_keys;"
```

### Method 1: SQLite Command Line Interface

**Windows:**

```cmd
cd ballerina-backend\database
sqlite3 userportal.db
```

**Unix/Linux/macOS:**

```bash
cd ballerina-backend/database
sqlite3 userportal.db
```

**Essential SQLite Commands:**

```sql
.help                      -- Show all available commands
.tables                    -- List all tables in database
.schema                    -- Show complete database schema
.schema users              -- Show users table structure only
.schema jwt_tokens         -- Show tokens table structure only
.headers on                -- Show column headers in results
.mode column               -- Format output in columns
.width 10 20 30            -- Set column widths for better display
SELECT * FROM users;       -- View all user records
SELECT * FROM jwt_tokens;  -- View all token records
.quit                      -- Exit SQLite
```

### Method 2: DB Browser for SQLite (Recommended GUI)

1. **Download and Install:**

   - Visit https://sqlitebrowser.org/
   - Download for your operating system
   - Install following standard procedures

2. **Open Database:**

   - Launch DB Browser for SQLite
   - Click "Open Database" button
   - Navigate to `ballerina-backend/database/userportal.db`
   - Browse tables, run queries, and modify data visually

3. **Features:**
   - Visual table browsing with sorting and filtering
   - SQL query editor with syntax highlighting
   - Database structure visualization
   - Export data to various formats (CSV, JSON, etc.)

### Method 3: VS Code SQLite Extension

1. **Install Extension:**

   - Open VS Code Extensions panel (Ctrl+Shift+X)
   - Search for "SQLite Viewer" or "SQLite"
   - Install a popular SQLite extension

2. **Open Database:**
   - In VS Code Explorer, navigate to `ballerina-backend/database/`
   - Right-click on `userportal.db`
   - Select "Open Database" or similar option
   - Browse tables and run queries within VS Code

### Method 4: Quick View Script

**Windows:**

```cmd
.\view-database.bat
```

This script will:

- Show database file location and size
- Display basic database information
- Open SQLite CLI if available on system
- Provide helpful commands for database exploration

### Method 5: Online SQLite Viewers

For quick inspection without installing software:

1. Visit online SQLite viewers (search "online sqlite viewer")
2. Upload your `userportal.db` file
3. Browse tables and run queries in browser
4. **Note:** Only use trusted sites and avoid uploading sensitive production data

### Essential Database Queries

#### User Management Queries

```sql
-- View all users (excluding sensitive password hash)
SELECT id, username, email, created_at, updated_at, is_active
FROM users
ORDER BY created_at DESC;

-- Count total registered users
SELECT COUNT(*) as total_users FROM users;

-- Find users by email domain
SELECT username, email, created_at
FROM users
WHERE email LIKE '%@gmail.com';

-- Check for inactive users
SELECT username, email, created_at
FROM users
WHERE is_active = 0;
```

#### Token Management Queries

```sql
-- View active tokens with user information
SELECT
    u.username,
    u.email,
    jt.created_at as token_issued,
    jt.expires_at as token_expires,
    jt.is_revoked
FROM jwt_tokens jt
JOIN users u ON jt.user_id = u.id
WHERE jt.is_revoked = 0
ORDER BY jt.created_at DESC;

-- Count active vs revoked tokens
SELECT
    is_revoked,
    COUNT(*) as token_count
FROM jwt_tokens
GROUP BY is_revoked;

-- Find expired tokens that should be cleaned up
SELECT COUNT(*) as expired_tokens
FROM jwt_tokens
WHERE expires_at < datetime('now') AND is_revoked = 0;

-- View token activity for specific user
SELECT
    jt.created_at as issued,
    jt.expires_at as expires,
    jt.is_revoked as revoked
FROM jwt_tokens jt
JOIN users u ON jt.user_id = u.id
WHERE u.username = 'your_username'
ORDER BY jt.created_at DESC;
```

#### System Analytics Queries

```sql
-- Database overview statistics
SELECT
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM jwt_tokens) as total_tokens,
    (SELECT COUNT(*) FROM jwt_tokens WHERE is_revoked = 0) as active_tokens,
    (SELECT COUNT(*) FROM jwt_tokens WHERE expires_at < datetime('now')) as expired_tokens;

-- User registration trends (by day)
SELECT
    DATE(created_at) as registration_date,
    COUNT(*) as new_users
FROM users
GROUP BY DATE(created_at)
ORDER BY registration_date DESC
LIMIT 10;

-- Token usage patterns
SELECT
    DATE(created_at) as date,
    COUNT(*) as tokens_issued
FROM jwt_tokens
GROUP BY DATE(created_at)
ORDER BY date DESC
LIMIT 10;
```

#### API Key Management Queries

```sql
-- View all API keys with user information
SELECT
    u.username,
    u.email,
    ak.name as key_name,
    ak.description,
    ak.status,
    ak.usage_count,
    ak.created_at,
    ak.updated_at
FROM api_keys ak
JOIN users u ON ak.user_id = u.id
WHERE ak.status != 'revoked'
ORDER BY ak.created_at DESC;

-- Count API keys by status
SELECT
    status,
    COUNT(*) as key_count
FROM api_keys
GROUP BY status;

-- Find users with maximum API keys (3)
SELECT
    u.username,
    u.email,
    COUNT(ak.id) as key_count
FROM users u
JOIN api_keys ak ON u.id = ak.user_id
WHERE ak.status != 'revoked'
GROUP BY u.id, u.username, u.email
HAVING COUNT(ak.id) >= 3;

-- API key usage statistics
SELECT
    ak.name,
    ak.usage_count,
    ak.status,
    u.username
FROM api_keys ak
JOIN users u ON ak.user_id = u.id
ORDER BY ak.usage_count DESC;

-- Find inactive API keys that could be cleaned up
SELECT
    u.username,
    ak.name,
    ak.status,
    ak.updated_at
FROM api_keys ak
JOIN users u ON ak.user_id = u.id
WHERE ak.status = 'inactive'
AND ak.updated_at < datetime('now', '-30 days');
```

#### Database Maintenance Queries

```sql
-- Clean up expired tokens (DELETE operation)
DELETE FROM jwt_tokens
WHERE expires_at < datetime('now') AND is_revoked = 1;

-- Revoke all tokens for a specific user
UPDATE jwt_tokens
SET is_revoked = 1
WHERE user_id = (SELECT id FROM users WHERE username = 'username_to_revoke');

-- Revoke all API keys for a specific user
UPDATE api_keys
SET status = 'revoked', updated_at = CURRENT_TIMESTAMP
WHERE user_id = (SELECT id FROM users WHERE username = 'username_to_revoke');

-- Clean up old revoked API keys (optional)
DELETE FROM api_keys
WHERE status = 'revoked'
AND updated_at < datetime('now', '-90 days');

-- Check database integrity
PRAGMA integrity_check;

-- View database file size and page info
PRAGMA page_count;
PRAGMA page_size;
```

### Database Backup and Restore

#### Create Backup

```bash
# Create backup copy
cp ballerina-backend/database/userportal.db userportal_backup_$(date +%Y%m%d).db

# Or using SQLite dump
sqlite3 ballerina-backend/database/userportal.db .dump > userportal_backup.sql
```

#### Restore from Backup

```bash
# Restore from file copy
cp userportal_backup_20240101.db ballerina-backend/database/userportal.db

# Or restore from SQL dump
sqlite3 ballerina-backend/database/userportal.db < userportal_backup.sql
```

### Database Security Notes

- Database file contains sensitive user information
- Password hashes are stored but still should be protected
- Token hashes could potentially be used maliciously if exposed
- Always backup before making structural changes
- Consider encrypting database file in production environments
- Limit file system access to database directory

### Frontend Configuration (.env.local)

```env
NEXT_PUBLIC_API_URL=http://localhost:8080/api
```

## Security Features

### ✅ Implemented Security Measures

- **Real JWT Tokens**: RSA-based JWT signing with proper validation
- **Password Hashing**: BCrypt hashing for secure password storage
- **Database Storage**: User data and tokens stored in MySQL database
- **Token Revocation**: Logout revokes tokens in database
- **Token Expiration**: Automatic token expiry handling (1 hour default)
- **Input Validation**: Email format and password strength validation
- **CORS Protection**: Configured for specific origins
- **Protected Routes**: JWT validation middleware
- **Token Cleanup**: Automatic cleanup of expired/revoked tokens

### 🔒 Security Best Practices

- Passwords never stored in plain text
- JWT tokens are cryptographically signed
- Tokens tracked in database for revocation
- Automatic token expiry prevents long-term exposure
- Input sanitization and validation
- Secure error handling without information leakage

## Development

### Backend Development

```bash
cd ballerina-backend
bal run --observability-included
```

### Frontend Development

```bash
cd userportal
npm run dev
```

### Testing the API

Use the provided curl examples or tools like Postman to test the API endpoints.

## Production Considerations

### ✅ Already Implemented

- ✅ Real JWT tokens with RSA signing
- ✅ BCrypt password hashing
- ✅ MySQL database with proper schema
- ✅ Input validation and sanitization
- ✅ Token revocation and cleanup
- ✅ Secure error handling

### 🚀 Additional Production Requirements

1. **Security Enhancements:**

   - Use HTTPS/TLS certificates
   - Implement rate limiting for login attempts
   - Add CSRF protection
   - Set up Web Application Firewall (WAF)
   - Enable database SSL connections

2. **Configuration:**

   - Use environment variables for sensitive config
   - Change default JWT secret key
   - Set up proper database user with limited privileges
   - Configure secure session management

3. **Monitoring & Logging:**

   - Add structured logging
   - Implement health checks and metrics
   - Set up error tracking (e.g., Sentry)
   - Monitor database performance

4. **Infrastructure:**

   - Set up proper CI/CD pipeline
   - Configure load balancing
   - Implement database backups
   - Set up monitoring and alerting

5. **Performance:**
   - Add database connection pooling (already configured)
   - Implement caching for frequently accessed data
   - Optimize database queries with indexes (already added)

## Troubleshooting

### Common Issues

1. **Backend won't start:**

   - Check if Java 11+ is installed
   - Verify Ballerina installation
   - Check if port 8080 is available

2. **Frontend can't connect to backend:**

   - Verify backend is running on port 8080
   - Check CORS configuration
   - Verify API URL in .env.local

3. **JWT token issues:**
   - Check keystore generation
   - Verify JWT secret configuration
   - Check token expiration

### Logs

- Backend logs appear in the terminal where `bal run` is executed
- Frontend logs appear in browser console and terminal

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is for educational purposes. Modify and use as needed for your projects.
