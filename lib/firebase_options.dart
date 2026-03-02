import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyA9KMdtIBNVYSASc5C2w5JGVTL-NISXFog",
    authDomain: "paglachat.firebaseapp.com",
    databaseURL: "https://paglachat-default-rtdb.asia-southeast1.firebasedatabase.app",
    projectId: "paglachat",
    storageBucket: "paglachat.firebasestorage.app",
    messagingSenderId: "25052070011",
    appId: "1:25052070011:web:7c447f8d011fbdf3d662de",
    measurementId: "G-946LX0V0Q9",
  );
}
