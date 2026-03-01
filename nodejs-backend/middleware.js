// Authentication middleware
const { validateToken, hashToken } = require('./auth');
const { isTokenValid } = require('./database');

// Middleware to validate JWT token from request
function requireAuth(req, res, next) {
  try {
    // Get authorization header
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({ error: 'No authorization header' });
    }
    
    if (!authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Invalid authorization format' });
    }
    
    const token = authHeader.substring(7);
    
    // Validate token
    const payload = validateToken(token);
    
    // Check if token exists in database and is not revoked
    const tokenHash = hashToken(token);
    const valid = isTokenValid(tokenHash);
    
    if (!valid) {
      return res.status(401).json({ error: 'Token has been revoked or expired' });
    }
    
    // Attach user payload to request
    req.user = payload;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

module.exports = {
  requireAuth
};
