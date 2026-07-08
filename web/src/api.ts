// Talks to the Arise API on Railway. When VITE_API_URL is unset the app stays
// fully local-first (no cloud calls).
const API_URL = (import.meta.env.VITE_API_URL as string | undefined)?.replace(/\/+$/, "");
export const GOOGLE_CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID as string | undefined;
export const apiConfigured = Boolean(API_URL && GOOGLE_CLIENT_ID);

export interface AriseUser { id: string; email: string; }

export async function authGoogle(idToken: string): Promise<{ token: string; user: AriseUser }> {
  const r = await fetch(`${API_URL}/api/auth/google`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ idToken }),
  });
  if (!r.ok) throw new Error(`auth failed (${r.status})`);
  return r.json();
}

export async function getRemoteState(jwt: string): Promise<{ state: unknown; updatedAt: string | null }> {
  const r = await fetch(`${API_URL}/api/state`, { headers: { Authorization: `Bearer ${jwt}` } });
  if (!r.ok) throw new Error(`get state failed (${r.status})`);
  return r.json();
}

export async function putRemoteState(jwt: string, state: unknown): Promise<{ updatedAt: string }> {
  const r = await fetch(`${API_URL}/api/state`, {
    method: "PUT",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${jwt}` },
    body: JSON.stringify({ state }),
  });
  if (!r.ok) throw new Error(`put state failed (${r.status})`);
  return r.json();
}
