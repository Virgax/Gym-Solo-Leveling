import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Base path is "/" for local dev / root hosting (Railway, Vercel) and
// "/Gym-Solo-Leveling/" for GitHub Pages (set via VITE_BASE in CI).
export default defineConfig({
  base: process.env.VITE_BASE ?? "/",
  plugins: [react()],
});
