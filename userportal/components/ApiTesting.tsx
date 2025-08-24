"use client";

import { useState, useEffect } from "react";
import { useAuth } from "@/hooks/useAuth";

interface ApiKey {
  id: string;
  name: string;
  key_preview: string;
  status: string;
  current_month_usage: number;
  monthly_quota: number;
}

interface TestEndpoint {
  id: string;
  name: string;
  method: "GET" | "POST" | "PUT" | "DELETE";
  path: string;
  description: string;
  requiresBody?: boolean;
  sampleBody?: string;
  headers?: Record<string, string>;
}

interface TestResult {
  status: number;
  statusText: string;
  data: any;
  headers: Record<string, string>;
  duration: number;
  timestamp: string;
}

const TEST_ENDPOINTS: TestEndpoint[] = [
  {
    id: "health",
    name: "Health Check",
    method: "GET",
    path: "/api/health",
    description: "Check API service health status",
  },
  {
    id: "users",
    name: "Get All Users",
    method: "GET",
    path: "/api/users",
    description: "Retrieve all users from the system",
  },
  {
    id: "user-by-id",
    name: "Get User by ID",
    method: "GET",
    path: "/api/users/1",
    description: "Retrieve a specific user by their ID",
  },
  {
    id: "projects",
    name: "Get All Projects",
    method: "GET",
    path: "/api/projects",
    description: "Retrieve all projects from the system",
  },
  {
    id: "create-project",
    name: "Create Project",
    method: "POST",
    path: "/api/projects",
    description: "Create a new project",
    requiresBody: true,
    sampleBody: JSON.stringify(
      {
        name: "Test Project",
        description: "A test project created via API testing",
      },
      null,
      2
    ),
  },
  {
    id: "analytics",
    name: "Get Analytics Summary",
    method: "GET",
    path: "/api/analytics/summary",
    description: "Retrieve analytics summary data",
  },
  {
    id: "moderate-content",
    name: "Moderate Text Content",
    method: "POST",
    path: "/api/moderate-content/text/v1",
    description: "Test content moderation for text",
    requiresBody: true,
    sampleBody: JSON.stringify(
      {
        text: "This is a sample text for content moderation testing",
      },
      null,
      2
    ),
  },
  {
    id: "moderate-content-flagged",
    name: "Moderate Flagged Content",
    method: "POST",
    path: "/api/moderate-content/text/v1",
    description: "Test content moderation with flagged content",
    requiresBody: true,
    sampleBody: JSON.stringify(
      {
        text: "This content contains spam and inappropriate material",
      },
      null,
      2
    ),
  },
  {
    id: "validate-key",
    name: "Validate API Key",
    method: "POST",
    path: "/api/apikeys/validate",
    description: "Test API key validation (uses selected key)",
    requiresBody: true,
    sampleBody: JSON.stringify(
      {
        apiKey: "your-api-key-here",
      },
      null,
      2
    ),
  },
];

export function ApiTesting() {
  const { user } = useAuth();
  const [apiKeys, setApiKeys] = useState<ApiKey[]>([]);
  const [selectedKeyId, setSelectedKeyId] = useState<string>("");
  const [selectedEndpoint, setSelectedEndpoint] = useState<TestEndpoint | null>(
    null
  );
  const [requestBody, setRequestBody] = useState<string>("");
  const [customHeaders, setCustomHeaders] = useState<string>("");
  const [testResult, setTestResult] = useState<TestResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string>("");
  const [testHistory, setTestHistory] = useState<TestResult[]>([]);

  useEffect(() => {
    fetchApiKeys();
  }, []);

  const fetchApiKeys = async () => {
    try {
      const token = localStorage.getItem("token");
      const response = await fetch("http://localhost:8080/api/apikeys", {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const data = await response.json();
        setApiKeys(data.apiKeys || []);
        if (data.apiKeys?.length > 0) {
          setSelectedKeyId(data.apiKeys[0].id);
        }
      }
    } catch (error) {
      console.error("Failed to fetch API keys:", error);
    }
  };

  const handleEndpointSelect = (endpoint: TestEndpoint) => {
    setSelectedEndpoint(endpoint);
    setRequestBody(endpoint.sampleBody || "");
    setCustomHeaders("");
    setTestResult(null);
    setError("");
  };

  const executeTest = async () => {
    if (!selectedEndpoint || !selectedKeyId) {
      setError("Please select an API key and endpoint");
      return;
    }

    setLoading(true);
    setError("");
    setTestResult(null);

    try {
      const selectedKey = apiKeys.find((key) => key.id === selectedKeyId);
      if (!selectedKey) {
        throw new Error("Selected API key not found");
      }

      const startTime = Date.now();

      // Prepare headers
      const headers: Record<string, string> = {
        "Content-Type": "application/json",
      };

      // For testing purposes, we'll use a mock API key format
      // In a real implementation, you'd need to store and retrieve the actual key
      const mockApiKey = `mk_test_${selectedKey.id.substring(0, 8)}${Date.now()
        .toString()
        .slice(-4)}`;

      // Add API key to headers
      headers["X-API-Key"] = mockApiKey;

      // Add custom headers if provided
      if (customHeaders.trim()) {
        try {
          const parsedHeaders = JSON.parse(customHeaders);
          Object.assign(headers, parsedHeaders);
        } catch (e) {
          throw new Error("Invalid JSON in custom headers");
        }
      }

      // Prepare request options
      const requestOptions: RequestInit = {
        method: selectedEndpoint.method,
        headers,
      };

      // Add body for POST/PUT requests
      if (selectedEndpoint.requiresBody && requestBody.trim()) {
        if (selectedEndpoint.id === "validate-key") {
          // Special case for validate endpoint - use the mock key
          const bodyObj = JSON.parse(requestBody);
          bodyObj.apiKey = mockApiKey;
          requestOptions.body = JSON.stringify(bodyObj);
        } else {
          requestOptions.body = requestBody;
        }
      }

      // Make the request
      const response = await fetch(
        `http://localhost:8080${selectedEndpoint.path}`,
        requestOptions
      );

      const endTime = Date.now();
      const duration = endTime - startTime;

      // Parse response
      let responseData;
      const contentType = response.headers.get("content-type");
      if (contentType && contentType.includes("application/json")) {
        responseData = await response.json();
      } else {
        responseData = await response.text();
      }

      // Collect response headers
      const responseHeaders: Record<string, string> = {};
      response.headers.forEach((value, key) => {
        responseHeaders[key] = value;
      });

      const result = {
        status: response.status,
        statusText: response.statusText,
        data: responseData,
        headers: responseHeaders,
        duration,
        timestamp: new Date().toISOString(),
      };

      setTestResult(result);

      // Add to history (keep last 10 results)
      setTestHistory((prev) => [result, ...prev.slice(0, 9)]);
    } catch (error) {
      setError(error instanceof Error ? error.message : "An error occurred");
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status: number) => {
    if (status >= 200 && status < 300) return "text-green-600";
    if (status >= 400 && status < 500) return "text-yellow-600";
    if (status >= 500) return "text-red-600";
    return "text-gray-600";
  };

  return (
    <div className="p-6 max-w-7xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">API Testing</h1>
        <p className="text-gray-600">
          Test your API keys and endpoints in real-time
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Left Panel - Configuration */}
        <div className="space-y-6">
          {/* API Key Selection */}
          <div className="bg-white rounded-lg shadow-sm border p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">
              Select API Key
            </h2>
            {apiKeys.length === 0 ? (
              <div className="text-center py-8">
                <p className="text-gray-500 mb-4">No API keys found</p>
                <a
                  href="/apikeys"
                  className="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Create API Key
                </a>
              </div>
            ) : (
              <div className="space-y-3">
                {apiKeys.map((key) => (
                  <label
                    key={key.id}
                    className="flex items-center space-x-3 cursor-pointer"
                  >
                    <input
                      type="radio"
                      name="apiKey"
                      value={key.id}
                      checked={selectedKeyId === key.id}
                      onChange={(e) => setSelectedKeyId(e.target.value)}
                      className="text-blue-600"
                    />
                    <div className="flex-1">
                      <div className="flex items-center justify-between">
                        <span className="font-medium text-gray-900">
                          {key.name}
                        </span>
                        <span
                          className={`px-2 py-1 text-xs rounded-full ${
                            key.status === "active"
                              ? "bg-green-100 text-green-800"
                              : "bg-gray-100 text-gray-800"
                          }`}
                        >
                          {key.status}
                        </span>
                      </div>
                      <div className="text-sm text-gray-500">
                        Usage: {key.current_month_usage}/{key.monthly_quota}
                      </div>
                    </div>
                  </label>
                ))}
              </div>
            )}
          </div>

          {/* Endpoint Selection */}
          <div className="bg-white rounded-lg shadow-sm border p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">
              Select Endpoint
            </h2>
            <div className="space-y-2 max-h-96 overflow-y-auto">
              {TEST_ENDPOINTS.map((endpoint) => (
                <button
                  key={endpoint.id}
                  onClick={() => handleEndpointSelect(endpoint)}
                  className={`w-full text-left p-3 rounded-lg border transition-colors ${
                    selectedEndpoint?.id === endpoint.id
                      ? "border-blue-500 bg-blue-50"
                      : "border-gray-200 hover:border-gray-300 hover:bg-gray-50"
                  }`}
                >
                  <div className="flex items-center justify-between mb-1">
                    <span className="font-medium text-gray-900">
                      {endpoint.name}
                    </span>
                    <span
                      className={`px-2 py-1 text-xs rounded font-mono ${
                        endpoint.method === "GET"
                          ? "bg-green-100 text-green-800"
                          : endpoint.method === "POST"
                          ? "bg-blue-100 text-blue-800"
                          : endpoint.method === "PUT"
                          ? "bg-yellow-100 text-yellow-800"
                          : "bg-red-100 text-red-800"
                      }`}
                    >
                      {endpoint.method}
                    </span>
                  </div>
                  <div className="text-sm text-gray-600 mb-1">
                    {endpoint.path}
                  </div>
                  <div className="text-xs text-gray-500">
                    {endpoint.description}
                  </div>
                  {selectedEndpoint?.id === endpoint.id && selectedKeyId && (
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        executeTest();
                      }}
                      disabled={loading}
                      className="mt-2 text-xs bg-blue-600 text-white px-2 py-1 rounded hover:bg-blue-700 disabled:opacity-50"
                    >
                      Quick Test
                    </button>
                  )}
                </button>
              ))}
            </div>
          </div>

          {/* Request Configuration */}
          {selectedEndpoint && (
            <div className="bg-white rounded-lg shadow-sm border p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">
                Request Configuration
              </h2>

              {selectedEndpoint.requiresBody && (
                <div className="mb-4">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Request Body (JSON)
                  </label>
                  <textarea
                    value={requestBody}
                    onChange={(e) => setRequestBody(e.target.value)}
                    className="w-full h-32 px-3 py-2 border border-gray-300 rounded-lg font-mono text-sm"
                    placeholder="Enter JSON request body..."
                  />
                </div>
              )}

              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Custom Headers (JSON)
                </label>
                <textarea
                  value={customHeaders}
                  onChange={(e) => setCustomHeaders(e.target.value)}
                  className="w-full h-20 px-3 py-2 border border-gray-300 rounded-lg font-mono text-sm"
                  placeholder='{"Custom-Header": "value"}'
                />
              </div>

              <div className="flex space-x-3">
                <button
                  onClick={executeTest}
                  disabled={loading || !selectedKeyId}
                  className="flex-1 bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {loading ? "Testing..." : "Execute Test"}
                </button>
                <button
                  onClick={() => {
                    setRequestBody(selectedEndpoint?.sampleBody || "");
                    setCustomHeaders("");
                  }}
                  className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
                  title="Reset to defaults"
                >
                  Reset
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Right Panel - Results */}
        <div className="space-y-6">
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4">
              <div className="flex items-center">
                <svg
                  className="w-5 h-5 text-red-400 mr-2"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                <span className="text-red-800 font-medium">Error</span>
              </div>
              <p className="text-red-700 mt-1">{error}</p>
            </div>
          )}

          {testResult && (
            <div className="bg-white rounded-lg shadow-sm border p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">
                Test Results
              </h2>

              {/* Status and Timing */}
              <div className="grid grid-cols-2 gap-4 mb-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Status
                  </label>
                  <div
                    className={`text-lg font-semibold ${getStatusColor(
                      testResult.status
                    )}`}
                  >
                    {testResult.status} {testResult.statusText}
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Duration
                  </label>
                  <div className="text-lg font-semibold text-gray-900">
                    {testResult.duration}ms
                  </div>
                </div>
              </div>

              {/* Response Headers */}
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Response Headers
                </label>
                <div className="bg-gray-50 rounded-lg p-3 max-h-32 overflow-y-auto">
                  <pre className="text-xs text-gray-600">
                    {JSON.stringify(testResult.headers, null, 2)}
                  </pre>
                </div>
              </div>

              {/* Response Body */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Response Body
                </label>
                <div className="bg-gray-50 rounded-lg p-3 max-h-96 overflow-y-auto">
                  <pre className="text-xs text-gray-800 whitespace-pre-wrap">
                    {typeof testResult.data === "string"
                      ? testResult.data
                      : JSON.stringify(testResult.data, null, 2)}
                  </pre>
                </div>
              </div>

              <div className="mt-4 text-xs text-gray-500">
                Tested at: {new Date(testResult.timestamp).toLocaleString()}
              </div>
            </div>
          )}

          {!testResult && !error && (
            <div className="bg-white rounded-lg shadow-sm border p-6">
              <div className="text-center py-12">
                <svg
                  className="w-12 h-12 text-gray-400 mx-auto mb-4"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
                  />
                </svg>
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  Ready to Test
                </h3>
                <p className="text-gray-500">
                  Select an API key and endpoint, then click "Execute Test" to
                  see results here.
                </p>
              </div>
            </div>
          )}

          {/* Test History */}
          {testHistory.length > 0 && (
            <div className="bg-white rounded-lg shadow-sm border p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">
                Recent Tests
              </h2>
              <div className="space-y-3 max-h-64 overflow-y-auto">
                {testHistory.map((result, index) => (
                  <div
                    key={index}
                    className="flex items-center justify-between p-3 bg-gray-50 rounded-lg cursor-pointer hover:bg-gray-100"
                    onClick={() => setTestResult(result)}
                  >
                    <div className="flex items-center space-x-3">
                      <div
                        className={`w-3 h-3 rounded-full ${
                          result.status >= 200 && result.status < 300
                            ? "bg-green-500"
                            : result.status >= 400 && result.status < 500
                            ? "bg-yellow-500"
                            : "bg-red-500"
                        }`}
                      />
                      <span className="text-sm font-medium text-gray-900">
                        {result.status}
                      </span>
                      <span className="text-sm text-gray-500">
                        {result.duration}ms
                      </span>
                    </div>
                    <span className="text-xs text-gray-400">
                      {new Date(result.timestamp).toLocaleTimeString()}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
