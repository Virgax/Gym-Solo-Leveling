import { useEffect, useState } from "react";
import type { User } from "@supabase/supabase-js";
import { isCloudConfigured, supabase } from "./supabase";

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [ready, setReady] = useState(!isCloudConfigured);

  useEffect(() => {
    if (!supabase) return;
    supabase.auth.getSession().then(({ data }) => {
      setUser(data.session?.user ?? null);
      setReady(true);
    });
    const { data: sub } = supabase.auth.onAuthStateChange((_e, session) => setUser(session?.user ?? null));
    return () => sub.subscription.unsubscribe();
  }, []);

  const redirectTo = typeof window !== "undefined" ? window.location.href : undefined;

  return {
    user,
    ready,
    configured: isCloudConfigured,
    signInWithGoogle: () => supabase?.auth.signInWithOAuth({ provider: "google", options: { redirectTo } }),
    signInWithEmail: (email: string) => supabase?.auth.signInWithOtp({ email, options: { emailRedirectTo: redirectTo } }),
    signOut: () => supabase?.auth.signOut(),
  };
}

export type Auth = ReturnType<typeof useAuth>;
