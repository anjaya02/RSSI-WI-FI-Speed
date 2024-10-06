package com.example.rssi

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "wifiInfo"

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getWifiInfo") {
                val wifiInfo = getWifiInfo()
                result.success(wifiInfo)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getWifiInfo(): Map<String, Any?> {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val wifiInfo = wifiManager.connectionInfo
        val ssid = wifiInfo.ssid.removeSurrounding("\"")
        val rssi = wifiInfo.rssi
        val level = WifiManager.calculateSignalLevel(rssi, 100)  // Calculate signal level from RSSI

        // Returning SSID, RSSI, and Signal Level
        return mapOf(
            "ssid" to ssid,
            "rssi" to rssi,
            "level" to level
        )
    }
}
