import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔥 স্টোরি আপলোড (রিয়েল প্রোফাইল ডাটা ফিক্স করা হয়েছে)
  Future<void> uploadStory(String imagePath, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // ১. প্রোফাইল ডাটাবেস (users collection) থেকে আসল তথ্য টেনে আনা
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      String realName = "পাগলা ইউজার";
      String realProfilePic = "";

      if (userDoc.exists) {
        // আপনার প্রোফাইল পেজে ডাটা সেভ করার সময় যে নাম ব্যবহার করেছেন (name/image)
        realName = userDoc.get('name') ?? user.displayName ?? "User";
        realProfilePic = userDoc.get('image') ?? user.photoURL ?? "";
      } else {
        realName = user.displayName ?? user.email?.split('@')[0] ?? "User";
        realProfilePic = user.photoURL ?? "";
      }

      // ২. এখন আসল তথ্য দিয়ে স্টোরি সেভ করা হচ্ছে
      await _firestore.collection('stories').add({
        'userId': user.uid,
        'userName': realName, 
        'userImage': realProfilePic, 
        'storyImage': imagePath, 
        'caption': text,
        'timestamp': FieldValue.serverTimestamp(), 
      });
      print("Story Uploaded Successfully! ✅");
    } catch (e) {
      print("Upload Error: $e");
    }
  }

  // 🔥 স্টোরি আসা বন্ধ হওয়ার সমাধান (orderBy সাময়িকভাবে অফ রাখা হয়েছে)
  Stream<QuerySnapshot> getStories() {
    // এখানে আপাতত orderBy সরিয়ে দিলাম যাতে আপনার ইনডেক্স এরর না আসে এবং স্টোরি সাথে সাথে শো করে
    return _firestore.collection('stories').snapshots();
  }
}
