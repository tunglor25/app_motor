/**
 * ECU Data Engine
 * Handles Bluetooth LE connection, raw ECU data parsing, calculations, and Mock simulation.
 */

window.ECUData = {
    // Raw Data
    rpm: 0,
    speed: 0,
    ect: 85, // Engine Coolant Temp (C)
    tps: 0, // Throttle Position (%)
    battery: 12.5, // Voltage
    injectorPulse: 0.0, // ms
    o2Voltage: 0.45, // V
    map: 30, // kPa
    iat: 35, // Intake Air Temp
    dtc: [], // Error codes
    
    // Computed Data
    tripA: 0.0, // km
    tripB: 0.0, // km
    fuelConsumed: 0.0, // Liters
    avgKmL: 0.0,
    instantL100km: 0.0,
    
    // Brand Logos (SVGs & PNGs)
    brands: {
        'bmw': '<img src="img/logos/bmw.png" style="height: 32px; object-fit: contain;">',
        
        'honda': '<img src="img/logos/honda.png" style="height: 32px; object-fit: contain;">',
        
        'yamaha': '<img src="img/logos/yamaha.png" style="height: 32px; object-fit: contain;">',
        
        'ducati': '<img src="img/logos/ducati.png" style="height: 32px; object-fit: contain;">',
        
        'kawasaki': '<img src="img/logos/kawasaki.png" style="height: 32px; object-fit: contain;">',
        
        'redbull': '<img src="img/logos/redbull.png" style="height: 32px; object-fit: contain;">'
    },
    
    // Acceleration Tracking
    accelTiming: {
        active: false,
        startTime: 0,
        time0to60: 0,
        time0to100: 0
    },

    // State
    isConnected: false,
    isMocking: false
};

const ECUController = {
    _mockInterval: null,
    _lastUpdateTime: Date.now(),

    init() {
        // Load saved trips
        ECUData.tripA = parseFloat(localStorage.getItem('tripA') || 0);
        ECUData.tripB = parseFloat(localStorage.getItem('tripB') || 0);
        ECUData.fuelConsumed = parseFloat(localStorage.getItem('fuelConsumed') || 0);
        
        // Start Mock Data if enabled in settings
        if (!ECUData.isConnected && localStorage.getItem('demo_mode') === 'true') {
            this.startMockData();
        } else {
            // Dispatch initial empty data so UI has 0 values instead of NaN
            this.dispatchUpdate('ecu_data', ECUData);
        }
    },

    updateComputed() {
        const now = Date.now();
        const deltaMs = now - this._lastUpdateTime;
        this._lastUpdateTime = now;
        
        if (deltaMs > 0 && deltaMs < 2000) {
            // Distance traveled in this delta (km) = Speed(km/h) * (deltaMs / 3600000)
            const dist = ECUData.speed * (deltaMs / 3600000);
            ECUData.tripA += dist;
            ECUData.tripB += dist;

            // Fuel consumed (Rough estimation based on injector pulse)
            // Example: 150cc engine, say 0.005 ml per ms of pulse width per revolution.
            // Simplified calculation for demo purposes:
            // RPM / 2 (4-stroke) = Injection events per minute.
            const injectionsPerMin = ECUData.rpm / 2;
            const injectionsPerMs = injectionsPerMin / 60000;
            const injectionsThisDelta = injectionsPerMs * deltaMs;
            
            // Assume an injector flow rate of ~120cc/min (0.002 ml/ms)
            const mlConsumed = injectionsThisDelta * ECUData.injectorPulse * 0.002;
            const litersConsumed = mlConsumed / 1000;
            ECUData.fuelConsumed += litersConsumed;

            // Instant L/100km
            if (ECUData.speed > 5) {
                // (liters_per_hour / speed) * 100
                const litersPerHour = (mlConsumed * (3600000 / deltaMs)) / 1000;
                ECUData.instantL100km = (litersPerHour / ECUData.speed) * 100;
            } else {
                ECUData.instantL100km = 0;
            }

            // Avg Km/L
            if (ECUData.fuelConsumed > 0.001) {
                ECUData.avgKmL = ECUData.tripA / ECUData.fuelConsumed;
            } else {
                ECUData.avgKmL = 0;
            }

            // Save periodically
            if (Math.random() < 0.05) {
                localStorage.setItem('tripA', ECUData.tripA);
                localStorage.setItem('tripB', ECUData.tripB);
                localStorage.setItem('fuelConsumed', ECUData.fuelConsumed);
            }
            
            // Acceleration Logic
            if (ECUData.speed > 0 && ECUData.speed < 5 && !ECUData.accelTiming.active) {
                ECUData.accelTiming.active = true;
                ECUData.accelTiming.startTime = now;
                ECUData.accelTiming.time0to60 = 0;
                ECUData.accelTiming.time0to100 = 0;
            } else if (ECUData.accelTiming.active) {
                const elapsed = (now - ECUData.accelTiming.startTime) / 1000;
                if (ECUData.speed >= 60 && ECUData.accelTiming.time0to60 === 0) {
                    ECUData.accelTiming.time0to60 = elapsed;
                    this.dispatchUpdate('accel_60', elapsed);
                }
                if (ECUData.speed >= 100 && ECUData.accelTiming.time0to100 === 0) {
                    ECUData.accelTiming.time0to100 = elapsed;
                    ECUData.accelTiming.active = false; // Stop tracking after 100
                    this.dispatchUpdate('accel_100', elapsed);
                }
                if (ECUData.speed === 0) {
                    ECUData.accelTiming.active = false; // Aborted
                }
            }
        }
        
        this.dispatchUpdate('ecu_data', ECUData);
    },

    dispatchUpdate(eventName, detail) {
        window.dispatchEvent(new CustomEvent(eventName, { detail }));
    },

    resetTripA() {
        ECUData.tripA = 0;
        ECUData.fuelConsumed = 0;
        localStorage.setItem('tripA', 0);
        localStorage.setItem('fuelConsumed', 0);
    },

    // --- MOCK SIMULATION ---
    startMockData() {
        if (this._mockInterval) return;
        ECUData.isMocking = true;
        let phase = 0;
        
        this._mockInterval = setInterval(() => {
            phase += 0.05;
            
            // Simulate revving and speed
            const baseRpm = 1500; // idle
            const throttle = (Math.sin(phase) + 1) / 2; // 0 to 1
            
            ECUData.tps = throttle * 100;
            
            // RPM lags behind throttle slightly, but we just simulate a direct relation with noise
            let targetRpm = baseRpm + (throttle * 8000);
            if (throttle > 0.8) targetRpm += (Math.random() * 500); // erratic at high rpm
            
            ECUData.rpm = ECUData.rpm * 0.8 + targetRpm * 0.2;
            
            // Speed climbs if RPM is high enough
            if (ECUData.rpm > 3000) {
                ECUData.speed += (throttle * 1.5);
            } else {
                ECUData.speed -= 0.5;
            }
            if (ECUData.speed > 110) ECUData.speed = 110 - Math.random()*2;
            if (ECUData.speed < 0) ECUData.speed = 0;
            
            // ECT slowly warms up
            if (ECUData.ect < 95) ECUData.ect += 0.01;
            else if (ECUData.speed > 50) ECUData.ect -= 0.02; // cooling
            
            // Battery fluctuates slightly
            ECUData.battery = 13.8 + (ECUData.rpm > 2000 ? 0.4 : 0) + (Math.random() * 0.1);
            
            // Injector pulse based on throttle and RPM
            if (throttle > 0.1) {
                ECUData.injectorPulse = 2.0 + (throttle * 5.0) - (ECUData.rpm > 8000 ? 1.0 : 0);
            } else {
                ECUData.injectorPulse = ECUData.rpm > 2000 ? 0.0 : 1.5; // fuel cut off on decel
            }

            // O2 sensor oscillates
            ECUData.o2Voltage = 0.1 + (Math.sin(phase * 5) * 0.4) + 0.4;
            
            this.updateComputed();
            
        }, 100); // 10Hz updates
    },

    stopMockData() {
        clearInterval(this._mockInterval);
        this._mockInterval = null;
        ECUData.isMocking = false;
    }
};

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    ECUController.init();
});
