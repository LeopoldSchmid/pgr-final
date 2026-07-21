const SHELL_CACHE = "plangoreminisce-shell-v1";
const ASSET_CACHE = "plangoreminisce-assets-v1";
const NAVIGATION_FALLBACKS = ["/", "/en/expenses", "/expenses"];

self.addEventListener("install", (event) => {
  event.waitUntil(self.skipWaiting());
});

self.addEventListener("activate", (event) => {
  const expectedCaches = [SHELL_CACHE, ASSET_CACHE];

  event.waitUntil(
    caches.keys()
      .then((cacheNames) => Promise.all(
        cacheNames.map((cacheName) => {
          if (!expectedCaches.includes(cacheName)) return caches.delete(cacheName);
          return undefined;
        }),
      ))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (request.method !== "GET") return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  if (request.mode === "navigate") {
    event.respondWith(networkFirst(request, SHELL_CACHE));
    return;
  }

  if (isRuntimeAsset(request, url)) {
    event.respondWith(cacheFirst(request, ASSET_CACHE));
  }
});

async function networkFirst(request, cacheName) {
  const cache = await caches.open(cacheName);

  try {
    const response = await fetch(request);
    if (response.ok) await cache.put(request, response.clone());
    return response;
  } catch (_error) {
    const cached = await cache.match(request);
    if (cached) return cached;

    for (const fallbackUrl of NAVIGATION_FALLBACKS) {
      const fallback = await cache.match(fallbackUrl);
      if (fallback) return fallback;
    }

    return new Response("Offline", {
      status: 503,
      headers: { "Content-Type": "text/plain; charset=utf-8" },
    });
  }
}

async function cacheFirst(request, cacheName) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(request);
  if (cached) return cached;

  const response = await fetch(request);
  if (response.ok) await cache.put(request, response.clone());
  return response;
}

function isRuntimeAsset(request, url) {
  if (url.pathname.startsWith("/assets/")) return true;
  if (url.pathname === "/icon.png") return true;
  return ["script", "style", "image", "font"].includes(request.destination);
}
