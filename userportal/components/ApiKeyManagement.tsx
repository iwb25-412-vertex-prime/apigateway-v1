"use client";

import { useState, useEffect } from "react";
import {
  ApiKeyService,
  ApiKey,
  CreateApiKeyRequest,
  CreateApiKeyResponse,
} from "@/lib/apikeys";
import { CreateApiKeyModal } from "./CreateApiKeyModal";
import { ApiKeyCard } from "./ApiKeyCard";
import { useAuth } from "@/hooks/useAuth";

export function ApiKeyManagement() {
  const { isAuthenticated } = useAuth();
  const [apiKeys, setApiKeys] = useState<ApiKey[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);

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
      setError(err instanceof Error ? err.message : "Failed to load API keys");
    } finally {
      setLoading(false);
    }
  };

  const handleCreateApiKey = async (
    data: CreateApiKeyRequest
  ): Promise<CreateApiKeyResponse | void> => {
    try {
      const result = await ApiKeyService.createApiKey(data);
      await loadApiKeys();
      return result || undefined;
    } catch (err) {
      throw err;
    }
  };

  const handleUpdateStatus = async (
    keyId: string,
    status: "active" | "inactive"
  ) => {
    try {
      await ApiKeyService.updateApiKeyStatus(keyId, status);
      await loadApiKeys();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to update API key status"
      );
    }
  };

  const handleDeleteApiKey = async (keyId: string) => {
    if (
      !confirm(
        "Are you sure you want to delete this API key? This action cannot be undone."
      )
    ) {
      return;
    }

    try {
      await ApiKeyService.deleteApiKey(keyId);
      await loadApiKeys();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to delete API key");
    }
  };

  const handleUpdateApiKey = (updatedApiKey: ApiKey) => {
    setApiKeys(prev => 
      prev.map(key => 
        key.id === updatedApiKey.id ? updatedApiKey : key
      )
    );
  };

  if (!isAuthenticated) {
    return (
      <div className="text-center py-8">
        <p className="text-gray-600">Please log in to manage your API keys.</p>
      </div>
    );
  }

  const activeKeys = apiKeys.filter((key) => key.status !== "revoked");
  const canCreateMore = activeKeys.length < 3;

  return (
    <div className="max-w-4xl mx-auto p-6">
      {/* Simple Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-slate-900 mb-2">API Keys</h1>
        <p className="text-slate-600 mb-4">
          Create and manage your API keys. You can have up to 3 active keys with 100 free requests each per month.
        </p>
        
        <button
          onClick={() => setShowCreateModal(true)}
          disabled={!canCreateMore}
          className={`px-4 py-2 rounded-lg font-medium transition-colors flex items-center gap-2 ${
            canCreateMore
              ? "bg-orange-600 text-white hover:bg-orange-700"
              : "bg-slate-300 text-slate-500 cursor-not-allowed"
          }`}
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
          </svg>
          Create New Key
        </button>
      </div>

      {/* Alerts */}
      {!canCreateMore && (
        <div className="bg-orange-50 border-l-4 border-orange-400 p-4 mb-6">
          <p className="text-orange-800">
            <strong>Limit reached:</strong> You have 3/3 API keys. Delete one to create a new key.
          </p>
        </div>
      )}

      {error && (
        <div className="bg-red-50 border-l-4 border-red-400 p-4 mb-6">
          <p className="text-red-800">
            <strong>Error:</strong> {error}
          </p>
        </div>
      )}

      {/* Content */}
      {loading ? (
        <div className="text-center py-8">
          <div className="inline-block animate-spin rounded-full h-6 w-6 border-b-2 border-orange-600"></div>
          <p className="mt-2 text-slate-600">Loading...</p>
        </div>
      ) : activeKeys.length === 0 ? (
        <div className="text-center py-12 bg-slate-50 rounded-lg">
          <svg className="mx-auto h-12 w-12 text-slate-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
          </svg>
          <h3 className="text-lg font-medium text-slate-900 mb-2">No API keys yet</h3>
          <p className="text-slate-500 mb-4">Create your first API key to get started.</p>
          {canCreateMore && (
            <button
              onClick={() => setShowCreateModal(true)}
              className="px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700"
            >
              Create API Key
            </button>
          )}
        </div>
      ) : (
        <div className="space-y-4">
          {activeKeys.map((apiKey) => (
            <ApiKeyCard
              key={apiKey.id}
              apiKey={apiKey}
              onUpdateStatus={handleUpdateStatus}
              onDelete={handleDeleteApiKey}
              onUpdate={handleUpdateApiKey}
            />
          ))}
        </div>
      )}

      {/* Modal */}
      {showCreateModal && (
        <CreateApiKeyModal
          onClose={() => setShowCreateModal(false)}
          onSubmit={handleCreateApiKey}
        />
      )}
    </div>
  );
}
