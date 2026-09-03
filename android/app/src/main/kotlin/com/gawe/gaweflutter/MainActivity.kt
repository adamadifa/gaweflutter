package com.gawe.gaweflutter

import android.app.AppOpsManager
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.Process
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.gawe.gaweflutter/anti_mock_location"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "checkMockLocation") {
                try {
                    val isMock = isMockLocationActive()
                    result.success(isMock)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun isMockLocationActive(): Boolean {
        // Check fresh location from GPS or Network provider (only if newer than 30 seconds)
        try {
            val locationManager = getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            if (locationManager != null) {
                val providers = locationManager.getProviders(true)
                for (provider in providers) {
                    val location: Location? = try {
                        locationManager.getLastKnownLocation(provider)
                    } catch (e: SecurityException) {
                        null
                    }
                    if (location != null) {
                        // Ignore stale cache older than 30 seconds
                        val ageMillis = System.currentTimeMillis() - location.time
                        if (ageMillis < 30000) {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                if (location.isMock) {
                                    return true
                                }
                            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                                @Suppress("DEPRECATION")
                                if (location.isFromMockProvider) {
                                    return true
                                }
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            // Ignore
        }

        return false
    }
}
