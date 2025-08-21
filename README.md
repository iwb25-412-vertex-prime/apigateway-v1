# User Portal with Ballerina JWT Authentication

A full-stack application with JWT authentication using Ballerina backend and Next.js frontend.

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
- JWT token generation and validation
- User registration and login
- Protected endpoints
- CORS support for frontend
- User profile management
- RSA key-based JWT signing

### Frontend (Next.js)
- React components for authentication
- Custom hooks for auth state management
- TypeScript support
- Tailwind CSS styling
- Local storage for token persistence

## Prerequisites

- **Ballerina**: Swan Lake (2201.10.0 or later)
- **Node.js**: 18.x or later
- **Java**: 11 or later (for Ballerina)

## Quick Start

### Option 1: Use Startup Scripts

**Windows:**
```bash
start-services.bat
```

**Unix/Linux/macOS:**
```bash
./start-services.sh
```

### Option 2: Manual Setup

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

### Frontend Configuration (.env.local)
```env
NEXT_PUBLIC_API_URL=http://localhost:8080/api
```

## Security Features

- RSA-based JWT signing
- Token expiration handling
- CORS protection
- Secure password handling (extend with hashing in production)
- Protected route middleware

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

1. **Security:**
   - Change JWT secret key
   - Implement password hashing (bcrypt)
   - Use HTTPS
   - Implement rate limiting
   - Add input validation

2. **Database:**
   - Replace in-memory storage with a proper database
   - Add user data persistence

3. **Monitoring:**
   - Add logging and monitoring
   - Implement health checks
   - Add error tracking

4. **Deployment:**
   - Use environment variables for configuration
   - Set up proper CI/CD pipeline
   - Configure load balancing

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