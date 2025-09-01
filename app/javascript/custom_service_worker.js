// app/javascript/custom_service_worker.js

const CACHE_NAME = 'plangoreminisce-cache-v2';
const OFFLINE_DATA_CACHE = 'plangoreminisce-offline-data-v1';
const urlsToCache = [
  '/',
  '/plan',
  '/go',
  '/reminisce',
  // Add other static assets you want to cache
  // '/assets/application.css', // Example
  // '/assets/application.js',  // Example
];

// Store for offline journal entries with location data
const OFFLINE_STORE_NAME = 'offline-journal-entries';
const OFFLINE_LOCATION_STORE = 'offline-locations';

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('Opened cache');
        return cache.addAll(urlsToCache);
      })
  );
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        // Cache hit - return response
        if (response) {
          return response;
        }
        return fetch(event.request);
      })
  );
});

self.addEventListener('activate', event => {
  const cacheWhitelist = [CACHE_NAME, OFFLINE_DATA_CACHE];
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheWhitelist.indexOf(cacheName) === -1) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});

// Background Sync for offline location data
self.addEventListener('sync', event => {
  if (event.tag === 'location-sync') {
    event.waitUntil(syncOfflineLocations());
  } else if (event.tag === 'journal-sync') {
    event.waitUntil(syncOfflineJournalEntries());
  }
});

// Handle offline location storage and synchronization
async function syncOfflineLocations() {
  try {
    const cache = await caches.open(OFFLINE_DATA_CACHE);
    const cachedLocations = await cache.match(OFFLINE_LOCATION_STORE);
    
    if (cachedLocations) {
      const locations = await cachedLocations.json();
      
      // Process each cached location request
      for (const locationData of locations) {
        try {
          // Try to get fresh location data
          const response = await fetch('https://api.bigdatacloud.net/data/client-info');
          if (response.ok) {
            const freshData = await response.json();
            // Update cached location with fresh data
            locationData.fresh = freshData;
            locationData.synced = true;
            locationData.syncedAt = new Date().toISOString();
          }
        } catch (error) {
          console.log('Failed to sync location data:', error);
        }
      }
      
      // Update cache with synced data
      await cache.put(OFFLINE_LOCATION_STORE, 
        new Response(JSON.stringify(locations), {
          headers: {'Content-Type': 'application/json'}
        })
      );
    }
  } catch (error) {
    console.error('Location sync failed:', error);
  }
}

async function syncOfflineJournalEntries() {
  try {
    const cache = await caches.open(OFFLINE_DATA_CACHE);
    const cachedEntries = await cache.match(OFFLINE_STORE_NAME);
    
    if (cachedEntries) {
      const entries = await cachedEntries.json();
      const syncedEntries = [];
      
      // Try to sync each entry
      for (const entry of entries) {
        if (!entry.synced) {
          try {
            const response = await fetch(entry.url, {
              method: entry.method,
              headers: entry.headers,
              body: entry.body
            });
            
            if (response.ok) {
              entry.synced = true;
              entry.syncedAt = new Date().toISOString();
              console.log('Successfully synced offline journal entry');
            } else {
              syncedEntries.push(entry); // Keep unsynced for later
            }
          } catch (error) {
            syncedEntries.push(entry); // Keep unsynced for later
            console.log('Failed to sync journal entry:', error);
          }
        }
      }
      
      // Update cache with remaining unsynced entries
      await cache.put(OFFLINE_STORE_NAME, 
        new Response(JSON.stringify(syncedEntries), {
          headers: {'Content-Type': 'application/json'}
        })
      );
    }
  } catch (error) {
    console.error('Journal entry sync failed:', error);
  }
}

// Message handling for offline operations
self.addEventListener('message', event => {
  if (event.data.action === 'store-offline-location') {
    storeOfflineLocation(event.data.locationData);
  } else if (event.data.action === 'store-offline-journal') {
    storeOfflineJournalEntry(event.data.journalData);
  } else if (event.data.action === 'get-offline-locations') {
    getOfflineLocations().then(locations => {
      event.ports[0].postMessage({success: true, data: locations});
    }).catch(error => {
      event.ports[0].postMessage({success: false, error: error.message});
    });
  }
});

async function storeOfflineLocation(locationData) {
  try {
    const cache = await caches.open(OFFLINE_DATA_CACHE);
    const existing = await cache.match(OFFLINE_LOCATION_STORE);
    
    let locations = [];
    if (existing) {
      locations = await existing.json();
    }
    
    // Add new location data with timestamp
    locations.push({
      ...locationData,
      timestamp: new Date().toISOString(),
      synced: false
    });
    
    await cache.put(OFFLINE_LOCATION_STORE, 
      new Response(JSON.stringify(locations), {
        headers: {'Content-Type': 'application/json'}
      })
    );
    
    // Register for background sync
    if ('serviceWorker' in navigator && 'sync' in window.ServiceWorkerRegistration.prototype) {
      const registration = await self.registration;
      await registration.sync.register('location-sync');
    }
    
    console.log('Stored offline location data');
  } catch (error) {
    console.error('Failed to store offline location:', error);
  }
}

async function storeOfflineJournalEntry(journalData) {
  try {
    const cache = await caches.open(OFFLINE_DATA_CACHE);
    const existing = await cache.match(OFFLINE_STORE_NAME);
    
    let entries = [];
    if (existing) {
      entries = await existing.json();
    }
    
    // Add new journal entry with timestamp
    entries.push({
      ...journalData,
      timestamp: new Date().toISOString(),
      synced: false
    });
    
    await cache.put(OFFLINE_STORE_NAME, 
      new Response(JSON.stringify(entries), {
        headers: {'Content-Type': 'application/json'}
      })
    );
    
    // Register for background sync
    if ('serviceWorker' in navigator && 'sync' in window.ServiceWorkerRegistration.prototype) {
      const registration = await self.registration;
      await registration.sync.register('journal-sync');
    }
    
    console.log('Stored offline journal entry');
  } catch (error) {
    console.error('Failed to store offline journal entry:', error);
  }
}

async function getOfflineLocations() {
  try {
    const cache = await caches.open(OFFLINE_DATA_CACHE);
    const cached = await cache.match(OFFLINE_LOCATION_STORE);
    
    if (cached) {
      return await cached.json();
    }
    return [];
  } catch (error) {
    console.error('Failed to get offline locations:', error);
    return [];
  }
}