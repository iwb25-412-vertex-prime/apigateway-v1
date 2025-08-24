"use client";

import { useState } from "react";

interface CodeBlockProps {
  language: string;
  code: string;
  showCopy?: boolean;
}

export function CodeBlock({ language, code, showCopy = true }: CodeBlockProps) {
  const [copied, setCopied] = useState(false);

  const copyToClipboard = async () => {
    try {
      await navigator.clipboard.writeText(code);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error('Failed to copy code:', err);
    }
  };

  const getLanguageColor = (lang: string) => {
    switch (lang.toLowerCase()) {
      case 'json':
        return 'text-yellow-400';
      case 'javascript':
        return 'text-yellow-300';
      case 'python':
        return 'text-blue-400';
      case 'bash':
        return 'text-green-400';
      default:
        return 'text-slate-300';
    }
  };

  return (
    <div className="relative">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-2 bg-slate-800 border-b border-slate-700">
        <span className={`text-xs font-medium ${getLanguageColor(language)}`}>
          {language.toUpperCase()}
        </span>
        
        {showCopy && (
          <button
            onClick={copyToClipboard}
            className="flex items-center gap-1 px-2 py-1 text-xs text-slate-300 hover:text-white bg-slate-700 hover:bg-slate-600 rounded transition-colors"
          >
            {copied ? (
              <>
                <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
                Copied!
              </>
            ) : (
              <>
                <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
                Copy
              </>
            )}
          </button>
        )}
      </div>

      {/* Code Content */}
      <div className="p-4 bg-slate-900 overflow-x-auto">
        <pre className="text-sm text-slate-100 font-mono leading-relaxed">
          <code className="whitespace-pre">{code}</code>
        </pre>
      </div>
    </div>
  );
}