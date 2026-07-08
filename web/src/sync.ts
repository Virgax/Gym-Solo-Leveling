import { useEffect, useRef } from "react";
import type { User } from "@supabase/supabase-js";
import { supabase } from "./supabase";
import { AppState, getLocalTs } from "./store";

const TABLE = "user_state";

async function push(userId: string, state: AppState) {
  if (!supabase) return;
  await supabase.from(TABLE).upsert({ user_id: userId, state, updated_at: new Date().toISOString() });
}

/**
 * Two-way cloud sync (last-write-wins):
 *  - On sign-in, pull the remote copy if it's newer than local; otherwise seed
 *    the remote from local.
 *  - While signed in, debounce-push local changes to the cloud.
 * The app keeps working offline; this only runs when configured + signed in.
 */
export function useCloudSync(user: User | null, state: AppState, replaceState: (s: AppState) => void) {
  const pulled = useRef(false);

  useEffect(() => {
    if (!supabase || !user) { pulled.current = false; return; }
    let cancelled = false;
    (async () => {
      const { data } = await supabase!
        .from(TABLE)
        .select("state, updated_at")
        .eq("user_id", user.id)
        .maybeSingle();
      if (cancelled) return;
      if (data?.state) {
        const remoteTs = new Date(data.updated_at as string).getTime();
        if (remoteTs > getLocalTs()) replaceState(data.state as AppState);
        else await push(user.id, state);
      } else {
        await push(user.id, state);
      }
      pulled.current = true;
    })();
    return () => { cancelled = true; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user]);

  useEffect(() => {
    if (!supabase || !user || !pulled.current) return;
    const t = setTimeout(() => { void push(user.id, state); }, 1500);
    return () => clearTimeout(t);
  }, [state, user]);
}
