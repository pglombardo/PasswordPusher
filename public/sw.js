// Service Worker for Performance Optimization
// Version 1.0.0

const CACHE_NAME = 'pwpush-v1';
const STATIC_CACHE_NAME = 'pwpush-static-v1';
const DYNAMIC_CACHE_NAME = 'pwpush-dynamic-v1';

// Assets to cache immediately
const STATIC_ASSETS = [
  '/',
  '/assets/application.js',
  '/assets/application.css',
  '/assets/critical.css',
  '/manifest.json'
];

// Assets to cache on first request
const DYNAMIC_ASSETS = [
  '/assets/images/',
  '/assets/fonts/',
  '/flags/'
];

// Install event - cache static assets
self.addEventListener('install', (event) => {
  console.log('Service Worker installing...');
  
  event.waitUntil(
    caches.open(STATIC_CACHE_NAME)
      .then((cache) => {
        console.log('Caching static assets');
        return cache.addAll(STATIC_ASSETS);
      })
      .then(() => {
        console.log('Static assets cached');
        return self.skipWaiting();
      })
      .catch((error) => {
        console.error('Failed to cache static assets:', error);
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('Service Worker activating...');
  
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== STATIC_CACHE_NAME && cacheName !== DYNAMIC_CACHE_NAME) {
            console.log('Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      console.log('Service Worker activated');
      return self.clients.claim();
    })
  );
});

// Fetch event - serve from cache with network fallback
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }
  
  // Skip external requests
  if (url.origin !== location.origin) {
    return;
  }
  
  // Handle different types of requests
  if (isStaticAsset(request.url)) {
    event.respondWith(handleStaticAsset(request));
  } else if (isDynamicAsset(request.url)) {
    event.respondWith(handleDynamicAsset(request));
  } else {
    event.respondWith(handlePageRequest(request));
  }
});

// Check if request is for a static asset
function isStaticAsset(url) {
  return url.includes('/assets/') || 
         url.includes('/packs/') ||
         url.includes('/manifest.json') ||
         url.endsWith('.css') ||
         url.endsWith('.js');
}

// Check if request is for a dynamic asset
function isDynamicAsset(url) {
  return url.includes('/assets/images/') ||
         url.includes('/assets/fonts/') ||
         url.includes('/flags/') ||
         url.includes('.png') ||
         url.includes('.jpg') ||
         url.includes('.jpeg') ||
         url.includes('.gif') ||
         url.includes('.svg') ||
         url.includes('.woff') ||
         url.includes('.woff2') ||
         url.includes('.ttf');
}

// Handle static assets (cache first)
async function handleStaticAsset(request) {
  try {
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(STATIC_CACHE_NAME);
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    console.error('Static asset fetch failed:', error);
    return new Response('Asset not available', { status: 503 });
  }
}

// Handle dynamic assets (cache first with expiration)
async function handleDynamicAsset(request) {
  try {
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      // Check if cached response is still fresh (24 hours)
      const cachedDate = new Date(cachedResponse.headers.get('date'));
      const now = new Date();
      const hoursSinceCached = (now - cachedDate) / (1000 * 60 * 60);
      
      if (hoursSinceCached < 24) {
        return cachedResponse;
      }
    }
    
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(DYNAMIC_CACHE_NAME);
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    console.error('Dynamic asset fetch failed:', error);
    const cachedResponse = await caches.match(request);
    return cachedResponse || new Response('Asset not available', { status: 503 });
  }
}

// Handle page requests (network first with cache fallback)
async function handlePageRequest(request) {
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(DYNAMIC_CACHE_NAME);
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    console.error('Page request failed:', error);
    const cachedResponse = await caches.match(request);
    return cachedResponse || new Response('Page not available offline', { 
      status: 503,
      headers: { 'Content-Type': 'text/html' }
    });
  }
}

// Handle background sync for analytics
self.addEventListener('sync', (event) => {
  if (event.tag === 'background-sync') {
    event.waitUntil(doBackgroundSync());
  }
});

async function doBackgroundSync() {
  // Implement background sync logic here
  console.log('Background sync triggered');
}

// Handle push notifications (if needed)
self.addEventListener('push', (event) => {
  console.log('Push notification received');
  // Implement push notification handling here
});

// Cleanup old caches periodically
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'CLEANUP_CACHES') {
    event.waitUntil(cleanupOldCaches());
  }
});

async function cleanupOldCaches() {
  const cacheNames = await caches.keys();
  const oldCaches = cacheNames.filter(name => 
    !name.includes(STATIC_CACHE_NAME) && 
    !name.includes(DYNAMIC_CACHE_NAME)
  );
  
  return Promise.all(oldCaches.map(name => caches.delete(name)));
}