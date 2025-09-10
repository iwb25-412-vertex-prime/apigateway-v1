"use client";

import { useState } from "react";
import { CodeBlock } from "./CodeBlock";

interface Endpoint {
  method: string;
  path: string;
  title: string;
  description: string;
  requestBody?: Record<string, unknown>;
  responseExample: Record<string, unknown>;
  curlExample: string;
}

interface EndpointCardProps {
  endpoint: Endpoint;
  baseUrl: string;
}

export function EndpointCard({ endpoint, baseUrl }: EndpointCardProps) {
  const [activeTab, setActiveTab] = useState<"request" | "response" | "curl">("request");

  return (
    <div className="bg-white rounded-lg border border-slate-200 p-6">
      {/* Header */}
      <div className="mb-6">
        <div className="flex items-center gap-3 mb-3">
          <span className={`px-2 py-1 rounded text-sm font-mono font-medium ${
            endpoint.method === 'GET' 
              ? 'bg-blue-100 text-blue-800' 
              : 'bg-green-100 text-green-800'
          }`}>
            {endpoint.method}
          </span>
          <code className="text-lg font-mono text-slate-800">{endpoint.path}</code>
        </div>
        
        <h2 className="text-2xl font-bold text-slate-900 mb-2">{endpoint.title}</h2>
        <p className="text-slate-600">{endpoint.description}</p>
      </div>

      {/* Tabs */}
      <div className="border-b border-slate-200 mb-6">
        <nav className="flex space-x-8">
          {[
            { key: "request", label: "Request" },
            { key: "response", label: "Response" },
            { key: "curl", label: "cURL Example" }
          ].map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key as "request" | "response" | "curl")}
              className={`py-2 px-1 border-b-2 font-medium text-sm transition-colors ${
                activeTab === tab.key
                  ? "border-orange-500 text-orange-600"
                  : "border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300"
              }`}
            >
              {tab.label}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      <div className="space-y-6">
        {activeTab === "request" && (
          <div>
            <h3 className="text-lg font-semibold text-slate-900 mb-4">Request Format</h3>
            
            <div className="space-y-4">
              <div>
                <h4 className="font-medium text-slate-900 mb-2">Endpoint</h4>
                <CodeBlock
                  language="text"
                  code={`${endpoint.method} ${baseUrl}${endpoint.path}`}
                />
              </div>
              
              <div>
                <h4 className="font-medium text-slate-900 mb-2">Headers</h4>
                <CodeBlock
                  language="text"
                  code={`X-API-Key: ak_your_api_key_here
Content-Type: application/json`}
                />
              </div>
              
              {endpoint.requestBody && (
                <div>
                  <h4 className="font-medium text-slate-900 mb-2">Request Body</h4>
                  <CodeBlock
                    language="json"
                    code={JSON.stringify(endpoint.requestBody, null, 2)}
                  />
                </div>
              )}
            </div>
          </div>
        )}

        {activeTab === "response" && (
          <div>
            <h3 className="text-lg font-semibold text-slate-900 mb-4">Response Format</h3>
            
            <div className="space-y-4">
              <div>
                <h4 className="font-medium text-slate-900 mb-2">Success Response (200 OK)</h4>
                <CodeBlock
                  language="json"
                  code={JSON.stringify(endpoint.responseExample, null, 2)}
                />
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
                  <h5 className="font-medium text-green-900 mb-2">Response Fields</h5>
                  <ul className="text-sm text-green-800 space-y-1">
                    <li><code>status</code> - Request success indicator</li>
                    <li><code>result</code> - Moderation analysis results</li>
                    <li><code>metadata</code> - Request processing information</li>
                  </ul>
                </div>
                
                <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                  <h5 className="font-medium text-blue-900 mb-2">Result Fields</h5>
                  <ul className="text-sm text-blue-800 space-y-1">
                    <li><code>flagged</code> - Content flagged for review</li>
                    <li><code>confidence</code> - Analysis confidence (0-1)</li>
                    <li><code>categories</code> - Violation categories found</li>
                    <li><code>action_recommended</code> - Suggested action</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        )}

        {activeTab === "curl" && (
          <div>
            <h3 className="text-lg font-semibold text-slate-900 mb-4">cURL Example</h3>
            
            <div className="space-y-4">
              <CodeBlock
                language="bash"
                code={endpoint.curlExample}
              />
              
              <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                <p className="text-sm text-yellow-800">
                  <strong>Note:</strong> Replace <code>ak_your_api_key_here</code> with your actual API key from the 
                  <a href="/apikeys" className="text-yellow-600 hover:text-yellow-800 underline ml-1">
                    API Keys section
                  </a>.
                </p>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}