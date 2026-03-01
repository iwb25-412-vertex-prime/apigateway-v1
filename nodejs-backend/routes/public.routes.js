// Public API routes (require API key authentication)
const express = require('express');
const router = express.Router();
const { validateApiKeyWithQuota } = require('../quota');
const { incrementApiKeyUsage, toApiKeyResponse } = require('../apikeys');

// Middleware to validate API key from request
function requireApiKey(req, res, next) {
  try {
    // Try to get API key from header first
    let apiKey = req.headers['x-api-key'];
    
    if (!apiKey) {
      // Try to get from Authorization header as ApiKey token
      const authHeader = req.headers.authorization;
      if (authHeader && authHeader.startsWith('ApiKey ')) {
        apiKey = authHeader.substring(7);
      }
    }
    
    if (!apiKey) {
      return res.status(401).json({ 
        error: 'API key not provided. Use X-API-Key header or Authorization: ApiKey <key>' 
      });
    }
    
    // Validate API key and check quota
    const [validatedKey, quotaAvailable] = validateApiKeyWithQuota(apiKey);
    
    if (!quotaAvailable) {
      return res.status(429).json({
        error: 'Monthly quota exceeded. Quota resets on: ' + validatedKey.quota_reset_date
      });
    }
    
    // Increment usage count
    incrementApiKeyUsage(validatedKey.id);
    
    // Attach API key info to request
    req.apiKey = validatedKey;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid API key: ' + error.message });
  }
}

// Sample data for demonstration
const sampleUsers = [
  { id: '1', name: 'John Doe', email: 'john@company.com', department: 'Engineering', role: 'Developer' },
  { id: '2', name: 'Jane Smith', email: 'jane@company.com', department: 'Marketing', role: 'Manager' },
  { id: '3', name: 'Bob Wilson', email: 'bob@company.com', department: 'Sales', role: 'Representative' }
];

const sampleProjects = [
  { id: '1', name: 'Website Redesign', description: 'Modernize company website', status: 'In Progress', created_date: '2024-01-15' },
  { id: '2', name: 'Mobile App', description: 'Customer mobile application', status: 'Planning', created_date: '2024-02-01' },
  { id: '3', name: 'API Integration', description: 'Third-party API integration', status: 'Completed', created_date: '2024-01-01' }
];

// Get all users
router.get('/users', requireApiKey, (req, res) => {
  res.json({
    users: sampleUsers,
    count: sampleUsers.length,
    api_key_used: req.apiKey.name
  });
});

// Get user by ID
router.get('/users/:userId', requireApiKey, (req, res) => {
  const { userId } = req.params;
  const user = sampleUsers.find(u => u.id === userId);
  
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }
  
  res.json({
    user,
    api_key_used: req.apiKey.name
  });
});

// Get all projects
router.get('/projects', requireApiKey, (req, res) => {
  res.json({
    projects: sampleProjects,
    count: sampleProjects.length,
    api_key_used: req.apiKey.name
  });
});

// Create new project
router.post('/projects', requireApiKey, (req, res) => {
  const { name, description } = req.body;
  
  // Validate input
  if (!name || !description) {
    return res.status(400).json({ error: 'Missing required fields: name, description' });
  }
  
  if (name.length < 1 || name.length > 100) {
    return res.status(400).json({ error: 'Project name must be between 1 and 100 characters' });
  }
  
  // Create new project (in real app, this would save to database)
  const newProject = {
    id: (sampleProjects.length + 1).toString(),
    name,
    description,
    status: 'Planning',
    created_date: new Date().toISOString().split('T')[0]
  };
  
  res.status(201).json({
    message: 'Project created successfully',
    project: newProject,
    api_key_used: req.apiKey.name
  });
});

// Get analytics data
router.get('/analytics/summary', requireApiKey, (req, res) => {
  const analyticsData = {
    total_users: sampleUsers.length,
    total_projects: sampleProjects.length,
    active_projects: 2,
    completed_projects: 1,
    departments: {
      Engineering: 1,
      Marketing: 1,
      Sales: 1
    },
    api_key_used: req.apiKey.name,
    generated_at: new Date().toISOString()
  };
  
  res.json(analyticsData);
});

// Content moderation endpoint
router.post('/moderate-content/text/v1', requireApiKey, (req, res) => {
  const { text } = req.body;
  
  // Validate input
  if (!text) {
    return res.status(400).json({ error: 'Missing required field: text' });
  }
  
  if (text.length === 0) {
    return res.status(400).json({ error: 'Text cannot be empty' });
  }
  
  if (text.length > 10000) {
    return res.status(400).json({ error: 'Text cannot exceed 10,000 characters' });
  }
  
  // Simple content moderation logic (in real app, this would use ML models)
  const flaggedWords = ['spam', 'hate', 'violence', 'inappropriate'];
  let flagged = false;
  const detectedIssues = [];
  
  const lowerText = text.toLowerCase();
  flaggedWords.forEach(word => {
    if (lowerText.includes(word)) {
      flagged = true;
      detectedIssues.push(word);
    }
  });
  
  // Calculate confidence score (mock)
  const confidence = flagged ? 0.85 : 0.95;
  
  res.json({
    status: true,
    result: {
      flagged,
      confidence,
      categories: flagged ? detectedIssues : [],
      severity: flagged ? 'medium' : 'none',
      action_recommended: flagged ? 'review' : 'approve'
    },
    metadata: {
      text_length: text.length,
      processing_time_ms: 45,
      model_version: 'v1.2.3',
      api_key_used: req.apiKey.name
    }
  });
});

// API documentation endpoint - no authentication required
router.get('/docs', (req, res) => {
  res.json({
    api_version: '1.0.0',
    description: 'User Portal API - Manage users, projects, and analytics',
    authentication: 'API Key required (X-API-Key header or Authorization: ApiKey <key>)',
    endpoints: {
      'GET /api/users': {
        description: 'Get all users',
        response: 'Array of user objects'
      },
      'GET /api/users/{id}': {
        description: 'Get user by ID',
        response: 'Single user object'
      },
      'GET /api/projects': {
        description: 'Get all projects',
        response: 'Array of project objects'
      },
      'POST /api/projects': {
        description: 'Create new project',
        body: { name: 'string', description: 'string' },
        response: 'Created project object'
      },
      'GET /api/analytics/summary': {
        description: 'Get analytics summary',
        response: 'Analytics data object'
      },
      'POST /api/moderate-content/text/v1': {
        description: 'Moderate text content',
        body: { text: 'string' },
        response: 'Moderation result object'
      }
    },
    access_control: {
      authentication: 'Valid API key required',
      permissions: 'All API keys have access to all endpoints'
    },
    rate_limits: {
      monthly_quota: 100,
      quota_reset: 'First day of each month'
    }
  });
});

module.exports = router;
