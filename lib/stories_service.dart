import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class StoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 🔥 স্টোরি আপলোড লজিক (নিখুঁত ইমেজ হ্যান্ডলিং-সহ)
  Future<void> uploadStory(String imagePath, String text, {dynamic webImageBytes}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String downloadUrl = "";

    try {
      // ১. ছবি আপলোড লজিক (নিশ্চিত করা হচ্ছে যেন URL জেনারেট হয়)
      if (webImageBytes != null || imagePath.isNotEmpty) {
        String fileName = 'stories/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference ref = _storage.ref().child(fileName);

        if (kIsWeb) {
          if (webImageBytes != null) {
            // ওয়েবের জন্য বাইটস আপলোড
            TaskSnapshot task = await ref.putData(webImageBytes);
            downloadUrl = await task.ref.getDownloadURL();
          }
        } else {
          // মোবাইলের জন্য পাথ থেকে ফাইল আপলোড
          File file = File(imagePath);
          if (await file.exists()) {
            TaskSnapshot task = await ref.putFile(file);
            downloadUrl = await task.ref.getDownloadURL();
          } else {
            print("Error: File does not exist at path: $imagePath");
          }
        }
      }

      // ২. 🔥 প্রোফাইল ডাটা আনা (আপনার রিয়েল অবতার ও সেভ করা নাম)
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      String actualName = "ইউজার";
      String actualProfilePic = "";

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        actualName = data['name'] ?? (user.displayName ?? "ইউজার");
        actualProfilePic = data['profilePic'] ?? (user.photoURL ?? "");
      }

      // ৩. ডাটাবেসে স্টোরি সেভ (সব ফিচার এখানে অ্যাক্টিভ)
      await _firestore.collection('stories').add({
        'userId': user.uid,
        'userName': actualName, 
        'userImage': actualProfilePic, 
        'storyImage': downloadUrl, // এখন এখানে সঠিক URL যাবে
        'caption': text,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [], // লাইক ফিচার সচল রাখার জন্য ডিফল্ট খালি লিস্ট
      });

      print("Story Uploaded Successfully! ✅ URL: $downloadUrl");
    } catch (e) {
      print("Upload Error: $e");
    }
  }

  // রিয়েল টাইম স্টোরি গেট করা
  Stream<QuerySnapshot> getStories() {
    return _firestore
        .collection('stories')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
