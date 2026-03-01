// Authentication routes
const express = require('express');
const router = express.Router();
const {
  hashPassword,
  checkPassword,
  generateToken,
  isValidEmail,
  isValidPassword,
  toUserResponse,
  hashToken
} = require('../auth');
const {
  createUser,
  getUserByUsername,
  getUserByEmail,
  getUserById,
  storeJWTToken,
  revokeToken
} = require('../database');
const { requireAuth } = require('../middleware');
const config = require('../config');

// Register new user
router.post('/register', (req, res) => {
  try {
    const { username, email, password } = req.body;
    
    // Validate input
    if (!username || !email || !password) {
      return res.status(400).json({ error: 'Missing required fields: username, email, password' });
    }
    
    if (username.length < 3 || username.length > 50) {
      return res.status(400).json({ error: 'Username must be between 3 and 50 characters' });
    }
    
    if (!isValidEmail(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }
    
    if (!isValidPassword(password)) {
      return res.status(400).json({ error: 'Password must be at least 8 characters long' });
    }
    
    // Check if user already exists
    const existingUserByUsername = getUserByUsername(username);
    if (existingUserByUsername) {
      return res.status(409).json({ error: 'Username already exists' });
    }
    
    const existingUserByEmail = getUserByEmail(email);
    if (existingUserByEmail) {
      return res.status(409).json({ error: 'Email already exists' });
    }
    
    // Create user
    const passwordHash = hashPassword(password);
    const newUser = createUser(username, email, passwordHash);
    
    console.log('User registered successfully:', username);
    res.status(201).json({
      message: 'User registered successfully',
      user: toUserResponse(newUser)
    });
  } catch (error) {
    console.error('Failed to create user:', error);
    res.status(500).json({ error: 'Failed to create user' });
  }
});

// Login user
router.post('/login', (req, res) => {
  try {
    const { username, password } = req.body;
    
    // Validate input
    if (!username || !password) {
      return res.status(400).json({ error: 'Missing username or password' });
    }
    
    // Find user
    const user = getUserByUsername(username);
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    // Verify password
    const passwordValid = checkPassword(password, user.password_hash);
    if (!passwordValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    // Generate token
    const token = generateToken(user);
    
    // Hash token for storage
    const tokenHash = hashToken(token);
    
    // Store token in database
    const expiresAt = new Date(Date.now() + config.jwtExpiryTime * 1000).toISOString();
    storeJWTToken(user.id, tokenHash, expiresAt);
    
    console.log('User logged in successfully:', username);
    res.json({
      token,
      message: 'Login successful',
      user: toUserResponse(user),
      expiresIn: config.jwtExpiryTime
    });
  } catch (error) {
    console.error('Failed to login:', error);
    res.status(500).json({ error: 'Failed to login' });
  }
});

// Get user profile
router.get('/profile', requireAuth, (req, res) => {
  try {
    const userId = req.user.userId;
    const user = getUserById(userId);
    
    if (!user) {
      return res.status(401).json({ error: 'User not found' });
    }
    
    res.json({
      user: toUserResponse(user),
      message: 'Profile retrieved successfully'
    });
  } catch (error) {
    console.error('Failed to get profile:', error);
    res.status(500).json({ error: 'Failed to get profile' });
  }
});

// Logout user
router.post('/logout', (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      const tokenHash = hashToken(token);
      revokeToken(tokenHash);
    }
    
    res.json({ message: 'Logout successful' });
  } catch (error) {
    console.error('Failed to logout:', error);
    res.json({ message: 'Logout successful' });
  }
});

module.exports = router;
