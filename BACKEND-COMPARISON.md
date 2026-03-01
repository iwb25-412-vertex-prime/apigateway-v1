# Backend Comparison: Ballerina vs Node.js

Both backends provide **identical functionality** and can be used interchangeably with the same frontend. Here's a detailed comparison:

## Functional Equivalence

### ✅ All Features Identical

Both backends implement:
- User registration and login
- JWT-like token authentication
- Password hashing (SHA256 in Ballerina, bcrypt in Node.js)
- Token revocation and logout
- API key generation and management
- Quota tracking and enforcement (100 requests/month)
- Database schema (SQLite)
- All API endpoints
- CORS configuration
- Input validation
- Error handling

## File Structure Comparison

### Ballerina Backend Structure
```
ballerina-backend/
├── main.bal              # Main service and HTTP endpoints
├── auth.bal              # Authentication logic
├── database.bal          # Database operations
├── apikeys.bal           # API key management
├── quota.bal             # Quota management
├── types.bal             # Data types
├── utils.bal             # Utility functions
├── api-endpoints.bal     # Public API endpoints
├── Ballerina.toml        # Project config
└── Dependencies.toml     # Dependencies
```

### Node.js Backend Structure
```
nodejs-backend/
├── server.js             # Main Express server
├── auth.js               # Authentication utilities
├── database.js           # Database operations
├── apikeys.js            # API key management
├── quota.js              # Quota management
├── middleware.js         # Auth middleware
├── config.js             # Configuration
├── routes/
│   ├── auth.routes.js    # Auth endpoints
│   ├── apikeys.routes.js # API key endpoints
│   └── public.routes.js  # Public endpoints
├── package.json          # Dependencies
└── .env                  # Environment config
```

## Code Comparison: Key Functions

### User Registration

**Ballerina:**
```ballerina
resource function post auth/register(@http:Payload json payload) returns http:Response {
    // Extract fields from payload
    string username = usernameField.toString();
    string email = emailField.toString();
    string password = passwordField.toString();
    
    // Validate input
    if username.length() < 3 || username.length() > 50 { ... }
    if !isValidEmail(email) { ... }
    
    // Hash password
    string hashedPassword = hashPassword(password);
    
    // Create user
    User|error newUser = createUser(username, email, hashedPassword);
    
    // Return response
    res.setJsonPayload({ "message": "User registered successfully", ... });
}
```

**Node.js:**
```javascript
router.post('/register', (req, res) => {
    // Extract fields from body
    const { username, email, password } = req.body;
    
    // Validate input
    if (username.length < 3 || username.length > 50) { ... }
    if (!isValidEmail(email)) { ... }
    
    // Hash password
    const passwordHash = hashPassword(password);
    
    // Create user
    const newUser = createUser(username, email, passwordHash);
    
    // Return response
    res.status(201).json({ message: 'User registered successfully', ... });
});
```

### API Key Validation

**Ballerina:**
```ballerina
public function validateApiKey(string apiKey) returns ApiKey|error {
    string keyHash = hashApiKey(apiKey);
    
    record {...}|sql:Error result = dbClient->queryRow(`
        SELECT * FROM api_keys WHERE key_hash = ${keyHash} AND status = 'active'
    `);
    
    if result is sql:Error {
        return error("Invalid API key");
    }
    
    return parseApiKey(result);
}
```

**Node.js:**
```javascript
function validateApiKey(apiKey) {
    const keyHash = hashApiKey(apiKey);
    
    const stmt = db.prepare(`
        SELECT * FROM api_keys WHERE key_hash = ? AND status = 'active'
    `);
    
    const result = stmt.get(keyHash);
    
    if (!result) {
        throw new Error('Invalid API key');
    }
    
    return parseApiKey(result);
}
```

## API Endpoints Comparison

Both backends expose **identical endpoints** on port 8080:

### Authentication Endpoints
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/profile` - Get user profile (requires JWT)
- `POST /api/auth/logout` - Logout user (requires JWT)

### API Key Management Endpoints
- `POST /api/apikeys` - Create new API key (requires JWT)
- `GET /api/apikeys` - Get all API keys (requires JWT)
- `PUT /api/apikeys/:keyId/status` - Update status (requires JWT)
- `PUT /api/apikeys/:keyId/rules` - Update rules (requires JWT)
- `DELETE /api/apikeys/:keyId` - Delete API key (requires JWT)
- `POST /api/apikeys/validate` - Validate API key
- `GET /api/apikeys/:keyId/quota` - Get quota status (requires JWT)

### Public API Endpoints (require API Key)
- `GET /api/users` - Get all users
- `GET /api/users/:userId` - Get user by ID
- `GET /api/projects` - Get all projects
- `POST /api/projects` - Create new project
- `GET /api/analytics/summary` - Get analytics
- `POST /api/moderate-content/text/v1` - Moderate content
- `GET /api/docs` - API documentation (no auth)

### Health Check
- `GET /api/health` - Server health check

## Database Schema

**Identical SQLite schema in both backends:**

```sql
-- Users table
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT 1
);

-- JWT tokens table
CREATE TABLE jwt_tokens (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    token_hash TEXT NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_revoked BOOLEAN DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- API keys table
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

## Performance Considerations

### Ballerina Backend
- **Pros:**
  - Excellent concurrency model
  - Built for cloud-native applications
  - Strong type safety
  - Better for microservices architecture
- **Cons:**
  - Requires Java runtime
  - Less familiar to most developers
  - Smaller ecosystem

### Node.js Backend
- **Pros:**
  - JavaScript ecosystem familiarity
  - Huge package ecosystem (npm)
  - Easy to find developers
  - No additional runtime needed (just Node.js)
- **Cons:**
  - Single-threaded event loop
  - Can have callback hell (mitigated with async/await)
  - Type safety requires TypeScript

## When to Use Each Backend

### Choose Ballerina if:
- Building cloud-native microservices
- Need strong concurrency
- Want built-in integration features
- Team has Java/Ballerina experience
- Enterprise-grade reliability is priority

### Choose Node.js if:
- Team is familiar with JavaScript
- Want quick prototyping
- Need access to npm ecosystem
- Prefer Express.js patterns
- Want easier deployment options

## Migration Between Backends

**Frontend works with both backends without changes!**

To switch backends:

1. **Stop current backend** (Ctrl+C)
2. **Start other backend:**
   - For Ballerina: `cd ballerina-backend && bal run`
   - For Node.js: `cd nodejs-backend && npm start`
3. **Frontend continues working** - no changes needed!

The frontend connects to `http://localhost:8080` regardless of which backend is running.

## Testing

Both backends can be tested with the same scripts:
- `test-auth.ps1` - Test authentication endpoints
- `test-apikeys.ps1` - Test API key management
- `test-public-api.ps1` - Test public API endpoints

## Summary

| Feature | Ballerina | Node.js |
|---------|-----------|---------|
| **Functionality** | ✅ Complete | ✅ Complete |
| **API Endpoints** | ✅ All endpoints | ✅ All endpoints |
| **Database Schema** | ✅ SQLite | ✅ SQLite |
| **Authentication** | ✅ JWT + API Keys | ✅ JWT + API Keys |
| **Quota Management** | ✅ Full support | ✅ Full support |
| **Performance** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Developer Familiarity** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Ecosystem** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Type Safety** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Deployment** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

**Both are excellent choices! Pick based on your team's expertise and project requirements.**
