import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io'; // ফাইল হ্যান্ডলিং এর জন্য

class StoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 🔥 স্টোরি আপলোড লজিক (প্রোফাইল ডাটা-সহ)
  Future<void> uploadStory(String imagePath, String text, {dynamic webImageBytes}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String downloadUrl = "";

    try {
      // ১. ছবি আপলোড লজিক ফিক্সিং
      if (imagePath.isNotEmpty || webImageBytes != null) {
        String fileName = 'stories/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference ref = _storage.ref().child(fileName);

        if (kIsWeb) {
          if (webImageBytes != null) {
            await ref.putData(webImageBytes);
            downloadUrl = await ref.getDownloadURL();
          }
        } else {
          // মোবাইলের জন্য পাথ থেকে ফাইল আপলোড
          File file = File(imagePath);
          await ref.putFile(file);
          downloadUrl = await ref.getDownloadURL();
        }
      }

      // ২. 🔥 জিমেইল এর নাম বাদ দিয়ে প্রোফাইল ডাটা আনা
      // আপনার ডাটাবেসের 'users' কালেকশন থেকে নাম ও ছবি রিড করা হচ্ছে
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      String actualName = "পাগলা ইউজার";
      String actualProfilePic = "";

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        actualName = data['name'] ?? "ইউজার"; // আপনার সেভ করা নাম
        actualProfilePic = data['profilePic'] ?? ""; // আপনার নতুন রিয়েল অবতার
      }

      // ৩. ডাটাবেসে স্টোরি সেভ
      await _firestore.collection('stories').add({
        'userId': user.uid,
        'userName': actualName, // প্রোফাইল থেকে আসা নাম
        'userImage': actualProfilePic, // প্রোফাইল থেকে আসা ছবি
        'storyImage': downloadUrl, // আপলোড হওয়া পোস্টের ছবি
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
