# API Documentation

## Overview

The User Portal API provides endpoints for content moderation, user management, project management, and analytics. All endpoints require API key authentication and respect permission-based access control.

**Base URL:** `http://localhost:8080/api`

## Authentication

All API endpoints (except `/docs`) require authentication using an API key. Include your API key in one of these ways:

### Method 1: X-API-Key Header (Recommended)
```
X-API-Key: ak_your_api_key_here
```

### Method 2: Authorization Header
```
Authorization: ApiKey ak_your_api_key_here
```

## Getting Your API Key

1. Visit the web portal: `http://localhost:3000/apikeys`
2. Login with your account
3. Create a new API key with desired permissions
4. Copy the generated key (shown only once!)

## Rate Limiting

- **Monthly Quota:** 100 requests per API key
- **Quota Reset:** First day of each month
- **Quota Exceeded Response:** HTTP 429 with reset date

## Permissions System

When creating API keys, assign these permissions:

- **`read`** - Access to GET endpoints (users, projects)
- **`write`** - Access to POST/PUT/DELETE endpoints
- **`moderate`** - Access to content moderation endpoints
- **`analytics`** - Access to analytics endpoints

---

## Content Moderation API

### Moderate Text Content

Analyze text content for inappropriate material, spam, or policy violations.

**Endpoint:** `POST /moderate-content/text/v1`

**Required Permission:** `moderate`

**Headers:**
```
X-API-Key: ak_your_api_key_here
Content-Type: application/json
```

**Request Body:**
```json
{
  "text": "The text content to analyze for moderation"
}
```

**Response (Success - 200):**
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

**Response (Flagged Content - 200):**
```json
{
  "status": true,
  "result": {
    "flagged": true,
    "confidence": 0.85,
    "categories": ["spam", "inappropriate"],
    "severity": "medium",
    "action_recommended": "review"
  },
  "metadata": {
    "text_length": 156,
    "processing_time_ms": 52,
    "model_version": "v1.2.3",
    "api_key_used": "My Moderation Key"
  }
}
```

**Complete Example Request:**
```bash
curl -X POST http://localhost:8080/api/moderate-content/text/v1 \
  -H "X-API-Key: ak_abc123def456..." \
  -H "Content-Type: application/json" \
  -d '{
    "text": "This is a sample text to moderate for inappropriate content"
  }'
```

**Field Descriptions:**

| Field | Type | Description |
|-------|------|-------------|
| `text` | string | Text content to analyze (max 10,000 characters) |
| `flagged` | boolean | Whether content was flagged as inappropriate |
| `confidence` | float | Confidence score (0.0 to 1.0) |
| `categories` | array | List of detected issue categories |
| `severity` | string | Severity level: "none", "low", "medium", "high" |
| `action_recommended` | string | Recommended action: "approve", "review", "reject" |

---

## User Management API

### Get All Users

**Endpoint:** `GET /users`  
**Required Permission:** `read`

**Headers:**
```
X-API-Key: ak_your_api_key_here
```

**Response:**
```json
{
  "users": [
    {
      "id": "1",
      "name": "John Doe",
      "email": "john@company.com",
      "department": "Engineering",
      "role": "Developer"
    }
  ],
  "count": 3,
  "api_key_used": "My Read Key"
}
```

### Get User by ID

**Endpoint:** `GET /users/{id}`  
**Required Permission:** `read`

**Example:**
```bash
curl -H "X-API-Key: ak_abc123..." http://localhost:8080/api/users/1
```

---

## Project Management API

### Get All Projects

**Endpoint:** `GET /projects`  
**Required Permission:** `read`

**Response:**
```json
{
  "projects": [
    {
      "id": "1",
      "name": "Website Redesign",
      "description": "Modernize company website",
      "status": "In Progress",
      "created_date": "2024-01-15"
    }
  ],
  "count": 3,
  "api_key_used": "My Read Key"
}
```

### Create New Project

**Endpoint:** `POST /projects`  
**Required Permission:** `write`

**Request Body:**
```json
{
  "name": "New Project Name",
  "description": "Project description"
}
```

**Example:**
```bash
curl -X POST http://localhost:8080/api/projects \
  -H "X-API-Key: ak_abc123..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Mobile App Development",
    "description": "Build customer mobile application"
  }'
```

---

## Analytics API

### Get Analytics Summary

**Endpoint:** `GET /analytics/summary`  
**Required Permission:** `analytics`

**Response:**
```json
{
  "total_users": 3,
  "total_projects": 3,
  "active_projects": 2,
  "completed_projects": 1,
  "departments": {
    "Engineering": 1,
    "Marketing": 1,
    "Sales": 1
  },
  "api_key_used": "My Analytics Key",
  "generated_at": "2024-08-24T10:30:00Z"
}
```

---

## Error Responses

### 401 Unauthorized
```json
{
  "error": "Invalid API key"
}
```

### 403 Forbidden
```json
{
  "error": "API key does not have 'moderate' permission"
}
```

### 429 Too Many Requests
```json
{
  "error": "Monthly quota exceeded",
  "message": "You have exceeded your monthly quota of 100 requests. Quota resets on: 2024-09-01",
  "apiKey": {
    "name": "My API Key",
    "current_month_usage": 100,
    "monthly_quota": 100,
    "quota_reset_date": "2024-09-01"
  }
}
```

### 400 Bad Request
```json
{
  "error": "Missing required field: text"
}
```

---

## API Information

### Get API Documentation

**Endpoint:** `GET /docs`  
**Authentication:** None required

Returns complete API specification and available endpoints.

---

## Testing Your API Key

### Validate API Key
```bash
curl -X POST http://localhost:8080/api/apikeys/validate \
  -H "Content-Type: application/json" \
  -d '{"apiKey": "ak_your_key_here"}'
```

### Check Quota Status
Visit your dashboard at `http://localhost:3000/apikeys` to see:
- Current usage
- Remaining quota  
- Quota reset date
- API key status

---

## Quick Start Examples

### 1. Content Moderation
```bash
# Moderate text content
curl -X POST http://localhost:8080/api/moderate-content/text/v1 \
  -H "X-API-Key: ak_abc123..." \
  -H "Content-Type: application/json" \
  -d '{"text": "Check this message for inappropriate content"}'
```

### 2. Get Users
```bash
# List all users
curl -H "X-API-Key: ak_abc123..." http://localhost:8080/api/users
```

### 3. Create Project
```bash
# Create new project
curl -X POST http://localhost:8080/api/projects \
  -H "X-API-Key: ak_abc123..." \
  -H "Content-Type: application/json" \
  -d '{"name": "New Project", "description": "Project description"}'
```

### 4. Get Analytics
```bash
# Get analytics summary
curl -H "X-API-Key: ak_abc123..." http://localhost:8080/api/analytics/summary
```

---

## Support

- **Web Dashboard:** http://localhost:3000
- **API Key Management:** http://localhost:3000/apikeys
- **API Documentation:** http://localhost:8080/api/docs