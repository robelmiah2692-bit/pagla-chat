import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔥 স্টোরি আপলোড (টাইমস্ট্যাম্প সহ)
  Future<void> uploadStory(String imagePath) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('stories').add({
        'userId': user.uid,
        'userName': user.displayName ?? "User",
        'userImage': user.photoURL ?? "",
        'storyImage': imagePath,
        'timestamp': FieldValue.serverTimestamp(), // এটি দিয়ে সিরিয়াল হবে
      });
      print("Story Uploaded Successfully! ✅");
    } catch (e) {
      print("Upload Error: $e");
    }
  }

  // 🔥 নতুন স্টোরি সবার আগে দেখানোর জন্য (Descending Order)
  Stream<QuerySnapshot> getStories() {
    return _firestore
        .collection('stories')
        .orderBy('timestamp', descending: true) // নতুনগুলো টপে আসবে
        .snapshots();
  }
}
