import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔥 স্টোরি আপলোড (ইউজার প্রোফাইল ডাটাবেস থেকে রিয়েল নাম ও ছবি নিশ্চিত করা হয়েছে)
  Future<void> uploadStory(String imagePath, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // ১. প্রোফাইল ডাটাবেস (users collection) থেকে আসল তথ্য টেনে আনা
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      String realName = "পাগলা ইউজার";
      String realProfilePic = "";

      if (userDoc.exists) {
        // এখানে নিশ্চিত করুন আপনার প্রোফাইল পেজে ডাটা সেভ করার সময় কি নাম ব্যবহার করেছেন
        // যদি 'name' আর 'image' হয় তবে নিচের কোড ঠিক আছে
        realName = userDoc.get('name') ?? user.displayName ?? user.email?.split('@')[0] ?? "User";
        realProfilePic = userDoc.get('image') ?? user.photoURL ?? "";
      } else {
        // যদি ইউজার ডাটাবেসে না থাকে তবে লগইন ইনফো ব্যবহার করবে
        realName = user.displayName ?? user.email?.split('@')[0] ?? "User";
        realProfilePic = user.photoURL ?? "";
      }

      // ২. এখন আসল নাম-ছবি দিয়ে ডাটাবেসে স্টোরি সেভ করা হচ্ছে
      await _firestore.collection('stories').add({
        'userId': user.uid,
        'userName': realName, // প্রোফাইলের রিয়েল নাম
        'userImage': realProfilePic, // প্রোফাইলের রিয়েল ছবি
        'storyImage': imagePath, 
        'caption': text,
        'timestamp': FieldValue.serverTimestamp(), 
      });
      
      print("Story Uploaded with Real Profile Info! ✅");
    } catch (e) {
      print("Upload Error: $e");
    }
  }

  // স্টোরি ডাটা লোড করা
  Stream<QuerySnapshot> getStories() {
    return _firestore
        .collection('stories')
        .orderBy('timestamp', descending: true) 
        .snapshots();
  }
}
