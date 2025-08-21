// Authentication utilities for working with Ballerina JWT backend

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api";

export interface User {
  id: string;
  username: string;
  email: string;
  created_at: string;
  updated_at: string;
  is_active: boolean;
}

export interface LoginRequest {
  username: string;
  password: string;
}

export interface RegisterRequest {
  username: string;
  email: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  message: string;
  user: User;
  expiresIn: number;
}

export class AuthService {
  private static TOKEN_KEY = "auth_token";
  private static USER_KEY = "auth_user";
  private static TOKEN_EXPIRY_KEY = "auth_token_expiry";

  // Register a new user
  static async register(data: RegisterRequest): Promise<boolean> {
    try {
      console.log(
        "Attempting to register with URL:",
        `${API_BASE_URL}/auth/register`
      );
      console.log("Registration data:", data);

      const response = await fetch(`${API_BASE_URL}/auth/register`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(data),
      });

      console.log("Registration response status:", response.status);
      console.log("Registration response ok:", response.ok);

      if (response.ok) {
        const result = await response.json();
        console.log("Registration result:", result);
      }

      return response.ok;
    } catch (error) {
      console.error("Registration error:", error);
      return false;
    }
  }

  // Login user
  static async login(data: LoginRequest): Promise<LoginResponse | null> {
    try {
      const response = await fetch(`${API_BASE_URL}/auth/login`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        const errorData = await response.json();
        console.error("Login failed:", errorData.error);
        return null;
      }

      const result: LoginResponse = await response.json();

      // Store token, user data, and expiry time
      if (typeof window !== "undefined") {
        const expiryTime = Date.now() + (result.expiresIn * 1000);
        localStorage.setItem(this.TOKEN_KEY, result.token);
        localStorage.setItem(this.USER_KEY, JSON.stringify(result.user));
        localStorage.setItem(this.TOKEN_EXPIRY_KEY, expiryTime.toString());
      }

      return result;
    } catch (error) {
      console.error("Login error:", error);
      return null;
    }
  }

  // Logout user
  static async logout(): Promise<void> {
    try {
      const token = this.getToken();
      if (token) {
        await fetch(`${API_BASE_URL}/auth/logout`, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${token}`,
          },
        });
      }
    } catch (error) {
      console.error("Logout error:", error);
    } finally {
      // Clear all stored auth data
      this.clearStorage();
    }
  }

  // Get stored token
  static getToken(): string | null {
    if (typeof window === "undefined") return null;
    return localStorage.getItem(this.TOKEN_KEY);
  }

  // Get stored user
  static getUser(): User | null {
    if (typeof window === "undefined") return null;
    const userStr = localStorage.getItem(this.USER_KEY);
    return userStr ? JSON.parse(userStr) : null;
  }

  // Check if user is authenticated
  static isAuthenticated(): boolean {
    const token = this.getToken();
    if (!token) return false;

    // Check if token is expired
    const expiryTime = this.getTokenExpiry();
    if (expiryTime && Date.now() > expiryTime) {
      this.clearStorage();
      return false;
    }

    return true;
  }

  // Get token expiry time
  private static getTokenExpiry(): number | null {
    if (typeof window === "undefined") return null;
    const expiry = localStorage.getItem(this.TOKEN_EXPIRY_KEY);
    return expiry ? parseInt(expiry) : null;
  }

  // Clear all stored auth data
  private static clearStorage(): void {
    if (typeof window !== "undefined") {
      localStorage.removeItem(this.TOKEN_KEY);
      localStorage.removeItem(this.USER_KEY);
      localStorage.removeItem(this.TOKEN_EXPIRY_KEY);
    }
  }

  // Get user profile from backend
  static async getProfile(): Promise<User | null> {
    try {
      const token = this.getToken();
      if (!token || !this.isAuthenticated()) return null;

      const response = await fetch(`${API_BASE_URL}/auth/profile`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        // Token might be expired or invalid, clear storage
        this.clearStorage();
        return null;
      }

      const result = await response.json();
      return result.user;
    } catch (error) {
      console.error("Profile fetch error:", error);
      this.clearStorage();
      return null;
    }
  }

  // Update user profile
  static async updateProfile(data: Partial<User>): Promise<boolean> {
    try {
      const token = this.getToken();
      if (!token) return false;

      const response = await fetch(`${API_BASE_URL}/auth/profile`, {
        method: "PUT",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(data),
      });

      if (response.ok) {
        // Update local user data
        const currentUser = this.getUser();
        if (currentUser && typeof window !== "undefined") {
          const updatedUser = { ...currentUser, ...data };
          localStorage.setItem(this.USER_KEY, JSON.stringify(updatedUser));
        }
        return true;
      }

      return false;
    } catch (error) {
      console.error("Profile update error:", error);
      return false;
    }
  }

  // Make authenticated API request
  static async authenticatedFetch(
    url: string,
    options: RequestInit = {}
  ): Promise<Response> {
    const token = this.getToken();

    const headers = {
      ...options.headers,
      ...(token && { Authorization: `Bearer ${token}` }),
    };

    return fetch(url, {
      ...options,
      headers,
    });
  }
}
