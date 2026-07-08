import { useEffect, useRef } from "react";
import { getRemoteState, putRemoteState } from "./api";
import { AppState, getLocalTs } from "./store";

/**
 * Two-way cloud sync against the Railway API (last-write-wins):
 *  - On sign-in, pull the remote copy if it's newer than local; otherwise seed
 *    the remote from local.
 *  - While signed in, debounce-push local changes.
 * Fully local-first: nothing runs until there's a session JWT.
 */
export function useCloudSync(jwt: string | null, state: AppState, replaceState: (s: AppState) => void) {
  const pulled = useRef(false);

  useEffect(() => {
    if (!jwt) { pulled.current = false; return; }
    let cancelled = false;
    (async () => {
      try {
        const { state: remote, updatedAt } = await getRemoteState(jwt);
        if (cancelled) return;
        if (remote && updatedAt && new Date(updatedAt).getTime() > getLocalTs()) {
          replaceState(remote as AppState);
        } else {
          await putRemoteState(jwt, state);
        }
      } catch (e) {
        console.error("[sync] pull failed", e);
      }
      pulled.current = true;
    })();
    return () => { cancelled = true; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [jwt]);

  useEffect(() => {
    if (!jwt || !pulled.current) return;
    const t = setTimeout(() => { putRemoteState(jwt, state).catch((e) => console.error("[sync] push failed", e)); }, 1500);
    return () => clearTimeout(t);
  }, [state, jwt]);
}
