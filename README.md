# User Portal - API Gateway

A comprehensive full-stack application featuring secure user authentication and API key management system. Built with **Next.js frontend** and **Node.js/Express backend** with SQLite database. Includes password hashing, JWT-like tokens, database storage, token revocation, and complete API key lifecycle management with quota tracking.

## 🚀 Quick Start

### Prerequisites

- **Node.js** (14.0 or later) - [Download here](https://nodejs.org/)

### 1. Start the Backend (Node.js)

**First time setup:**
```bash
setup-nodejs.bat
```

**Start the server:**
```bash
start-nodejs-backend.bat
```

Or manually:
```bash
cd nodejs-backend
npm install
npm start
```

✅ Backend runs on http://localhost:8080

### 2. Start the Frontend (Next.js)

```bash
cd userportal
npm install
npm run dev
```

✅ Frontend runs on http://localhost:3000

### 3. Access the Application

- **Frontend UI**: http://localhost:3000
- **Backend API**: http://localhost:8080/api/health
- **API Documentation**: http://localhost:8080/api/docs

## 📋 Current Status

✅ **WORKING** - Node.js backend fully operational  
✅ **RUNNING** - Backend service successfully started  
✅ **DATABASE** - SQLite schema initialized  
✅ **QUOTA SYSTEM** - Monthly limits and tracking active  
✅ **FRONTEND** - Next.js UI with full functionality  
✅ **SCRIPTS** - Windows batch scripts for easy setup  
✅ **TESTED** - All endpoints verified and working

## 📁 Project Structure

```
├── nodejs-backend/            # Node.js/Express authentication & API service
│   ├── server.js              # 🌐 Main Express server & routing
│   ├── config.js              # ⚙️ Configuration management
│   ├── database.js            # 🗄️ SQLite database operations & schema
│   ├── auth.js                # 🔐 Authentication utilities
│   ├── apikeys.js             # 🔑 API key management & validation
│   ├── quota.js               # 📊 Usage quota tracking & limits
│   ├── middleware.js          # 🛡️ Authentication middleware
│   ├── routes/                # 📡 API route handlers
│   │   ├── auth.routes.js     # Authentication endpoints
│   │   ├── apikeys.routes.js  # API key management endpoints
│   │   └── public.routes.js   # Public API endpoints
│   ├── database/              # 💾 SQLite database files
│   │   └── userportal.db      # Main database (auto-created)
│   ├── package.json           # 📦 Node.js dependencies
│   ├── .env                   # 🔐 Environment variables
│   └── README.md              # 📖 Backend-specific documentation
├── userportal/                # Next.js frontend application
│   ├── app/                   # 🎨 Next.js app router pages
│   ├── components/            # ⚛️ React UI components
│   ├── hooks/                 # 🪝 Custom React hooks
│   ├── lib/                   # 📚 Utility libraries & helpers
│   ├── public/                # 🌍 Static assets
│   └── package.json           # 📦 Frontend dependencies
├── start-nodejs-backend.bat   # 🪟 Windows startup script
├── setup-nodejs.bat           # 🛠️ Node.js dependencies setup
├── setup-sqlite.bat           # 🛠️ SQLite database setup
├── view-database.bat          # 🔍 Database viewer script
└── README.md                  # 📖 Main project documentation
```

## What's Implemented

This project includes a complete authentication and API key management system with comprehensive quota management and usage tracking.

### 🎯 Backend Technology

**Node.js/Express Backend**
- Located in `nodejs-backend/` directory  
- Uses Express.js framework
- JavaScript-based with modern async/await patterns
- RESTful API design
- Start with: `npm start` or `start-nodejs-backend.bat`

### ✅ Core Features Implemented

- **User Registration & Login System** - Complete user account management with validation
- **JWT-like Token Authentication** - Secure token-based authentication with database tracking
- **Password Security** - bcrypt hashing for secure password protection
- **SQLite Database Integration** - Automatic database creation and management with proper indexing
- **API Key Management System** - Create, manage, and validate API keys (max 3 per user)
- **Dynamic Rule Management** - Update content policy rules for API keys after creation
- **Quota Management System** - Monthly usage limits (100 requests/month per key) with automatic reset
- **Usage Tracking** - Real-time tracking of API key usage with detailed analytics
- **Token Revocation** - Secure logout with immediate token invalidation
- **Modular Architecture** - Clean, organized Node.js/Express codebase with separated concerns:
  - `server.js` - Main Express server and routing
  - `auth.js` - Authentication utilities and token management
  - `database.js` - SQLite database operations
  - `apikeys.js` - API key management functions
  - `quota.js` - Quota tracking and reset logic
  - `middleware.js` - Authentication middleware
  - `routes/` - Organized API route handlers
- **Database Tables Auto-Creation** - Three tables created automatically on first run:
  - `users` - User account information with security features
  - `jwt_tokens` - Token tracking and revocation for security
  - `api_keys` - API key management with usage tracking and quota management
- **Express.js Framework** - Industry-standard web framework for Node.js
- **RESTful API Design** - Clean, predictable API endpoints
- **Environment Configuration** - Flexible configuration via .env file

### ✅ Security Features

- **Secure Password Storage** - Never store plain text passwords (bcrypt hashing)
- **Token Signing & Validation** - Cryptographic token security with database verification
- **Database Token Tracking** - All tokens tracked for security auditing and revocation
- **API Key Security** - Keys hashed in database, never stored in plain text
- **API Key Limits** - Maximum 3 API keys per user to prevent abuse
- **Quota Enforcement** - Monthly usage limits prevent API abuse
- **Input Validation** - Email format and password strength validation
- **CORS Protection** - Configured for frontend integration
- **Secure Key Generation** - Cryptographically secure API key generation

### ✅ Frontend Components

- **React Authentication UI** - Login, register, and profile components
- **API Key Management UI** - Complete interface for creating and managing API keys
- **Quota Monitoring Dashboard** - Real-time usage tracking and quota warnings
- **Auth Context Provider** - Global authentication state management
- **TypeScript Support** - Full type safety throughout
- **Tailwind CSS Styling** - Modern, responsive design with professional UI
- **Token Expiry Handling** - Automatic cleanup and re-authentication
- **Real-time Updates** - Live quota updates and usage statistics

### ✅ Development Tools

- **Startup Scripts** - Easy service startup for Windows
- **Database Viewer Script** - Quick database inspection tools
- **API Testing Scripts** - Automated testing for API key functionality
- **Comprehensive Documentation** - Complete setup and usage guides

## How Authentication Works

### 🔐 Authentication Flow

The application implements a secure JWT-like authentication system with database token tracking:

1. **User Registration**:
   - User provides username, email, and password via `/api/auth/register`
   - Password is hashed using bcrypt for security
   - User data stored in SQLite `users` table with UUID as primary key
   - Returns success message with user info (password excluded for security)

2. **User Login**:
   - User provides username and password via `/api/auth/login`
   - Backend verifies username exists in database
   - Password is compared against stored bcrypt hash
   - If valid, a JWT-like token is generated containing user ID, username, email, and expiry time
   - Token is signed with secret key (HMAC-SHA256)
   - Token hash is stored in `jwt_tokens` table for tracking and revocation
   - Returns token to client along with expiry information

3. **Authenticated Requests**:
   - Client includes token in `Authorization: Bearer <token>` header
   - Backend validates token signature and checks expiry time
   - Backend verifies token exists in database and is not revoked
   - If valid, request proceeds; otherwise returns 401 Unauthorized

4. **Logout**:
   - Client sends logout request with token via `/api/auth/logout`
   - Backend marks token as revoked in `jwt_tokens` table
   - Client discards token
   - Token immediately becomes invalid for all future requests
   - Security: Revoked tokens cannot be reused even if stolen

### 🔑 API Key Management Flow

The application includes a complete API key lifecycle management system with usage quotas:

1. **API Key Creation**:
   - User must be authenticated (JWT token required)
   - User can create up to 3 API keys via `/api/apikeys` endpoint
   - Each key has a name, optional description, and access rules
   - System generates a secure API key with prefix `ak_` (e.g., `ak_abc123...`)
   - API key is hashed before storing in database (original key shown only once)
   - Each key starts with 100 requests/month quota
   - Quota resets automatically on the 1st of each month
   - Returns the plain API key (shown only once - must be saved by user)

2. **Using API Keys**:
   - Public API endpoints require API key authentication
   - Client includes key in `X-API-Key` header or `Authorization: ApiKey <key>` header
   - Backend validates API key hash against database
   - Backend checks if key status is 'active'
   - Backend checks if monthly quota is not exceeded
   - If valid and quota available, request proceeds
   - Usage counter is incremented for tracking

3. **Managing API Keys**:
   - List all keys: `GET /api/apikeys` (shows masked keys, never full keys)
   - Update status: `PUT /api/apikeys/:id/status` (activate/deactivate keys)
   - Update rules: `PUT /api/apikeys/:id/rules` (modify access permissions)
   - Delete key: `DELETE /api/apikeys/:id` (revokes key - cannot be undone)
   - Check quota: `GET /api/apikeys/:id/quota` (view usage and remaining quota)

4. **Quota Management**:
   - Each API key has 100 requests/month
   - Usage is tracked in `current_month_usage` column
   - Quota resets automatically on 1st of each month
   - When quota exceeded, API returns HTTP 429 (Too Many Requests)
   - Users can check remaining quota via dashboard or API endpoint

### 📊 Database Schema

The SQLite database includes three main tables:

#### 1. Users Table
```sql
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT 1
);
```

#### 2. JWT Tokens Table
```sql
CREATE TABLE jwt_tokens (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    token_hash TEXT NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_revoked BOOLEAN DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 3. API Keys Table
```sql
CREATE TABLE api_keys (
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
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

## API Endpoints

### Health Check
- `GET /api/health` - Server health status

### Authentication Endpoints
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/profile` - Get user profile (requires JWT)
- `POST /api/auth/logout` - Logout user (requires JWT)

### API Key Management (require JWT authentication)
- `POST /api/apikeys` - Create new API key
- `GET /api/apikeys` - List all user's API keys
- `PUT /api/apikeys/:keyId/status` - Update API key status
- `PUT /api/apikeys/:keyId/rules` - Update API key rules
- `DELETE /api/apikeys/:keyId` - Delete (revoke) API key
- `POST /api/apikeys/validate` - Validate API key
- `GET /api/apikeys/:keyId/quota` - Get quota status

### Public API Endpoints (require API Key)
- `GET /api/users` - Get all users
- `GET /api/users/:userId` - Get user by ID
- `GET /api/projects` - Get all projects
- `POST /api/projects` - Create new project
- `GET /api/analytics/summary` - Get analytics data
- `POST /api/moderate-content/text/v1` - Content moderation
- `GET /api/docs` - API documentation (no auth required)

## Environment Configuration

Edit `nodejs-backend/.env` to configure:

```env
# Server Configuration
PORT=8080
NODE_ENV=development

# Database Configuration
DB_PATH=./database/userportal.db

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRY_TIME=3600
JWT_ISSUER=userportal-auth
JWT_AUDIENCE=userportal-users

# CORS Configuration
CORS_ORIGINS=http://localhost:3000,http://localhost:3001
```

## Development

### Running in Development Mode

```bash
cd nodejs-backend
npm run dev
```

### Viewing the Database

```bash
view-database.bat
```

Or manually:
```bash
cd nodejs-backend\database
sqlite3 userportal.db
.tables
SELECT * FROM users;
```

### Testing the API

Use the provided PowerShell scripts or test with curl:

```bash
# Test health endpoint
curl http://localhost:8080/api/health

# Register a new user
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"password123"}'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}'
```

## Troubleshooting

### Port Already in Use

If port 8080 is in use, change it in `.env`:
```env
PORT=3001
```

### Database Issues

Delete and recreate:
```bash
cd nodejs-backend
Remove-Item -Recurse -Force database
npm start
```

### Module Not Found

Reinstall dependencies:
```bash
cd nodejs-backend
Remove-Item -Recurse -Force node_modules
npm install
```

## Security Best Practices

- ✅ **Change JWT_SECRET** in production
- ✅ **Use HTTPS** in production
- ✅ **Never commit .env** files
- ✅ **Implement rate limiting** for production
- ✅ **Regular security audits** of dependencies
- ✅ **Monitor API usage** for abuse
- ✅ **Backup database** regularly

## License

ISC

## Contributors

Built with ❤️ using Node.js, Express, and Next.js
