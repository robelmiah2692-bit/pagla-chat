import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔥 স্টোরি আপলোড (ইমেজ এবং টেক্সট দুটোই গ্রহণ করবে)
  Future<void> uploadStory(String imagePath, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('stories').add({
        'userId': user.uid,
        'userName': user.displayName ?? "User",
        'userImage': user.photoURL ?? "",
        'storyImage': imagePath,
        'caption': text, // 🔥 এখানে টেক্সট/ক্যাপশন সেভ হচ্ছে
        'timestamp': FieldValue.serverTimestamp(), 
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
        .orderBy('timestamp', descending: true) 
        .snapshots();
  }
}
