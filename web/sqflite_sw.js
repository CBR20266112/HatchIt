// Minimal service worker placeholder for sqflite_common_ffi_web.
// Prevents 404 noise in web preview environments.
self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});
