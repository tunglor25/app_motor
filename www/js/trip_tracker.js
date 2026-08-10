const TripTracker = (function() {
  const STORAGE_KEY = 'trip_history';
  const MAX_TRIPS = 50;

  let currentTrip = null;
  let recording = false;

  // Haversine formula to calculate distance between two coordinates in km
  function calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Radius of the earth in km
    const dLat = deg2rad(lat2 - lat1);
    const dLon = deg2rad(lon2 - lon1);
    const a = 
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * 
      Math.sin(dLon / 2) * Math.sin(dLon / 2); 
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)); 
    return R * c; // Distance in km
  }

  function deg2rad(deg) {
    return deg * (Math.PI / 180);
  }

  function loadTrips() {
    try {
      const data = localStorage.getItem(STORAGE_KEY);
      return data ? JSON.parse(data) : [];
    } catch (e) {
      console.error("Error loading trips:", e);
      return [];
    }
  }

  function saveTrips(trips) {
    try {
      // Keep only max trips, remove oldest
      if (trips.length > MAX_TRIPS) {
        trips = trips.slice(trips.length - MAX_TRIPS);
      }
      localStorage.setItem(STORAGE_KEY, JSON.stringify(trips));
    } catch (e) {
      console.error("Error saving trips:", e);
    }
  }

  return {
    start: function() {
      if (recording) return;
      recording = true;
      const now = Date.now();
      currentTrip = {
        id: 'trip_' + now,
        startTime: now,
        endTime: null,
        duration: 0,
        totalDistance: 0,
        maxSpeedECU: 0,
        maxSpeedGPS: 0,
        sumSpeedECU: 0,
        sumSpeedGPS: 0,
        avgSpeedECU: 0,
        avgSpeedGPS: 0,
        maxRPM: 0,
        sumRPM: 0,
        avgRPM: 0,
        maxECT: 0,
        fuelConsumed: 0,
        routeCoords: [],
        sampleCountECU: 0,
        sampleCountGPS: 0,
        lastValidCoord: null
      };
      
      // Reset fuel in ECU if needed, or track delta.
      // Assuming data_engine.js gives us instant fuel, we can accumulate it or take from trip meter.
      // We will track it externally or via ECUData.
    },

    stop: function() {
      if (!recording || !currentTrip) return null;
      recording = false;
      currentTrip.endTime = Date.now();
      currentTrip.duration = currentTrip.endTime - currentTrip.startTime;
      
      // Finalize averages
      if (currentTrip.sampleCountECU > 0) {
        currentTrip.avgSpeedECU = currentTrip.sumSpeedECU / currentTrip.sampleCountECU;
        currentTrip.avgRPM = currentTrip.sumRPM / currentTrip.sampleCountECU;
      }
      if (currentTrip.sampleCountGPS > 0) {
        currentTrip.avgSpeedGPS = currentTrip.sumSpeedGPS / currentTrip.sampleCountGPS;
      }

      // Cleanup temp variables before saving
      delete currentTrip.sumSpeedECU;
      delete currentTrip.sumSpeedGPS;
      delete currentTrip.sumRPM;
      delete currentTrip.lastValidCoord;

      const trips = loadTrips();
      trips.push(currentTrip);
      saveTrips(trips);

      // Sync to Firebase cloud
      if (window.FirebaseSync) {
        FirebaseSync.syncTrip(currentTrip);
      }

      const savedId = currentTrip.id;
      currentTrip = null;
      return savedId;
    },

    isRecording: function() {
      return recording;
    },

    addGPSPoint: function(lat, lng, speed, timestamp, accuracy = 0) {
      if (!recording || !currentTrip) return;
      
      // Filter out inaccurate points
      if (accuracy > 30) return;

      const pt = {
        lat: lat,
        lng: lng,
        timestamp: timestamp || Date.now(),
        speedGPS: speed || 0
      };

      // Add to route
      currentTrip.routeCoords.push(pt);

      // Distance calculation
      if (currentTrip.lastValidCoord) {
        const dist = calculateDistance(
          currentTrip.lastValidCoord.lat, currentTrip.lastValidCoord.lng,
          lat, lng
        );
        currentTrip.totalDistance += dist;
      }
      currentTrip.lastValidCoord = { lat, lng };

      // Stats
      if (speed) {
        if (speed > currentTrip.maxSpeedGPS) currentTrip.maxSpeedGPS = speed;
        currentTrip.sumSpeedGPS += speed;
        currentTrip.sampleCountGPS++;
      }
    },

    addECUData: function(speed, rpm, ect, tps, battery) {
      if (!recording || !currentTrip) return;
      
      if (speed !== undefined) {
        if (speed > currentTrip.maxSpeedECU) currentTrip.maxSpeedECU = speed;
        currentTrip.sumSpeedECU += speed;
      }
      if (rpm !== undefined) {
        if (rpm > currentTrip.maxRPM) currentTrip.maxRPM = rpm;
        currentTrip.sumRPM += rpm;
      }
      if (ect !== undefined) {
        if (ect > currentTrip.maxECT) currentTrip.maxECT = ect;
      }
      
      if (speed !== undefined || rpm !== undefined) {
        currentTrip.sampleCountECU++;
      }

      // If we have fuel data injected here, we would add it.
      // As a fallback, maybe ECU controller updates it.
    },
    
    // Can be used to inject fuel consumed directly at the end of the trip
    setFuelConsumed: function(liters) {
       if (recording && currentTrip) {
           currentTrip.fuelConsumed = liters;
       }
    },

    getCurrentStats: function() {
      if (!recording || !currentTrip) return null;
      
      const duration = Date.now() - currentTrip.startTime;
      return {
        duration: duration,
        totalDistance: currentTrip.totalDistance,
        maxSpeedECU: currentTrip.maxSpeedECU,
        maxSpeedGPS: currentTrip.maxSpeedGPS,
        avgSpeedECU: currentTrip.sampleCountECU > 0 ? (currentTrip.sumSpeedECU / currentTrip.sampleCountECU) : 0,
        avgSpeedGPS: currentTrip.sampleCountGPS > 0 ? (currentTrip.sumSpeedGPS / currentTrip.sampleCountGPS) : 0,
        maxRPM: currentTrip.maxRPM,
        avgRPM: currentTrip.sampleCountECU > 0 ? (currentTrip.sumRPM / currentTrip.sampleCountECU) : 0,
        maxECT: currentTrip.maxECT,
        fuelConsumed: currentTrip.fuelConsumed
      };
    },

    getTripById: function(id) {
      const trips = loadTrips();
      return trips.find(t => t.id === id);
    },

    getAllTrips: function() {
      return loadTrips().sort((a, b) => b.startTime - a.startTime); // newest first
    },

    /**
     * Get all trips merged with Firebase cloud data
     * Returns a Promise
     */
    getAllTripsCloud: async function() {
      const local = loadTrips();
      if (window.FirebaseSync && FirebaseSync.isReady()) {
        try {
          const cloud = await FirebaseSync.loadAllTrips();
          const merged = FirebaseSync.mergeWithLocal(local, cloud);
          // Update local cache with merged data
          saveTrips(merged);
          return merged;
        } catch(e) {
          console.error('Cloud merge failed:', e);
        }
      }
      return local.sort((a, b) => b.startTime - a.startTime);
    },

    deleteTrip: function(id) {
      let trips = loadTrips();
      trips = trips.filter(t => t.id !== id);
      saveTrips(trips);
      // Also delete from cloud
      if (window.FirebaseSync) {
        FirebaseSync.deleteTrip(id);
      }
    },

    clearAllTrips: function() {
      localStorage.removeItem(STORAGE_KEY);
      // Also clear cloud
      if (window.FirebaseSync) {
        FirebaseSync.clearAllTrips();
      }
    }
  };
})();
