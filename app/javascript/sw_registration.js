// Service Worker Registration
// Registers the service worker for caching and offline functionality

class ServiceWorkerManager {
  constructor() {
    this.swRegistration = null;
    this.isUpdateAvailable = false;
  }

  async register() {
    if (!('serviceWorker' in navigator)) {
      console.log('Service Worker not supported');
      return;
    }

    try {
      console.log('Registering Service Worker...');
      
      this.swRegistration = await navigator.serviceWorker.register('/sw.js', {
        scope: '/'
      });

      console.log('Service Worker registered:', this.swRegistration);

      // Handle updates
      this.swRegistration.addEventListener('updatefound', () => {
        console.log('Service Worker update found');
        this.handleUpdate();
      });

      // Check for updates periodically
      this.checkForUpdates();

    } catch (error) {
      console.error('Service Worker registration failed:', error);
    }
  }

  handleUpdate() {
    if (!this.swRegistration.installing) return;

    const installingWorker = this.swRegistration.installing;
    
    installingWorker.addEventListener('statechange', () => {
      if (installingWorker.state === 'installed') {
        if (navigator.serviceWorker.controller) {
          // New update available
          this.isUpdateAvailable = true;
          this.showUpdateNotification();
        } else {
          // First install
          console.log('Service Worker installed for the first time');
          this.showInstallNotification();
        }
      }
    });
  }

  showUpdateNotification() {
    // Create a subtle notification about the update
    const notification = document.createElement('div');
    notification.className = 'sw-update-notification';
    notification.innerHTML = `
      <div class="alert alert-info alert-dismissible fade show" role="alert">
        <strong>Update Available!</strong> A new version is ready. 
        <button type="button" class="btn btn-sm btn-outline-primary ms-2" onclick="swManager.activateUpdate()">
          Update Now
        </button>
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
      </div>
    `;
    
    document.body.appendChild(notification);
    
    // Auto-dismiss after 10 seconds
    setTimeout(() => {
      if (notification.parentNode) {
        notification.remove();
      }
    }, 10000);
  }

  showInstallNotification() {
    console.log('App is ready for offline use');
    
    // Optional: Show a toast notification
    const toast = document.createElement('div');
    toast.className = 'toast-container position-fixed bottom-0 end-0 p-3';
    toast.innerHTML = `
      <div class="toast show" role="alert" aria-live="assertive" aria-atomic="true">
        <div class="toast-header">
          <strong class="me-auto">App Ready</strong>
          <button type="button" class="btn-close" data-bs-dismiss="toast" aria-label="Close"></button>
        </div>
        <div class="toast-body">
          This app is now available offline!
        </div>
      </div>
    `;
    
    document.body.appendChild(toast);
    
    // Auto-dismiss after 5 seconds
    setTimeout(() => {
      if (toast.parentNode) {
        toast.remove();
      }
    }, 5000);
  }

  async activateUpdate() {
    if (!this.swRegistration || !this.swRegistration.waiting) {
      return;
    }

    // Send message to waiting service worker to skip waiting
    this.swRegistration.waiting.postMessage({ type: 'SKIP_WAITING' });
    
    // Reload the page to activate the new service worker
    window.location.reload();
  }

  async checkForUpdates() {
    if (!this.swRegistration) return;

    try {
      await this.swRegistration.update();
    } catch (error) {
      console.error('Failed to check for updates:', error);
    }

    // Check again in 30 minutes
    setTimeout(() => this.checkForUpdates(), 30 * 60 * 1000);
  }

  async unregister() {
    if (!this.swRegistration) return;

    try {
      await this.swRegistration.unregister();
      console.log('Service Worker unregistered');
    } catch (error) {
      console.error('Failed to unregister Service Worker:', error);
    }
  }

  // Performance monitoring
  measurePerformance() {
    if (!('performance' in window)) return;

    // Measure key performance metrics
    window.addEventListener('load', () => {
      setTimeout(() => {
        const perfData = performance.getEntriesByType('navigation')[0];
        const metrics = {
          dns: perfData.domainLookupEnd - perfData.domainLookupStart,
          tcp: perfData.connectEnd - perfData.connectStart,
          ttfb: perfData.responseStart - perfData.requestStart,
          download: perfData.responseEnd - perfData.responseStart,
          domParsing: perfData.domContentLoadedEventEnd - perfData.responseEnd,
          totalLoad: perfData.loadEventEnd - perfData.navigationStart
        };

        console.log('Performance Metrics:', metrics);
        
        // Send to analytics if available
        if (typeof gtag !== 'undefined') {
          gtag('event', 'performance_metrics', {
            event_category: 'performance',
            custom_map: {
              'custom_parameter_1': 'ttfb',
              'custom_parameter_2': 'total_load'
            },
            ttfb: Math.round(metrics.ttfb),
            total_load: Math.round(metrics.totalLoad)
          });
        }
      }, 1000);
    });
  }

  // Cache management
  async clearCache() {
    if (!('caches' in window)) return;

    try {
      const cacheNames = await caches.keys();
      await Promise.all(
        cacheNames.map(cacheName => caches.delete(cacheName))
      );
      console.log('All caches cleared');
    } catch (error) {
      console.error('Failed to clear caches:', error);
    }
  }

  // Get cache size
  async getCacheSize() {
    if (!('caches' in window)) return 0;

    try {
      const cacheNames = await caches.keys();
      let totalSize = 0;

      for (const cacheName of cacheNames) {
        const cache = await caches.open(cacheName);
        const keys = await cache.keys();
        
        for (const key of keys) {
          const response = await cache.match(key);
          if (response) {
            const blob = await response.blob();
            totalSize += blob.size;
          }
        }
      }

      return totalSize;
    } catch (error) {
      console.error('Failed to get cache size:', error);
      return 0;
    }
  }
}

// Initialize and register service worker
const swManager = new ServiceWorkerManager();

// Register when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    swManager.register();
    swManager.measurePerformance();
  });
} else {
  swManager.register();
  swManager.measurePerformance();
}

// Make swManager globally available
window.swManager = swManager;

// Handle service worker messages
navigator.serviceWorker.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'CACHE_UPDATED') {
    console.log('Cache updated:', event.data.cacheName);
  }
});

export default swManager;