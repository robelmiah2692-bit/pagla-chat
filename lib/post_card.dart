import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? postId;

  const PostCard({super.key, required this.data, this.postId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? "";
    final List likes = data['likes'] ?? [];
    final bool isLiked = likes.contains(uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF18191A), // ফেসবুক ডার্ক মোড কালার
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ১. প্রোফাইল ও নাম সেকশন
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
            subtitle: Text(
              _formatTimestamp(data['timestamp']),
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            trailing: const Icon(Icons.more_horiz, color: Colors.white54),
          ),

          // ২. ক্যাপশন সেকশন
          if (data['caption'] != null && data['caption'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: Text(data['caption'], 
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
            ),

          // ৩. 🔥 ইমেজ সেকশন (এখানেই ফেসবুক লুক আসবে)
          if (data['storyImage'] != null && data['storyImage'].toString().isNotEmpty)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900], // ছবি লোড হওয়ার আগে এই ব্যাকগ্রাউন্ড থাকবে
              ),
              constraints: const BoxConstraints(minHeight: 200, maxHeight: 500),
              child: Image.network(
                data['storyImage'],
                fit: BoxFit.cover, // ছবির পুরো জায়গা জুড়ে থাকবে
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 250,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.blueAccent,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.white10,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.white24, size: 50),
                        Text("ছবি লোড করা সম্ভব হয়নি", style: TextStyle(color: Colors.white24)),
                      ],
                    ),
                  );
                },
              ),
            ),

          // ৪. রিঅ্যাকশন কাউন্ট (লাইক সংখ্যা)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 16),
                const SizedBox(width: 5),
                Text("${likes.length}", style: const TextStyle(color: Colors.white54)),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // ৫. বাটন সেকশন (লাইক, কমেন্ট, শেয়ার)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  isLiked ? Icons.favorite : Icons.favorite_border, 
                  isLiked ? Colors.red : Colors.white70, 
                  "Like", 
                  () {
                    if (postId != null) _PostController.toggleLike(postId!, likes);
                  }
                ),
                _buildActionButton(Icons.mode_comment_outlined, Colors.white70, "Comment", () {}),
                _buildActionButton(Icons.share_outlined, Colors.white70, "Share", () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 5),
            Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    DateTime date = (timestamp as Timestamp).toDate();
    return "${date.hour}:${date.minute} - ${date.day}/${date.month}";
  }
}

// কন্ট্রোলার
class _PostController {
  static Future<void> toggleLike(String pId, List currentLikes) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    DocumentReference ref = FirebaseFirestore.instance.collection('stories').doc(pId);
    if (currentLikes.contains(uid)) {
      await ref.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      await ref.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }
}
