// API Key management utilities for working with Ballerina backend

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api";

export interface ApiKey {
  id: string;
  name: string;
  description?: string;
  key_hash: string;
  rules: string[];
  status: 'active' | 'inactive' | 'revoked';
  usage_count: number;
  monthly_quota: number;
  current_month_usage: number;
  remaining_quota: number;
  quota_reset_date: string;
  created_at: string;
  updated_at: string;
}

export interface CreateApiKeyRequest {
  name: string;
  description?: string;
  rules: string[];
}

export interface CreateApiKeyResponse {
  message: string;
  apiKey: {
    id: string;
    name: string;
    description?: string;
    rules: string[];
    status: string;
    usage_count: number;
    monthly_quota: number;
    current_month_usage: number;
    remaining_quota: number;
    quota_reset_date: string;
    created_at: string;
    updated_at: string;
  };
  key: string; // The actual API key (only returned on creation)
}

export interface QuotaStatus {
  keyId: string;
  monthlyQuota: number;
  currentMonthUsage: number;
  remainingQuota: number;
  quotaResetDate: string;
  quotaAvailable: boolean;
  status: string;
}

export interface UpdateApiKeyStatusRequest {
  status: 'active' | 'inactive';
}

export interface UpdateApiKeyRulesRequest {
  rules: string[];
}

export class ApiKeyService {
  // Get authentication token from localStorage
  private static getToken(): string | null {
    if (typeof window === "undefined") return null;
    return localStorage.getItem("auth_token");
  }

  // Create a new API key
  static async createApiKey(data: CreateApiKeyRequest): Promise<CreateApiKeyResponse | null> {
    try {
      const token = this.getToken();
      if (!token) throw new Error("No authentication token");

      const response = await fetch(`${API_BASE_URL}/apikeys`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${token}`,
        },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || "Failed to create API key");
      }

      return await response.json();
    } catch (error) {
      console.error("Create API key error:", error);
      throw error;
    }
  }

  // Get all API keys for the current user
  static async getApiKeys(): Promise<ApiKey[]> {
    try {
      const token = this.getToken();
      if (!token) throw new Error("No authentication token");

      const response = await fetch(`${API_BASE_URL}/apikeys`, {
        headers: {
          "Authorization": `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || "Failed to fetch API keys");
      }

      const result = await response.json();
      return result.apiKeys || [];
    } catch (error) {
      console.error("Get API keys error:", error);
      throw error;
    }
  }

  // Update API key status
  static async updateApiKeyStatus(keyId: string, status: 'active' | 'inactive'): Promise<boolean> {
    try {
      const token = this.getToken();
      if (!token) throw new Error("No authentication token");

      const response = await fetch(`${API_BASE_URL}/apikeys/${keyId}/status`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${token}`,
        },
        body: JSON.stringify({ status }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || "Failed to update API key status");
      }

      return true;
    } catch (error) {
      console.error("Update API key status error:", error);
      throw error;
    }
  }

  // Update API key rules
  static async updateApiKeyRules(keyId: string, rules: string[]): Promise<ApiKey> {
    try {
      const token = this.getToken();
      if (!token) throw new Error("No authentication token");

      const response = await fetch(`${API_BASE_URL}/apikeys/${keyId}/rules`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${token}`,
        },
        body: JSON.stringify({ rules }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || "Failed to update API key rules");
      }

      const result = await response.json();
      return result.apiKey;
    } catch (error) {
      console.error("Update API key rules error:", error);
      throw error;
    }
  }

  // Delete (revoke) an API key
  static async deleteApiKey(keyId: string): Promise<boolean> {
    try {
      const token = this.getToken();
      if (!token) throw new Error("No authentication token");

      const response = await fetch(`${API_BASE_URL}/apikeys/${keyId}`, {
        method: "DELETE",
        headers: {
          "Authorization": `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || "Failed to delete API key");
      }

      return true;
    } catch (error) {
      console.error("Delete API key error:", error);
      throw error;
    }
  }

  // Validate an API key
  static async validateApiKey(apiKey: string): Promise<boolean> {
    try {
      const response = await fetch(`${API_BASE_URL}/apikeys/validate`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ apiKey }),
      });

      if (!response.ok) {
        return false;
      }

      const result = await response.json();
      return result.valid === true;
    } catch (error) {
      console.error("Validate API key error:", error);
      return false;
    }
  }

  // Get quota status for an API key
  static async getQuotaStatus(keyId: string): Promise<QuotaStatus> {
    try {
      const token = this.getToken();
      if (!token) throw new Error("No authentication token");

      const response = await fetch(`${API_BASE_URL}/apikeys/${keyId}/quota`, {
        headers: {
          "Authorization": `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || "Failed to fetch quota status");
      }

      return await response.json();
    } catch (error) {
      console.error("Get quota status error:", error);
      throw error;
    }
  }
}