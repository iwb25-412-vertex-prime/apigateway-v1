"use client";

import Link from "next/link";
import { DashboardLayout } from "@/components/DashboardLayout";
import { DashboardHome } from "@/components/DashboardHome";
import { useAuth } from "@/hooks/useAuth";

export default function Home() {
  const { isAuthenticated } = useAuth();

  if (!isAuthenticated) {
    return (
      <DashboardLayout>
        <div className="max-w-4xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <h1 className="text-4xl font-bold text-gray-900 mb-4">
              Welcome to Modarato API
            </h1>
            <p className="text-xl text-gray-600 mb-8">
              A SaaS platform that enables developers to define and enforce
              custom content policies via API
            </p>

            <div className="grid md:grid-cols-2 gap-8 max-w-2xl mx-auto mb-12">
              <div className="bg-white p-6 rounded-lg shadow-sm border">
                <div className="text-blue-600 mb-4">
                  <svg
                    className="w-8 h-8 mx-auto"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                    />
                  </svg>
                </div>
                <h3 className="text-lg font-semibold text-gray-900 mb-2">
                  Secure Authentication
                </h3>
                <p className="text-gray-600">
                  JWT-like tokens with database tracking and secure password
                  hashing
                </p>
              </div>

              <div className="bg-white p-6 rounded-lg shadow-sm border">
                <div className="text-green-600 mb-4">
                  <svg
                    className="w-8 h-8 mx-auto"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1721 9z"
                    />
                  </svg>
                </div>
                <h3 className="text-lg font-semibold text-gray-900 mb-2">
                  Content Policy API
                </h3>
                <p className="text-gray-600">
                  Create and manage up to 3 API keys with custom content policy
                  rules
                </p>
              </div>
            </div>

            <div className="space-y-4">
              <Link
                href="/auth"
                className="inline-block bg-blue-600 text-white px-8 py-3 rounded-lg text-lg font-medium hover:bg-blue-700 transition-colors"
              >
                Get Started
              </Link>
              <p className="text-gray-500">
                Already have an account?{" "}
                <Link
                  href="/auth"
                  className="text-blue-600 hover:text-blue-700"
                >
                  Sign in
                </Link>
              </p>
            </div>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <DashboardHome />
    </DashboardLayout>
  );
}
