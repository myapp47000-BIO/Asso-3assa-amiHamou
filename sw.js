/* ============================================================
   sw.js — عامل الخدمة (Service Worker)
   ------------------------------------------------------------
   الهدف: جعل التطبيق قابلا للتثبيت والعمل دون اتصال بالإنترنت،
   مع استقبال الإشعارات المحلية (Push / Notification).
   ============================================================ */
const VERSION = "jamaa-assa-v3";
const CACHE = VERSION;

const CORE = [
  "./",
  "./index.html",
  "./manifest.json",
  "./style.css",
  "./js/data.js",
  "./js/store.js",
  "./js/api.js",
  "./js/auth.js",
  "./js/ui.js",
  "./js/views.js",
  "./js/app.js",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
  "./icons/icon-maskable-192.png",
  "./icons/icon-maskable-512.png",
  "./icons/favicon-32.png",
  "./icons/apple-touch-icon.png",
];

/* ---------- التثبيت: تخزين الملفات الأساسية ---------- */
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches
      .open(CACHE)
      .then((cache) => cache.addAll(CORE))
      .then(() => self.skipWaiting())
      .catch(() => self.skipWaiting())
  );
});

/* ---------- التفعيل: حذف النسخ القديمة ---------- */
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

/* ---------- الجلب: الشبكة أولا لملفات التطبيق، ثم النسخة المخزنة ---------- */
self.addEventListener("fetch", (event) => {
  const req = event.request;
  if (req.method !== "GET") return;

  const url = new URL(req.url);

  /* الخطوط الخارجية: الشبكة أولا مع بديل مخزن */
  if (url.origin !== self.location.origin) {
    event.respondWith(
      fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE).then((c) => c.put(req, copy)).catch(() => {});
          return res;
        })
        .catch(() => caches.match(req))
    );
    return;
  }

  /* نفس الأصل: الشبكة أولا ثم النسخة المخزنة.
     سبب الاعتماد على الشبكة: التطبيق كله في المتصفح، وأي اختلاف بين
     index.html و js/*.js (نسخة قديمة من الذاكرة) يوقف الإقلاع بصفحة بيضاء.
     المخزن يبقى كبديل وحيد عند انقطاع الإنترنت. */
  event.respondWith(
    fetch(req)
      .then((res) => {
        if (res && res.status === 200 && res.type === "basic") {
          const copy = res.clone();
          caches.open(CACHE).then((c) => c.put(req, copy)).catch(() => {});
        }
        return res;
      })
      .catch(() =>
        caches.match(req).then(
          (hit) =>
            hit ||
            (req.mode === "navigate"
              ? caches.match("./index.html").then((r) => r || caches.match("./"))
              : undefined)
        )
      )
  );
});

/* ---------- إشعارات واردة من الخادم (للاستعمال المستقبلي مع خادم حقيقي) ---------- */
self.addEventListener("push", (event) => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (e) {
    payload = { title: "إشعار جديد", body: event.data ? event.data.text() : "" };
  }
  event.waitUntil(
    self.registration.showNotification(payload.title || "جمعية حي العسة", {
      body: payload.body || "",
      icon: "icons/icon-192.png",
      badge: "icons/icon-192.png",
      dir: "rtl",
      lang: "ar",
      tag: payload.tag || "jamaa-assa",
      data: { url: payload.url || "./index.html#notifications" },
    })
  );
});

/* ---------- النقر على الإشعار ---------- */
self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const target = (event.notification.data && event.notification.data.url) || "./index.html#notifications";
  event.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((list) => {
      for (const client of list) {
        if ("focus" in client) {
          client.navigate && client.navigate(target);
          return client.focus();
        }
      }
      if (self.clients.openWindow) return self.clients.openWindow(target);
      return undefined;
    })
  );
});

/* ---------- رسالة من الصفحة: تحديث فوري ---------- */
self.addEventListener("message", (event) => {
  if (event.data === "skipWaiting" || (event.data && event.data.type === "skipWaiting")) {
    self.skipWaiting();
  }
});
