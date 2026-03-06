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
      color: const Color(0xFF18191A), // ডার্ক থিম
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // প্রোফাইল সেকশন
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(data['userImage'] ?? "https://www.w3schools.com/howto/img_avatar.png"),
            ),
            title: Text(data['userName'] ?? "User", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text("Just now", style: TextStyle(color: Colors.white54, fontSize: 11)),
            trailing: const Icon(Icons.more_vert, color: Colors.white54),
          ),

          // ক্যাপশন
          if (data['caption'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Text(data['caption'], style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),

          // 🔥 ফিক্সড ইমেজ সেকশন (ছবি না থাকলেও জায়গা ধরে রাখবে না, থাকলে ফেসবুকের মতো দেখাবে)
          if (data['storyImage'] != null && data['storyImage'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Image.network(
                data['storyImage'],
                width: double.infinity,
                fit: BoxFit.contain, // ছবি কাটবে না, পূর্ণ দেখাবে
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.white10,
                    child: const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink(); // এরর হলে জায়গা খালি রাখবে
                },
              ),
            ),

          // লাইক কাউন্ট
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

          // বাটন সেকশন (লাইক, কমেন্ট, শেয়ার)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBtn(isLiked ? Icons.favorite : Icons.favorite_border, isLiked ? Colors.red : Colors.white70, "লাইক", () {
                if (postId != null) _toggleLike(postId!, uid, likes);
              }),
              
              // 🔥 কমেন্ট বাটন (ক্লিক করলে কমেন্ট বক্স খুলবে)
              _buildBtn(Icons.mode_comment_outlined, Colors.white70, "কমেন্ট", () {
                _showCommentSheet(context, postId!);
              }),
              
              _buildBtn(Icons.share_outlined, Colors.white70, "শেয়ার", () {}),
            ],
          ),
        ],
      ),
    );
  }

  // বাটন ডিজাইন
  Widget _buildBtn(IconData icon, Color color, String text, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 20),
      label: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }

  // লাইক লজিক
  void _toggleLike(String pId, String uId, List currentLikes) {
    DocumentReference ref = FirebaseFirestore.instance.collection('stories').doc(pId);
    if (currentLikes.contains(uId)) {
      ref.update({'likes': FieldValue.arrayRemove([uId])});
    } else {
      ref.update({'likes': FieldValue.arrayUnion([uId])});
    }
  }

  // 🔥 কমেন্ট বক্স লজিক (ফেসবুকের মতো নিচ থেকে উঠবে)
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
            
            // কমেন্ট লিস্ট (রিয়েল টাইম)
            SizedBox(
              height: 300,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('stories').doc(pId).collection('comments').orderBy('timestamp').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  return ListView(
                    children: snapshot.data!.docs.map((doc) => ListTile(
                      leading: CircleAvatar(radius: 15, backgroundImage: NetworkImage(doc['userImage'] ?? "")),
                      title: Text(doc['userName'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(doc['text'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    )).toList(),
                  );
                },
              ),
            ),

            // ইনপুট বক্স
            TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "আপনার মতামত লিখুন...",
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
    if (text.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    // প্রোফাইল ডাটা নিয়ে কমেন্ট সেভ
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    
    await FirebaseFirestore.instance.collection('stories').doc(pId).collection('comments').add({
      'text': text,
      'userName': userDoc['name'] ?? "User",
      'userImage': userDoc['profilePic'] ?? "",
      'timestamp': FieldValue.serverTimestamp(),
    });
    controller.clear();
  }
}
