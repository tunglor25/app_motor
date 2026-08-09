// ios_statusbar.js - Hide iOS status bar on all pages
document.addEventListener('DOMContentLoaded', function() {
  if (window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.StatusBar) {
    window.Capacitor.Plugins.StatusBar.hide();
    window.Capacitor.Plugins.StatusBar.setOverlaysWebView({ overlay: true });
  }
});
