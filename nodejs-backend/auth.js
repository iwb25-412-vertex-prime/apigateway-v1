// Authentication utilities and token management
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const config = require('./config');
const { storeJWTToken, isTokenValid } = require('./database');

// Password hashing
function hashPassword(password) {
  return bcrypt.hashSync(password, 10);
}

function checkPassword(password, hash) {
  return bcrypt.compareSync(password, hash);
}

// Token generation and validation
function generateToken(user) {
  const currentTime = Math.floor(Date.now() / 1000);
  const expiryTime = currentTime + config.jwtExpiryTime;
  
  // Create a simple token with user info and expiry
  const tokenData = `${user.id}|${user.username}|${user.email}|${expiryTime}`;
  const signature = crypto
    .createHash('sha256')
    .update(tokenData + config.jwtSecret)
    .digest('hex');
  
  return `${tokenData}|${signature}`;
}

function validateToken(token) {
  const parts = token.split('|');
  if (parts.length !== 5) {
    throw new Error('Invalid token format');
  }
  
  const [userId, username, email, expStr, providedSignature] = parts;
  
  // Reconstruct token data for signature verification
  const tokenData = `${userId}|${username}|${email}|${expStr}`;
  const expectedSignature = crypto
    .createHash('sha256')
    .update(tokenData + config.jwtSecret)
    .digest('hex');
  
  if (expectedSignature !== providedSignature) {
    throw new Error('Invalid token signature');
  }
  
  // Check expiry
  const exp = parseInt(expStr);
  const currentTime = Math.floor(Date.now() / 1000);
  if (exp < currentTime) {
    throw new Error('Token expired');
  }
  
  // Return payload
  return {
    userId,
    username,
    email,
    exp,
    iss: config.jwtIssuer,
    aud: config.jwtAudience
  };
}

// Helper to extract user ID from token payload
function extractUserId(payload) {
  if (!payload.userId) {
    throw new Error('Invalid token claims');
  }
  return payload.userId;
}

// Validation utilities
function isValidEmail(email) {
  const emailPattern = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  return emailPattern.test(email);
}

function isValidPassword(password) {
  return password.length >= 8;
}

// Helper to convert user to response (remove sensitive data)
function toUserResponse(user) {
  return {
    id: user.id,
    username: user.username,
    email: user.email,
    created_at: user.created_at,
    updated_at: user.updated_at,
    is_active: Boolean(user.is_active)
  };
}

// Hash token for storage
function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

module.exports = {
  hashPassword,
  checkPassword,
  generateToken,
  validateToken,
  extractUserId,
  isValidEmail,
  isValidPassword,
  toUserResponse,
  hashToken
};
