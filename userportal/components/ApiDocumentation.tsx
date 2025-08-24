"use client";

import { useState } from "react";
import { CodeBlock, EndpointCard } from "./index";

interface Endpoint {
  method: string;
  path: string;
  title: string;
  description: string;
  requestBody?: any;
  responseExample: any;
  curlExample: string;
}

interface EndpointCategory {
  title: string;
  icon: string;
  endpoints: string[];
  comingSoon?: boolean;
}

export function ApiDocumentation() {
  const [selectedEndpoint, setSelectedEndpoint] = useState<string>("moderate");

  const baseUrl = "http://localhost:8080/api";

  const endpoints: Record<string, Endpoint> = {
    moderate: {
      method: "POST",
      path: "/moderate-content/text/v1",
      title: "Content Moderation",
      description: "Analyze text content for inappropriate material, spam, or policy violations using AI-powered moderation.",
      requestBody: {
        text: "The text content to analyze for moderation (max 10,000 characters)"
      },
      responseExample: {
        status: true,
        result: {
          flagged: false,
          confidence: 0.95,
          categories: [],
          severity: "none",
          action_recommended: "approve"
        },
        metadata: {
          text_length: 42,
          processing_time_ms: 45,
          model_version: "v1.2.3",
          api_key_used: "My Moderation Key"
        }
      },
      curlExample: `curl -X POST ${baseUrl}/moderate-content/text/v1 \\
  -H "X-API-Key: ak_your_api_key_here" \\
  -H "Content-Type: application/json" \\
  -d '{
    "text": "Check this message for inappropriate content"
  }'`
    }
  };

  const endpointCategories = [
    {
      title: "Content Moderation",
      icon: "🛡️",
      endpoints: ["moderate"]
    },
    {
      title: "Analytics",
      icon: "📊",
      endpoints: [],
      comingSoon: true
    }
  ];

  return (
    <div className="max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-slate-900 mb-3">API Documentation</h1>
        <p className="text-lg text-slate-600 mb-4">
          Complete reference for the Content Moderation API. Analyze and filter text content using AI-powered moderation.
        </p>
        
        {/* Quick Info Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-orange-50 border border-orange-200 rounded-lg p-4">
            <div className="flex items-center gap-2 mb-2">
              <div className="w-2 h-2 bg-orange-500 rounded-full"></div>
              <span className="font-medium text-orange-900">Base URL</span>
            </div>
            <code className="text-sm text-orange-800 font-mono">{baseUrl}</code>
          </div>
          
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <div className="flex items-center gap-2 mb-2">
              <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
              <span className="font-medium text-blue-900">Authentication</span>
            </div>
            <code className="text-sm text-blue-800 font-mono">X-API-Key header</code>
          </div>
          
          <div className="bg-green-50 border border-green-200 rounded-lg p-4">
            <div className="flex items-center gap-2 mb-2">
              <div className="w-2 h-2 bg-green-500 rounded-full"></div>
              <span className="font-medium text-green-900">Content Limit</span>
            </div>
            <span className="text-sm text-green-800">10,000 chars/request</span>
          </div>
          
          <div className="bg-purple-50 border border-purple-200 rounded-lg p-4">
            <div className="flex items-center gap-2 mb-2">
              <div className="w-2 h-2 bg-purple-500 rounded-full"></div>
              <span className="font-medium text-purple-900">Rate Limit</span>
            </div>
            <span className="text-sm text-purple-800">100 requests/month</span>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Sidebar Navigation */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-lg border border-slate-200 p-4 sticky top-6">
            <h3 className="font-semibold text-slate-900 mb-4">Endpoints</h3>
            
            {endpointCategories.map((category) => (
              <div key={category.title} className="mb-4">
                <div className="flex items-center gap-2 mb-2">
                  <span className="text-lg">{category.icon}</span>
                  <span className="text-sm font-medium text-slate-700">{category.title}</span>
                </div>
                
                <div className="ml-6 space-y-1">
                  {category.comingSoon ? (
                    <div className="px-3 py-2 text-sm text-slate-500 italic">
                      <div className="flex items-center gap-2">
                        <span className="px-2 py-1 bg-slate-100 text-slate-600 rounded text-xs">
                          Coming Soon
                        </span>
                        <span>Advanced Analytics</span>
                      </div>
                    </div>
                  ) : (
                    category.endpoints.map((endpointKey) => {
                      const endpoint = endpoints[endpointKey];
                      return (
                        <button
                          key={endpointKey}
                          onClick={() => setSelectedEndpoint(endpointKey)}
                          className={`w-full text-left px-3 py-2 rounded-md text-sm transition-colors ${
                            selectedEndpoint === endpointKey
                              ? "bg-orange-100 text-orange-900 border-l-2 border-orange-500"
                              : "text-slate-600 hover:bg-slate-50 hover:text-slate-900"
                          }`}
                        >
                          <div className="flex items-center gap-2">
                            <span className={`px-1.5 py-0.5 rounded text-xs font-mono ${
                              endpoint.method === 'GET' 
                                ? 'bg-blue-100 text-blue-800' 
                                : 'bg-green-100 text-green-800'
                            }`}>
                              {endpoint.method}
                            </span>
                            <span className="truncate">{endpoint.title}</span>
                          </div>
                        </button>
                      );
                    })
                  )}
                </div>
              </div>
            ))}
            
            {/* Quick Links */}
            <div className="mt-6 pt-4 border-t border-slate-200">
              <h4 className="text-sm font-medium text-slate-700 mb-2">Quick Links</h4>
              <div className="space-y-1">
                <a href="#authentication" className="block text-sm text-slate-600 hover:text-orange-600 transition-colors">
                  Authentication
                </a>
                <a href="#errors" className="block text-sm text-slate-600 hover:text-orange-600 transition-colors">
                  Error Codes
                </a>
                <a href="#rate-limits" className="block text-sm text-slate-600 hover:text-orange-600 transition-colors">
                  Rate Limits
                </a>
              </div>
            </div>
          </div>
        </div>

        {/* Main Content */}
        <div className="lg:col-span-3">
          {selectedEndpoint && (
            <EndpointCard 
              endpoint={endpoints[selectedEndpoint]}
              baseUrl={baseUrl}
            />
          )}
          
          {/* Additional Documentation Sections */}
          <div className="mt-8 space-y-8">
            {/* Authentication Section */}
            <section id="authentication" className="bg-white rounded-lg border border-slate-200 p-6">
              <h2 className="text-xl font-semibold text-slate-900 mb-4">Authentication</h2>
              <p className="text-slate-600 mb-4">
                All API endpoints require authentication using an API key. Include your API key in the request header:
              </p>
              
              <div className="space-y-4">
                <div>
                  <h4 className="font-medium text-slate-900 mb-2">Method 1: X-API-Key Header (Recommended)</h4>
                  <CodeBlock
                    language="bash"
                    code={`X-API-Key: ak_your_api_key_here`}
                  />
                </div>
                
                <div>
                  <h4 className="font-medium text-slate-900 mb-2">Method 2: Authorization Header</h4>
                  <CodeBlock
                    language="bash"
                    code={`Authorization: ApiKey ak_your_api_key_here`}
                  />
                </div>
              </div>
              
              <div className="mt-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
                <p className="text-sm text-blue-800">
                  <strong>Getting API Keys:</strong> Create and manage your API keys in the 
                  <a href="/apikeys" className="text-blue-600 hover:text-blue-800 underline ml-1">
                    API Keys section
                  </a> of this dashboard.
                </p>
              </div>
            </section>

            {/* Error Codes Section */}
            <section id="errors" className="bg-white rounded-lg border border-slate-200 p-6">
              <h2 className="text-xl font-semibold text-slate-900 mb-4">Error Codes</h2>
              
              <div className="space-y-4">
                <div className="border border-slate-200 rounded-lg overflow-hidden">
                  <table className="w-full">
                    <thead className="bg-slate-50">
                      <tr>
                        <th className="px-4 py-3 text-left text-sm font-medium text-slate-900">Status Code</th>
                        <th className="px-4 py-3 text-left text-sm font-medium text-slate-900">Description</th>
                        <th className="px-4 py-3 text-left text-sm font-medium text-slate-900">Example Response</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-200">
                      <tr>
                        <td className="px-4 py-3 text-sm font-mono text-red-600">401</td>
                        <td className="px-4 py-3 text-sm text-slate-600">Unauthorized - Invalid or missing API key</td>
                        <td className="px-4 py-3 text-sm font-mono text-slate-500">{`{"error": "Invalid API key"}`}</td>
                      </tr>
                      <tr>
                        <td className="px-4 py-3 text-sm font-mono text-yellow-600">429</td>
                        <td className="px-4 py-3 text-sm text-slate-600">Too Many Requests - Monthly quota exceeded</td>
                        <td className="px-4 py-3 text-sm font-mono text-slate-500">{`{"error": "Monthly quota exceeded"}`}</td>
                      </tr>
                      <tr>
                        <td className="px-4 py-3 text-sm font-mono text-red-600">400</td>
                        <td className="px-4 py-3 text-sm text-slate-600">Bad Request - Invalid request format</td>
                        <td className="px-4 py-3 text-sm font-mono text-slate-500">{`{"error": "Missing required field"}`}</td>
                      </tr>
                      <tr>
                        <td className="px-4 py-3 text-sm font-mono text-red-600">404</td>
                        <td className="px-4 py-3 text-sm text-slate-600">Not Found - Resource doesn't exist</td>
                        <td className="px-4 py-3 text-sm font-mono text-slate-500">{`{"error": "User not found"}`}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </section>

            {/* Rate Limits Section */}
            <section id="rate-limits" className="bg-white rounded-lg border border-slate-200 p-6">
              <h2 className="text-xl font-semibold text-slate-900 mb-4">Rate Limits</h2>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="p-4 bg-orange-50 border border-orange-200 rounded-lg">
                  <h4 className="font-medium text-orange-900 mb-2">Monthly Quota</h4>
                  <p className="text-sm text-orange-800">100 requests per API key per month</p>
                </div>
                
                <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                  <h4 className="font-medium text-blue-900 mb-2">Quota Reset</h4>
                  <p className="text-sm text-blue-800">Resets on the 1st day of each month</p>
                </div>
              </div>
              
              <div className="mt-4 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                <p className="text-sm text-yellow-800">
                  <strong>Monitor Usage:</strong> Check your current usage and remaining quota in the 
                  <a href="/apikeys" className="text-yellow-600 hover:text-yellow-800 underline ml-1">
                    API Keys dashboard
                  </a>.
                </p>
              </div>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
}