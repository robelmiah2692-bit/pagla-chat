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

    // 🔥 মালিক শনাক্তকরণ (Hridoy ভাইয়ের জন্য বিশেষ কোড)
    bool isOwner = (data['userId'] == "আপনার_ইউজার_আইডি" || data['userName'] == "King.Hridoy");

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF18191A), // ফেসবুক ডার্ক থিম
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- প্রোফাইল সেকশন ---
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[800],
              backgroundImage: NetworkImage(data['userImage'] ?? "https://www.w3schools.com/howto/img_avatar.png"),
            ),
            title: Row(
              children: [
                Text(
                  data['userName'] ?? "User",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 5),
                // মালিক হলে ভেরিফাইড ব্যাজ দেখাবে
                if (isOwner)
                  const Icon(Icons.verified, color: Colors.blueAccent, size: 16),
              ],
            ),
            subtitle: const Text("Just now", style: TextStyle(color: Colors.white54, fontSize: 11)),
            trailing: const Icon(Icons.more_vert, color: Colors.white54),
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

          // --- 🔥 ফিক্সড ইমেজ ফ্রেম (আপনার মূল সমস্যা এখানেই ছিল) ---
          if (data['storyImage'] != null && data['storyImage'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: 200, // ছবি আসার আগে অন্তত ২০০ পিক্সেল জায়গা নিয়ে থাকবে
                  maxHeight: 500, // খুব বড় ছবি হলে অটো অ্যাডজাস্ট করবে
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05), // জায়গাটা বোঝানোর জন্য হালকা কালার
                ),
                child: Image.network(
                  data['storyImage'],
                  width: double.infinity,
                  fit: BoxFit.contain, // ছবি কাটবে না, পুরোটা দেখাবে
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
                  errorBuilder: (context, error, stackTrace) {
                    // ছবি লোড না হলে জায়গাটি খালি না রেখে একটি আইকন দেখাবে
                    return Container(
                      height: 200,
                      color: Colors.white10,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: Colors.white24, size: 40),
                          SizedBox(height: 8),
                          Text("ছবিটি লোড করা যাচ্ছে না", style: TextStyle(color: Colors.white24)),
                        ],
                      ),
                    );
                  },
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

          // --- বাটন সেকশন (লাইক, কমেন্ট, শেয়ার) ---
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

  // বাটন ডিজাইন উইজেট
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

  // কমেন্ট বক্স লজিক
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
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    
    await FirebaseFirestore.instance.collection('stories').doc(pId).collection('comments').add({
      'text': text,
      'userName': userDoc.exists ? userDoc['name'] : "User",
      'userImage': userDoc.exists ? userDoc['profilePic'] : "",
      'timestamp': FieldValue.serverTimestamp(),
    });
    controller.clear();
  }
}
