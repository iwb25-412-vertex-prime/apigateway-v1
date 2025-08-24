# Ballerina Authentication & API Key Management Backend

A comprehensive Ballerina-based authentication service with JWT tokens, API key management, and quota tracking system.

## 🚀 Quick Start

```bash
# Start the service
bal run

# Service runs on http://localhost:8080
# Health check: http://localhost:8080/api/health
```

## ✅ Current Status (August 25, 2025)

- ✅ **COMPILATION**: All errors fixed, service compiles successfully
- ✅ **DATABASE**: SQLite schema initialized automatically  
- ✅ **AUTHENTICATION**: JWT token system fully operational
- ✅ **API KEYS**: Complete lifecycle management with quota tracking
- ✅ **QUOTA SYSTEM**: Monthly limits (100 requests/month) with auto-reset

## 🏗️ Architecture

### Modular Design
```
├── main.bal           # 🌐 HTTP service & endpoints
├── auth.bal           # 🔐 JWT authentication system  
├── database.bal       # 🗄️ SQLite operations & schema
├── apikeys.bal        # 🔑 API key management
├── quota.bal          # 📊 Usage tracking & limits
├── types.bal          # 📋 Data models & types
├── utils.bal          # 🛠️ Utilities & validation
└── api-endpoints.bal  # 📡 Public API endpoints
```

### Database Schema
- **users**: Account management with secure password hashing
- **jwt_tokens**: Token tracking for security & revocation  
- **api_keys**: Key management with quota tracking

## 🔑 Key Features

### Authentication System
- **Secure Registration**: Username/email validation, password hashing
- **JWT Tokens**: Cryptographically signed with 1-hour expiry
- **Token Revocation**: Immediate invalidation on logout
- **Database Tracking**: All tokens tracked for security auditing

### API Key Management  
- **Limited Keys**: Max 3 keys per user to prevent abuse
- **Secure Generation**: Cryptographically secure with `ak_` prefix
- **Usage Tracking**: Lifetime + monthly usage statistics
- **Status Management**: Enable/disable without deletion
- **Rule System**: Flexible permission management

### Quota System
- **Monthly Limits**: 100 requests per key per month
- **Auto Reset**: Automatic quota reset on 1st of each month
- **Real-time Tracking**: Live usage monitoring
- **Quota Enforcement**: HTTP 429 when limits exceeded

## 📡 API Endpoints

### Authentication
```bash
POST /api/auth/register    # User registration
POST /api/auth/login       # User login  
POST /api/auth/logout      # Token revocation
GET  /api/auth/profile     # User profile (protected)
```

### API Key Management (Protected)
```bash
POST   /api/apikeys              # Create API key
GET    /api/apikeys              # List user's keys
PUT    /api/apikeys/{id}/status  # Enable/disable key
PUT    /api/apikeys/{id}/rules   # Update permissions
DELETE /api/apikeys/{id}         # Revoke key
GET    /api/apikeys/{id}/quota   # Check quota status
```

### API Key Validation (Public)
```bash
POST /api/apikeys/validate       # Validate key & increment usage
```

### Public API (API Key Required)
```bash
GET  /api/users                  # List users
GET  /api/users/{id}             # Get user by ID
GET  /api/projects               # List projects
POST /api/projects               # Create project
GET  /api/analytics/summary      # Analytics data
POST /api/moderate-content/text/v1  # Content moderation
```

## 🔧 Configuration

### Environment Variables
```bash
JWT_SECRET=your-secret-key-here
JWT_EXPIRY=3600
DB_PATH=database/userportal.db
PORT=8080
```

### Config.toml
```toml
[auth]
jwtSecret = "your-secret-key"
jwtExpiryTime = 3600

[database]  
path = "database/userportal.db"
```

## 🧪 Testing

### Quick Test
```bash
# Health check
curl http://localhost:8080/api/health

# Register user
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@example.com","password":"password123"}'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"password123"}'
```

### API Key Testing
```bash
# Create API key (requires JWT token)
curl -X POST http://localhost:8080/api/apikeys \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Key","description":"For testing"}'

# Validate API key
curl -X POST http://localhost:8080/api/apikeys/validate \
  -H "Content-Type: application/json" \
  -d '{"apiKey":"ak_your_api_key_here"}'
```

## 🔒 Security Features

- **Password Security**: SHA256 hashing with salt
- **Token Security**: Cryptographic signing & database tracking
- **API Key Security**: Hashed storage, never plain text
- **Input Validation**: Email format, password strength
- **CORS Protection**: Configured for frontend origins
- **Quota Limits**: Prevent API abuse
- **Error Handling**: Secure error messages

## 🐛 Recent Fixes

### Fixed Issues (August 25, 2025)
1. **SQL Import Error**: Added missing `import ballerina/sql;` to quota.bal
2. **Continue Statement**: Removed invalid continue from `from` expression  
3. **Type Compatibility**: Fixed stream type issues in quota management
4. **Compilation**: All compilation errors resolved

### Performance Optimizations
- Database indexes for optimal query performance
- Efficient API key validation with hash lookups
- Optimized quota checking with indexed queries

## 🚀 Production Deployment

### Docker
```dockerfile
FROM ballerina/ballerina:2201.10.0
COPY . /app
WORKDIR /app
RUN bal build
EXPOSE 8080
CMD ["bal", "run"]
```

### Security Checklist
- [ ] Change JWT secret key
- [ ] Enable HTTPS/TLS
- [ ] Configure rate limiting  
- [ ] Set up database backups
- [ ] Enable monitoring & logging
- [ ] Use environment variables for secrets

## 📚 Documentation

- **Main README**: ../README.md (comprehensive documentation)
- **API Docs**: http://localhost:8080/api/docs (when running)
- **Code Comments**: Inline documentation in source files

---

**Status**: ✅ Production Ready | **Last Updated**: August 25, 2025