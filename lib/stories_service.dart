import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔥 স্টোরি ডাটাবেসে সেভ করা
  Future<void> uploadStory(String imageUrl) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('stories').add({
      'userId': user.uid,
      'userName': user.displayName ?? "User",
      'userImage': user.photoURL ?? "https://www.w3schools.com/howto/img_avatar.png",
      'storyImage': imageUrl,
      'timestamp': FieldValue.serverTimestamp(), // সার্ভার টাইম
      'expiresAt': DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch,
    });
  }

  // 🔥 সকল স্টোরি রিড করা (অটো আপডেট ফিক্সড)
  Stream<QuerySnapshot> getStories() {
    // এখানে serverTimestamp এর নাল ভ্যালু হ্যান্ডেল করার জন্য 
    // আমরা snapshots এ includeMetadataChanges: true ব্যবহার করতে পারি 
    // অথবা সিম্পলি নিচের মতো কুয়েরি করতে পারি
    return _firestore
        .collection('stories')
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true); // 🔥 এটি নতুন ডেটা সাথে সাথে দেখাবে
  }
}
