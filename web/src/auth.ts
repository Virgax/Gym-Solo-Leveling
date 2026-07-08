import { useCallback, useRef, useState } from "react";
import { apiConfigured, authGoogle, AriseUser, GOOGLE_CLIENT_ID } from "./api";

const JWT_KEY = "arise.jwt";
const USER_KEY = "arise.user";

function loadUser(): AriseUser | null {
  try { const u = localStorage.getItem(USER_KEY); return u ? JSON.parse(u) : null; } catch { return null; }
}

export function useAuth() {
  const [user, setUser] = useState<AriseUser | null>(loadUser);
  const [jwt, setJwt] = useState<string | null>(() => localStorage.getItem(JWT_KEY));
  const inited = useRef(false);
  const configured = apiConfigured;

  const handleCredential = useCallback(async (resp: { credential: string }) => {
    try {
      const { token, user: u } = await authGoogle(resp.credential);
      localStorage.setItem(JWT_KEY, token);
      localStorage.setItem(USER_KEY, JSON.stringify(u));
      setJwt(token);
      setUser(u);
    } catch (e) {
      console.error(e);
      alert("Sign-in failed. Please try again.");
    }
  }, []);

  const ensureInit = useCallback(() => {
    const g = (window as any).google;
    if (!g?.accounts?.id || !GOOGLE_CLIENT_ID) return false;
    if (!inited.current) {
      g.accounts.id.initialize({ client_id: GOOGLE_CLIENT_ID, callback: handleCredential });
      inited.current = true;
    }
    return true;
  }, [handleCredential]);

  const renderButton = useCallback((el: HTMLElement) => {
    if (!ensureInit()) return false;
    (window as any).google.accounts.id.renderButton(el, {
      theme: "filled_black", size: "large", shape: "pill", text: "continue_with", width: 300,
    });
    return true;
  }, [ensureInit]);

  const signOut = useCallback(() => {
    localStorage.removeItem(JWT_KEY);
    localStorage.removeItem(USER_KEY);
    setJwt(null);
    setUser(null);
    (window as any).google?.accounts?.id?.disableAutoSelect?.();
  }, []);

  return { user, jwt, configured, renderButton, signOut };
}

export type Auth = ReturnType<typeof useAuth>;
