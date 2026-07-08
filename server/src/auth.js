import { OAuth2Client } from "google-auth-library";
import jwt from "jsonwebtoken";

const CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const JWT_SECRET = process.env.JWT_SECRET || "dev-insecure-secret-change-me";
const client = new OAuth2Client();

/** Verify a Google ID token (from Google Sign-In in the PWA). Returns null on
 *  any invalid/expired/malformed token so callers can respond 401, not 500. */
export async function verifyGoogle(idToken) {
  try {
    const ticket = await client.verifyIdToken({ idToken, audience: CLIENT_ID });
    const p = ticket.getPayload();
    if (!p || !p.sub) return null;
    return { sub: p.sub, email: p.email ?? null };
  } catch {
    return null;
  }
}

/** App session token (sent by the PWA on every /api/state call). */
export function signToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: "60d" });
}

export function authMiddleware(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: "missing token" });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: "invalid token" });
  }
}
