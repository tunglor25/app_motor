/**
 * Firebase Sync Module for Trip Tracker
 * Uses Firebase Web SDK v10 (modular, CDN)
 * Anonymous Auth + Firestore
 */
const FirebaseSync = (function() {
  // ============================================================
  // ⚠️ REPLACE THIS CONFIG with your Firebase project config
  // Get it from: Firebase Console → Project Settings → Web App
  // ============================================================
  const firebaseConfig = {
    apiKey: "AIzaSyDM63iAL2wTmgUc3dtcnVeRCcm1r-Y2dBg",
    authDomain: "motor-speed-map.firebaseapp.com",
    projectId: "motor-speed-map",
    storageBucket: "motor-speed-map.firebasestorage.app",
    messagingSenderId: "550952078774",
    appId: "1:550952078774:web:80ab088b3aad3dbfab0517",
    measurementId: "G-P0Q2HHNBQB"
  };

  let db = null;
  let auth = null;
  let currentUser = null;
  let initialized = false;
  let pendingSync = [];

  // Dynamic import Firebase modules from CDN
  async function loadFirebase() {
    if (initialized) return true;
    
    // Check if config is set
    if (firebaseConfig.apiKey === "YOUR_API_KEY") {
      console.warn('[FirebaseSync] Firebase config not set. Cloud sync disabled.');
      return false;
    }

    try {
      const { initializeApp } = await import('https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js');
      const { getFirestore, collection, doc, setDoc, getDocs, deleteDoc, query, orderBy } = await import('https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js');
      const { getAuth, signInAnonymously, onAuthStateChanged } = await import('https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js');

      const app = initializeApp(firebaseConfig);
      db = getFirestore(app);
      auth = getAuth(app);

      // Store module references for later use
      FirebaseSync._fb = { collection, doc, setDoc, getDocs, deleteDoc, query, orderBy };

      // Anonymous auth
      await signInAnonymously(auth);

      return new Promise((resolve) => {
        onAuthStateChanged(auth, (user) => {
          if (user) {
            currentUser = user;
            console.log('[FirebaseSync] Authenticated as:', user.uid);
            initialized = true;

            // Process pending syncs
            if (pendingSync.length > 0) {
              console.log(`[FirebaseSync] Processing ${pendingSync.length} pending syncs...`);
              pendingSync.forEach(trip => FirebaseSync.syncTrip(trip));
              pendingSync = [];
            }

            resolve(true);
          }
        });
      });

    } catch (e) {
      console.error('[FirebaseSync] Failed to load Firebase:', e);
      return false;
    }
  }

  // Get user's trips collection path
  function tripsPath() {
    if (!currentUser) return null;
    return `users/${currentUser.uid}/trips`;
  }

  return {
    /**
     * Initialize Firebase (call on app start)
     */
    init: async function() {
      return await loadFirebase();
    },

    /**
     * Check if Firebase is ready
     */
    isReady: function() {
      return initialized && currentUser !== null;
    },

    /**
     * Get current user UID
     */
    getUID: function() {
      return currentUser ? currentUser.uid : null;
    },

    /**
     * Sync a single trip to Firestore
     */
    syncTrip: async function(tripData) {
      if (!initialized || !currentUser) {
        pendingSync.push(tripData);
        // Try to init
        loadFirebase();
        return false;
      }

      try {
        const { doc, setDoc } = FirebaseSync._fb;
        const tripRef = doc(db, tripsPath(), tripData.id);

        // Clean data for Firestore (remove functions, undefined values)
        const cleanData = JSON.parse(JSON.stringify(tripData));

        await setDoc(tripRef, cleanData, { merge: true });
        console.log('[FirebaseSync] Trip synced:', tripData.id);
        return true;
      } catch (e) {
        console.error('[FirebaseSync] Sync failed:', e);
        pendingSync.push(tripData);
        return false;
      }
    },

    /**
     * Load all trips from Firestore
     */
    loadAllTrips: async function() {
      if (!initialized || !currentUser) return [];

      try {
        const { collection, getDocs, query, orderBy } = FirebaseSync._fb;
        const tripsRef = collection(db, tripsPath());
        const q = query(tripsRef, orderBy('startTime', 'desc'));
        const snapshot = await getDocs(q);

        const trips = [];
        snapshot.forEach(doc => {
          trips.push(doc.data());
        });

        console.log(`[FirebaseSync] Loaded ${trips.length} trips from cloud`);
        return trips;
      } catch (e) {
        console.error('[FirebaseSync] Load failed:', e);
        return [];
      }
    },

    /**
     * Delete a trip from Firestore
     */
    deleteTrip: async function(tripId) {
      if (!initialized || !currentUser) return false;

      try {
        const { doc, deleteDoc } = FirebaseSync._fb;
        const tripRef = doc(db, tripsPath(), tripId);
        await deleteDoc(tripRef);
        console.log('[FirebaseSync] Trip deleted from cloud:', tripId);
        return true;
      } catch (e) {
        console.error('[FirebaseSync] Delete failed:', e);
        return false;
      }
    },

    /**
     * Clear all trips from Firestore
     */
    clearAllTrips: async function() {
      if (!initialized || !currentUser) return false;

      try {
        const { collection, getDocs, doc, deleteDoc } = FirebaseSync._fb;
        const tripsRef = collection(db, tripsPath());
        const snapshot = await getDocs(tripsRef);

        const deletePromises = [];
        snapshot.forEach(d => {
          deletePromises.push(deleteDoc(doc(db, tripsPath(), d.id)));
        });

        await Promise.all(deletePromises);
        console.log('[FirebaseSync] All trips cleared from cloud');
        return true;
      } catch (e) {
        console.error('[FirebaseSync] Clear failed:', e);
        return false;
      }
    },

    /**
     * Merge cloud data with local data
     * Returns merged array (cloud wins on conflict)
     */
    mergeWithLocal: function(localTrips, cloudTrips) {
      const merged = new Map();

      // Add local trips first
      localTrips.forEach(t => merged.set(t.id, t));

      // Cloud overwrites local on conflict
      cloudTrips.forEach(t => merged.set(t.id, t));

      return Array.from(merged.values()).sort((a, b) => b.startTime - a.startTime);
    }
  };
})();

// Auto-init when online
if (navigator.onLine) {
  FirebaseSync.init();
}
window.addEventListener('online', () => {
  FirebaseSync.init();
});
