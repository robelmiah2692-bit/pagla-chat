import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔥 স্টোরি আপলোড (রিয়েল প্রোফাইল ডাটা নিশ্চিত করা হয়েছে)
  Future<void> uploadStory(String imagePath, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // ইউজার যদি নাম সেট না করে থাকে, তবে তার ইমেইলের প্রথম অংশ নেওয়া হবে
    String name = user.displayName ?? user.email?.split('@')[0] ?? "পাগলা ইউজার";
    String profilePic = user.photoURL ?? "";

    try {
      await _firestore.collection('stories').add({
        'userId': user.uid,
        'userName': name, // রিয়েল নাম
        'userImage': profilePic, // রিয়েল প্রোফাইল পিকচার
        'storyImage': imagePath, // স্টোরির মেইন বড় ছবি
        'caption': text,
        'timestamp': FieldValue.serverTimestamp(), // সার্ভার টাইম (ডাটা হারাবে না)
      });
      print("Story Uploaded Successfully! ✅");
    } catch (e) {
      print("Upload Error: $e");
    }
  }

  // 🔥 ডাটা হারাবে না এবং সিরিয়াল ঠিক থাকবে
  Stream<QuerySnapshot> getStories() {
    // এখানে orderBy ব্যবহার করা জরুরি যাতে নতুন পোস্ট সবার উপরে থাকে
    // যদি এরর আসে, তবে কনসোলে দেওয়া লিঙ্কে ক্লিক করে একবার 'Index' তৈরি করে নিতে হবে
    return _firestore
        .collection('stories')
        .orderBy('timestamp', descending: true) 
        .snapshots();
  }
}
