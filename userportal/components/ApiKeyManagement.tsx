'use client';

import { useState, useEffect } from 'react';
import { ApiKeyService, ApiKey, CreateApiKeyRequest } from '@/lib/apikeys';
import { CreateApiKeyModal } from './CreateApiKeyModal';
import { ApiKeyCard } from './ApiKeyCard';
import { useAuth } from '@/hooks/useAuth';

export function ApiKeyManagement() {
  const { isAuthenticated } = useAuth();
  const [apiKeys, setApiKeys] = useState<ApiKey[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);

  // Load API keys on component mount
  useEffect(() => {
    if (isAuthenticated) {
      loadApiKeys();
    }
  }, [isAuthenticated]);

  const loadApiKeys = async () => {
    try {
      setLoading(true);
      setError(null);
      const keys = await ApiKeyService.getApiKeys();
      setApiKeys(keys);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load API keys');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateApiKey = async (data: CreateApiKeyRequest) => {
    try {
      await ApiKeyService.createApiKey(data);
      setShowCreateModal(false);
      await loadApiKeys(); // Reload the list
    } catch (err) {
      throw err; // Let the modal handle the error
    }
  };

  const handleUpdateStatus = async (keyId: string, status: 'active' | 'inactive') => {
    try {
      await ApiKeyService.updateApiKeyStatus(keyId, status);
      await loadApiKeys(); // Reload the list
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update API key status');
    }
  };

  const handleDeleteApiKey = async (keyId: string) => {
    if (!confirm('Are you sure you want to delete this API key? This action cannot be undone.')) {
      return;
    }

    try {
      await ApiKeyService.deleteApiKey(keyId);
      await loadApiKeys(); // Reload the list
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete API key');
    }
  };

  if (!isAuthenticated) {
    return (
      <div className="text-center py-8">
        <p className="text-gray-600">Please log in to manage your API keys.</p>
      </div>
    );
  }

  const activeKeys = apiKeys.filter(key => key.status !== 'revoked');
  const canCreateMore = activeKeys.length < 3;

  return (
    <div className="max-w-4xl mx-auto p-6">
      <div className="mb-8">
        <div className="flex justify-between items-center mb-4">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">API Key Management</h1>
            <p className="text-gray-600 mt-2">
              Create and manage your API keys for programmatic access. Maximum 3 active keys allowed.
            </p>
          </div>
          <button
            onClick={() => setShowCreateModal(true)}
            disabled={!canCreateMore}
            className={`px-4 py-2 rounded-lg font-medium ${
              canCreateMore
                ? 'bg-blue-600 text-white hover:bg-blue-700'
                : 'bg-gray-300 text-gray-500 cursor-not-allowed'
            }`}
          >
            Create API Key
          </button>
        </div>

        {/* API Key Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div className="bg-white p-4 rounded-lg border">
            <div className="text-2xl font-bold text-blue-600">{activeKeys.length}</div>
            <div className="text-sm text-gray-600">Active Keys</div>
          </div>
          <div className="bg-white p-4 rounded-lg border">
            <div className="text-2xl font-bold text-green-600">
              {activeKeys.filter(key => key.status === 'active').length}
            </div>
            <div className="text-sm text-gray-600">Enabled Keys</div>
          </div>
          <div className="bg-white p-4 rounded-lg border">
            <div className="text-2xl font-bold text-orange-600">
              {activeKeys.reduce((sum, key) => sum + key.usage_count, 0)}
            </div>
            <div className="text-sm text-gray-600">Total Usage</div>
          </div>
        </div>

        {!canCreateMore && (
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-6">
            <div className="flex">
              <div className="flex-shrink-0">
                <svg className="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                </svg>
              </div>
              <div className="ml-3">
                <h3 className="text-sm font-medium text-yellow-800">
                  Maximum API Keys Reached
                </h3>
                <div className="mt-2 text-sm text-yellow-700">
                  <p>You have reached the maximum limit of 3 API keys. Delete an existing key to create a new one.</p>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Error Display */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
          <div className="flex">
            <div className="flex-shrink-0">
              <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
              </svg>
            </div>
            <div className="ml-3">
              <h3 className="text-sm font-medium text-red-800">Error</h3>
              <div className="mt-2 text-sm text-red-700">
                <p>{error}</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Loading State */}
      {loading ? (
        <div className="text-center py-8">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <p className="mt-2 text-gray-600">Loading API keys...</p>
        </div>
      ) : (
        <>
          {/* API Keys List */}
          {activeKeys.length === 0 ? (
            <div className="text-center py-12 bg-gray-50 rounded-lg">
              <svg className="mx-auto h-12 w-12 text-gray-400" stroke="currentColor" fill="none" viewBox="0 0 48 48">
                <path d="M34 40h10v-4a6 6 0 00-10.712-3.714M34 40H14m20 0v-4a9.971 9.971 0 00-.712-3.714M14 40H4v-4a6 6 0 0110.713-3.714M14 40v-4c0-1.313.253-2.566.713-3.714m0 0A9.971 9.971 0 0124 24c4.004 0 7.625 2.371 9.287 6.286" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" />
              </svg>
              <h3 className="mt-2 text-sm font-medium text-gray-900">No API keys</h3>
              <p className="mt-1 text-sm text-gray-500">Get started by creating your first API key.</p>
              {canCreateMore && (
                <div className="mt-6">
                  <button
                    onClick={() => setShowCreateModal(true)}
                    className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                  >
                    Create API Key
                  </button>
                </div>
              )}
            </div>
          ) : (
            <div className="grid gap-4">
              {activeKeys.map((apiKey) => (
                <ApiKeyCard
                  key={apiKey.id}
                  apiKey={apiKey}
                  onUpdateStatus={handleUpdateStatus}
                  onDelete={handleDeleteApiKey}
                />
              ))}
            </div>
          )}
        </>
      )}

      {/* Create API Key Modal */}
      {showCreateModal && (
        <CreateApiKeyModal
          onClose={() => setShowCreateModal(false)}
          onSubmit={handleCreateApiKey}
        />
      )}
    </div>
  );
}