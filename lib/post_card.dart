import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? postId;

  const PostCard({super.key, required this.data, this.postId});

  // --- টাইম ক্যালকুলেশন ফাংশন (টাইমার ঠিক করার জন্য) ---
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

  // --- পোস্ট ডিলিট লজিক (অপরিবর্তিত) ---
  void _deletePost(BuildContext context) async {
    if (postId == null) return;
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242526),
        title: const Text("Delete post", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure delete this post?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Yes", style: TextStyle(color: Colors.red))
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      // --- গ্লাস ডিজাইন পোস্ট বক্স ---
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08), 
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[800],
              backgroundImage: NetworkImage(
                (data['userImage'] != null && data['userImage'].toString().isNotEmpty)
                    ? data['userImage']
                    : "https://www.w3schools.com/howto/img_avatar.png",
              ),
            ),
            title: Row(
              children: [
                Text(
                  data['userName'] ?? "User",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 5),
                if (isOwner)
                  const Icon(Icons.verified, color: Colors.blueAccent, size: 16),
              ],
            ),
            // --- এখানে টাইমার সেট করা হয়েছে ---
            subtitle: Text(
              _getTimeAgo(data['timestamp']), 
              style: const TextStyle(color: Colors.white54, fontSize: 11)
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              onPressed: () {
                if (isOwner) {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF242526),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (context) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            title: const Text("Delete post", style: TextStyle(color: Colors.white)),
                            onTap: () {
                              Navigator.pop(context);
                              _deletePost(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.close, color: Colors.white54),
                            title: const Text("Cancel", style: TextStyle(color: Colors.white54)),
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Deleted Only post owner")),
                  );
                }
              },
            ),
          ),

          // --- ক্যাপশন ---
          if (data['caption'] != null && data['caption'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Text(
                data['caption'],
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),

          // --- ইমেজ সেকশন (গ্লাস ডিজাইন বর্ডারসহ) ---
          if (data['storyImage'] != null && data['storyImage'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 200, maxHeight: 500),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05)),
                  child: Image.network(
                    data['storyImage'],
                    width: double.infinity,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)));
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      color: Colors.white10,
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 40)),
                    ),
                  ),
                ),
              ),
            ),

          // --- লাইক ও বাটন সেকশন ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 16),
                const SizedBox(width: 5),
                Text("${likes.length}", style: const TextStyle(color: Colors.white54)),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBtn(isLiked ? Icons.favorite : Icons.favorite_border, isLiked ? Colors.red : Colors.white70, "Like", () {
                if (postId != null) _toggleLike(postId!, uid, likes);
              }),
              _buildBtn(Icons.mode_comment_outlined, Colors.white70, "Comments", () {
                if (postId != null) _showCommentSheet(context, postId!);
              }),
              _buildBtn(Icons.share_outlined, Colors.white70, "Share", () {}),
            ],
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildBtn(IconData icon, Color color, String text, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 20),
      label: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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

  // --- কমেন্ট শিট লজিক (অপরিবর্তিত) ---
  void _showCommentSheet(BuildContext context, String pId) {
    final TextEditingController _commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF242526),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 15, right: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("comment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('stories')
                    .doc(pId)
                    .collection('comments')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      Map<String, dynamic> cData = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 15, 
                          backgroundImage: NetworkImage(cData['userImage'] ?? "https://www.w3schools.com/howto/img_avatar.png")
                        ),
                        title: Text(cData['userName'] ?? "User", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text(cData['text'] ?? "", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "type anything ...",
                hintStyle: const TextStyle(color: Colors.white38),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () => _submitComment(pId, _commentController.text, _commentController),
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
