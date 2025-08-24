"use client";

import { useState } from "react";
import { ApiKey, ApiKeyService } from "@/lib/apikeys";

interface ManageRulesModalProps {
  apiKey: ApiKey;
  onClose: () => void;
  onUpdate: (updatedApiKey: ApiKey) => void;
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

export function ManageRulesModal({
  apiKey,
  onClose,
  onUpdate,
}: ManageRulesModalProps) {
  const [rules, setRules] = useState<string[]>([...apiKey.rules]);
  const [customRule, setCustomRule] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError(null);

    try {
      const updatedApiKey = await ApiKeyService.updateApiKeyRules(apiKey.id, rules);
      onUpdate(updatedApiKey);
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to update rules");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleRuleToggle = (rule: string) => {
    setRules((prev) =>
      prev.includes(rule)
        ? prev.filter((r) => r !== rule)
        : [...prev, rule]
    );
  };

  const handleAddCustomRule = () => {
    const rule = customRule.trim();
    if (rule && !rules.includes(rule)) {
      setRules((prev) => [...prev, rule]);
      setCustomRule("");
    }
  };

  const handleRemoveRule = (rule: string) => {
    setRules((prev) => prev.filter((r) => r !== rule));
  };

  const hasChanges = JSON.stringify(rules.sort()) !== JSON.stringify(apiKey.rules.sort());

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <form onSubmit={handleSubmit} className="p-6">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h2 className="text-xl font-semibold text-slate-900">
                Manage Content Rules
              </h2>
              <p className="text-sm text-slate-600 mt-1">
                API Key: {apiKey.name}
              </p>
            </div>
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
              <h3 className="text-lg font-medium text-slate-700 mb-4">
                Content Policy Rules
              </h3>
              <p className="text-sm text-slate-500 mb-4">
                Define what content policies this API key should enforce. Changes will take effect immediately.
              </p>

              <div className="space-y-4">
                <div>
                  <h4 className="text-sm font-medium text-slate-600 mb-3">
                    Common Content Policies
                  </h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
                    {COMMON_CONTENT_POLICIES.map((rule) => (
                      <label key={rule} className="flex items-center">
                        <input
                          type="checkbox"
                          checked={rules.includes(rule)}
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
                      className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500 text-gray-900"
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

                {rules.length > 0 && (
                  <div>
                    <h4 className="text-sm font-medium text-gray-600 mb-2">
                      Current Policy Rules ({rules.length})
                    </h4>
                    <div className="flex flex-wrap gap-2">
                      {rules.map((rule) => (
                        <span
                          key={rule}
                          className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-orange-100 text-orange-800"
                        >
                          {rule.replace(/-/g, " ")}
                          <button
                            type="button"
                            onClick={() => handleRemoveRule(rule)}
                            className="ml-1 text-orange-600 hover:text-orange-800"
                          >
                            ×
                          </button>
                        </span>
                      ))}
                    </div>
                  </div>
                )}

                {hasChanges && (
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
                          Changes Detected
                        </h3>
                        <div className="mt-2 text-sm text-blue-700">
                          <p>
                            You have unsaved changes to the content policy rules. 
                            Click "Update Rules" to apply these changes.
                          </p>
                        </div>
                      </div>
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
              className="px-4 py-2 text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200 font-medium transition-colors duration-200"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting || !hasChanges}
              className="px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 font-medium disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200"
            >
              {isSubmitting ? (
                <div className="flex items-center gap-2">
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                  Updating...
                </div>
              ) : (
                "Update Rules"
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}