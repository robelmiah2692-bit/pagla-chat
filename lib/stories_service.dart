import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔥 স্টোরি আপলোড
  Future<void> uploadStory(String imagePath, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('stories').add({
        'userId': user.uid,
        'userName': user.displayName ?? "User",
        'userImage': user.photoURL ?? "",
        'storyImage': imagePath,
        'caption': text,
        'timestamp': FieldValue.serverTimestamp(), 
      });
      print("Story Uploaded Successfully! ✅");
    } catch (e) {
      print("Upload Error: $e");
    }
  }

  // 🔥 ইনডেক্সিং ঝামেলা এড়াতে আপাতত orderBy সরিয়ে snapshots নিচ্ছি
  Stream<QuerySnapshot> getStories() {
    // এখানে orderBy সরিয়ে দেওয়া হয়েছে যাতে কোনো ইনডেক্স না লাগে
    return _firestore
        .collection('stories')
        .snapshots();
  }
}
