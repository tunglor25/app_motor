const GPSManager = (function() {
    let watchId = null;
    let lastQueryLat = 0;
    let lastQueryLon = 0;
    let currentSpeedLimit = 0;
    let isQuerying = false;

    // Haversine distance in meters
    function getDistanceInMeters(lat1, lon1, lat2, lon2) {
        const R = 6371e3;
        const φ1 = lat1 * Math.PI/180;
        const φ2 = lat2 * Math.PI/180;
        const Δφ = (lat2-lat1) * Math.PI/180;
        const Δλ = (lon2-lon1) * Math.PI/180;

        const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
                  Math.cos(φ1) * Math.cos(φ2) *
                  Math.sin(Δλ/2) * Math.sin(Δλ/2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        return R * c;
    }

    const tomtomKey = 'TNsjEBPR6I6MSu4Lwq1O3YO8udmg5aU3';

    async function querySpeedLimit(lat, lon) {
        if (isQuerying) return;
        isQuerying = true;
        
        try {
            const url = `https://api.tomtom.com/search/2/reverseGeocode/${lat},${lon}.json?key=${tomtomKey}&returnSpeedLimit=true`;
            const response = await fetch(url);
            if (response.ok) {
                const data = await response.json();
                if (data && data.addresses && data.addresses.length > 0) {
                    const addr = data.addresses[0].address;
                    if (addr && addr.speedLimit) {
                        let sl = addr.speedLimit;
                        let limitNum = parseInt(sl.replace(/\\D/g, ''));
                        if (!isNaN(limitNum) && limitNum > 0) {
                            currentSpeedLimit = limitNum;
                            // Dispatch global event
                            const event = new CustomEvent('speed_limit_data', { detail: { limit: currentSpeedLimit } });
                            window.dispatchEvent(event);
                        } else {
                            currentSpeedLimit = 0;
                            const event = new CustomEvent('speed_limit_data', { detail: { limit: 0 } });
                            window.dispatchEvent(event);
                        }
                    } else {
                        currentSpeedLimit = 0;
                        const event = new CustomEvent('speed_limit_data', { detail: { limit: 0 } });
                        window.dispatchEvent(event);
                    }
                } else {
                    currentSpeedLimit = 0;
                    const event = new CustomEvent('speed_limit_data', { detail: { limit: 0 } });
                    window.dispatchEvent(event);
                }
            }
        } catch (e) {
            console.error("TomTom API error:", e);
        } finally {
            lastQueryLat = lat;
            lastQueryLon = lon;
            isQuerying = false;
        }
    }

    return {
        init: function() {
            if (localStorage.getItem('demo_mode') === 'true') {
                console.log("Demo mode active. Real GPS disabled.");
                return;
            }
            if (!window.Capacitor || !Capacitor.Plugins.Geolocation) {
                console.warn("Geolocation plugin not available.");
                return;
            }

            watchId = Capacitor.Plugins.Geolocation.watchPosition({
                enableHighAccuracy: true,
                timeout: 5000,
                maximumAge: 0
            }, (pos, err) => {
                if (err) {
                    console.error("GPS Watch Error:", err);
                    return;
                }
                
                if (pos && pos.coords) {
                    const lat = pos.coords.latitude;
                    const lon = pos.coords.longitude;
                    const speed = pos.coords.speed ? (pos.coords.speed * 3.6) : 0; // m/s to km/h
                    const accuracy = pos.coords.accuracy;

                    // Add point to TripTracker if it exists
                    if (window.TripTracker) {
                        TripTracker.addGPSPoint(lat, lon, speed, pos.timestamp, accuracy);
                    }

                    // Dispatch gps_data event for UI updates
                    window.dispatchEvent(new CustomEvent('gps_data', { 
                        detail: { lat, lon, speed, accuracy } 
                    }));

                    // Dynamic Speed Limit Logic
                    const warnEnabled = localStorage.getItem('speed_warn_enabled') === 'true';
                    if (warnEnabled) {
                        if (currentSpeedLimit === 0 || lastQueryLat === 0) {
                            // First query
                            querySpeedLimit(lat, lon);
                        } else {
                            // Check distance moved. If moved more than 300 meters, query again
                            const dist = getDistanceInMeters(lastQueryLat, lastQueryLon, lat, lon);
                            if (dist > 300) {
                                querySpeedLimit(lat, lon);
                            } else {
                                // Dispatch cached speed limit
                                const event = new CustomEvent('speed_limit_data', { detail: { limit: currentSpeedLimit } });
                                window.dispatchEvent(event);
                            }
                        }
                    } else {
                        // If warning is disabled, we dispatch 0 so the UI shows --
                        const event = new CustomEvent('speed_limit_data', { detail: { limit: 0 } });
                        window.dispatchEvent(event);
                    }
                }
            });
        },
        
        getSpeedLimit: function() {
            return currentSpeedLimit;
        },

        stop: function() {
            if (watchId !== null && window.Capacitor && Capacitor.Plugins.Geolocation) {
                Capacitor.Plugins.Geolocation.clearWatch({ id: watchId });
                watchId = null;
            }
        }
    };
})();

// Auto initialize when loaded in HTML
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        GPSManager.init();
    });
} else {
    GPSManager.init();
}
