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

    // 🔥 আপনি মালিক কি না চেক (আপনার ইনস্ট্রাকশন অনুযায়ী হদয় আইডি চেক)
    final bool isOwner = (uid == data['userId'] || data['userName'] == "Hridoy");

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // প্রোফাইল ও নাম
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[800],
              backgroundImage: (data['userImage'] != null && data['userImage'].toString().isNotEmpty)
                  ? NetworkImage(data['userImage'])
                  : const NetworkImage("https://www.w3schools.com/howto/img_avatar.png"),
            ),
            title: Text(data['userName'] ?? "User", 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              _formatTimestamp(data['timestamp']),
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            // 🔥 ডিলিট বাটন (শুধুমাত্র পোস্টকারী বা মালিকের জন্য)
            trailing: isOwner 
              ? IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                  onPressed: () => _showDeleteDialog(context, postId),
                )
              : null,
          ),

          // ক্যাপশন
          if (data['caption'] != null && data['caption'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Text(data['caption'], style: const TextStyle(color: Colors.white)),
            ),

          // 🖼️ ইমেজ সেকশন (ফিক্স করা হয়েছে)
          if (data['storyImage'] != null && data['storyImage'].toString().isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              width: double.infinity,
              child: Image.network(
                data['storyImage'],
                fit: BoxFit.contain, // ইমেজ যেন কেটে না যায়
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                },
                errorBuilder: (context, error, stackTrace) {
                  // ছবি লোড না হলে একটি এম্পটি বক্স দেখাবে
                  return Container(
                    height: 200,
                    color: Colors.white10,
                    child: const Icon(Icons.broken_image, color: Colors.white24, size: 40),
                  );
                },
              ),
            ),

          // বাটন সেকশন
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // লাইক
                _buildAction(
                  isLiked ? Icons.favorite : Icons.favorite_border, 
                  isLiked ? Colors.red : Colors.white70, 
                  "Like ${likes.length}", 
                  () {
                    if (postId != null) _StaticPostController.toggleLike(postId!, likes);
                  }
                ),
                // কমেন্ট
                _buildAction(Icons.mode_comment_outlined, Colors.white70, "Comment", () {
                  print("Comment Clicked");
                }),
                // শেয়ার
                _buildAction(Icons.share_outlined, Colors.white70, "Share", () {
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

  Widget _buildAction(IconData icon, Color color, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return "${date.hour}:${date.minute} - ${date.day}/${date.month}";
    }
    return "Just now";
  }

  void _showDeleteDialog(BuildContext context, String? pId) {
    if (pId == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("পোস্ট ডিলিট করবেন?", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("না")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('stories').doc(pId).delete();
              Navigator.pop(context);
            }, 
            child: const Text("হ্যাঁ", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}

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

    // 🔥 শেয়ার করার সময় ইউজারের প্রোফাইল ডাটা আনা
    DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();
    String myName = userDoc.exists ? userDoc.get('name') : "User";
    String myPic = userDoc.exists ? userDoc.get('profilePic') : "";

    await _db.collection('stories').add({
      'userId': user.uid,
      'userName': myName,
      'userImage': myPic,
      'storyImage': postData['storyImage'] ?? "",
      'caption': "Shared: ${postData['caption'] ?? ""}",
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [],
    });
  }
}
