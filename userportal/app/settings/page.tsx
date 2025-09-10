"use client";

import { useState } from "react";
import { useAuth } from "@/hooks/useAuth";
import { DashboardLayout } from "@/components/DashboardLayout";

export default function SettingsPage() {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState("profile");
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);

  // Form states
  const [profileData, setProfileData] = useState({
    username: user?.username || "",
    email: user?.email || "",
    currentPassword: "",
    newPassword: "",
    confirmPassword: "",
  });

  const [preferences, setPreferences] = useState({
    emailNotifications: true,
    apiKeyAlerts: true,
    usageAlerts: true,
    theme: "light",
    timezone: "UTC",
  });

  const tabs = [
    { id: "profile", name: "Profile", icon: "👤" },
    { id: "security", name: "Security", icon: "🔒" },
    { id: "preferences", name: "Preferences", icon: "⚙️" },
    { id: "billing", name: "Billing", icon: "💳" },
  ];

  const handleProfileUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setMessage(null);

    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));
      setMessage({ type: "success", text: "Profile updated successfully!" });
    } catch {
      setMessage({ type: "error", text: "Failed to update profile. Please try again." });
    } finally {
      setIsLoading(false);
    }
  };

  const handlePasswordChange = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (profileData.newPassword !== profileData.confirmPassword) {
      setMessage({ type: "error", text: "New passwords don&apos;t match." });
      return;
    }

    setIsLoading(true);
    setMessage(null);

    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));
      setMessage({ type: "success", text: "Password changed successfully!" });
      setProfileData(prev => ({ ...prev, currentPassword: "", newPassword: "", confirmPassword: "" }));
    } catch {
      setMessage({ type: "error", text: "Failed to change password. Please try again." });
    } finally {
      setIsLoading(false);
    }
  };

  const handlePreferencesUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setMessage(null);

    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));
      setMessage({ type: "success", text: "Preferences updated successfully!" });
    } catch {
      setMessage({ type: "error", text: "Failed to update preferences. Please try again." });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <DashboardLayout>
      <div className="p-6">
        <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-slate-900 mb-2">Settings</h1>
          <p className="text-slate-600">Manage your account settings and preferences</p>
        </div>

        {/* Message */}
        {message && (
          <div className={`mb-6 p-4 rounded-lg ${
            message.type === "success" 
              ? "bg-green-50 border border-green-200 text-green-800" 
              : "bg-red-50 border border-red-200 text-red-800"
          }`}>
            {message.text}
          </div>
        )}

        <div className="grid lg:grid-cols-4 gap-6">
          {/* Sidebar Navigation */}
          <div className="lg:col-span-1">
            <nav className="space-y-1">
              {tabs.map((tab) => (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`w-full flex items-center space-x-3 px-4 py-3 text-left rounded-lg transition-colors ${
                    activeTab === tab.id
                      ? "bg-orange-100 text-orange-700 border border-orange-200"
                      : "text-slate-600 hover:bg-slate-100"
                  }`}
                >
                  <span className="text-lg">{tab.icon}</span>
                  <span className="font-medium">{tab.name}</span>
                </button>
              ))}
            </nav>
          </div>

          {/* Content Area */}
          <div className="lg:col-span-3">
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              
              {/* Profile Tab */}
              {activeTab === "profile" && (
                <div>
                  <h2 className="text-xl font-semibold text-slate-900 mb-6">Profile Information</h2>
                  
                  <form onSubmit={handleProfileUpdate} className="space-y-6">
                    <div className="grid md:grid-cols-2 gap-6">
                      <div>
                        <label className="block text-sm font-medium text-slate-700 mb-2">
                          Username
                        </label>
                        <input
                          type="text"
                          value={profileData.username}
                          onChange={(e) => setProfileData(prev => ({ ...prev, username: e.target.value }))}
                          className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
                        />
                      </div>
                      
                      <div>
                        <label className="block text-sm font-medium text-slate-700 mb-2">
                          Email Address
                        </label>
                        <input
                          type="email"
                          value={profileData.email}
                          onChange={(e) => setProfileData(prev => ({ ...prev, email: e.target.value }))}
                          className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
                        />
                      </div>
                    </div>

                    <div className="flex justify-end">
                      <button
                        type="submit"
                        disabled={isLoading}
                        className="px-6 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                      >
                        {isLoading ? "Updating..." : "Update Profile"}
                      </button>
                    </div>
                  </form>
                </div>
              )}

              {/* Security Tab */}
              {activeTab === "security" && (
                <div>
                  <h2 className="text-xl font-semibold text-slate-900 mb-6">Security Settings</h2>
                  
                  <form onSubmit={handlePasswordChange} className="space-y-6">
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-2">
                        Current Password
                      </label>
                      <input
                        type="password"
                        value={profileData.currentPassword}
                        onChange={(e) => setProfileData(prev => ({ ...prev, currentPassword: e.target.value }))}
                        className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
                        required
                      />
                    </div>

                    <div className="grid md:grid-cols-2 gap-6">
                      <div>
                        <label className="block text-sm font-medium text-slate-700 mb-2">
                          New Password
                        </label>
                        <input
                          type="password"
                          value={profileData.newPassword}
                          onChange={(e) => setProfileData(prev => ({ ...prev, newPassword: e.target.value }))}
                          className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
                          required
                        />
                      </div>
                      
                      <div>
                        <label className="block text-sm font-medium text-slate-700 mb-2">
                          Confirm New Password
                        </label>
                        <input
                          type="password"
                          value={profileData.confirmPassword}
                          onChange={(e) => setProfileData(prev => ({ ...prev, confirmPassword: e.target.value }))}
                          className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
                          required
                        />
                      </div>
                    </div>

                    <div className="bg-slate-50 p-4 rounded-lg">
                      <h3 className="font-medium text-slate-900 mb-2">Password Requirements</h3>
                      <ul className="text-sm text-slate-600 space-y-1">
                        <li>• At least 8 characters long</li>
                        <li>• Contains uppercase and lowercase letters</li>
                        <li>• Contains at least one number</li>
                        <li>• Contains at least one special character</li>
                      </ul>
                    </div>

                    <div className="flex justify-end">
                      <button
                        type="submit"
                        disabled={isLoading}
                        className="px-6 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                      >
                        {isLoading ? "Changing..." : "Change Password"}
                      </button>
                    </div>
                  </form>
                </div>
              )}

              {/* Preferences Tab */}
              {activeTab === "preferences" && (
                <div>
                  <h2 className="text-xl font-semibold text-slate-900 mb-6">Preferences</h2>
                  
                  <form onSubmit={handlePreferencesUpdate} className="space-y-6">
                    <div>
                      <h3 className="text-lg font-medium text-slate-900 mb-4">Notifications</h3>
                      <div className="space-y-4">
                        {[
                          { key: "emailNotifications", label: "Email Notifications", description: "Receive general updates via email" },
                          { key: "apiKeyAlerts", label: "API Key Alerts", description: "Get notified when API keys are created or deleted" },
                          { key: "usageAlerts", label: "Usage Alerts", description: "Receive alerts when approaching usage limits" },
                        ].map((item) => (
                          <div key={item.key} className="flex items-center justify-between">
                            <div>
                              <label className="text-sm font-medium text-slate-700">{item.label}</label>
                              <p className="text-sm text-slate-500">{item.description}</p>
                            </div>
                            <label className="relative inline-flex items-center cursor-pointer">
                              <input
                                type="checkbox"
                                checked={preferences[item.key as keyof typeof preferences] as boolean}
                                onChange={(e) => setPreferences(prev => ({ ...prev, [item.key]: e.target.checked }))}
                                className="sr-only peer"
                              />
                              <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-orange-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-orange-600"></div>
                            </label>
                          </div>
                        ))}
                      </div>
                    </div>

                    <div>
                      <h3 className="text-lg font-medium text-slate-900 mb-4">Display</h3>
                      <div className="grid md:grid-cols-2 gap-6">
                        <div>
                          <label className="block text-sm font-medium text-slate-700 mb-2">
                            Theme
                          </label>
                          <select
                            value={preferences.theme}
                            onChange={(e) => setPreferences(prev => ({ ...prev, theme: e.target.value }))}
                            className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
                          >
                            <option value="light">Light</option>
                            <option value="dark">Dark</option>
                            <option value="system">System</option>
                          </select>
                        </div>
                        
                        <div>
                          <label className="block text-sm font-medium text-slate-700 mb-2">
                            Timezone
                          </label>
                          <select
                            value={preferences.timezone}
                            onChange={(e) => setPreferences(prev => ({ ...prev, timezone: e.target.value }))}
                            className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
                          >
                            <option value="UTC">UTC</option>
                            <option value="America/New_York">Eastern Time</option>
                            <option value="America/Chicago">Central Time</option>
                            <option value="America/Denver">Mountain Time</option>
                            <option value="America/Los_Angeles">Pacific Time</option>
                          </select>
                        </div>
                      </div>
                    </div>

                    <div className="flex justify-end">
                      <button
                        type="submit"
                        disabled={isLoading}
                        className="px-6 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                      >
                        {isLoading ? "Saving..." : "Save Preferences"}
                      </button>
                    </div>
                  </form>
                </div>
              )}

              {/* Billing Tab */}
              {activeTab === "billing" && (
                <div>
                  <h2 className="text-xl font-semibold text-slate-900 mb-6">Billing & Usage</h2>
                  
                  <div className="space-y-6">
                    {/* Current Plan */}
                    <div className="bg-gradient-to-r from-orange-50 to-orange-100 p-6 rounded-lg border border-orange-200">
                      <div className="flex items-center justify-between">
                        <div>
                          <h3 className="text-lg font-semibold text-orange-900">Free Plan</h3>
                          <p className="text-orange-700">Up to 3 API keys and 300 requests per month</p>
                        </div>
                        <div className="text-right">
                          <div className="text-2xl font-bold text-orange-900">$0</div>
                          <div className="text-sm text-orange-700">per month</div>
                        </div>
                      </div>
                    </div>

                    {/* Usage Stats */}
                    <div>
                      <h3 className="text-lg font-medium text-slate-900 mb-4">Current Usage</h3>
                      <div className="grid md:grid-cols-2 gap-6">
                        <div className="bg-slate-50 p-4 rounded-lg">
                          <div className="flex items-center justify-between mb-2">
                            <span className="text-sm font-medium text-slate-700">API Keys</span>
                            <span className="text-sm text-slate-600">1 / 3</span>
                          </div>
                          <div className="w-full bg-slate-200 rounded-full h-2">
                            <div className="bg-orange-600 h-2 rounded-full" style={{ width: "33%" }}></div>
                          </div>
                        </div>
                        
                        <div className="bg-slate-50 p-4 rounded-lg">
                          <div className="flex items-center justify-between mb-2">
                            <span className="text-sm font-medium text-slate-700">API Requests</span>
                            <span className="text-sm text-slate-600">6 / 300</span>
                          </div>
                          <div className="w-full bg-slate-200 rounded-full h-2">
                            <div className="bg-orange-600 h-2 rounded-full" style={{ width: "24.7%" }}></div>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Upgrade Options */}
                    <div>
                      <h3 className="text-lg font-medium text-slate-900 mb-4">Upgrade Options</h3>
                      <div className="grid md:grid-cols-2 gap-6">
                        <div className="border border-slate-200 rounded-lg p-6">
                          <h4 className="text-lg font-semibold text-slate-900 mb-2">Pro Plan</h4>
                          <div className="text-3xl font-bold text-slate-900 mb-2">$29<span className="text-lg font-normal text-slate-600">/month</span></div>
                          <ul className="text-sm text-slate-600 space-y-2 mb-4">
                            <li>• Up to 10 API keys</li>
                            <li>• 50,000 requests per month</li>
                            <li>• Priority support</li>
                            <li>• Advanced analytics</li>
                          </ul>
                          <button className="w-full px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors">
                            Upgrade to Pro
                          </button>
                        </div>
                        
                        <div className="border border-slate-200 rounded-lg p-6">
                          <h4 className="text-lg font-semibold text-slate-900 mb-2">Enterprise</h4>
                          <div className="text-3xl font-bold text-slate-900 mb-2">Custom</div>
                          <ul className="text-sm text-slate-600 space-y-2 mb-4">
                            <li>• Unlimited API keys</li>
                            <li>• Custom request limits</li>
                            <li>• Dedicated support</li>
                            <li>• Custom integrations</li>
                          </ul>
                          <button className="w-full px-4 py-2 border border-slate-300 text-slate-700 rounded-lg hover:bg-slate-50 transition-colors">
                            Contact Sales
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}