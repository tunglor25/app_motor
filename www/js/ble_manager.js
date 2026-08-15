/**
 * BLE Manager — ket noi that toi ESP32 (Honda_AB2025_Dash) qua Capacitor BluetoothLe plugin.
 * Dung truc tiep Capacitor.Plugins.BluetoothLe (khong qua bundler), dung UUID khop voi
 * AirBlade_Dashboard.ino. navigator.bluetooth (Web Bluetooth API) KHONG chay trong
 * WebView cua Capacitor (Android/iOS) nen khong the dung o day.
 */
(function () {
    const SERVICE_UUID = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
    const CHAR_RPM = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
    const CHAR_SPEED = '8b423985-7977-4b72-b2d6-4e5088277be9';
    const CHAR_ECT = 'e3b1c67d-94bb-4286-904b-3cc34a4c6a99';
    const CHAR_TPS = '19a28e8d-71b5-4148-84be-97b7cbce39fa';
    const CHAR_BATTERY = 'c19f5615-585a-4712-b062-1bd074a1a5b8';
    const CHAR_IAT = 'd4e8f1a2-3b5c-4d6e-8f9a-0b1c2d3e4f5a';
    const CHAR_O2 = 'f6a8b1c2-4d5e-4f6a-8b9c-1d2e3f4a5b6c';
    const STORAGE_KEY = 'ble_device_id';

    function hexToDataView(hex) {
        if (typeof hex !== 'string' || hex.length === 0) return new DataView(new ArrayBuffer(0));
        const bytes = new Uint8Array(hex.length / 2);
        for (let i = 0; i < bytes.length; i++) {
            bytes[i] = parseInt(hex.substr(i * 2, 2), 16);
        }
        return new DataView(bytes.buffer);
    }

    const BLEManager = {
        deviceId: null,
        _statusCb: null,

        isAvailable() {
            return !!(window.Capacitor && Capacitor.Plugins && Capacitor.Plugins.BluetoothLe);
        },

        _plugin() {
            return Capacitor.Plugins.BluetoothLe;
        },

        _setStatus(status, extra) {
            if (this._statusCb) this._statusCb(status, extra);
            window.dispatchEvent(new CustomEvent('ble_status', { detail: { status, extra } }));
        },

        onStatus(cb) {
            this._statusCb = cb;
        },

        // Quet va ghep noi thiet bi moi (goi tu man hinh Settings, can tuong tac nguoi dung)
        async scanAndConnect() {
            if (!this.isAvailable()) throw new Error('Plugin BluetoothLe khong co san (chi chay tren app that)');
            const ble = this._plugin();
            await ble.initialize();
            this._setStatus('scanning');
            const device = await ble.requestDevice({
                services: [SERVICE_UUID]
            });
            this.deviceId = device.deviceId;
            localStorage.setItem(STORAGE_KEY, this.deviceId);
            await this._connectAndSubscribe();
            return device;
        },

        // Tu ket noi lai voi thiet bi da luu tu lan truoc (goi luc app khoi dong)
        async tryReconnectSaved() {
            if (!this.isAvailable()) return false;
            const saved = localStorage.getItem(STORAGE_KEY);
            if (!saved) return false;
            this.deviceId = saved;
            try {
                await this._plugin().initialize();
                await this._connectAndSubscribe();
                return true;
            } catch (e) {
                console.warn('[BLE] Reconnect that bai:', e && e.message);
                this._setStatus('error', e && e.message);
                return false;
            }
        },

        async _connectAndSubscribe() {
            const ble = this._plugin();
            const deviceId = this.deviceId;

            await ble.addListener(`disconnected|${deviceId}`, () => {
                if (typeof ECUData !== 'undefined') ECUData.isConnected = false;
                this._setStatus('disconnected');
                setTimeout(() => {
                    this._connectAndSubscribe().catch(() => {
                        this._setStatus('disconnected');
                    });
                }, 3000);
            });

            this._setStatus('connecting');
            await ble.connect({ deviceId });

            if (typeof ECUData !== 'undefined') ECUData.isConnected = true;
            if (typeof ECUController !== 'undefined' && ECUController.stopMockData) {
                ECUController.stopMockData();
            }
            this._setStatus('connected');

            await this._subscribe(CHAR_RPM, (dv) => {
                if (dv.byteLength >= 2) ECUData.rpm = dv.getUint16(0, true);
            });
            await this._subscribe(CHAR_SPEED, (dv) => {
                if (dv.byteLength >= 1) ECUData.speed = dv.getUint8(0);
            });
            await this._subscribe(CHAR_ECT, (dv) => {
                if (dv.byteLength >= 1) ECUData.ect = dv.getInt8(0);
            });
            await this._subscribe(CHAR_TPS, (dv) => {
                if (dv.byteLength >= 1) ECUData.tps = dv.getUint8(0);
            });
            await this._subscribe(CHAR_BATTERY, (dv) => {
                const str = new TextDecoder().decode(dv.buffer);
                const v = parseFloat(str);
                if (!isNaN(v)) ECUData.battery = v;
            });
            await this._subscribe(CHAR_IAT, (dv) => {
                if (dv.byteLength >= 1) ECUData.iat = dv.getInt8(0);
            });
            await this._subscribe(CHAR_O2, (dv) => {
                const str = new TextDecoder().decode(dv.buffer);
                const v = parseFloat(str);
                if (!isNaN(v)) ECUData.o2Voltage = v;
            });
        },

        async _subscribe(charUuid, handler) {
            const ble = this._plugin();
            const deviceId = this.deviceId;
            const key = `notification|${deviceId}|${SERVICE_UUID}|${charUuid}`;
            await ble.addListener(key, (event) => {
                const dv = hexToDataView(event && event.value);
                handler(dv);
                if (typeof ECUController !== 'undefined') {
                    ECUController.updateComputed();
                }
            });
            await ble.startNotifications({ deviceId, service: SERVICE_UUID, characteristic: charUuid });
        },

        async disconnect() {
            if (!this.deviceId || !this.isAvailable()) return;
            try {
                await this._plugin().disconnect({ deviceId: this.deviceId });
            } catch (e) { /* noop */ }
            if (typeof ECUData !== 'undefined') ECUData.isConnected = false;
            this._setStatus('disconnected');
        },

        forget() {
            localStorage.removeItem(STORAGE_KEY);
            this.deviceId = null;
        }
    };

    window.BLEManager = BLEManager;

    document.addEventListener('DOMContentLoaded', () => {
        BLEManager.tryReconnectSaved();
    });
})();
