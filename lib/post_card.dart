import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String postId;

  const PostCard({super.key, required this.data, required this.postId});

  // 🔥 ১. লাইক সিস্টেম (ডাটাবেসে সেভ হবে)
  Future<void> _handleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentReference postRef = FirebaseFirestore.instance.collection('stories').doc(postId);
    DocumentSnapshot doc = await postRef.get();
    
    // ডাটাবেস থেকে লাইক লিস্ট নেওয়া
    List likes = (doc.data() as Map<String, dynamic>)['likes'] ?? [];

    if (likes.contains(user.uid)) {
      await postRef.update({'likes': FieldValue.arrayRemove([user.uid])});
    } else {
      await postRef.update({'likes': FieldValue.arrayUnion([user.uid])});
    }
  }

  // 🔥 ২. শেয়ার সিস্টেম (শেয়ারকারীর আইডি দিয়ে নতুন পোস্ট)
  Future<void> _handleShare(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('stories').add({
        'userId': user.uid,
        'userName': user.displayName ?? "User",
        'userImage': user.photoURL ?? "",
        'storyImage': data['storyImage'] ?? "",
        'caption': "Shared: ${data['caption'] ?? ""}",
        'timestamp': FieldValue.serverTimestamp(),
        'isShared': true,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("শেয়ার হয়েছে! ✅")));
    } catch (e) {
      print("Share Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userName = data['userName']?.toString() ?? "User";
    final String userImg = data['userImage']?.toString() ?? "";
    final String postImg = data['storyImage']?.toString() ?? "";
    final String caption = data['caption']?.toString() ?? "";
    
    // লাইক চেক
    List likes = data['likes'] ?? [];
    bool isLiked = likes.contains(FirebaseAuth.instance.currentUser?.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // প্রোফাইল ও নাম
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(userImg.isNotEmpty ? userImg : "https://www.w3schools.com/howto/img_avatar.png"),
            ),
            title: Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text("Just now", style: TextStyle(color: Colors.white54, fontSize: 11)),
          ),

          // ক্যাপশন
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Text(caption, style: const TextStyle(color: Colors.white)),
            ),

          // বড় ছবি
          if (postImg.isNotEmpty)
            Image.network(postImg, width: double.infinity, fit: BoxFit.cover, 
              errorBuilder: (context, error, stackTrace) => const SizedBox(height: 10)),

          // বাটন সেকশন
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBtn(isLiked ? Icons.favorite : Icons.favorite_border, isLiked ? "Liked" : "Like", 
                    isLiked ? Colors.red : Colors.white70, _handleLike),
                _buildBtn(Icons.mode_comment_outlined, "Comment", Colors.white70, () {
                  // কমেন্ট ফাংশন এখানে কল হবে
                }),
                _buildBtn(Icons.share_outlined, "Share", Colors.white70, () => _handleShare(context)),
              ],
            ),
          ),
          const Divider(color: Colors.white10, thickness: 6),
        ],
      ),
    );
  }

  Widget _buildBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
