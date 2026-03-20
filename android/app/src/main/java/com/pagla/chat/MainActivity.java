package com.pagla.chat;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        // এটি আপনার সব প্লাগইনকে সঠিকভাবে অ্যান্ড্রয়েডের সাথে লিঙ্ক করবে
        GeneratedPluginRegistrant.registerWith(flutterEngine);
    }
}
