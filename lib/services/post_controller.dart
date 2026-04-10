import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostController {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔥 লাইক হ্যান্ডেল করার ফাংশন
  static Future<void> toggleLike(String postId, List currentLikes) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // আপনার স্ক্রিনশট অনুযায়ী 'stories' কালেকশন ব্যবহার করা হয়েছে
    DocumentReference postRef = _firestore.collection('stories').doc(postId);

    if (currentLikes.contains(uid)) {
      await postRef.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      await postRef.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }

  // 🔥 শেয়ার হ্যান্ডেল করার ফাংশন (ফায়ারবেস ফিল্ডের সাথে মিল রেখে)
  static Future<void> sharePost(Map<String, dynamic> postData, {String? customUID}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('stories').add({
      'authUID': user.uid, // ফায়ারবেস অথেন্টিকেশন আইডি
      'uID': customUID ?? "", // আপনার মালিকের চেনার আইডি (যেমন: 153530)
      'name': postData['name'] ?? user.displayName ?? "User", // 'userName' এর বদলে 'name'
      'profilePic': postData['profilePic'] ?? user.photoURL ?? "", // 'userImage' এর বদলে 'profilePic'
      'storyImage': postData['storyImage'] ?? "",
      'caption': "Shared: ${postData['caption'] ?? ""}",
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [], // নতুন পোস্টে ০ লাইক
    });
  }
}
