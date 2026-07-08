import express from "express";
import cors from "cors";
import { pool, migrate } from "./db.js";
import { authMiddleware, signToken, verifyGoogle } from "./auth.js";

const app = express();
app.use(express.json({ limit: "1mb" }));

// CORS: allow the PWA origin(s). Set CORS_ORIGIN to your Pages origin
// (e.g. https://virgax.github.io). Comma-separate multiple; "*" allows all.
const originEnv = process.env.CORS_ORIGIN || "*";
app.use(cors({ origin: originEnv === "*" ? true : originEnv.split(",").map((s) => s.trim()) }));

app.get("/health", (_req, res) => res.json({ ok: true, service: "arise-server" }));

// Sign in: PWA sends a Google ID token → we verify it and return a session JWT.
app.post("/api/auth/google", async (req, res) => {
  try {
    const { idToken } = req.body || {};
    if (!idToken) return res.status(400).json({ error: "idToken required" });
    const g = await verifyGoogle(idToken);
    if (!g) return res.status(401).json({ error: "invalid Google token" });
    await pool.query(
      "insert into users (id, email) values ($1, $2) on conflict (id) do update set email = excluded.email",
      [g.sub, g.email],
    );
    res.json({ token: signToken({ sub: g.sub, email: g.email }), user: { id: g.sub, email: g.email } });
  } catch (err) {
    console.error("[auth] ", err);
    res.status(500).json({ error: "auth failed" });
  }
});

// Pull the user's saved state.
app.get("/api/state", authMiddleware, async (req, res) => {
  try {
    const { rows } = await pool.query("select state, updated_at from user_state where user_id = $1", [req.user.sub]);
    if (!rows.length) return res.json({ state: null, updatedAt: null });
    res.json({ state: rows[0].state, updatedAt: rows[0].updated_at });
  } catch (err) {
    console.error("[state:get] ", err);
    res.status(500).json({ error: "read failed" });
  }
});

// Push (upsert) the user's state.
app.put("/api/state", authMiddleware, async (req, res) => {
  try {
    const { state } = req.body || {};
    if (!state) return res.status(400).json({ error: "state required" });
    const { rows } = await pool.query(
      `insert into user_state (user_id, state, updated_at) values ($1, $2, now())
       on conflict (user_id) do update set state = excluded.state, updated_at = now()
       returning updated_at`,
      [req.user.sub, state],
    );
    res.json({ updatedAt: rows[0].updated_at });
  } catch (err) {
    console.error("[state:put] ", err);
    res.status(500).json({ error: "write failed" });
  }
});

const port = process.env.PORT || 3000;
migrate()
  .catch((err) => console.error("[db] migration error:", err))
  .finally(() => app.listen(port, () => console.log(`[arise-server] listening on ${port}`)));
