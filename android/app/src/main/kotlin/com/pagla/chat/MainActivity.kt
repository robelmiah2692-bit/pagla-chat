package com.pagla.chat

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Native Ad Factory রেজিস্টার করা হলো
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "listTile",
            NativeAdFactoryListTile(layoutInflater)
        )
    }

    override fun cleanUpFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTile")
        super.cleanUpFlutterEngine(flutterEngine)
    }
}