'use client';

import { useState, useEffect, useContext, createContext, ReactNode } from 'react';
import { AuthService, User, LoginRequest, RegisterRequest } from '@/lib/auth';

interface AuthContextType {
  user: User | null;
  loading: boolean;
  login: (data: LoginRequest) => Promise<boolean>;
  register: (data: RegisterRequest) => Promise<boolean>;
  logout: () => Promise<void>;
  updateProfile: (data: Partial<User>) => Promise<boolean>;
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check if user is already logged in
    const initAuth = async () => {
      const storedUser = AuthService.getUser();
      if (storedUser && AuthService.isAuthenticated()) {
        // Verify token is still valid by fetching profile
        const profile = await AuthService.getProfile();
        if (profile) {
          setUser(profile);
        } else {
          // Token expired or invalid
          setUser(null);
        }
      }
      setLoading(false);
    };

    initAuth();
  }, []);

  const login = async (data: LoginRequest): Promise<boolean> => {
    setLoading(true);
    try {
      const result = await AuthService.login(data);
      if (result) {
        setUser(result.user);
        return true;
      }
      return false;
    } finally {
      setLoading(false);
    }
  };

  const register = async (data: RegisterRequest): Promise<boolean> => {
    setLoading(true);
    try {
      return await AuthService.register(data);
    } finally {
      setLoading(false);
    }
  };

  const logout = async (): Promise<void> => {
    setLoading(true);
    try {
      await AuthService.logout();
      setUser(null);
    } finally {
      setLoading(false);
    }
  };

  const updateProfile = async (data: Partial<User>): Promise<boolean> => {
    const success = await AuthService.updateProfile(data);
    if (success && user) {
      setUser({ ...user, ...data });
    }
    return success;
  };

  const value: AuthContextType = {
    user,
    loading,
    login,
    register,
    logout,
    updateProfile,
    isAuthenticated: !!user,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}