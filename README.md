# User Portal with Secure JWT Authentication

A full-stack application with secure JWT authentication using Ballerina backend, MySQL database, and Next.js frontend.

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

## Features

### Backend (Ballerina)
- **Secure JWT Authentication**: Real JWT tokens with RSA signing
- **Password Security**: BCrypt password hashing
- **Database Storage**: MySQL database for persistent user data
- **Token Management**: JWT tokens stored and tracked in database
- **Token Revocation**: Logout revokes tokens in database
- **Input Validation**: Email format and password strength validation
- **Protected Endpoints**: JWT validation for secure routes
- **CORS Support**: Configured for frontend integration
- **Token Cleanup**: Automatic cleanup of expired tokens

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
- **MySQL**: 8.0 or later
- **MySQL Connector**: Included in dependencies

## Quick Start

### Step 1: Database Setup

**Windows:**
```bash
setup-database.bat
```

**Unix/Linux/macOS:**
```bash
./setup-database.sh
```

Or manually:
```sql
mysql -u root -p < ballerina-backend/database/schema.sql
```

### Step 2: Configure Database

Update `ballerina-backend/Config.toml` with your MySQL credentials:
```toml
[userportal.auth_service.database]
host = "localhost"
port = 3306
name = "userportal"
username = "your_mysql_username"
password = "your_mysql_password"
```

### Step 3: Start Services

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

### Protected Endpoints
- `GET /api/auth/profile` - Get user profile
- `PUT /api/auth/profile` - Update user profile

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

### Database Schema
The application uses the following database structure:

**Users Table:**
- `id`: Unique user identifier (UUID)
- `username`: Unique username (3-50 characters)
- `email`: Unique email address (validated format)
- `password_hash`: BCrypt hashed password
- `created_at`, `updated_at`: Timestamps
- `is_active`: Account status

**JWT Tokens Table:**
- `id`: Unique token identifier
- `user_id`: Reference to users table
- `token_hash`: SHA256 hash of JWT token
- `expires_at`: Token expiration timestamp
- `is_revoked`: Token revocation status

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