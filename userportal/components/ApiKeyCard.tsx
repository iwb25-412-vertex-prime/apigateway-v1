'use client';

import { useState } from 'react';
import { ApiKey } from '@/lib/apikeys';
import { ManageRulesModal } from './ManageRulesModal';

interface ApiKeyCardProps {
  apiKey: ApiKey;
  onUpdateStatus: (keyId: string, status: 'active' | 'inactive') => Promise<void>;
  onDelete: (keyId: string) => Promise<void>;
  onUpdate: (updatedApiKey: ApiKey) => void;
}

export function ApiKeyCard({ apiKey, onUpdateStatus, onDelete, onUpdate }: ApiKeyCardProps) {
  const [isUpdating, setIsUpdating] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [showRulesModal, setShowRulesModal] = useState(false);

  const handleStatusToggle = async () => {
    if (isUpdating) return;
    
    setIsUpdating(true);
    try {
      const newStatus = apiKey.status === 'active' ? 'inactive' : 'active';
      await onUpdateStatus(apiKey.id, newStatus);
    } catch (error) {
      console.error('Failed to update status:', error);
    } finally {
      setIsUpdating(false);
    }
  };

  const handleDelete = async () => {
    if (isDeleting) return;
    
    setIsDeleting(true);
    try {
      await onDelete(apiKey.id);
    } catch (error) {
      console.error('Failed to delete API key:', error);
      setIsDeleting(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800';
      case 'inactive':
        return 'bg-yellow-100 text-yellow-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const usagePercentage = Math.round((apiKey.current_month_usage / apiKey.monthly_quota) * 100);
  const isQuotaExceeded = apiKey.current_month_usage >= apiKey.monthly_quota;

  return (
    <div className="bg-white border border-slate-200 rounded-lg p-4 shadow-sm">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <h3 className="text-lg font-semibold text-slate-900">{apiKey.name}</h3>
          {apiKey.description && (
            <p className="text-sm text-slate-600 mt-1">{apiKey.description}</p>
          )}
        </div>
        <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(apiKey.status)}`}>
          {apiKey.status === 'active' ? 'Active' : 'Inactive'}
        </span>
      </div>

      {/* Usage Stats */}
      <div className="mb-4">
        <div className="flex justify-between items-center mb-2">
          <span className="text-sm text-slate-600">Monthly Usage</span>
          <span className="text-sm font-medium text-slate-900">
            {apiKey.current_month_usage} / {apiKey.monthly_quota} requests
          </span>
        </div>
        
        <div className="w-full bg-slate-200 rounded-full h-2">
          <div
            className={`h-2 rounded-full transition-all duration-300 ${
              isQuotaExceeded ? 'bg-red-500' :
              usagePercentage >= 80 ? 'bg-orange-500' :
              'bg-green-500'
            }`}
            style={{ width: `${Math.min(usagePercentage, 100)}%` }}
          ></div>
        </div>
        
        <div className="flex justify-between items-center mt-2 text-xs text-slate-500">
          <span>{usagePercentage}% used</span>
          <span>Resets {formatDate(apiKey.quota_reset_date)}</span>
        </div>

        {isQuotaExceeded && (
          <div className="mt-2 p-2 bg-red-50 border border-red-200 rounded text-sm text-red-700">
            ⚠️ Monthly quota exceeded. API requests will be rejected until quota resets.
          </div>
        )}
      </div>

      {/* Key Info */}
      <div className="mb-4 p-3 bg-slate-50 rounded border-l-4 border-orange-400">
        <div className="flex items-center">
          <svg className="h-4 w-4 text-orange-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
          </svg>
          <div>
            <p className="text-sm text-slate-700">
              API key is hidden for security. Key ID: <code className="font-mono text-xs">{apiKey.id.substring(0, 8)}...</code>
            </p>
          </div>
        </div>
      </div>

      {/* Content Rules */}
      <div className="mb-4">
        <div className="flex items-center justify-between mb-2">
          <p className="text-sm font-medium text-slate-600">Content Rules:</p>
          {apiKey.status !== 'revoked' && (
            <button
              onClick={() => setShowRulesModal(true)}
              className="text-xs text-orange-600 hover:text-orange-800 font-medium"
            >
              Manage Rules
            </button>
          )}
        </div>
        {apiKey.rules && apiKey.rules.length > 0 ? (
          <div className="flex flex-wrap gap-1">
            {apiKey.rules.slice(0, 3).map((rule, index) => (
              <span
                key={index}
                className="px-2 py-1 bg-orange-100 text-orange-800 text-xs rounded"
              >
                {rule.replace(/-/g, ' ')}
              </span>
            ))}
            {apiKey.rules.length > 3 && (
              <span className="px-2 py-1 bg-slate-100 text-slate-600 text-xs rounded">
                +{apiKey.rules.length - 3} more
              </span>
            )}
          </div>
        ) : (
          <p className="text-xs text-slate-500 italic">No rules configured</p>
        )}
      </div>

      {/* Actions */}
      <div className="flex items-center justify-between pt-3 border-t border-slate-200">
        <div className="text-xs text-slate-500">
          Created {formatDate(apiKey.created_at)}
        </div>
        
        <div className="flex gap-2">
          {apiKey.status !== 'revoked' && (
            <button
              onClick={handleStatusToggle}
              disabled={isUpdating}
              className={`px-3 py-1 text-sm rounded transition-colors ${
                apiKey.status === 'active'
                  ? 'bg-orange-100 text-orange-800 hover:bg-orange-200'
                  : 'bg-green-100 text-green-800 hover:bg-green-200'
              } ${isUpdating ? 'opacity-50 cursor-not-allowed' : ''}`}
            >
              {isUpdating ? 'Updating...' : (apiKey.status === 'active' ? 'Disable' : 'Enable')}
            </button>
          )}
          
          <button
            onClick={handleDelete}
            disabled={isDeleting}
            className={`px-3 py-1 text-sm bg-red-100 text-red-800 hover:bg-red-200 rounded transition-colors ${
              isDeleting ? 'opacity-50 cursor-not-allowed' : ''
            }`}
          >
            {isDeleting ? 'Deleting...' : 'Delete'}
          </button>
        </div>
      </div>

      {/* Rules Management Modal */}
      {showRulesModal && (
        <ManageRulesModal
          apiKey={apiKey}
          onClose={() => setShowRulesModal(false)}
          onUpdate={onUpdate}
        />
      )}
    </div>
  );
}