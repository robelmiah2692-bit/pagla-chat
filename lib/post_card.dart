import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String postId; // পোস্টের ইউনিক আইডি

  const PostCard({super.key, required this.data, required this.postId});

  // 🔥 ১. লাইক সিস্টেম (ডাটাবেসে সেভ থাকবে)
  Future<void> _handleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentReference postRef = FirebaseFirestore.instance.collection('stories').doc(postId);
    
    // চেক করবে ইউজার আগে লাইক দিয়েছে কি না
    DocumentSnapshot doc = await postRef.get();
    List likes = doc.get('likes') ?? [];

    if (likes.contains(user.uid)) {
      // যদি আগে লাইক দিয়ে থাকে, তবে লাইক উঠে যাবে (Unlike)
      await postRef.update({'likes': FieldValue.arrayRemove([user.uid])});
    } else {
      // না দিয়ে থাকলে নতুন লাইক যোগ হবে
      await postRef.update({'likes': FieldValue.arrayUnion([user.uid])});
    }
  }

  // 🔥 ২. শেয়ার সিস্টেম (যে শেয়ার করবে তার আইডি দিয়ে নতুন পোস্ট হবে)
  Future<void> _handleShare(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // শেয়ার করা ইউজারের প্রোফাইল থেকে তথ্য নেওয়া
      await FirebaseFirestore.instance.collection('stories').add({
        'userId': user.uid,
        'userName': user.displayName ?? "User",
        'userImage': user.photoURL ?? "",
        'storyImage': data['storyImage'], // অরিজিনাল পোস্টের ছবি
        'caption': "Shared: ${data['caption']}", // শেয়ার করা ক্যাপশন
        'timestamp': FieldValue.serverTimestamp(),
        'isShared': true,
        'originalPostId': postId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("আপনার প্রোফাইলে শেয়ার হয়েছে! ✅")),
      );
    } catch (e) {
      print("Share Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // লাইক সংখ্যা চেক করা
    List likes = data['likes'] ?? [];
    bool isLiked = likes.contains(FirebaseAuth.instance.currentUser?.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      color: Colors.black,
      child: Column(
        children: [
          // ... (প্রোফাইল ও ইমেজ অংশ আগের মতোই থাকবে) ...

          // ৪. বাটন সেকশন
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildButton(
                  isLiked ? Icons.favorite : Icons.favorite_border, 
                  isLiked ? "Liked" : "Like", 
                  isLiked ? Colors.red : Colors.white70, 
                  _handleLike
                ),
                _buildButton(Icons.mode_comment_outlined, "Comment", Colors.white70, () {
                   // কমেন্ট বক্স ওপেন করার ফাংশন (আগেরটা)
                }),
                _buildButton(Icons.share_outlined, "Share", Colors.white70, () {
                  _handleShare(context); // এখানে ক্লিক করলে শেয়ার হবে
                }),
              ],
            ),
          ),
          const Divider(color: Colors.white10, thickness: 5),
        ],
      ),
    );
  }

  Widget _buildButton(IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 5),
          Text(title, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
