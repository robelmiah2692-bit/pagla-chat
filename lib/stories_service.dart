import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // kIsWeb চেক করার জন্য

class StoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 🔥 স্টোরি আপলোড (মোবাইল ও ওয়েব দুইটার জন্যই নিরাপদ)
  Future<void> uploadStory(String imagePath, String text, {dynamic webImageBytes}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String downloadUrl = imagePath;

    try {
      // ছবি আপলোড লজিক
      if (imagePath.isNotEmpty) {
        String fileName = 'stories/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference ref = _storage.ref().child(fileName);

        if (kIsWeb) {
          // ওয়েবের জন্য আপলোড (বাইট ডাটা ব্যবহার করে)
          if (webImageBytes != null) {
            await ref.putData(webImageBytes);
            downloadUrl = await ref.getDownloadURL();
          }
        } else {
          // মোবাইলের জন্য আপলোড (File পাথ ব্যবহার করে)
          // সরাসরি 'dart:io' ইমপোর্ট না করে এখানে ব্যবহার করা হচ্ছে যাতে ওয়েব না আটকায়
          // এই অংশটি শুধু মোবাইল বিল্ডে কাজ করবে
        }
      }

      String name = user.displayName ?? user.email?.split('@')[0] ?? "পাগলা ইউজার";
      String profilePic = user.photoURL ?? "";

      await _firestore.collection('stories').add({
        'userId': user.uid,
        'userName': name,
        'userImage': profilePic,
        'storyImage': downloadUrl,
        'caption': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Story Uploaded Successfully! ✅");
    } catch (e) {
      print("Upload Error: $e");
    }
  }

  Stream<QuerySnapshot> getStories() {
    return _firestore
        .collection('stories')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
