"use client";

import { useState } from "react";
import { CodeBlock } from "@/components/CodeBlock";

interface Endpoint {
  method: string;
  path: string;
  title: string;
  description: string;
  requestBody?: any;
  responseExample: any;
  curlExample: string;
}

interface EndpointCardProps {
  endpoint: Endpoint;
  baseUrl: string;
}

export function EndpointCard({ endpoint, baseUrl }: EndpointCardProps) {
  const [activeTab, setActiveTab] = useState<"curl" | "javascript" | "python">(
    "curl"
  );

  const getMethodColor = (method: string) => {
    switch (method) {
      case "GET":
        return "bg-blue-100 text-blue-800 border-blue-200";
      case "POST":
        return "bg-green-100 text-green-800 border-green-200";
      case "PUT":
        return "bg-yellow-100 text-yellow-800 border-yellow-200";
      case "DELETE":
        return "bg-red-100 text-red-800 border-red-200";
      default:
        return "bg-gray-100 text-gray-800 border-gray-200";
    }
  };

  const generateJavaScriptExample = () => {
    const hasBody = endpoint.requestBody;

    return `// Using fetch API
const response = await fetch('${baseUrl}${endpoint.path}', {
  method: '${endpoint.method}',
  headers: {
    'X-API-Key': 'ak_your_api_key_here',${
      hasBody
        ? `
    'Content-Type': 'application/json'`
        : ""
    }
  }${
    hasBody
      ? `,
  body: JSON.stringify(${JSON.stringify(endpoint.requestBody, null, 4)})`
      : ""
  }
});

const data = await response.json();
console.log(data);`;
  };

  const generatePythonExample = () => {
    const hasBody = endpoint.requestBody;

    return `import requests
import json

url = "${baseUrl}${endpoint.path}"
headers = {
    "X-API-Key": "ak_your_api_key_here"${
      hasBody
        ? `,
    "Content-Type": "application/json"`
        : ""
    }
}${
      hasBody
        ? `

data = ${JSON.stringify(endpoint.requestBody, null, 4)}

response = requests.${endpoint.method.toLowerCase()}(url, headers=headers, json=data)`
        : `

response = requests.${endpoint.method.toLowerCase()}(url, headers=headers)`
    }
print(response.json())`;
  };

  return (
    <div className="bg-white rounded-lg border border-slate-200 overflow-hidden">
      {/* Header */}
      <div className="p-6 border-b border-slate-200">
        <div className="flex items-center gap-3 mb-3">
          <span
            className={`px-3 py-1 rounded-md text-sm font-mono font-medium border ${getMethodColor(
              endpoint.method
            )}`}
          >
            {endpoint.method}
          </span>
          <code className="text-lg font-mono text-slate-700">
            {endpoint.path}
          </code>
        </div>

        <h2 className="text-2xl font-semibold text-slate-900 mb-2">
          {endpoint.title}
        </h2>
        <p className="text-slate-600">{endpoint.description}</p>
      </div>

      {/* Request Body Section */}
      {endpoint.requestBody && (
        <div className="p-6 border-b border-slate-200 bg-slate-50">
          <h3 className="text-lg font-semibold text-slate-900 mb-3">
            Request Body
          </h3>
          <div className="bg-white rounded-lg border border-slate-200 p-4">
            <CodeBlock
              language="json"
              code={JSON.stringify(endpoint.requestBody, null, 2)}
            />
          </div>

          {/* Parameter descriptions */}
          <div className="mt-4">
            <h4 className="font-medium text-slate-900 mb-2">Parameters</h4>
            <div className="space-y-2">
              {Object.entries(endpoint.requestBody).map(
                ([key, description]) => (
                  <div key={key} className="flex gap-3">
                    <code className="text-sm font-mono text-orange-600 bg-orange-50 px-2 py-1 rounded">
                      {key}
                    </code>
                    <span className="text-sm text-slate-600">
                      {description as string}
                    </span>
                  </div>
                )
              )}
            </div>
          </div>
        </div>
      )}

      {/* Code Examples */}
      <div className="p-6 border-b border-slate-200">
        <h3 className="text-lg font-semibold text-slate-900 mb-4">
          Code Examples
        </h3>

        {/* Tab Navigation */}
        <div className="flex border-b border-slate-200 mb-4">
          {[
            { key: "curl", label: "cURL", icon: "🔧" },
            { key: "javascript", label: "JavaScript", icon: "🟨" },
            { key: "python", label: "Python", icon: "🐍" },
          ].map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key as any)}
              className={`px-4 py-2 text-sm font-medium border-b-2 transition-colors ${
                activeTab === tab.key
                  ? "border-orange-500 text-orange-600"
                  : "border-transparent text-slate-600 hover:text-slate-900 hover:border-slate-300"
              }`}
            >
              <span className="mr-2">{tab.icon}</span>
              {tab.label}
            </button>
          ))}
        </div>

        {/* Code Content */}
        <div className="bg-slate-900 rounded-lg overflow-hidden">
          {activeTab === "curl" && (
            <CodeBlock language="bash" code={endpoint.curlExample} />
          )}

          {activeTab === "javascript" && (
            <CodeBlock
              language="javascript"
              code={generateJavaScriptExample()}
            />
          )}

          {activeTab === "python" && (
            <CodeBlock language="python" code={generatePythonExample()} />
          )}
        </div>
      </div>

      {/* Response Example */}
      <div className="p-6">
        <h3 className="text-lg font-semibold text-slate-900 mb-3">
          Response Example
        </h3>

        <div className="bg-slate-900 rounded-lg overflow-hidden">
          <div className="flex items-center justify-between px-4 py-2 bg-slate-800 border-b border-slate-700">
            <span className="text-sm font-medium text-slate-300">200 OK</span>
            <span className="text-xs text-slate-400">application/json</span>
          </div>

          <CodeBlock
            language="json"
            code={JSON.stringify(endpoint.responseExample, null, 2)}
          />
        </div>

        {/* Response Field Descriptions */}
        <div className="mt-4">
          <h4 className="font-medium text-slate-900 mb-2">Response Fields</h4>
          <div className="space-y-2 text-sm">
            {endpoint.path.includes("moderate-content") && (
              <>
                <div className="flex gap-3">
                  <code className="font-mono text-orange-600 bg-orange-50 px-2 py-1 rounded">
                    status
                  </code>
                  <span className="text-slate-600">
                    Always true for successful requests
                  </span>
                </div>
                <div className="flex gap-3">
                  <code className="font-mono text-orange-600 bg-orange-50 px-2 py-1 rounded">
                    result.flagged
                  </code>
                  <span className="text-slate-600">
                    Whether content was flagged as inappropriate
                  </span>
                </div>
                <div className="flex gap-3">
                  <code className="font-mono text-orange-600 bg-orange-50 px-2 py-1 rounded">
                    result.confidence
                  </code>
                  <span className="text-slate-600">
                    Confidence score (0.0 to 1.0)
                  </span>
                </div>
                <div className="flex gap-3">
                  <code className="font-mono text-orange-600 bg-orange-50 px-2 py-1 rounded">
                    result.categories
                  </code>
                  <span className="text-slate-600">
                    Array of detected issue categories
                  </span>
                </div>
                <div className="flex gap-3">
                  <code className="font-mono text-orange-600 bg-orange-50 px-2 py-1 rounded">
                    result.severity
                  </code>
                  <span className="text-slate-600">
                    Severity level: "none", "low", "medium", "high"
                  </span>
                </div>
                <div className="flex gap-3">
                  <code className="font-mono text-orange-600 bg-orange-50 px-2 py-1 rounded">
                    result.action_recommended
                  </code>
                  <span className="text-slate-600">
                    Recommended action: "approve", "review", "reject"
                  </span>
                </div>
              </>
            )}

            <div className="flex gap-3">
              <code className="font-mono text-orange-600 bg-orange-50 px-2 py-1 rounded">
                api_key_used
              </code>
              <span className="text-slate-600">
                Name of the API key used for the request
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
