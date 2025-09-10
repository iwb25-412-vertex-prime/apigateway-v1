"use client";

import { useState } from "react";
import {
  CreateApiKeyRequest,
  CreateApiKeyResponse,
} from "@/lib/apikeys";

interface CreateApiKeyModalProps {
  onClose: () => void;
  onSubmit: (data: CreateApiKeyRequest) => Promise<CreateApiKeyResponse | void>;
}

const COMMON_CONTENT_POLICIES = [
  "no-selling-products",
  "no-adult-content",
  "no-hate-speech",
  "no-spam-content",
  "no-violence-content",
  "no-misinformation",
  "no-personal-data",
  "no-copyrighted-content",
  "family-friendly-only",
  "professional-content-only",
];

export function CreateApiKeyModal({
  onClose,
  onSubmit,
}: CreateApiKeyModalProps) {
  const [formData, setFormData] = useState<CreateApiKeyRequest>({
    name: "",
    description: "",
    rules: [],
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [createdApiKey, setCreatedApiKey] =
    useState<CreateApiKeyResponse | null>(null);
  const [customRule, setCustomRule] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!formData.name.trim()) {
      setError("API key name is required");
      return;
    }

    if (formData.name.length > 100) {
      setError("API key name must be 100 characters or less");
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      const result = await onSubmit(formData);
      if (result) {
        setCreatedApiKey(result);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to create API key");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleRuleToggle = (rule: string) => {
    setFormData((prev) => ({
      ...prev,
      rules: prev.rules.includes(rule)
        ? prev.rules.filter((r) => r !== rule)
        : [...prev.rules, rule],
    }));
  };

  const handleAddCustomRule = () => {
    const rule = customRule.trim();
    if (rule && !formData.rules.includes(rule)) {
      setFormData((prev) => ({
        ...prev,
        rules: [...prev.rules, rule],
      }));
      setCustomRule("");
    }
  };

  const handleRemoveRule = (rule: string) => {
    setFormData((prev) => ({
      ...prev,
      rules: prev.rules.filter((r) => r !== rule),
    }));
  };

  const handleClose = () => {
    onClose();
  };

  // If API key was created successfully, show the success screen
  if (createdApiKey) {
    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
        <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
          <div className="p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-semibold text-slate-900">
                API Key Created Successfully!
              </h2>
              <button
                onClick={handleClose}
                className="text-gray-400 hover:text-gray-600"
              >
                <svg
                  className="w-6 h-6"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>

            <div className="bg-green-50 border border-green-200 rounded-lg p-4 mb-6">
              <div className="flex">
                <div className="flex-shrink-0">
                  <svg
                    className="h-5 w-5 text-green-400"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                  >
                    <path
                      fillRule="evenodd"
                      d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                      clipRule="evenodd"
                    />
                  </svg>
                </div>
                <div className="ml-3">
                  <h3 className="text-sm font-medium text-green-800">
                    Your API key has been created successfully!
                  </h3>
                  <div className="mt-2 text-sm text-green-700">
                    <p>
                      Please copy and save your API key now. You won&apos;t be able
                      to see it again.
                    </p>
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
                  <span className="text-gray-900 font-medium">
                    {createdApiKey.apiKey.name}
                  </span>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Your API Key
                </label>
                <div className="bg-yellow-50 border-2 border-yellow-300 rounded-md p-4">
                  <div className="flex items-center mb-2">
                    <svg
                      className="h-5 w-5 text-yellow-600 mr-2"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path
                        fillRule="evenodd"
                        d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                        clipRule="evenodd"
                      />
                    </svg>
                    <span className="text-sm font-medium text-yellow-800">
                      IMPORTANT: Save this key now!
                    </span>
                  </div>
                  <div className="relative">
                    <code 
                      id="api-key-display"
                      className="text-sm text-gray-900 font-mono break-all select-all bg-white p-3 rounded border block pr-12"
                    >
                      {createdApiKey.key || 'API key not available'}
                    </code>
                    <button
                      onClick={() => {
                        const keyText = createdApiKey.key;
                        if (keyText) {
                          navigator.clipboard.writeText(keyText).then(() => {
                            // Show temporary success feedback
                            const button = document.getElementById('copy-button');
                            if (button) {
                              const originalText = button.innerHTML;
                              button.innerHTML = '✓ Copied!';
                              button.className = button.className.replace('text-gray-600', 'text-green-600');
                              setTimeout(() => {
                                button.innerHTML = originalText;
                                button.className = button.className.replace('text-green-600', 'text-gray-600');
                              }, 2000);
                            }
                          }).catch(() => {
                            // Fallback: select the text
                            const element = document.getElementById('api-key-display');
                            if (element) {
                              const range = document.createRange();
                              range.selectNodeContents(element);
                              const selection = window.getSelection();
                              selection?.removeAllRanges();
                              selection?.addRange(range);
                            }
                          });
                        }
                      }}
                      id="copy-button"
                      className="absolute right-2 top-2 p-1 text-gray-600 hover:text-gray-800 bg-gray-100 hover:bg-gray-200 rounded"
                      title="Copy API key"
                    >
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                      </svg>
                    </button>
                  </div>
                  <p className="text-xs text-yellow-700 mt-2">
                    This is the only time you&apos;ll see this key. Copy and store it
                    securely - you won&apos;t be able to retrieve it again.
                  </p>
                </div>
              </div>

              {createdApiKey.apiKey.description && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Description
                  </label>
                  <div className="bg-gray-50 p-3 rounded-md">
                    <span className="text-gray-900">
                      {createdApiKey.apiKey.description}
                    </span>
                  </div>
                </div>
              )}

              {createdApiKey.apiKey.rules.length > 0 && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Content Policy Rules
                  </label>
                  <div className="flex flex-wrap gap-2">
                    {createdApiKey.apiKey.rules.map((rule, index) => (
                      <span
                        key={index}
                        className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
                      >
                        {rule.replace(/-/g, " ")}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>

            <div className="flex justify-end pt-6 border-t border-gray-200 mt-6">
              <button
                onClick={handleClose}
                className="px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 font-medium transition-colors duration-200"
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
            <h2 className="text-xl font-semibold text-slate-900">
              Create New API Key
            </h2>
            <button
              type="button"
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600"
            >
              <svg
                className="w-6 h-6"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>

          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
              <div className="flex">
                <div className="flex-shrink-0">
                  <svg
                    className="h-5 w-5 text-red-400"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                  >
                    <path
                      fillRule="evenodd"
                      d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                      clipRule="evenodd"
                    />
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
              <label
                htmlFor="name"
                className="block text-sm font-medium text-slate-700 mb-2"
              >
                API Key Name *
              </label>
              <input
                type="text"
                id="name"
                value={formData.name}
                onChange={(e) =>
                  setFormData((prev) => ({ ...prev, name: e.target.value }))
                }
                className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500 text-slate-900"
                placeholder="e.g., Development Key, Production API, Mobile App"
                maxLength={100}
                required
              />
              <p className="text-xs text-slate-500 mt-1">
                Choose a descriptive name to identify this API key (
                {formData.name.length}/100)
              </p>
            </div>

            <div>
              <label
                htmlFor="description"
                className="block text-sm font-medium text-slate-700 mb-2"
              >
                Description (Optional)
              </label>
              <textarea
                id="description"
                value={formData.description}
                onChange={(e) =>
                  setFormData((prev) => ({
                    ...prev,
                    description: e.target.value,
                  }))
                }
                className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500 text-slate-900"
                rows={3}
                placeholder="Describe what content policies this API key will enforce..."
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 mb-3">
                Content Policy Rules (Optional)
              </label>
              <p className="text-sm text-slate-500 mb-4">
                Define what content policies this API key should enforce. You
                can customize these rules later through the API.
              </p>

              <div className="space-y-4">
                <div>
                  <h4 className="text-sm font-medium text-slate-600 mb-2">
                    Common Content Policies
                  </h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
                    {COMMON_CONTENT_POLICIES.map((rule) => (
                      <label key={rule} className="flex items-center">
                        <input
                          type="checkbox"
                          checked={formData.rules.includes(rule)}
                          onChange={() => handleRuleToggle(rule)}
                          className="rounded border-slate-300 text-orange-600 focus:ring-orange-500"
                        />
                        <span className="ml-2 text-sm text-slate-700 capitalize">
                          {rule.replace(/-/g, " ")}
                        </span>
                      </label>
                    ))}
                  </div>
                </div>

                <div>
                  <h4 className="text-sm font-medium text-gray-600 mb-2">
                    Add Custom Policy Rule
                  </h4>
                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={customRule}
                      onChange={(e) => setCustomRule(e.target.value)}
                      className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-900"
                      placeholder="e.g., no-selling-anything, no-political-content"
                      onKeyPress={(e) =>
                        e.key === "Enter" &&
                        (e.preventDefault(), handleAddCustomRule())
                      }
                    />
                    <button
                      type="button"
                      onClick={handleAddCustomRule}
                      className="px-3 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200"
                    >
                      Add
                    </button>
                  </div>
                  <p className="text-xs text-gray-500 mt-1">
                    Use kebab-case format (e.g., no-selling-anything)
                  </p>
                </div>

                {formData.rules.length > 0 && (
                  <div>
                    <h4 className="text-sm font-medium text-gray-600 mb-2">
                      Selected Policy Rules
                    </h4>
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

                <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
                  <div className="flex">
                    <div className="flex-shrink-0">
                      <svg
                        className="h-5 w-5 text-blue-400"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                      >
                        <path
                          fillRule="evenodd"
                          d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
                          clipRule="evenodd"
                        />
                      </svg>
                    </div>
                    <div className="ml-3">
                      <h3 className="text-sm font-medium text-blue-800">
                        Policy Rules Info
                      </h3>
                      <div className="mt-2 text-sm text-blue-700">
                        <p>
                          These rules define what content policies your API key
                          will enforce. You can modify and add more specific
                          rules later using our API endpoints.
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div className="flex justify-end gap-3 pt-6 border-t border-gray-200 mt-6">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200 font-medium transition-colors duration-200"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting || !formData.name.trim()}
              className="px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 font-medium disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200"
            >
              {isSubmitting ? (
                <div className="flex items-center gap-2">
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                  Creating...
                </div>
              ) : (
                "Create API Key"
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
