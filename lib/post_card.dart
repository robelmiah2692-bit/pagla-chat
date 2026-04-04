import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui'; // গ্লাস ইফেক্টের জন্য

class PostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? postId;

  const PostCard({super.key, required this.data, this.postId});

  // --- টাইম ক্যালকুলেশন ফাংশন ---
  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) return "Just now";
    DateTime postTime = timestamp.toDate();
    Duration diff = DateTime.now().difference(postTime);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${postTime.day}/${postTime.month}/${postTime.year}";
  }

  // --- পোস্ট ডিলিট লজিক ---
  void _deletePost(BuildContext context) async {
    if (postId == null) return;
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete post", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure delete this post?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Yes", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('stories').doc(postId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Post deleted successfully"), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        debugPrint("Delete Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? "";
    final List likes = data['likes'] ?? [];
    final bool isLiked = likes.contains(uid);
    bool isOwner = (data['userId'] == uid);

    // থিম কালারস
    const Color premiumGold = Color(0xFFFFD700);
    const Color cyanOwner = Color(0xFF00FBFF);
    // গ্লাস বডির জন্য নতুন কালার (কালো বা গোলাপি নয়)
    final Color glassColor = const Color(0xFF1E2A47).withOpacity(0.3); 

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // গ্লাস ইফেক্টের ব্লার
          child: Container(
            decoration: BoxDecoration(
              color: glassColor, // কালো বা গোলাপি বাদে প্রিমিয়াম ব্লু গ্লাস
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: premiumGold.withOpacity(0.4), // গোল্ডেন চিকন বর্ডার
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [cyanOwner, cyanOwner.withOpacity(0.2)]),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey[900],
                      backgroundImage: NetworkImage(
                        (data['userImage'] != null && data['userImage'].toString().isNotEmpty)
                            ? data['userImage']
                            : "https://www.w3schools.com/howto/img_avatar.png",
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        data['userName'] ?? "User",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(width: 5),
                      if (isOwner)
                        const Icon(Icons.verified, color: cyanOwner, size: 17),
                    ],
                  ),
                  subtitle: Text(
                    _getTimeAgo(data['timestamp']), 
                    style: const TextStyle(color: Colors.white38, fontSize: 10)
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.white70),
                    onPressed: () {
                      if (isOwner) {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: const Color(0xFF121212),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
                          builder: (context) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                                  title: const Text("Remove Post", style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _deletePost(context);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.close, color: Colors.white38),
                                  title: const Text("Cancel", style: TextStyle(color: Colors.white38)),
                                  onTap: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Only post owner can delete this")),
                        );
                      }
                    },
                  ),
                ),

                if (data['caption'] != null && data['caption'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 18, right: 18, bottom: 10, top: 2),
                    child: Text(
                      data['caption'],
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                    ),
                  ),

                if (data['storyImage'] != null && data['storyImage'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 200, maxHeight: 500),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.03)),
                        child: Image.network(
                          data['storyImage'],
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: cyanOwner, strokeWidth: 2)));
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 150,
                            color: Colors.white10,
                            child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 40)),
                          ),
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 5),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.redAccent, size: 14),
                      const SizedBox(width: 6),
                      Text("${likes.length} People liked", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Divider(color: Colors.white10, thickness: 0.8),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildVIPBtn(isLiked ? Icons.favorite : Icons.favorite_border, isLiked ? Colors.redAccent : Colors.white70, "Like", () {
                      if (postId != null) _toggleLike(postId!, uid, likes);
                    }),
                    _buildVIPBtn(Icons.chat_bubble_outline_rounded, Colors.white70, "Comment", () {
                      if (postId != null) _showCommentSheet(context, postId!);
                    }),
                    _buildVIPBtn(Icons.share_rounded, Colors.white70, "Share", () {}),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVIPBtn(IconData icon, Color color, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _toggleLike(String pId, String uId, List currentLikes) {
    DocumentReference ref = FirebaseFirestore.instance.collection('stories').doc(pId);
    if (currentLikes.contains(uId)) {
      ref.update({'likes': FieldValue.arrayRemove([uId])});
    } else {
      ref.update({'likes': FieldValue.arrayUnion([uId])});
    }
  }

  void _showCommentSheet(BuildContext context, String pId) {
    final TextEditingController _commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 15, right: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 15),
            const Text("COMMENTS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 15),
            SizedBox(
              height: 350,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('stories')
                    .doc(pId)
                    .collection('comments')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00FBFF)));
                  if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No comments yet", style: TextStyle(color: Colors.white38)));
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      Map<String, dynamic> cData = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16, 
                          backgroundImage: NetworkImage(cData['userImage'] ?? "https://www.w3schools.com/howto/img_avatar.png")
                        ),
                        title: Text(cData['userName'] ?? "User", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        subtitle: Text(cData['text'] ?? "", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  hintText: "Add a comment...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF00FBFF)),
                    onPressed: () => _submitComment(pId, _commentController.text, _commentController),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _submitComment(String pId, String text, TextEditingController controller) async {
    if (text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    await FirebaseFirestore.instance.collection('stories').doc(pId).collection('comments').add({
      'text': text.trim(),
      'userName': userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['name'] : "User",
      'userImage': userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['profilePic'] : "",
      'timestamp': FieldValue.serverTimestamp(),
    });
    controller.clear();
  }
}
