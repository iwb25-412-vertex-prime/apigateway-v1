# API Usage Examples

## Getting Started

1. **Create an API Key**
   - Go to http://localhost:3000/apikeys
   - Login with your account
   - Create a new API key with desired permissions
   - Copy the generated key (shown only once!)

2. **Use the API Key**
   - Include in `X-API-Key` header, or
   - Use `Authorization: ApiKey <your-key>` header

## Available Endpoints

### 🛡️ Content Moderation API (requires 'moderate' permission)

**Moderate text content:**
```bash
curl -X POST http://localhost:8080/api/moderate-content/text/v1 \
     -H "X-API-Key: ak_your_api_key_here" \
     -H "Content-Type: application/json" \
     -d '{"text":"Check this message for inappropriate content"}'
```

**Response:**
```json
{
  "status": true,
  "result": {
    "flagged": false,
    "confidence": 0.95,
    "categories": [],
    "severity": "none", 
    "action_recommended": "approve"
  },
  "metadata": {
    "text_length": 42,
    "processing_time_ms": 45,
    "model_version": "v1.2.3",
    "api_key_used": "My Moderation Key"
  }
}
```

### 📖 API Documentation
```bash
curl http://localhost:8080/api/docs
```

### 👥 Users API (requires 'read' permission)

**Get all users:**
```bash
curl -H "X-API-Key: ak_your_api_key_here" \
     http://localhost:8080/api/users
```

**Get specific user:**
```bash
curl -H "X-API-Key: ak_your_api_key_here" \
     http://localhost:8080/api/users/1
```

### 📋 Projects API

**Get all projects (requires 'read' permission):**
```bash
curl -H "X-API-Key: ak_your_api_key_here" \
     http://localhost:8080/api/projects
```

**Create new project (requires 'write' permission):**
```bash
curl -X POST \
     -H "X-API-Key: ak_your_api_key_here" \
     -H "Content-Type: application/json" \
     -d '{"name":"My New Project","description":"Project created via API"}' \
     http://localhost:8080/api/projects
```

### 📊 Analytics API (requires 'analytics' permission)

**Get analytics summary:**
```bash
curl -H "X-API-Key: ak_your_api_key_here" \
     http://localhost:8080/api/analytics/summary
```

## Permission System

When creating API keys, you can assign these permissions:

- **`read`** - Access to GET endpoints (users, projects)
- **`write`** - Access to POST/PUT/DELETE endpoints  
- **`moderate`** - Access to content moderation endpoints
- **`analytics`** - Access to analytics endpoints

## Rate Limiting

- Each API key has **100 free requests per month**
- Quota resets on the 1st day of each month
- Check your usage at http://localhost:3000/apikeys

## Error Responses

- **401 Unauthorized** - Invalid or missing API key
- **403 Forbidden** - API key lacks required permission
- **429 Too Many Requests** - Monthly quota exceeded
- **404 Not Found** - Resource not found

## Alternative Authentication Header

You can also use the Authorization header:
```bash
curl -H "Authorization: ApiKey ak_your_api_key_here" \
     http://localhost:8080/api/users
```

## Testing Your Setup

Run the PowerShell test script:
```powershell
.\test-api-usage.ps1
```

This will test all endpoints and show you which permissions your API key has.