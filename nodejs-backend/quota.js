// Quota management system for API keys
const { db } = require('./database');
const { getApiKeyById, incrementApiKeyUsage, validateApiKey } = require('./apikeys');

// Calculate next month's first day for quota reset
function calculateNextMonthResetDate() {
  const now = new Date();
  const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  return nextMonth.toISOString().split('T')[0];
}

function checkQuotaLimit(apiKey) {
  const currentDate = new Date();
  const resetDate = new Date(apiKey.quota_reset_date + 'T00:00:00Z');
  
  // If current date is past the reset date, reset the quota
  if (currentDate >= resetDate) {
    resetMonthlyQuota(apiKey.id);
    return true; // After reset, quota is available
  }
  
  // Check if current usage is within quota
  return apiKey.current_month_usage < apiKey.monthly_quota;
}

function resetMonthlyQuota(keyId) {
  const quotaResetDate = calculateNextMonthResetDate();
  
  const stmt = db.prepare(`
    UPDATE api_keys 
    SET current_month_usage = 0, quota_reset_date = ?, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `);
  
  stmt.run(quotaResetDate, keyId);
}

function validateApiKeyWithQuota(apiKey) {
  const validatedKey = validateApiKey(apiKey);
  const quotaAvailable = checkQuotaLimit(validatedKey);
  return [validatedKey, quotaAvailable];
}

// Function to fix existing API keys with incorrect quota reset dates
function fixExistingApiKeyQuotas() {
  const correctResetDate = calculateNextMonthResetDate();
  
  const stmt = db.prepare(`
    UPDATE api_keys 
    SET current_month_usage = 0, 
        quota_reset_date = ?,
        updated_at = CURRENT_TIMESTAMP
    WHERE quota_reset_date LIKE '2025%' OR current_month_usage >= monthly_quota
  `);
  
  stmt.run(correctResetDate);
}

// Function to refresh quota status for all API keys
function refreshAllApiKeyQuotas() {
  const stmt = db.prepare(`
    SELECT id, quota_reset_date, current_month_usage, monthly_quota
    FROM api_keys WHERE status = 'active'
  `);
  
  const apiKeys = stmt.all();
  const currentDate = new Date();
  
  apiKeys.forEach(apiKey => {
    const resetDate = new Date(apiKey.quota_reset_date + 'T00:00:00Z');
    
    // If current date is past the reset date, reset the quota
    if (currentDate >= resetDate) {
      resetMonthlyQuota(apiKey.id);
    }
  });
}

module.exports = {
  checkQuotaLimit,
  resetMonthlyQuota,
  validateApiKeyWithQuota,
  fixExistingApiKeyQuotas,
  refreshAllApiKeyQuotas
};
