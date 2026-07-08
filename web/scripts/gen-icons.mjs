// One-off icon generator. Run: `npm i sharp --no-save && node scripts/gen-icons.mjs`
// Produces PNG icons into public/icons/. The PNGs are committed, so this is not
// part of the normal build and sharp is not a project dependency.
import sharp from "sharp";
import { mkdirSync } from "node:fs";

mkdirSync("public/icons", { recursive: true });

const glyph = (bg) => `
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#5BD6FF"/>
      <stop offset="1" stop-color="#1E6BFF"/>
    </linearGradient>
  </defs>
  <rect width="512" height="512" fill="${bg}"/>
  <path d="M256 96 L392 344 H320 L256 224 L192 344 H120 Z" fill="url(#g)"/>
  <rect x="176" y="380" width="160" height="26" rx="8" fill="#5BD6FF"/>
</svg>`;

const jobs = [
  { name: "icon-192.png", size: 192, bg: "#05070F" },
  { name: "icon-512.png", size: 512, bg: "#05070F" },
  { name: "maskable-512.png", size: 512, bg: "#0A1730" },
  { name: "apple-touch-icon.png", size: 180, bg: "#05070F" },
];

for (const j of jobs) {
  await sharp(Buffer.from(glyph(j.bg))).resize(j.size, j.size).png().toFile(`public/icons/${j.name}`);
  console.log("wrote", j.name);
}
