# Node.js Backend - User Portal API Gateway

This is the Node.js implementation of the User Portal API Gateway, providing the same functionality as the Ballerina backend.

## Features

- **User Authentication**: Register, login, profile management, and logout
- **JWT Token Management**: Secure token generation, validation, and revocation
- **API Key Management**: Create, list, update, and delete API keys (max 3 per user)
- **Quota Management**: Monthly request limits with automatic reset
- **Public API Endpoints**: User, project, analytics, and content moderation APIs
- **SQLite Database**: Lightweight, file-based database
- **CORS Support**: Cross-origin resource sharing configuration

## Technology Stack

- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: SQLite (better-sqlite3)
- **Authentication**: Custom JWT implementation with bcrypt password hashing
- **Additional Libraries**: 
  - cors - CORS middleware
  - dotenv - Environment variable management
  - uuid - Unique identifier generation

## Project Structure

```
nodejs-backend/
├── server.js               # Main server file
├── config.js               # Configuration module
├── database.js             # Database operations
├── auth.js                 # Authentication utilities
├── apikeys.js              # API key management
├── quota.js                # Quota management
├── middleware.js           # Authentication middleware
├── routes/
│   ├── auth.routes.js      # Authentication endpoints
│   ├── apikeys.routes.js   # API key management endpoints
│   └── public.routes.js    # Public API endpoints
├── database/
│   └── userportal.db       # SQLite database (created automatically)
├── package.json            # Node.js dependencies
├── .env                    # Environment variables
└── .env.example            # Environment variables template
```

## Installation

1. **Install Node.js** (v14 or higher)
   - Download from https://nodejs.org/

2. **Install dependencies**:
   ```bash
   cd nodejs-backend
   npm install
   ```
   
   Or use the provided batch script:
   ```bash
   setup-nodejs.bat
   ```

## Running the Server

### Option 1: Using npm
```bash
cd nodejs-backend
npm start
```

### Option 2: Using the batch script
```bash
start-nodejs-backend.bat
```

### Option 3: Development mode with auto-reload
```bash
cd nodejs-backend
npm run dev
```

The server will start on **http://localhost:8080**

## Configuration

Edit the `.env` file to configure the server:

```env
# Server Configuration
PORT=8080
NODE_ENV=development

# Database Configuration
DB_PATH=./database/userportal.db

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-in-production-min-32-chars
JWT_EXPIRY_TIME=3600
JWT_ISSUER=userportal-auth
JWT_AUDIENCE=userportal-users

# CORS Configuration
CORS_ORIGINS=http://localhost:3000,http://localhost:3001
```

## API Endpoints

### Health Check
- **GET** `/api/health` - Check server health

### Authentication Endpoints
- **POST** `/api/auth/register` - Register new user
- **POST** `/api/auth/login` - Login user
- **GET** `/api/auth/profile` - Get user profile (requires JWT)
- **POST** `/api/auth/logout` - Logout user (requires JWT)

### API Key Management Endpoints (require JWT authentication)
- **POST** `/api/apikeys` - Create new API key
- **GET** `/api/apikeys` - Get all API keys for user
- **PUT** `/api/apikeys/:keyId/status` - Update API key status
- **PUT** `/api/apikeys/:keyId/rules` - Update API key rules
- **DELETE** `/api/apikeys/:keyId` - Delete (revoke) API key
- **POST** `/api/apikeys/validate` - Validate API key (for testing)
- **GET** `/api/apikeys/:keyId/quota` - Get quota status

### Public API Endpoints (require API Key authentication)
- **GET** `/api/users` - Get all users
- **GET** `/api/users/:userId` - Get user by ID
- **GET** `/api/projects` - Get all projects
- **POST** `/api/projects` - Create new project
- **GET** `/api/analytics/summary` - Get analytics summary
- **POST** `/api/moderate-content/text/v1` - Moderate text content
- **GET** `/api/docs` - API documentation (no auth required)

## Authentication

### JWT Authentication (for API key management)
Include the JWT token in the Authorization header:
```
Authorization: Bearer <token>
```

### API Key Authentication (for public APIs)
Include the API key in either:
- **X-API-Key header**:
  ```
  X-API-Key: ak_your_api_key_here
  ```
- **Authorization header**:
  ```
  Authorization: ApiKey ak_your_api_key_here
  ```

## Quota Management

- Each API key has a **monthly quota of 100 requests**
- Usage is tracked per API key
- Quota automatically resets on the **1st day of each month**
- Quota status can be checked via the `/api/apikeys/:keyId/quota` endpoint
- When quota is exceeded, API returns **HTTP 429 (Too Many Requests)**

## Database Schema

The SQLite database includes three main tables:

1. **users** - User accounts
2. **jwt_tokens** - JWT token management
3. **api_keys** - API key management with quota tracking

The database is automatically initialized on first run.

## Error Handling

The API returns appropriate HTTP status codes:
- **200** - Success
- **201** - Created
- **400** - Bad Request
- **401** - Unauthorized
- **403** - Forbidden
- **404** - Not Found
- **409** - Conflict
- **429** - Too Many Requests (quota exceeded)
- **500** - Internal Server Error

## Development

### Adding New Endpoints

1. Create a new route file in `routes/` directory
2. Implement the route handlers
3. Import and mount the routes in `server.js`

### Modifying Database Schema

Update the `initializeDatabase()` function in `database.js` to add new tables or columns.

## Troubleshooting

### Port Already in Use
If port 8080 is already in use, change the `PORT` in `.env` file:
```env
PORT=3001
```

### Database Locked
If you get a database locked error, ensure no other process is accessing the database file.

### Module Not Found
Run `npm install` to ensure all dependencies are installed.

## Security Notes

- **Change JWT_SECRET** in production to a strong, unique value
- **Never commit** the `.env` file with production secrets
- **Use HTTPS** in production
- **Implement rate limiting** for production deployment
- **Validate all user input** (already implemented in routes)
- **Use environment variables** for sensitive configuration

## Differences from Ballerina Backend

The Node.js backend provides **identical functionality** to the Ballerina backend:
- Same API endpoints and routes
- Same authentication mechanisms
- Same database schema
- Same quota management system
- Same business logic

The only differences are:
- Implementation language (Node.js vs Ballerina)
- Dependencies (npm packages vs Ballerina modules)
- Startup method (node vs bal run)

## License

ISC
