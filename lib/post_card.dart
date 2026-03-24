import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? postId;

  const PostCard({super.key, required this.data, this.postId});

  // --- পোস্ট ডিলিট করার ফাংশন ---
  void _deletePost(BuildContext context) async {
    if (postId == null) return;

    // ডিলিট করার আগে একবার কনফার্মেশন ডায়ালগ দেখানো ভালো
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242526),
        title: const Text("পোস্ট ডিলিট", style: TextStyle(color: Colors.white)),
        content: const Text("আপনি কি নিশ্চিতভাবে এই পোস্টটি মুছে ফেলতে চান?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("না")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("হ্যাঁ, ডিলিট করুন", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('stories').doc(postId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("পোস্টটি সফলভাবে মুছে ফেলা হয়েছে"), backgroundColor: Colors.red),
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

    // মালিক শনাক্তকরণ
    bool isOwner = (data['userId'] == uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF18191A), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- প্রোফাইল সেকশন ---
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
            subtitle: const Text("Just now", style: TextStyle(color: Colors.white54, fontSize: 11)),
            
            // --- থ্রি ডট মেনু (এখানে ডিলিট অপশন যোগ করা হয়েছে) ---
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
                            title: const Text("পোস্ট ডিলিট করুন", style: TextStyle(color: Colors.white)),
                            onTap: () {
                              Navigator.pop(context); // বটম শিট বন্ধ
                              _deletePost(context); // ডিলিট ফাংশন কল
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.close, color: Colors.white54),
                            title: const Text("বাতিল", style: TextStyle(color: Colors.white54)),
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // যদি নিজের পোস্ট না হয়
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("আপনি শুধু নিজের পোস্ট ডিলিট করতে পারবেন")),
                  );
                }
              },
            ),
          ),

          // --- ক্যাপশন সেকশন ---
          if (data['caption'] != null && data['caption'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Text(
                data['caption'],
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),

          // --- ইমেজ সেকশন ---
          if (data['storyImage'] != null && data['storyImage'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
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
                    return Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.blueAccent,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    color: Colors.white10,
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 40)),
                  ),
                ),
              ),
            ),

          // --- লাইক কাউন্ট ---
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 16),
                const SizedBox(width: 5),
                Text("${likes.length}", style: const TextStyle(color: Colors.white54)),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // --- বাটন সেকশন ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBtn(isLiked ? Icons.favorite : Icons.favorite_border, isLiked ? Colors.red : Colors.white70, "লাইক", () {
                if (postId != null) _toggleLike(postId!, uid, likes);
              }),
              _buildBtn(Icons.mode_comment_outlined, Colors.white70, "কমেন্ট", () {
                if (postId != null) _showCommentSheet(context, postId!);
              }),
              _buildBtn(Icons.share_outlined, Colors.white70, "শেয়ার", () {}),
            ],
          ),
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
            const Text("কমেন্ট করুন", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                hintText: "আপনার মতামত লিখুন...",
                hintStyle: const TextStyle(color: Colors.white38),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () {
                    _submitComment(pId, _commentController.text, _commentController);
                  },
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
