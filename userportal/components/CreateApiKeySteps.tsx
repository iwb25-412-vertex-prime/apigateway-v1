"use client";

import { useState } from "react";
import { CreateApiKeyRequest, CreateApiKeyResponse } from "@/lib/apikeys";
import { useToast } from "@/hooks/useToast";
import {
  CheckIcon,
  KeyIcon,
  Cog6ToothIcon,
  DocumentCheckIcon,
  ClipboardDocumentIcon,
} from "@heroicons/react/24/outline";

interface CreateApiKeyStepsProps {
  onCancel: () => void;
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

type Step = 1 | 2 | 3 | 4;

export function CreateApiKeySteps({
  onCancel,
  onSubmit,
}: CreateApiKeyStepsProps) {
  const [currentStep, setCurrentStep] = useState<Step>(1);
  const [formData, setFormData] = useState<CreateApiKeyRequest>({
    name: "",
    description: "",
    rules: [],
  });
  const [customRule, setCustomRule] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [createdApiKey, setCreatedApiKey] =
    useState<CreateApiKeyResponse | null>(null);
  const { success: showSuccess, error: showError } = useToast();

  const steps = [
    {
      number: 1,
      title: "Basic Info",
      icon: KeyIcon,
      description: "Name and description",
    },
    {
      number: 2,
      title: "Content Policies",
      icon: Cog6ToothIcon,
      description: "Configure rules",
    },
    {
      number: 3,
      title: "Review",
      icon: DocumentCheckIcon,
      description: "Confirm details",
    },
    {
      number: 4,
      title: "Complete",
      icon: CheckIcon,
      description: "Your API key",
    },
  ];

  const handleNext = () => {
    if (currentStep === 1) {
      if (!formData.name.trim()) {
        setError("API key name is required");
        return;
      }
      if (formData.name.length > 100) {
        setError("API key name must be 100 characters or less");
        return;
      }
      setError(null);
    }

    if (currentStep < 4) {
      setCurrentStep((prev) => (prev + 1) as Step);
    }
  };

  const handlePrevious = () => {
    if (currentStep > 1) {
      setCurrentStep((prev) => (prev - 1) as Step);
    }
  };

  const handleSubmitForm = async () => {
    setIsSubmitting(true);
    setError(null);

    try {
      const result = await onSubmit(formData);
      if (result) {
        setCreatedApiKey(result);
        setCurrentStep(4);
        showSuccess(
          "API Key Created!",
          "Your new API key has been generated successfully"
        );
      }
    } catch (err) {
      const errorMessage =
        err instanceof Error ? err.message : "Failed to create API key";
      setError(errorMessage);
      showError("Creation Failed", errorMessage);
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

  const copyToClipboard = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text);
      showSuccess("Copied!", "API key copied to clipboard");
    } catch (err) {
      // Fallback for older browsers
      const textArea = document.createElement("textarea");
      textArea.value = text;
      document.body.appendChild(textArea);
      textArea.select();
      document.execCommand("copy");
      document.body.removeChild(textArea);
      showSuccess("Copied!", "API key copied to clipboard");
    }
  };

  return (
    <div className="max-w-4xl mx-auto">
      {/* Progress Steps */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          {steps.map((step, index) => {
            const StepIcon = step.icon;
            const isActive = currentStep === step.number;
            const isCompleted = currentStep > step.number;
            const isAccessible = currentStep >= step.number;

            return (
              <div key={step.number} className="flex items-center">
                <div className="flex flex-col items-center">
                  <div
                    className={`w-12 h-12 rounded-full flex items-center justify-center border-2 transition-all duration-200 ${
                      isCompleted
                        ? "bg-green-500 border-green-500 text-white"
                        : isActive
                        ? "bg-orange-500 border-orange-500 text-white"
                        : isAccessible
                        ? "border-orange-200 text-orange-500 hover:border-orange-300"
                        : "border-slate-200 text-slate-400"
                    }`}
                  >
                    {isCompleted ? (
                      <CheckIcon className="w-6 h-6" />
                    ) : (
                      <StepIcon className="w-6 h-6" />
                    )}
                  </div>
                  <div className="mt-2 text-center">
                    <div
                      className={`text-sm font-medium ${
                        isActive
                          ? "text-orange-600"
                          : isCompleted
                          ? "text-green-600"
                          : "text-slate-500"
                      }`}
                    >
                      {step.title}
                    </div>
                    <div className="text-xs text-slate-400 mt-1">
                      {step.description}
                    </div>
                  </div>
                </div>
                {index < steps.length - 1 && (
                  <div
                    className={`flex-1 h-0.5 mx-4 transition-colors duration-200 ${
                      currentStep > step.number
                        ? "bg-green-500"
                        : "bg-slate-200"
                    }`}
                  />
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Step Content */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-8">
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

        {/* Step 1: Basic Information */}
        {currentStep === 1 && (
          <div className="space-y-6">
            <div>
              <h2 className="text-2xl font-bold text-slate-900 mb-2">
                Basic Information
              </h2>
              <p className="text-slate-600">
                Let's start with the basics for your new API key.
              </p>
            </div>

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
                  className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500 text-slate-900 transition-colors"
                  placeholder="e.g., Development Key, Production API, Mobile App"
                  maxLength={100}
                  required
                />
                <p className="text-xs text-slate-500 mt-2">
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
                  className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500 text-slate-900 transition-colors"
                  rows={4}
                  placeholder="Describe what this API key will be used for and what content policies it should enforce..."
                />
                <p className="text-xs text-slate-500 mt-2">
                  Help your team understand the purpose of this API key
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Step 2: Content Policies */}
        {currentStep === 2 && (
          <div className="space-y-6">
            <div>
              <h2 className="text-2xl font-bold text-slate-900 mb-2">
                Content Policies
              </h2>
              <p className="text-slate-600">
                Configure what content policies this API key should enforce.
              </p>
            </div>

            <div className="space-y-6">
              <div>
                <h3 className="text-lg font-medium text-slate-800 mb-4">
                  Common Content Policies
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  {COMMON_CONTENT_POLICIES.map((rule) => (
                    <label
                      key={rule}
                      className="flex items-center p-3 border border-slate-200 rounded-lg hover:bg-slate-50 cursor-pointer transition-colors"
                    >
                      <input
                        type="checkbox"
                        checked={formData.rules.includes(rule)}
                        onChange={() => handleRuleToggle(rule)}
                        className="rounded border-slate-300 text-orange-600 focus:ring-orange-500"
                      />
                      <span className="ml-3 text-sm text-slate-700 capitalize">
                        {rule.replace(/-/g, " ")}
                      </span>
                    </label>
                  ))}
                </div>
              </div>

              <div>
                <h3 className="text-lg font-medium text-slate-800 mb-4">
                  Custom Policy Rule
                </h3>
                <div className="flex gap-3">
                  <input
                    type="text"
                    value={customRule}
                    onChange={(e) => setCustomRule(e.target.value)}
                    className="flex-1 px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500 text-slate-900 transition-colors"
                    placeholder="e.g., no-selling-anything, no-political-content"
                    onKeyPress={(e) =>
                      e.key === "Enter" &&
                      (e.preventDefault(), handleAddCustomRule())
                    }
                  />
                  <button
                    type="button"
                    onClick={handleAddCustomRule}
                    disabled={!customRule.trim()}
                    className="px-6 py-3 bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                  >
                    Add
                  </button>
                </div>
                <p className="text-xs text-slate-500 mt-2">
                  Use kebab-case format (e.g., no-selling-anything)
                </p>
              </div>

              {formData.rules.length > 0 && (
                <div>
                  <h3 className="text-lg font-medium text-slate-800 mb-4">
                    Selected Rules
                  </h3>
                  <div className="flex flex-wrap gap-2">
                    {formData.rules.map((rule) => (
                      <span
                        key={rule}
                        className="inline-flex items-center px-3 py-1.5 rounded-full text-sm font-medium bg-orange-100 text-orange-800"
                      >
                        {rule.replace(/-/g, " ")}
                        <button
                          type="button"
                          onClick={() => handleRemoveRule(rule)}
                          className="ml-2 text-orange-600 hover:text-orange-800 transition-colors"
                        >
                          ×
                        </button>
                      </span>
                    ))}
                  </div>
                </div>
              )}

              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
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
                    <h4 className="text-sm font-medium text-blue-800">
                      Policy Rules Info
                    </h4>
                    <div className="mt-2 text-sm text-blue-700">
                      <p>
                        These rules define what content policies your API key
                        will enforce. You can modify and add more specific rules
                        later using our API endpoints.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Step 3: Review */}
        {currentStep === 3 && (
          <div className="space-y-6">
            <div>
              <h2 className="text-2xl font-bold text-slate-900 mb-2">
                Review & Confirm
              </h2>
              <p className="text-slate-600">
                Please review your API key configuration before creating it.
              </p>
            </div>

            <div className="space-y-6">
              <div className="bg-slate-50 rounded-lg p-6">
                <h3 className="text-lg font-medium text-slate-800 mb-4">
                  API Key Details
                </h3>

                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-600 mb-1">
                      Name
                    </label>
                    <p className="text-slate-900 font-medium">
                      {formData.name}
                    </p>
                  </div>

                  {formData.description && (
                    <div>
                      <label className="block text-sm font-medium text-slate-600 mb-1">
                        Description
                      </label>
                      <p className="text-slate-900">{formData.description}</p>
                    </div>
                  )}

                  <div>
                    <label className="block text-sm font-medium text-slate-600 mb-2">
                      Content Policy Rules
                    </label>
                    {formData.rules.length > 0 ? (
                      <div className="flex flex-wrap gap-2">
                        {formData.rules.map((rule) => (
                          <span
                            key={rule}
                            className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-orange-100 text-orange-800"
                          >
                            {rule.replace(/-/g, " ")}
                          </span>
                        ))}
                      </div>
                    ) : (
                      <p className="text-slate-500 italic">
                        No content policy rules selected
                      </p>
                    )}
                  </div>
                </div>
              </div>

              <div className="bg-orange-50 border border-orange-200 rounded-lg p-4">
                <div className="flex">
                  <div className="flex-shrink-0">
                    <svg
                      className="h-5 w-5 text-orange-400"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path
                        fillRule="evenodd"
                        d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                        clipRule="evenodd"
                      />
                    </svg>
                  </div>
                  <div className="ml-3">
                    <h4 className="text-sm font-medium text-orange-800">
                      Important
                    </h4>
                    <div className="mt-2 text-sm text-orange-700">
                      <p>
                        Once created, you'll only see your API key once. Make
                        sure to copy and store it securely.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Step 4: Complete */}
        {currentStep === 4 && createdApiKey && (
          <div className="space-y-6">
            <div className="text-center">
              <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <CheckIcon className="w-8 h-8 text-green-600" />
              </div>
              <h2 className="text-2xl font-bold text-slate-900 mb-2">
                API Key Created Successfully!
              </h2>
              <p className="text-slate-600">
                Your API key has been generated and is ready to use.
              </p>
            </div>

            <div className="bg-green-50 border border-green-200 rounded-lg p-4 mb-6">
              <div className="flex">
                <div className="flex-shrink-0">
                  <CheckIcon className="h-5 w-5 text-green-400" />
                </div>
                <div className="ml-3">
                  <h3 className="text-sm font-medium text-green-800">
                    Success!
                  </h3>
                  <div className="mt-2 text-sm text-green-700">
                    <p>
                      Please copy and save your API key now. You won't be able
                      to see it again.
                    </p>
                  </div>
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">
                  API Key Name
                </label>
                <div className="bg-slate-50 p-3 rounded-lg">
                  <span className="text-slate-900 font-medium">
                    {createdApiKey.apiKey.name}
                  </span>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">
                  Your API Key
                </label>
                <div className="bg-yellow-50 border-2 border-yellow-300 rounded-lg p-4">
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
                    <code className="text-sm text-slate-900 font-mono break-all select-all bg-white p-3 rounded border block pr-12">
                      {createdApiKey.key || "API key not available"}
                    </code>
                    <button
                      onClick={() => copyToClipboard(createdApiKey.key || "")}
                      className="absolute right-2 top-2 p-1.5 text-slate-600 hover:text-slate-800 bg-slate-100 hover:bg-slate-200 rounded transition-colors"
                      title="Copy API key"
                    >
                      <ClipboardDocumentIcon className="w-4 h-4" />
                    </button>
                  </div>
                  <p className="text-xs text-yellow-700 mt-2">
                    This is the only time you'll see this key. Copy and store it
                    securely.
                  </p>
                </div>
              </div>

              {createdApiKey.apiKey.description && (
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">
                    Description
                  </label>
                  <div className="bg-slate-50 p-3 rounded-lg">
                    <span className="text-slate-900">
                      {createdApiKey.apiKey.description}
                    </span>
                  </div>
                </div>
              )}

              {createdApiKey.apiKey.rules.length > 0 && (
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">
                    Content Policy Rules
                  </label>
                  <div className="flex flex-wrap gap-2">
                    {createdApiKey.apiKey.rules.map((rule, index) => (
                      <span
                        key={index}
                        className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-orange-100 text-orange-800"
                      >
                        {rule.replace(/-/g, " ")}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Navigation Buttons */}
        <div className="flex justify-between pt-8 border-t border-slate-200 mt-8">
          <div>
            {currentStep > 1 && currentStep < 4 && (
              <button
                onClick={handlePrevious}
                className="px-6 py-3 text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200 font-medium transition-colors duration-200"
              >
                Previous
              </button>
            )}
          </div>

          <div className="flex gap-3">
            {currentStep < 4 && (
              <button
                onClick={onCancel}
                className="px-6 py-3 text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200 font-medium transition-colors duration-200"
              >
                Cancel
              </button>
            )}

            {currentStep < 3 && (
              <button
                onClick={handleNext}
                className="px-6 py-3 bg-orange-600 text-white rounded-lg hover:bg-orange-700 font-medium transition-colors duration-200"
              >
                Next
              </button>
            )}

            {currentStep === 3 && (
              <button
                onClick={handleSubmitForm}
                disabled={isSubmitting}
                className="px-6 py-3 bg-orange-600 text-white rounded-lg hover:bg-orange-700 font-medium disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200"
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
            )}

            {currentStep === 4 && (
              <button
                onClick={onCancel}
                className="px-6 py-3 bg-orange-600 text-white rounded-lg hover:bg-orange-700 font-medium transition-colors duration-200"
              >
                Done
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
