// API Key management operations
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const { db } = require('./database');
const config = require('./config');

// API Key utility functions
function generateApiKey() {
  // Generate a secure API key with prefix
  const randomPart = crypto.randomBytes(16).toString('hex');
  return `ak_${randomPart}`;
}

function hashApiKey(apiKey) {
  return crypto
    .createHash('sha256')
    .update(apiKey + config.jwtSecret)
    .digest('hex');
}

// Calculate next month's first day for quota reset
function calculateNextMonthResetDate() {
  const now = new Date();
  const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  return nextMonth.toISOString().split('T')[0];
}

// ===== API KEY OPERATIONS =====

function createApiKey(userId, name, description, rules) {
  // Check if user already has 3 API keys
  const keyCount = getApiKeyCountForUser(userId);
  if (keyCount >= 3) {
    throw new Error('Maximum of 3 API keys allowed per user');
  }
  
  const apiKeyId = uuidv4();
  const apiKey = generateApiKey();
  const keyHash = hashApiKey(apiKey);
  const rulesJson = JSON.stringify(rules);
  const quotaResetDate = calculateNextMonthResetDate();
  
  const stmt = db.prepare(`
    INSERT INTO api_keys (id, user_id, name, key_hash, description, rules, status, usage_count, monthly_quota, current_month_usage, quota_reset_date)
    VALUES (?, ?, ?, ?, ?, ?, 'active', 0, 100, 0, ?)
  `);
  
  const result = stmt.run(apiKeyId, userId, name, keyHash, description, rulesJson, quotaResetDate);
  
  if (result.changes === 1) {
    const createdKey = getApiKeyById(apiKeyId);
    return [createdKey, apiKey];
  }
  
  throw new Error('Failed to create API key');
}

function getApiKeyCountForUser(userId) {
  const stmt = db.prepare(`
    SELECT COUNT(*) as count FROM api_keys 
    WHERE user_id = ? AND status != 'revoked'
  `);
  
  const result = stmt.get(userId);
  return result ? result.count : 0;
}

function getApiKeyById(keyId) {
  const stmt = db.prepare(`
    SELECT id, user_id, name, key_hash, description, rules, status, usage_count, monthly_quota, current_month_usage, quota_reset_date, created_at, updated_at
    FROM api_keys WHERE id = ?
  `);
  
  const result = stmt.get(keyId);
  
  if (!result) {
    throw new Error('API key not found');
  }
  
  result.rules = JSON.parse(result.rules);
  return result;
}

function getApiKeysByUserId(userId) {
  const stmt = db.prepare(`
    SELECT id, user_id, name, key_hash, description, rules, status, usage_count, monthly_quota, current_month_usage, quota_reset_date, created_at, updated_at
    FROM api_keys WHERE user_id = ? AND status != 'revoked'
    ORDER BY created_at DESC
  `);
  
  const results = stmt.all(userId);
  
  return results.map(row => {
    row.rules = JSON.parse(row.rules);
    return row;
  });
}

function validateApiKey(apiKey) {
  const keyHash = hashApiKey(apiKey);
  
  const stmt = db.prepare(`
    SELECT id, user_id, name, key_hash, description, rules, status, usage_count, monthly_quota, current_month_usage, quota_reset_date, created_at, updated_at
    FROM api_keys WHERE key_hash = ? AND status = 'active'
  `);
  
  const result = stmt.get(keyHash);
  
  if (!result) {
    throw new Error('Invalid API key');
  }
  
  result.rules = JSON.parse(result.rules);
  return result;
}

function incrementApiKeyUsage(keyId) {
  const stmt = db.prepare(`
    UPDATE api_keys 
    SET usage_count = usage_count + 1, current_month_usage = current_month_usage + 1, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `);
  
  stmt.run(keyId);
}

function updateApiKeyStatus(keyId, status) {
  const stmt = db.prepare(`
    UPDATE api_keys 
    SET status = ?, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `);
  
  const result = stmt.run(status, keyId);
  return result.changes > 0;
}

function updateApiKeyRules(keyId, userId, rules) {
  const rulesJson = JSON.stringify(rules);
  
  const stmt = db.prepare(`
    UPDATE api_keys 
    SET rules = ?, updated_at = CURRENT_TIMESTAMP
    WHERE id = ? AND user_id = ? AND status != 'revoked'
  `);
  
  const result = stmt.run(rulesJson, keyId, userId);
  
  if (result.changes === 0) {
    throw new Error('API key not found or access denied');
  }
}

function deleteApiKey(keyId, userId) {
  const stmt = db.prepare(`
    UPDATE api_keys 
    SET status = 'revoked', updated_at = CURRENT_TIMESTAMP
    WHERE id = ? AND user_id = ?
  `);
  
  const result = stmt.run(keyId, userId);
  return result.changes > 0;
}

function toApiKeyResponse(apiKey) {
  const remainingQuota = apiKey.monthly_quota - apiKey.current_month_usage;
  return {
    id: apiKey.id,
    name: apiKey.name,
    description: apiKey.description,
    rules: apiKey.rules,
    status: apiKey.status,
    usage_count: apiKey.usage_count,
    monthly_quota: apiKey.monthly_quota,
    current_month_usage: apiKey.current_month_usage,
    remaining_quota: remainingQuota < 0 ? 0 : remainingQuota,
    quota_reset_date: apiKey.quota_reset_date,
    created_at: apiKey.created_at,
    updated_at: apiKey.updated_at
  };
}

module.exports = {
  generateApiKey,
  hashApiKey,
  createApiKey,
  getApiKeyCountForUser,
  getApiKeyById,
  getApiKeysByUserId,
  validateApiKey,
  incrementApiKeyUsage,
  updateApiKeyStatus,
  updateApiKeyRules,
  deleteApiKey,
  toApiKeyResponse
};
