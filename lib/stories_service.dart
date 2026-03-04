import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // এই লাইনটি যোগ করুন

class StoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // স্টোরেজ যোগ করা হলো

  // 🔥 স্টোরি আপলোড (আপনার কোডের সাথে মিল রেখে ছবি সেইভ করার লজিক)
  Future<void> uploadStory(String imagePath, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String downloadUrl = imagePath; // ডিফল্টভাবে আপনার পাথ থাকবে

    try {
      // ছবি যদি থাকে তবে সেটা স্থায়ীভাবে অনলাইনে সেভ করা হবে যাতে বের হলে মুছে না যায়
      if (imagePath.isNotEmpty && !imagePath.startsWith('http')) {
        String fileName = 'stories/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference ref = _storage.ref().child(fileName);
        
        // ফাইল আপলোড করা হচ্ছে
        File file = File(imagePath);
        await ref.putFile(file);
        
        // ছবির অনলাইন লিঙ্ক পাওয়া গেল
        downloadUrl = await ref.getDownloadURL();
      }

      // প্রোফাইল থেকে নাম ও ছবি নেওয়া
      String name = user.displayName ?? user.email?.split('@')[0] ?? "পাগলা ইউজার";
      String profilePic = user.photoURL ?? "";

      await _firestore.collection('stories').add({
        'userId': user.uid,
        'userName': name,
        'userImage': profilePic,
        'storyImage': downloadUrl, // এখন থেকে এই ছবি চিরস্থায়ী থাকবে
        'caption': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Story Uploaded Successfully! ✅");
    } catch (e) {
      print("Upload Error: $e");
    }
  }

  // 🔥 আপনার দেওয়া গেট স্টোরিজ ফাংশন
  Stream<QuerySnapshot> getStories() {
    return _firestore
        .collection('stories')
        .orderBy('timestamp', descending: true) 
        .snapshots();
  }
}
