// API Key management routes
const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware');
const {
  createApiKey,
  getApiKeyById,
  getApiKeysByUserId,
  updateApiKeyStatus,
  updateApiKeyRules,
  deleteApiKey,
  toApiKeyResponse,
  incrementApiKeyUsage
} = require('../apikeys');
const {
  checkQuotaLimit,
  refreshAllApiKeyQuotas,
  validateApiKeyWithQuota
} = require('../quota');

// Create new API key
router.post('/', requireAuth, (req, res) => {
  try {
    const userId = req.user.userId;
    const { name, description } = req.body;
    
    // Validate input
    if (!name || name.length < 1 || name.length > 100) {
      return res.status(400).json({ error: 'API key name must be between 1 and 100 characters' });
    }
    
    const rules = ['full_access']; // All keys have full access
    
    // Create API key
    const [apiKey, plainKey] = createApiKey(userId, name, description, rules);
    
    console.log('API key created successfully for user:', userId);
    res.status(201).json({
      message: 'API key created successfully',
      apiKey: toApiKeyResponse(apiKey),
      key: plainKey // Only returned once during creation
    });
  } catch (error) {
    console.error('Failed to create API key:', error);
    if (error.message.includes('Maximum of 3 API keys')) {
      return res.status(400).json({ error: error.message });
    }
    res.status(500).json({ error: 'Failed to create API key' });
  }
});

// Get all API keys for user
router.get('/', requireAuth, (req, res) => {
  try {
    const userId = req.user.userId;
    
    // Refresh quota status for all API keys before returning data
    refreshAllApiKeyQuotas();
    
    // Get user's API keys
    const apiKeys = getApiKeysByUserId(userId);
    
    const responseKeys = apiKeys.map(key => toApiKeyResponse(key));
    
    res.json({
      apiKeys: responseKeys,
      count: responseKeys.length,
      maxAllowed: 3
    });
  } catch (error) {
    console.error('Failed to get API keys:', error);
    res.status(500).json({ error: 'Failed to retrieve API keys' });
  }
});

// Update API key status
router.put('/:keyId/status', requireAuth, (req, res) => {
  try {
    const userId = req.user.userId;
    const { keyId } = req.params;
    const { status } = req.body;
    
    // Validate status
    if (!status) {
      return res.status(400).json({ error: 'Status field is required' });
    }
    
    if (status !== 'active' && status !== 'inactive') {
      return res.status(400).json({ error: "Status must be 'active' or 'inactive'" });
    }
    
    // Verify the API key belongs to the user
    const apiKey = getApiKeyById(keyId);
    if (apiKey.user_id !== userId) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    // Update status
    updateApiKeyStatus(keyId, status);
    
    res.json({ message: 'API key status updated successfully' });
  } catch (error) {
    console.error('Failed to update API key status:', error);
    if (error.message === 'API key not found') {
      return res.status(404).json({ error: 'API key not found' });
    }
    res.status(500).json({ error: 'Failed to update API key status' });
  }
});

// Update API key rules
router.put('/:keyId/rules', requireAuth, (req, res) => {
  try {
    const userId = req.user.userId;
    const { keyId } = req.params;
    const { rules } = req.body;
    
    if (!rules || !Array.isArray(rules)) {
      return res.status(400).json({ error: 'Rules must be an array' });
    }
    
    // Verify the API key belongs to the user and is not revoked
    const apiKey = getApiKeyById(keyId);
    
    if (apiKey.user_id !== userId) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    if (apiKey.status === 'revoked') {
      return res.status(400).json({ error: 'Cannot update rules for revoked API key' });
    }
    
    // Update rules
    updateApiKeyRules(keyId, userId, rules);
    
    // Get updated API key data
    const updatedKey = getApiKeyById(keyId);
    
    console.log('API key rules updated successfully for key:', keyId);
    res.json({
      message: 'API key rules updated successfully',
      apiKey: toApiKeyResponse(updatedKey)
    });
  } catch (error) {
    console.error('Failed to update API key rules:', error);
    if (error.message === 'API key not found') {
      return res.status(404).json({ error: 'API key not found' });
    }
    res.status(500).json({ error: 'Failed to update API key rules' });
  }
});

// Delete (revoke) API key
router.delete('/:keyId', requireAuth, (req, res) => {
  try {
    const userId = req.user.userId;
    const { keyId } = req.params;
    
    // Delete (revoke) API key
    const deleted = deleteApiKey(keyId, userId);
    
    if (!deleted) {
      return res.status(404).json({ error: 'API key not found or access denied' });
    }
    
    res.json({ message: 'API key deleted successfully' });
  } catch (error) {
    console.error('Failed to delete API key:', error);
    res.status(500).json({ error: 'Failed to delete API key' });
  }
});

// Validate API key (for testing)
router.post('/validate', (req, res) => {
  try {
    const { apiKey } = req.body;
    
    if (!apiKey) {
      return res.status(400).json({ error: 'API key is required' });
    }
    
    const [validatedKey, quotaAvailable] = validateApiKeyWithQuota(apiKey);
    
    if (!quotaAvailable) {
      return res.status(429).json({
        error: 'Monthly quota exceeded',
        message: `You have exceeded your monthly quota of 100 requests. Quota resets on: ${validatedKey.quota_reset_date}`,
        apiKey: toApiKeyResponse(validatedKey)
      });
    }
    
    // Increment usage count
    incrementApiKeyUsage(validatedKey.id);
    
    // Get updated key data after incrementing usage
    const updatedKey = getApiKeyById(validatedKey.id);
    
    res.json({
      valid: true,
      apiKey: toApiKeyResponse(updatedKey),
      message: 'API key is valid'
    });
  } catch (error) {
    console.error('Failed to validate API key:', error);
    res.status(401).json({ error: 'Invalid API key' });
  }
});

// Get quota status for specific API key
router.get('/:keyId/quota', requireAuth, (req, res) => {
  try {
    const userId = req.user.userId;
    const { keyId } = req.params;
    
    // Get API key and verify ownership
    const apiKey = getApiKeyById(keyId);
    
    if (apiKey.user_id !== userId) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    // Check if quota needs reset
    const quotaAvailable = checkQuotaLimit(apiKey);
    
    // Get updated key data after potential quota reset
    const updatedKey = getApiKeyById(keyId);
    
    const remainingQuota = updatedKey.monthly_quota - updatedKey.current_month_usage;
    
    res.json({
      keyId,
      monthlyQuota: updatedKey.monthly_quota,
      currentMonthUsage: updatedKey.current_month_usage,
      remainingQuota: remainingQuota < 0 ? 0 : remainingQuota,
      quotaResetDate: updatedKey.quota_reset_date,
      quotaAvailable,
      status: updatedKey.status
    });
  } catch (error) {
    console.error('Failed to get quota status:', error);
    if (error.message === 'API key not found') {
      return res.status(404).json({ error: 'API key not found' });
    }
    res.status(500).json({ error: 'Failed to get quota status' });
  }
});

module.exports = router;
