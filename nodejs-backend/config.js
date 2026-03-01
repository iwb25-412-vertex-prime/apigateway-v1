// Configuration module
require('dotenv').config();

module.exports = {
  // Server configuration
  port: process.env.PORT || 8080,
  nodeEnv: process.env.NODE_ENV || 'development',
  
  // Database configuration
  dbPath: process.env.DB_PATH || './database/userportal.db',
  
  // JWT configuration
  jwtSecret: process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production-min-32-chars',
  jwtExpiryTime: parseInt(process.env.JWT_EXPIRY_TIME) || 3600,
  jwtIssuer: process.env.JWT_ISSUER || 'userportal-auth',
  jwtAudience: process.env.JWT_AUDIENCE || 'userportal-users',
  
  // CORS configuration
  corsOrigins: process.env.CORS_ORIGINS 
    ? process.env.CORS_ORIGINS.split(',') 
    : ['http://localhost:3000', 'http://localhost:3001']
};
