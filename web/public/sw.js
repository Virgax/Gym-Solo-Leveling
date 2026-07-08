// Minimal offline-first service worker (runtime caching, no build step needed).
const CACHE = "arise-v1";

self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", (e) => e.waitUntil(self.clients.claim()));

self.addEventListener("fetch", (event) => {
  const req = event.request;
  if (req.method !== "GET") return;
  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE);
      const cached = await cache.match(req);
      try {
        const res = await fetch(req);
        if (res && res.status === 200 && res.type === "basic") cache.put(req, res.clone());
        return res;
      } catch {
        if (cached) return cached;
        if (req.mode === "navigate") {
          const fallback = await cache.match("index.html");
          if (fallback) return fallback;
        }
        throw new Error("offline and not cached");
      }
    })(),
  );
});
