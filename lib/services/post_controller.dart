import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostController {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔥 লাইক হ্যান্ডেল করার ফাংশন
  static Future<void> toggleLike(String postId, List currentLikes) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    DocumentReference postRef = _firestore.collection('stories').doc(postId);

    if (currentLikes.contains(uid)) {
      await postRef.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      await postRef.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }

  // 🔥 শেয়ার হ্যান্ডেল করার ফাংশন
  static Future<void> sharePost(Map<String, dynamic> postData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('stories').add({
      'userId': user.uid,
      'userName': user.displayName ?? user.email?.split('@')[0] ?? "User",
      'userImage': user.photoURL ?? "",
      'storyImage': postData['storyImage'] ?? "",
      'caption': "Shared: ${postData['caption'] ?? ""}",
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [], // নতুন পোস্টে ০ লাইক
    });
  }
}
