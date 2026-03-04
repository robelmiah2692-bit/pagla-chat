import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔥 স্টোরি আপলোড
  Future<void> uploadStory(String imagePath, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // লগিন ইমেইলের নাম নিচ্ছে
    String name = user.displayName ?? user.email?.split('@')[0] ?? "পাগলা ইউজার";
    String profilePic = user.photoURL ?? "";

    try {
      await _firestore.collection('stories').add({
        'userId': user.uid,
        'userName': name, 
        'userImage': profilePic, 
        'storyImage': imagePath, 
        'caption': text,
        'timestamp': FieldValue.serverTimestamp(), 
      });
      print("Story Uploaded Successfully! ✅");
    } catch (e) {
      print("Upload Error: $e");
    }
  }

  // 🔥 পোস্ট ফিরে পাওয়ার জন্য এই অংশটি খেয়াল করুন
  Stream<QuerySnapshot> getStories() {
    // আমি আপাতত orderBy অফ করে দিচ্ছি যাতে আপনার স্ক্রিনে পোস্টগুলো আবার চলে আসে
    // ইনডেক্সিং এর ঝামেলা মিটলে পরে এটা অন করা যাবে
    return _firestore
        .collection('stories')
        // .orderBy('timestamp', descending: true) // এই লাইনটির জন্যই পোস্ট আসছিল না
        .snapshots();
  }
}
