'use client';

import { useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { Navigation } from '@/components/Navigation';
import LoginForm from '@/components/LoginForm';
import RegisterForm from '@/components/RegisterForm';
import UserProfile from '@/components/UserProfile';

export default function AuthPage() {
  const [activeTab, setActiveTab] = useState<'login' | 'register'>('login');
  const { isAuthenticated, loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-50 via-white to-orange-50">
        <Navigation />
        <div className="flex items-center justify-center min-h-[calc(100vh-4rem)]">
          <div className="text-center">
            <div className="inline-block animate-spin rounded-full h-12 w-12 border-4 border-orange-200 border-t-orange-600 shadow-lg"></div>
            <p className="mt-4 text-slate-600 font-medium">Loading...</p>
          </div>
        </div>
      </div>
    );
  }

  if (isAuthenticated) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-50 via-white to-orange-50">
        <Navigation />
        <div className="py-12">
          <UserProfile />
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-white to-orange-50 relative overflow-hidden">
      {/* Background decorative elements */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-gradient-to-br from-orange-400/20 to-slate-400/20 rounded-full blur-3xl"></div>
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-gradient-to-tr from-slate-400/20 to-orange-400/20 rounded-full blur-3xl"></div>
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-gradient-to-br from-slate-400/10 to-orange-400/10 rounded-full blur-3xl"></div>
      </div>

      <Navigation />
      
      <div className="relative z-10 py-12 px-4">
        <div className="max-w-md mx-auto">
          {/* Tab Navigation */}
          <div className="backdrop-blur-xl bg-white/20 border border-white/30 rounded-2xl p-2 mb-8 shadow-lg">
            <div className="flex relative">
              <div 
                className={`absolute top-1 bottom-1 bg-white rounded-xl shadow-md transition-all duration-300 ease-out ${
                  activeTab === 'login' ? 'left-1 right-1/2 mr-1' : 'left-1/2 right-1 ml-1'
                }`}
              ></div>
              <button
                onClick={() => setActiveTab('login')}
                className={`relative z-10 flex-1 py-3 px-6 text-center font-semibold rounded-xl transition-all duration-300 ${
                  activeTab === 'login'
                    ? 'text-slate-900'
                    : 'text-slate-600 hover:text-slate-800'
                }`}
              >
                Sign In
              </button>
              <button
                onClick={() => setActiveTab('register')}
                className={`relative z-10 flex-1 py-3 px-6 text-center font-semibold rounded-xl transition-all duration-300 ${
                  activeTab === 'register'
                    ? 'text-slate-900'
                    : 'text-slate-600 hover:text-slate-800'
                }`}
              >
                Sign Up
              </button>
            </div>
          </div>

          {/* Form Container */}
          <div className="relative">
            <div className={`transition-all duration-500 ease-in-out ${
              activeTab === 'login' ? 'opacity-100 translate-x-0' : 'opacity-0 translate-x-4 absolute inset-0 pointer-events-none'
            }`}>
              {activeTab === 'login' && <LoginForm />}
            </div>
            <div className={`transition-all duration-500 ease-in-out ${
              activeTab === 'register' ? 'opacity-100 translate-x-0' : 'opacity-0 -translate-x-4 absolute inset-0 pointer-events-none'
            }`}>
              {activeTab === 'register' && <RegisterForm />}
            </div>
          </div>

          {/* Footer */}
          <div className="text-center mt-8">
            <p className="text-sm text-slate-600">
              By continuing, you agree to our{' '}
              <a href="#" className="text-orange-600 hover:text-orange-700 font-medium transition-colors duration-200">
                Terms of Service
              </a>{' '}
              and{' '}
              <a href="#" className="text-orange-600 hover:text-orange-700 font-medium transition-colors duration-200">
                Privacy Policy
              </a>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}