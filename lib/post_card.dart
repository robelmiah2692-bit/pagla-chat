import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? postId; // এখানে '?' দিয়ে অপশনাল করা হয়েছে

  // 'required' সরিয়ে দেওয়া হয়েছে যাতে home_page এর ডাটা নিয়ে ঝামেলা না হয়
  const PostCard({super.key, required this.data, this.postId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? "";
    final List likes = data['likes'] ?? [];
    final bool isLiked = likes.contains(uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // প্রোফাইল ও নাম
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                (data['userImage'] != null && data['userImage'].toString().isNotEmpty)
                    ? data['userImage']
                    : "https://www.w3schools.com/howto/img_avatar.png",
              ),
            ),
            title: Text(data['userName'] ?? "User", 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text("Just now", style: TextStyle(color: Colors.white54, fontSize: 11)),
          ),

          // ক্যাপশন
          if (data['caption'] != null && data['caption'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Text(data['caption'], style: const TextStyle(color: Colors.white)),
            ),

          // ইমেজ
          if (data['storyImage'] != null && data['storyImage'].toString().isNotEmpty)
            Image.network(data['storyImage'], width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink()),

          // বাটন সেকশন
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAction(isLiked ? Icons.favorite : Icons.favorite_border, 
                    isLiked ? Colors.red : Colors.white70, () {
                  if (postId != null) _StaticPostController.toggleLike(postId!, likes);
                }),
                _buildAction(Icons.mode_comment_outlined, Colors.white70, () {
                  print("Comment UI Triggered");
                }),
                _buildAction(Icons.share_outlined, Colors.white70, () {
                  _StaticPostController.sharePost(data);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("শেয়ার হয়েছে! ✅")));
                }),
              ],
            ),
          ),
          const Divider(color: Colors.white10, thickness: 6),
        ],
      ),
    );
  }

  Widget _buildAction(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(icon: Icon(icon, color: color, size: 24), onPressed: onTap);
  }
}

// কন্ট্রোলার এই ফাইলেই থাকবে যাতে ইমপোর্ট এরর না হয়
class _StaticPostController {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> toggleLike(String pId, List currentLikes) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    DocumentReference ref = _db.collection('stories').doc(pId);
    if (currentLikes.contains(uid)) {
      await ref.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      await ref.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }

  static Future<void> sharePost(Map<String, dynamic> postData) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('stories').add({
      'userId': user.uid,
      'userName': user.displayName ?? "User",
      'userImage': user.photoURL ?? "",
      'storyImage': postData['storyImage'] ?? "",
      'caption': "Shared: ${postData['caption'] ?? ""}",
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [],
    });
  }
}
