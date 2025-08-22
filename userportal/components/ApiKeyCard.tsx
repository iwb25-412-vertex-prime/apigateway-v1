'use client';

import { useState } from 'react';
import { ApiKey } from '@/lib/apikeys';

interface ApiKeyCardProps {
  apiKey: ApiKey;
  onUpdateStatus: (keyId: string, status: 'active' | 'inactive') => Promise<void>;
  onDelete: (keyId: string) => Promise<void>;
}

export function ApiKeyCard({ apiKey, onUpdateStatus, onDelete }: ApiKeyCardProps) {
  const [isUpdating, setIsUpdating] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

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
      case 'revoked':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  return (
    <div className="bg-white border border-gray-200 rounded-lg p-6 shadow-sm hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <div className="flex items-center gap-3 mb-2">
            <h3 className="text-lg font-semibold text-gray-900">{apiKey.name}</h3>
            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(apiKey.status)}`}>
              {apiKey.status.charAt(0).toUpperCase() + apiKey.status.slice(1)}
            </span>
          </div>
          
          {apiKey.description && (
            <p className="text-gray-600 mb-3">{apiKey.description}</p>
          )}

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
            <div>
              <dt className="text-sm font-medium text-gray-500">Usage Count</dt>
              <dd className="text-lg font-semibold text-gray-900">{apiKey.usage_count}</dd>
            </div>
            <div>
              <dt className="text-sm font-medium text-gray-500">Created</dt>
              <dd className="text-sm text-gray-900">{formatDate(apiKey.created_at)}</dd>
            </div>
            <div>
              <dt className="text-sm font-medium text-gray-500">Last Updated</dt>
              <dd className="text-sm text-gray-900">{formatDate(apiKey.updated_at)}</dd>
            </div>
          </div>

          {apiKey.rules && apiKey.rules.length > 0 && (
            <div className="mb-4">
              <dt className="text-sm font-medium text-gray-500 mb-2">Permissions</dt>
              <div className="flex flex-wrap gap-2">
                {apiKey.rules.map((rule, index) => (
                  <span
                    key={index}
                    className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
                  >
                    {rule}
                  </span>
                ))}
              </div>
            </div>
          )}

          <div className="mb-4">
            <dt className="text-sm font-medium text-gray-500 mb-2">API Key Hash</dt>
            <div className="bg-gray-50 p-3 rounded-md">
              <code className="text-sm text-gray-800 font-mono break-all">
                {apiKey.key_hash}
              </code>
            </div>
          </div>
        </div>
      </div>

      <div className="flex items-center justify-between pt-4 border-t border-gray-200">
        <div className="flex items-center gap-2">
          {apiKey.status !== 'revoked' && (
            <button
              onClick={handleStatusToggle}
              disabled={isUpdating}
              className={`px-3 py-1.5 text-sm font-medium rounded-md transition-colors ${
                apiKey.status === 'active'
                  ? 'bg-yellow-100 text-yellow-800 hover:bg-yellow-200'
                  : 'bg-green-100 text-green-800 hover:bg-green-200'
              } ${isUpdating ? 'opacity-50 cursor-not-allowed' : ''}`}
            >
              {isUpdating ? (
                <div className="flex items-center gap-2">
                  <div className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin"></div>
                  Updating...
                </div>
              ) : (
                apiKey.status === 'active' ? 'Disable' : 'Enable'
              )}
            </button>
          )}
        </div>

        <button
          onClick={handleDelete}
          disabled={isDeleting}
          className={`px-3 py-1.5 text-sm font-medium rounded-md bg-red-100 text-red-800 hover:bg-red-200 transition-colors ${
            isDeleting ? 'opacity-50 cursor-not-allowed' : ''
          }`}
        >
          {isDeleting ? (
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin"></div>
              Deleting...
            </div>
          ) : (
            'Delete'
          )}
        </button>
      </div>
    </div>
  );
}