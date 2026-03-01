// Main server file - User Portal API Gateway
const express = require('express');
const cors = require('cors');
const config = require('./config');
const { initializeDatabase } = require('./database');
const { fixExistingApiKeyQuotas } = require('./quota');

// Import routes
const authRoutes = require('./routes/auth.routes');
const apiKeysRoutes = require('./routes/apikeys.routes');
const publicRoutes = require('./routes/public.routes');

// Initialize Express app
const app = express();

// CORS configuration
app.use(cors({
  origin: config.corsOrigins,
  credentials: true,
  allowedHeaders: ['Authorization', 'Content-Type', 'X-API-Key'],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
}));

// Parse JSON body
app.use(express.json());

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'userportal-auth',
    timestamp: new Date().toISOString()
  });
});

// Mount routes
app.use('/api/auth', authRoutes);
app.use('/api/apikeys', apiKeysRoutes);
app.use('/api', publicRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Initialize database and start server
async function startServer() {
  try {
    // Initialize database schema
    initializeDatabase();
    
    // Fix existing API keys with incorrect quota dates
    try {
      fixExistingApiKeyQuotas();
      console.log('Fixed existing API key quotas');
    } catch (error) {
      console.error('Failed to fix existing API key quotas:', error);
    }
    
    // Start listening
    app.listen(config.port, () => {
      console.log(`\n🚀 User Portal API Gateway - Node.js Backend`);
      console.log(`🌐 Server running on http://localhost:${config.port}`);
      console.log(`📊 Environment: ${config.nodeEnv}`);
      console.log(`💾 Database: ${config.dbPath}`);
      console.log(`\nAvailable endpoints:`);
      console.log(`  - GET  /api/health`);
      console.log(`  - POST /api/auth/register`);
      console.log(`  - POST /api/auth/login`);
      console.log(`  - GET  /api/auth/profile`);
      console.log(`  - POST /api/auth/logout`);
      console.log(`  - POST /api/apikeys`);
      console.log(`  - GET  /api/apikeys`);
      console.log(`  - PUT  /api/apikeys/:keyId/status`);
      console.log(`  - PUT  /api/apikeys/:keyId/rules`);
      console.log(`  - DELETE /api/apikeys/:keyId`);
      console.log(`  - POST /api/apikeys/validate`);
      console.log(`  - GET  /api/apikeys/:keyId/quota`);
      console.log(`  - GET  /api/users`);
      console.log(`  - GET  /api/users/:userId`);
      console.log(`  - GET  /api/projects`);
      console.log(`  - POST /api/projects`);
      console.log(`  - GET  /api/analytics/summary`);
      console.log(`  - POST /api/moderate-content/text/v1`);
      console.log(`  - GET  /api/docs`);
      console.log(`\nPress Ctrl+C to stop the server\n`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n\nShutting down server gracefully...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n\nShutting down server gracefully...');
  process.exit(0);
});

// Start the server
startServer();
