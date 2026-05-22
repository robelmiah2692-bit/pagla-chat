import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'package:lottie/lottie.dart'; // গ্লাস ইফেক্টের জন্য

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
            title: const Text("Delete post",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: const Text("Are you sure delete this post?",
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("No", style: TextStyle(color: Colors.white54))),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Yes",
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
            ],
          ),
        ) ?? false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance
            .collection('stories')
            .doc(postId)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Post deleted successfully"),
                backgroundColor: Colors.red),
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
    final List likes = data['likes'] ?? [];

    // মালিকানা চেক করার জন্য
    bool isOwner = (data['authUID'] == user?.uid || data['userId'] == user?.uid);

    const Color premiumGold = Color(0xFFFFD700);
    const Color cyanOwner = Color(0xFF00FBFF);
    final Color glassColor = const Color(0xFF1E2A47).withOpacity(0.3);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: premiumGold.withOpacity(0.4),
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
                  leading: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                              colors: [cyanOwner, cyanOwner.withOpacity(0.2)]),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey[900],
                          backgroundImage: NetworkImage(
                            (data['userImage'] != null &&
                                    data['userImage'].toString().isNotEmpty)
                                ? data['userImage']
                                : "https://www.w3schools.com/howto/img_avatar.png",
                          ),
                        ),
                      ),
                      if (data['activeFrameUrl'] != null &&
                          data['activeFrameUrl'].toString().isNotEmpty)
                        Positioned.fill(
                          child: Transform.scale(
                            scale: 2.2,
                            child: IgnorePointer(
                              child: data['activeFrameUrl']
                                      .toString()
                                      .contains('.json')
                                  ? Lottie.network(
                                      data['activeFrameUrl'],
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const SizedBox(),
                                    )
                                  : Image.network(
                                      data['activeFrameUrl'],
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const SizedBox(),
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Text(
                        data['userName'] ?? "User",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      const SizedBox(width: 5),
                      if (isOwner)
                        const Icon(Icons.verified, color: cyanOwner, size: 17),
                    ],
                  ),
                  subtitle: Text(_getTimeAgo(data['timestamp']),
                      style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.white70),
                    onPressed: () {
                      if (isOwner) {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: const Color(0xFF121212),
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
                          builder: (context) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(
                                      Icons.delete_sweep_rounded,
                                      color: Colors.redAccent),
                                  title: const Text("Remove Post",
                                      style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _deletePost(context);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.close, color: Colors.white38),
                                  title: const Text("Cancel",
                                      style: TextStyle(color: Colors.white38)),
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
                            return const SizedBox(
                                height: 200,
                                child: Center(
                                    child: CircularProgressIndicator(
                                        color: cyanOwner, strokeWidth: 2)));
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 150,
                            color: Colors.white10,
                            child: const Center(
                                child: Icon(Icons.broken_image_outlined,
                                    color: Colors.white24, size: 40)),
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
                      Text("${likes.length} People liked",
                          style: const TextStyle(color: Colors.white38, fontSize: 11)),
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
                    _buildVIPBtn(
                        likes.contains(user?.uid) ? Icons.favorite : Icons.favorite_border,
                        likes.contains(user?.uid) ? Colors.redAccent : Colors.white70,
                        "Like", () {
                      if (postId != null && user != null) {
                        // 💡 রিয়েল-টাইম কাউন্টারের ম্যাচিং ফিক্স করতে সরাসরি আসল Firebase UID বের করে পাস করা হলো ভাই
                        String postOwnerUID = (data['authUID'] ?? data['userId'] ?? '').toString();
                        _toggleLike(postId!, postOwnerUID, likes);
                      }
                    }),
                    _buildVIPBtn(Icons.chat_bubble_outline_rounded, Colors.white70, "Comment", () {
                      if (postId != null) {
                        // 💡 কমেন্ট শিটেও কাস্টম লেখার আইডির বদলে সরাসরি আসল Firebase UID পাস করা হলো ভাই
                        String postOwnerUID = (data['authUID'] ?? data['userId'] ?? '').toString();
                        _showCommentSheet(context, postId!, postOwnerUID);
                      }
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
            Text(text,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _toggleLike(String pId, String postOwnerId, List currentLikes) async {
    DocumentReference ref = FirebaseFirestore.instance.collection('stories').doc(pId);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    bool isLiking = !currentLikes.contains(currentUser.uid);

    if (!isLiking) {
      ref.update({
        'likes': FieldValue.arrayRemove([currentUser.uid])
      });
    } else {
      ref.update({
        'likes': FieldValue.arrayUnion([currentUser.uid])
      });

      try {
        final senderQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: currentUser.email)
            .get();

        String sName = "Someone";
        String sPic = "";

        if (senderQuery.docs.isNotEmpty) {
          var sData = senderQuery.docs.first.data();
          sName = sData['name'] ?? "Someone";
          sPic = sData['profilePic'] ?? "";
        }

        // 💡 যদি সরাসরি পাঠানো আইডিটি আসল Firebase UID হয় (gDGBd9Xt...), তবে তা সরাসরি ব্যবহার হবে
        String targetAuthUID = postOwnerId;

        // ব্যাকআপ চেক: যদি পাঠানো আইডিটি ভুলবশত কাস্টম আইডি হয়, তবে ডাটাবেজ থেকে আসল authUID খুঁজে নেবে
        if (!postOwnerId.startsWith(RegExp(r'[0-9a-zA-Z]{20,}'))) {
          final ownerQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('uID', isEqualTo: postOwnerId)
              .get();

          if (ownerQuery.docs.isNotEmpty) {
            targetAuthUID = ownerQuery.docs.first.data()['authUID'] ?? postOwnerId;
          }
        }

        String pImage = (data['storyImage'] ?? '').toString();

        if (targetAuthUID.isNotEmpty && targetAuthUID != currentUser.uid) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'receiverId': targetAuthUID, // বারের লাইভ রিডার আইডির সাথে ১০০% ম্যাচড!
            'senderId': currentUser.uid,
            'senderName': sName,
            'senderPic': sPic,
            'type': 'like',
            'commentText': '',
            'postImage': pImage,
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
          debugPrint("✅ [PaglaChat] সফলভাবে লাইক নোটিফিকেশন কালেকশনে ফিল্ডসহ ডাটা পাঠানো হয়েছে!");
        }
      } catch (e) {
        debugPrint("❌ [PaglaChat] লাইক নোটিফিকেশন পাঠাতে এরর: $e");
      }
    }
  }

  void _showCommentSheet(BuildContext context, String pId, String postOwnerId) {
    final TextEditingController _commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20, left: 15, right: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 15),
            const Text("COMMENTS",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF00FBFF)));
                  }
                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text("No comments yet", style: TextStyle(color: Colors.white38)));
                  }
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      Map<String, dynamic> cData = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(cData['userImage'] != null && cData['userImage'] != ""
                                ? cData['userImage']
                                : "https://www.w3schools.com/howto/img_avatar.png")),
                        title: Text(cData['userName'] ?? "User",
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        subtitle: Text(cData['text'] ?? "",
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
                    onPressed: () => _submitComment(
                        pId, 
                        _commentController.text, 
                        _commentController, 
                        postOwnerId
                    ),
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

  void _submitComment(
      String pId, String text, TextEditingController controller, String postOwnerId) async {
    if (text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();

      String name = "User";
      String image = "";

      if (userQuery.docs.isNotEmpty) {
        var userData = userQuery.docs.first.data();
        name = userData['name'] ?? "User";
        image = userData['profilePic'] ?? "";
      }

      // ১. কমেন্ট সাবমিট
      await FirebaseFirestore.instance
          .collection('stories')
          .doc(pId)
          .collection('comments')
          .add({
        'text': text.trim(),
        'userName': name,
        'userImage': image,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // ২. নোটিফিকেশন ডাটাবেজে পাঠানো (Receiver ID সিঙ্কড উইথ আসল UID)
      if (postOwnerId.isNotEmpty && postOwnerId != user.uid) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'receiverId': postOwnerId,  // 💡 রিসিভারের আসল Firebase UID (gDGBd9Xt...)
          'senderId': user.uid,
          'senderName': name,
          'senderPic': image,
          'type': 'comment',
          'commentText': text.trim(),
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
        debugPrint("✅ [PaglaChat] সফলভাবে কমেন্ট নোটিফিকেশন ফিল্ডসহ ডাটা পাঠানো হয়েছে ভাই!");
      }

      controller.clear();
    } catch (e) {
      debugPrint("❌ [PaglaChat] কমেন্ট নোটিফিকেশন পাঠাতে এরর: $e");
    }
  }
}