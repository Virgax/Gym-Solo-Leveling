import pg from "pg";

const { Pool } = pg;
const url = process.env.DATABASE_URL;

// Railway injects DATABASE_URL when you attach a Postgres plugin. Internal
// networking needs no SSL; set PGSSL=true if you use an external URL.
export const pool = new Pool(
  url
    ? { connectionString: url, ssl: process.env.PGSSL === "true" ? { rejectUnauthorized: false } : false }
    : {},
);

export async function migrate() {
  if (!url) {
    console.warn("[db] No DATABASE_URL set — skipping migration (health only).");
    return;
  }
  await pool.query(`
    create table if not exists users (
      id text primary key,
      email text,
      created_at timestamptz not null default now()
    );
    create table if not exists user_state (
      user_id    text primary key references users (id) on delete cascade,
      state      jsonb not null,
      updated_at timestamptz not null default now()
    );
  `);
  console.log("[db] migrated");
}
