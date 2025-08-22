'use client';

import { useState } from 'react';
import { CreateApiKeyRequest, CreateApiKeyResponse, ApiKeyService } from '@/lib/apikeys';

interface CreateApiKeyModalProps {
  onClose: () => void;
  onSubmit: (data: CreateApiKeyRequest) => Promise<void>;
}

const COMMON_RULES = [
  'read',
  'write',
  'delete',
  'analytics',
  'admin',
  'user_management',
  'api_access',
  'data_export',
  'reporting',
  'monitoring'
];

export function CreateApiKeyModal({ onClose, onSubmit }: CreateApiKeyModalProps) {
  const [formData, setFormData] = useState<CreateApiKeyRequest>({
    name: '',
    description: '',
    rules: []
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [createdApiKey, setCreatedApiKey] = useState<CreateApiKeyResponse | null>(null);
  const [customRule, setCustomRule] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.name.trim()) {
      setError('API key name is required');
      return;
    }

    if (formData.name.length > 100) {
      setError('API key name must be 100 characters or less');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      const result = await ApiKeyService.createApiKey(formData);
      setCreatedApiKey(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create API key');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleRuleToggle = (rule: string) => {
    setFormData(prev => ({
      ...prev,
      rules: prev.rules.includes(rule)
        ? prev.rules.filter(r => r !== rule)
        : [...prev.rules, rule]
    }));
  };

  const handleAddCustomRule = () => {
    const rule = customRule.trim();
    if (rule && !formData.rules.includes(rule)) {
      setFormData(prev => ({
        ...prev,
        rules: [...prev.rules, rule]
      }));
      setCustomRule('');
    }
  };

  const handleRemoveRule = (rule: string) => {
    setFormData(prev => ({
      ...prev,
      rules: prev.rules.filter(r => r !== rule)
    }));
  };

  const handleClose = () => {
    if (createdApiKey) {
      // If API key was created successfully, trigger parent refresh
      onSubmit(formData).catch(() => {}); // Ignore errors, just refresh
    }
    onClose();
  };

  // If API key was created successfully, show the success screen
  if (createdApiKey) {
    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
        <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
          <div className="p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-semibold text-gray-900">API Key Created Successfully!</h2>
              <button
                onClick={handleClose}
                className="text-gray-400 hover:text-gray-600"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <div className="bg-green-50 border border-green-200 rounded-lg p-4 mb-6">
              <div className="flex">
                <div className="flex-shrink-0">
                  <svg className="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                  </svg>
                </div>
                <div className="ml-3">
                  <h3 className="text-sm font-medium text-green-800">
                    Your API key has been created successfully!
                  </h3>
                  <div className="mt-2 text-sm text-green-700">
                    <p>Please copy and save your API key now. You won't be able to see it again.</p>
                  </div>
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  API Key Name
                </label>
                <div className="bg-gray-50 p-3 rounded-md">
                  <span className="text-gray-900 font-medium">{createdApiKey.apiKey.name}</span>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Your API Key
                </label>
                <div className="bg-gray-50 p-3 rounded-md border-2 border-blue-200">
                  <code className="text-sm text-gray-900 font-mono break-all select-all">
                    {createdApiKey.apiKey.key}
                  </code>
                </div>
                <p className="text-xs text-gray-500 mt-1">
                  Click to select all, then copy this key. Store it securely.
                </p>
              </div>

              {createdApiKey.apiKey.description && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Description
                  </label>
                  <div className="bg-gray-50 p-3 rounded-md">
                    <span className="text-gray-900">{createdApiKey.apiKey.description}</span>
                  </div>
                </div>
              )}

              {createdApiKey.apiKey.rules.length > 0 && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Permissions
                  </label>
                  <div className="flex flex-wrap gap-2">
                    {createdApiKey.apiKey.rules.map((rule, index) => (
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
            </div>

            <div className="flex justify-end pt-6 border-t border-gray-200 mt-6">
              <button
                onClick={handleClose}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium"
              >
                Done
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <form onSubmit={handleSubmit} className="p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold text-gray-900">Create New API Key</h2>
            <button
              type="button"
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

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

          <div className="space-y-6">
            <div>
              <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-2">
                API Key Name *
              </label>
              <input
                type="text"
                id="name"
                value={formData.name}
                onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="e.g., Development Key, Production API, Mobile App"
                maxLength={100}
                required
              />
              <p className="text-xs text-gray-500 mt-1">
                Choose a descriptive name to identify this API key ({formData.name.length}/100)
              </p>
            </div>

            <div>
              <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-2">
                Description (Optional)
              </label>
              <textarea
                id="description"
                value={formData.description}
                onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                rows={3}
                placeholder="Describe what this API key will be used for..."
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-3">
                Permissions (Optional)
              </label>
              
              <div className="space-y-4">
                <div>
                  <h4 className="text-sm font-medium text-gray-600 mb-2">Common Permissions</h4>
                  <div className="grid grid-cols-2 md:grid-cols-3 gap-2">
                    {COMMON_RULES.map((rule) => (
                      <label key={rule} className="flex items-center">
                        <input
                          type="checkbox"
                          checked={formData.rules.includes(rule)}
                          onChange={() => handleRuleToggle(rule)}
                          className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                        />
                        <span className="ml-2 text-sm text-gray-700">{rule}</span>
                      </label>
                    ))}
                  </div>
                </div>

                <div>
                  <h4 className="text-sm font-medium text-gray-600 mb-2">Add Custom Permission</h4>
                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={customRule}
                      onChange={(e) => setCustomRule(e.target.value)}
                      className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                      placeholder="Enter custom permission"
                      onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddCustomRule())}
                    />
                    <button
                      type="button"
                      onClick={handleAddCustomRule}
                      className="px-3 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200"
                    >
                      Add
                    </button>
                  </div>
                </div>

                {formData.rules.length > 0 && (
                  <div>
                    <h4 className="text-sm font-medium text-gray-600 mb-2">Selected Permissions</h4>
                    <div className="flex flex-wrap gap-2">
                      {formData.rules.map((rule) => (
                        <span
                          key={rule}
                          className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
                        >
                          {rule}
                          <button
                            type="button"
                            onClick={() => handleRemoveRule(rule)}
                            className="ml-1 text-blue-600 hover:text-blue-800"
                          >
                            ×
                          </button>
                        </span>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>

          <div className="flex justify-end gap-3 pt-6 border-t border-gray-200 mt-6">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 font-medium"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting || !formData.name.trim()}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSubmitting ? (
                <div className="flex items-center gap-2">
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                  Creating...
                </div>
              ) : (
                'Create API Key'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}