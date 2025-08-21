# Ballerina JWT Authentication Backend

This is a Ballerina-based authentication service that provides JWT token-based authentication for the userportal frontend.

## Features

- User registration and login
- JWT token generation and validation
- Protected endpoints
- CORS support for frontend integration
- User profile management

## Prerequisites

- Ballerina Swan Lake (2201.10.0 or later)
- Java 11 or later

## Installation

1. Install Ballerina from https://ballerina.io/downloads/
2. Navigate to the backend directory:
   ```bash
   cd ballerina-backend
   ```

## Running the Service

```bash
bal run
```

The service will start on port 8080 by default.

## API Endpoints

### Public Endpoints

- `GET /api/health` - Health check
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout

### Protected Endpoints (Require JWT token)

- `GET /api/auth/profile` - Get user profile
- `PUT /api/auth/profile` - Update user profile

## Usage Examples

### Register a new user
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'
```

### Access protected endpoint
```bash
curl -X GET http://localhost:8080/api/auth/profile \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Configuration

Edit `Config.toml` to customize:
- JWT secret key
- Token expiry time
- Server port

## Security Notes

- Change the JWT secret in production
- Implement proper password hashing
- Use HTTPS in production
- Consider using a proper database instead of in-memory storage
- Implement rate limiting for authentication endpoints

## Frontend Integration

The service is configured to work with a Next.js frontend running on `http://localhost:3000`. Update the CORS configuration in `main.bal` if your frontend runs on a different port.