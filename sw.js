// Mở app được cả khi mạng yếu. ponytail: stale-while-revalidate → bản mới hiện ở lần mở thứ 2 sau khi deploy.
const C = 'bh-1';
self.addEventListener('install', e => { self.skipWaiting(); e.waitUntil(caches.open(C).then(c => c.addAll(['./', 'index.html', 'config.js', 'manifest.json', 'icon.png']))) });
self.addEventListener('activate', e => e.waitUntil(clients.claim()));
self.addEventListener('fetch', e => {
  const u = new URL(e.request.url);
  if (e.request.method !== 'GET' || !(u.origin === location.origin || u.host === 'cdn.jsdelivr.net')) return;
  e.respondWith(caches.open(C).then(async c => {
    const hit = await c.match(e.request);
    const net = fetch(e.request).then(r => { if (r.ok) c.put(e.request, r.clone()); return r }).catch(() => hit);
    return hit || net;
  }));
});
