"use client";

import Link from "next/link";
import { useAuth } from "@/hooks/useAuth";
import { AuthService } from "@/lib/auth";
import { useState, useEffect } from "react";

interface ApiKeyStats {
  totalKeys: number;
  activeKeys: number;
  totalUsage: number;
  monthlyUsage: number;
}

interface DashboardState {
  stats: ApiKeyStats;
  loading: boolean;
  refreshing: boolean;
  lastUpdated: Date | null;
}

export function DashboardHome() {
  const { user } = useAuth();
  const [dashboardState, setDashboardState] = useState<DashboardState>({
    stats: {
      totalKeys: 0,
      activeKeys: 0,
      totalUsage: 0,
      monthlyUsage: 0,
    },
    loading: true,
    refreshing: false,
    lastUpdated: null,
  });

  // Fetch API key statistics
  const fetchStats = async (isManualRefresh = false) => {
    console.log("fetchStats called, isManualRefresh:", isManualRefresh);
    
    // Set appropriate loading state
    if (isManualRefresh) {
      setDashboardState((prev) => ({ ...prev, refreshing: true }));
    } else if (dashboardState.stats.totalKeys === 0) {
      // Only show main loading on initial load
      setDashboardState((prev) => ({ ...prev, loading: true }));
    }

    try {
      const token = AuthService.getToken();
      console.log("Token exists:", !!token);
      console.log("Is authenticated:", AuthService.isAuthenticated());
      
      if (!token || !AuthService.isAuthenticated()) {
        console.log("No valid token found, clearing loading states");
        setDashboardState((prev) => ({ 
          ...prev, 
          loading: false, 
          refreshing: false 
        }));
        return;
      }

      console.log("Making API request to /api/apikeys");
      const response = await AuthService.authenticatedFetch("http://localhost:8080/api/apikeys");

      console.log("API response status:", response.status);

      if (response.ok) {
        const data = await response.json();
        console.log("API response data:", data);
        
        const apiKeys = data.apiKeys || [];
        console.log("API keys array:", apiKeys);

        const totalKeys = apiKeys.length;
        const activeKeys = apiKeys.filter(
          (key: any) => key.status === "active"
        ).length;
        const totalUsage = apiKeys.reduce(
          (sum: number, key: any) => {
            console.log(`Adding usage_count: ${key.usage_count} to sum: ${sum}`);
            return sum + (key.usage_count || 0);
          },
          0
        );
        const monthlyUsage = apiKeys.reduce(
          (sum: number, key: any) => {
            console.log(`Adding current_month_usage: ${key.current_month_usage} to sum: ${sum}`);
            return sum + (key.current_month_usage || 0);
          },
          0
        );

        console.log("Calculated stats:", { totalKeys, activeKeys, totalUsage, monthlyUsage });

        setDashboardState({
          stats: {
            totalKeys,
            activeKeys,
            totalUsage,
            monthlyUsage,
          },
          loading: false,
          refreshing: false,
          lastUpdated: new Date(),
        });
      } else {
        const errorText = await response.text();
        console.error("API request failed:", response.status, response.statusText, errorText);
        setDashboardState((prev) => ({ 
          ...prev, 
          loading: false, 
          refreshing: false 
        }));
      }
    } catch (error) {
      console.error("Failed to fetch API key stats:", error);
      setDashboardState((prev) => ({ 
        ...prev, 
        loading: false, 
        refreshing: false 
      }));
    }
  };

  useEffect(() => {
    fetchStats(false); // Initial load

    // Set up periodic refresh every 30 seconds to keep stats updated
    const interval = setInterval(() => fetchStats(false), 30000);

    return () => clearInterval(interval);
  }, []);

  const quickActions = [
    {
      title: "Create API Key",
      description: "Generate a new API key for your applications",
      href: "/apikeys",
      icon: (
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
            d="M12 6v6m0 0v6m0-6h6m-6 0H6"
          />
        </svg>
      ),
      color: "bg-orange-500 hover:bg-orange-600",
      buttonText: "Get Started", // Added button text
    },
    {
      title: "View Documentation",
      description: "Learn how to integrate Moderato API",
      href: "/docs",
      icon: (
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
            d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          />
        </svg>
      ),
      color: "bg-slate-500 hover:bg-slate-600",
      disabled: false,
      buttonText: "View Doc", // Changed button text here
    },
    {
      title: "API Testing",
      description: "Test your API keys and endpoints",
      href: "#",
      icon: (
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
            d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"
          />
        </svg>
      ),
      color: "bg-slate-600 hover:bg-slate-700",
      disabled: true,
    },
  ];

  const { stats, loading, refreshing, lastUpdated } = dashboardState;

  const statCards = [
    {
      title: "Total API Keys",
      value: loading ? "..." : stats.totalKeys,
      icon: (
        <svg
          className="w-8 h-8"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z"
          />
        </svg>
      ),
      color: "text-orange-600 bg-orange-100",
    },
    {
      title: "Active Keys",
      value: loading ? "..." : stats.activeKeys,
      icon: (
        <svg
          className="w-8 h-8"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
          />
        </svg>
      ),
      color: "text-green-600 bg-green-100",
    },
    {
      title: "Total Requests",
      value: loading ? "..." : stats.totalUsage.toLocaleString(),
      icon: (
        <svg
          className="w-8 h-8"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"
          />
        </svg>
      ),
      color: "text-slate-600 bg-slate-100",
    },
    {
      title: "This Month",
      value: loading ? "..." : stats.monthlyUsage.toLocaleString(),
      icon: (
        <svg
          className="w-8 h-8"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
          />
        </svg>
      ),
      color: "text-orange-600 bg-orange-100",
    },
  ];

  return (
    <div className="p-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-8 flex justify-between items-start">
        <div>
          <h1 className="text-3xl font-bold text-slate-900 mb-2">
            Welcome back, {user?.username}!
          </h1>
          <p className="text-slate-600">
            Manage your content policies and API keys from your dashboard
          </p>
          {lastUpdated && (
            <p className="text-sm text-slate-400 mt-1">
              Last updated: {lastUpdated.toLocaleTimeString()}
            </p>
          )}

        </div>
        <button
          onClick={() => fetchStats(true)}
          disabled={refreshing}
          className="flex items-center gap-2 px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          <svg
            className={`w-4 h-4 ${refreshing ? "animate-spin" : ""}`}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
            />
          </svg>
          {refreshing ? "Refreshing..." : "Refresh"}
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {statCards.map((stat, index) => (
          <div
            key={index}
            className="bg-white rounded-xl shadow-sm border border-slate-200 p-6 hover:shadow-md transition-shadow duration-200"
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 mb-1">
                  {stat.title}
                </p>
                <p className="text-2xl font-bold text-slate-900">
                  {stat.value}
                </p>
              </div>
              <div className={`p-3 rounded-lg ${stat.color}`}>{stat.icon}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Actions */}
      <div className="mb-8">
        <h2 className="text-xl font-semibold text-slate-900 mb-4">
          Quick Actions
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {quickActions.map((action, index) => (
            <div
              key={index}
              className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden hover:shadow-md transition-shadow duration-200"
            >
              {action.disabled ? (
                <div className="p-6 cursor-not-allowed opacity-60">
                  <div
                    className={`inline-flex items-center justify-center w-12 h-12 rounded-lg text-white mb-4 ${
                      action.color.split(" ")[0]
                    } opacity-50`}
                  >
                    {action.icon}
                  </div>
                  <h3 className="text-lg font-semibold text-slate-900 mb-2">
                    {action.title}
                  </h3>
                  <p className="text-slate-600 mb-4">{action.description}</p>
                  <span className="text-sm text-slate-400">Coming Soon</span>
                </div>
              ) : (
                <Link
                  href={action.href}
                  className="block p-6 hover:bg-slate-50 transition-colors"
                >
                  <div
                    className={`inline-flex items-center justify-center w-12 h-12 rounded-lg text-white mb-4 ${action.color}`}
                  >
                    {action.icon}
                  </div>
                  <h3 className="text-lg font-semibold text-slate-900 mb-2">
                    {action.title}
                  </h3>
                  <p className="text-slate-600 mb-4">{action.description}</p>
                  <div className="flex items-center text-orange-600 font-medium">
                    {action.buttonText} {/* Using the dynamic button text */}
                    <svg
                      className="w-4 h-4 ml-1"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </div>
                </Link>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Recent Activity */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6 hover:shadow-md transition-shadow duration-200">
        <h2 className="text-xl font-semibold text-slate-900 mb-4">
          Recent Activity
        </h2>
        <div className="text-center py-8">
          <svg
            className="w-12 h-12 text-slate-400 mx-auto mb-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
            />
          </svg>
          <p className="text-slate-500">No recent activity to display</p>
          <p className="text-sm text-slate-400 mt-1">
            Activity will appear here as you use your API keys
          </p>
        </div>
      </div>
    </div>
  );
}
