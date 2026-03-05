import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔥 ফাইল লোকেশন অনুযায়ী সঠিক ইমপোর্ট:
import '../services/post_controller.dart'; 

class PostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String postId;

  const PostCard({super.key, required this.data, required this.postId});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    
    // ডাটাবেস থেকে লাইক লিস্ট রিড করা
    final List likes = data['likes'] ?? [];
    final bool isLiked = likes.contains(uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ১. প্রোফাইল ও নাম অংশ
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                data['userImage'] != null && data['userImage'].toString().isNotEmpty 
                ? data['userImage'] 
                : "https://www.w3schools.com/howto/img_avatar.png"
              ),
            ),
            title: Text(data['userName'] ?? "User", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text("Just now", style: TextStyle(color: Colors.white54, fontSize: 11)),
          ),

          // ২. ক্যাপশন
          if (data['caption'] != null && data['caption'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Text(data['caption'], style: const TextStyle(color: Colors.white)),
            ),

          // ৩. ইমেজ অংশ
          if (data['storyImage'] != null && data['storyImage'].toString().isNotEmpty)
            Image.network(
              data['storyImage'],
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),

          // ৪. ইন্টারেকশন বাটন (লাইক, কমেন্ট, শেয়ার)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // লাইক বাটন
                _buildAction(
                  isLiked ? Icons.favorite : Icons.favorite_border, 
                  isLiked ? Colors.red : Colors.white70, 
                  () => PostController.toggleLike(postId, likes)
                ),
                // কমেন্ট বাটন (এখানে আমরা পরে মেসেজ বার যোগ করব)
                _buildAction(Icons.mode_comment_outlined, Colors.white70, () {
                  print("Comment clicked");
                }),
                // শেয়ার বাটন
                _buildAction(Icons.share_outlined, Colors.white70, () {
                  PostController.sharePost(data);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("আপনার প্রোফাইলে শেয়ার হয়েছে! ✅"))
                  );
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
    return IconButton(
      icon: Icon(icon, color: color, size: 24),
      onPressed: onTap,
    );
  }
}
