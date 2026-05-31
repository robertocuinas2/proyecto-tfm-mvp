const configuredApiUrl = process.env.NEXT_PUBLIC_API_URL;

export const API_BASE_URL = (
  configuredApiUrl === undefined ? "http://localhost:8000" : configuredApiUrl
).replace(/\/$/, "");

export const API_V1_URL = `${API_BASE_URL}/api/v1`;

export const TOKEN_STORAGE_KEY = "t4m_token";
export const USER_STORAGE_KEY = "t4m_user";
export const ACTIVE_ZONE_STORAGE_KEY = "t4m_active_zone";
export const ASSISTANT_ENABLED = process.env.NEXT_PUBLIC_ENABLE_ASSISTANT === "true";
