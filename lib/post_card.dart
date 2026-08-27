import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'package:lottie/lottie.dart';
import 'package:pagla_chat/profile_page.dart';
import 'package:pagla_chat/widgets/video_post_widget.dart'; // গ্লাস ইফেক্টের জন্য

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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Delete post",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: const Text("Are you sure delete this post?",
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("No",
                      style: TextStyle(color: Colors.white54))),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Yes",
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold))),
            ],
          ),
        ) ??
        false;

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

    // ১. পোস্ট ডাটা থেকে আইডি বের করা
    final String targetAuthUID = data['authUID'] ?? data['userId'] ?? '';

    // মালিকানা চেক করার জন্য
    bool isOwner = (targetAuthUID == user?.uid);

    const Color premiumGold = Color(0xFFFFD700);
    const Color cyanOwner = Color(0xFF00FBFF);
    final Color glassColor = const Color(0xFF1E2A47).withOpacity(0.3);

    // ফায়ারস্টোর থেকে ইউজারের লেটেস্ট ডেটা লাইভ আনার জন্য মাল্টিপল স্টেপ চেক (প্রথমে doc, তারপর uID, তারপর uid)
    return StreamBuilder<DocumentSnapshot>(
      stream: targetAuthUID.isNotEmpty
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(targetAuthUID)
              .snapshots()
          : const Stream.empty(),
      builder: (context, docSnapshot) {
        // যদি ডাইরেক্ট doc(targetId) এ পাওয়া যায়
        if (docSnapshot.hasData && docSnapshot.data!.exists) {
          var userDoc = docSnapshot.data!.data() as Map<String, dynamic>?;
          if (userDoc != null) {
            return _buildPostWidget(
                context, userDoc, targetAuthUID, isOwner, likes);
          }
        }

        // যদি ডাইরেক্ট না থাকে, তবে 'uID' ফিল্ড দিয়ে কোয়েরি
        return StreamBuilder<QuerySnapshot>(
          stream: targetAuthUID.isNotEmpty
              ? FirebaseFirestore.instance
                  .collection('users')
                  .where('uID', isEqualTo: targetAuthUID)
                  .snapshots()
              : const Stream.empty(),
          builder: (context, querySnapshot1) {
            if (querySnapshot1.hasData &&
                querySnapshot1.data!.docs.isNotEmpty) {
              var userDoc = querySnapshot1.data!.docs.first.data()
                  as Map<String, dynamic>;
              return _buildPostWidget(
                  context, userDoc, targetAuthUID, isOwner, likes);
            }

            // সবশেষে ছোট হাতের 'uid' ফিল্ড দিয়ে কোয়েরি
            return StreamBuilder<QuerySnapshot>(
              stream: targetAuthUID.isNotEmpty
                  ? FirebaseFirestore.instance
                      .collection('users')
                      .where('uid', isEqualTo: targetAuthUID)
                      .snapshots()
                  : const Stream.empty(),
              builder: (context, querySnapshot2) {
                Map<String, dynamic>? liveUserData;
                if (querySnapshot2.hasData &&
                    querySnapshot2.data!.docs.isNotEmpty) {
                  liveUserData = querySnapshot2.data!.docs.first.data()
                      as Map<String, dynamic>;
                }

                return _buildPostWidget(
                    context, liveUserData, targetAuthUID, isOwner, likes);
              },
            );
          },
        );
      },
    );
  }

// আলাদা একটি মেথড যা পুরো পোস্ট UI রেন্ডার করবে
  Widget _buildPostWidget(
      BuildContext context,
      Map<String, dynamic>? liveUserData,
      String targetAuthUID,
      bool isOwner,
      List likes) {
    const Color premiumGold = Color(0xFFFFD700);
    const Color cyanOwner = Color(0xFF00FBFF);
    final Color glassColor = const Color(0xFF1E2A47).withOpacity(0.3);
    final user = FirebaseAuth.instance.currentUser;

    // লাইভ ডাটা বা পোস্টের পুরাতন ডাটা ফলব্যাক হিসেবে ব্যবহার
    final String currentUserName = liveUserData?['name'] ??
        liveUserData?['userName'] ??
        data['userName'] ??
        "User";
    final String currentUserImage = liveUserData?['profilePic'] ??
        liveUserData?['userImage'] ??
        data['userImage'] ??
        "https://www.w3schools.com/howto/img_avatar.png";
    final String currentFrameUrl =
        liveUserData?['activeFrameUrl'] ?? data['activeFrameUrl'] ?? '';
    final bool isVerified = liveUserData?['isVerified'] ?? false;

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
                  leading: GestureDetector(
                    onTap: () async {
                      if (targetAuthUID.isEmpty) {
                        return;
                      }

                      // সঠিক আইডি খোঁজা প্রোফাইল পেজে যাওয়ার জন্য
                      String finalIdToPass = targetAuthUID;
                      try {
                        var userQuery = await FirebaseFirestore.instance
                            .collection('users')
                            .where('authUID', isEqualTo: targetAuthUID)
                            .limit(1)
                            .get();

                        if (userQuery.docs.isNotEmpty) {
                          finalIdToPass = userQuery.docs.first.id;
                        }
                      } catch (e) {}

                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfilePage(userId: finalIdToPass),
                        ),
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [
                              cyanOwner,
                              cyanOwner.withOpacity(0.2)
                            ]),
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.grey[900],
                            backgroundImage: NetworkImage(
                              (currentUserImage.isNotEmpty)
                                  ? currentUserImage
                                  : "https://www.w3schools.com/howto/img_avatar.png",
                            ),
                          ),
                        ),
                        if (currentFrameUrl.isNotEmpty)
                          Positioned.fill(
                            child: Transform.scale(
                              scale: 2.2,
                              child: IgnorePointer(
                                child: currentFrameUrl.contains('.json')
                                    ? Lottie.network(
                                        currentFrameUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const SizedBox(),
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: currentFrameUrl,
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) =>
                                            const SizedBox(),
                                        errorWidget:
                                            (context, error, stackTrace) =>
                                                const SizedBox(),
                                      ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        currentUserName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      const SizedBox(width: 5),
                      if (isVerified)
                        const Icon(Icons.verified, color: cyanOwner, size: 17),
                    ],
                  ),
                  subtitle: Text(_getTimeAgo(data['timestamp']),
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 10)),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.white70),
                    onPressed: () {
                      if (isOwner) {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: const Color(0xFF121212),
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(25))),
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
                                  leading: const Icon(Icons.close,
                                      color: Colors.white38),
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
                          const SnackBar(
                              content: Text("Only post owner can delete this")),
                        );
                      }
                    },
                  ),
                ),
                if (data['caption'] != null &&
                    data['caption'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 18, right: 18, bottom: 10, top: 2),
                    child: Text(
                      data['caption'],
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.4),
                    ),
                  ),
                if (data['storyImage'] != null &&
                    data['storyImage'].toString().isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(
                            minHeight: 200, maxHeight: 500),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03)),
                        child: CachedNetworkImage(
                          imageUrl: data['storyImage'],
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: cyanOwner, strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 150,
                            color: Colors.white10,
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: Colors.white24, size: 40),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if ((data['videoUrl'] != null &&
                        data['videoUrl'].toString().isNotEmpty) ||
                    (data['storyVideo'] != null &&
                        data['storyVideo'].toString().isNotEmpty))
                  FeedVideoPlayer(
                      videoUrl: data['videoUrl'] ?? data['storyVideo']),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 5),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite,
                          color: Colors.redAccent, size: 14),
                      const SizedBox(width: 6),
                      Text("${likes.length} People liked",
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
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
                        likes.contains(user?.uid)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        likes.contains(user?.uid)
                            ? Colors.redAccent
                            : Colors.white70,
                        "Like", () {
                      if (postId != null && user != null) {
                        String postOwnerUID =
                            (data['authUID'] ?? data['userId'] ?? '')
                                .toString();
                        _toggleLike(postId!, postOwnerUID, likes);
                      }
                    }),
                    _buildVIPBtn(Icons.chat_bubble_outline_rounded,
                        Colors.white70, "Comment", () {
                      if (postId != null) {
                        String postOwnerUID =
                            (data['authUID'] ?? data['userId'] ?? '')
                                .toString();
                        _showCommentSheet(context, postId!, postOwnerUID);
                      }
                    }),
                    _buildVIPBtn(
                        Icons.share_rounded, Colors.white70, "Share", () {}),
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

  Widget _buildVIPBtn(
      IconData icon, Color color, String text, VoidCallback onTap) {
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
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _toggleLike(String pId, String postOwnerId, List currentLikes) async {
    DocumentReference ref =
        FirebaseFirestore.instance.collection('stories').doc(pId);
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
            targetAuthUID =
                ownerQuery.docs.first.data()['authUID'] ?? postOwnerId;
          }
        }

        String pImage = (data['storyImage'] ?? '').toString();

        if (targetAuthUID.isNotEmpty && targetAuthUID != currentUser.uid) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'receiverId':
                targetAuthUID, // বারের লাইভ রিডার আইডির সাথে ১০০% ম্যাচড!
            'senderId': currentUser.uid,
            'senderName': sName,
            'senderPic': sPic,
            'type': 'like',
            'commentText': '',
            'postImage': pImage,
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {}
    }
  }

  void _showCommentSheet(BuildContext context, String pId, String postOwnerId) {
    final TextEditingController _commentController = TextEditingController();

    // রিপ্লাই দেওয়ার জন্য স্টেট ম্যানেজমেন্ট বা লোকাল ভেরিয়েবল
    ValueNotifier<Map<String, String>?> replyingToNotifier =
        ValueNotifier<Map<String, String>?>(null);

    const Color premiumGold = Color(0xFFFFD700);
    const Color cyanOwner = Color(0xFF00FBFF);
    final Color glassBg = const Color(0xFF1E2A47).withOpacity(0.4);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors
          .transparent, // গ্লাস ইফেক্টের জন্য ব্যাকগ্রাউন্ড ট্রান্সপারেন্ট করা হলো
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 12,
                right: 12),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    // ইউ আই ২ বা ৩ ছবির সাথে মিল রেখে পার্পল-ব্লু গ্রেডিয়েন্ট ব্যাকগ্রাউন্ড
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1a0b36)
                            .withOpacity(0.92), // রিচ ডিপ পার্পল
                        const Color(0xFF0d1b3a).withOpacity(0.92), // ডিপ ব্লু
                        const Color(0xFF050b18)
                            .withOpacity(0.95), // ভায়োলেট ব্ল্যাক টোন
                      ],
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border.all(
                      color: cyanOwner.withOpacity(0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3b0764).withOpacity(0.4),
                        blurRadius: 25,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      // ড্র্যাগ হ্যান্ডেল
                      Container(
                          width: 36,
                          height: 3.5,
                          decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(10))),
                      const SizedBox(height: 10),
                      const Text("COMMENTS",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 1.5)),
                      const Divider(color: Colors.white10, height: 20),

                      // কমেন্ট লিস্ট সেকশন (সাইজ আরও ছোট এবং কম্প্যাক্ট করার জন্য হাইট ২৫০ করা হলো)
                      SizedBox(
                        height: 250,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('stories')
                              .doc(pId)
                              .collection('comments')
                              .orderBy('timestamp', descending: false)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: cyanOwner, strokeWidth: 2));
                            }
                            if (snapshot.data!.docs.isEmpty) {
                              return const Center(
                                  child: Text("No comments yet. Be the first!",
                                      style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 13)));
                            }
                            return ListView.builder(
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                var doc = snapshot.data!.docs[index];
                                Map<String, dynamic> cData =
                                    doc.data() as Map<String, dynamic>;

                                String commentId = doc.id;
                                String senderName = cData['userName'] ?? "User";
                                String commentText = cData['text'] ?? "";
                                String? replyToName = cData['replyToName'];
                                String? replyToText = cData['replyToText'];

                                return InkWell(
                                  onTap: () {
                                    // কমেন্টে ক্লিক করলেই রিপ্লাই মোড অন হবে
                                    replyingToNotifier.value = {
                                      'id': commentId,
                                      'name': senderName,
                                      'text': commentText,
                                    };
                                    setState(() {});
                                  },
                                  child: Container(
                                    // কমেন্ট কার্ডের সাইজ ও মার্জিন ছোট করা হলো
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.03),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.grey[900],
                                          backgroundImage: NetworkImage(cData[
                                                          'userImage'] !=
                                                      null &&
                                                  cData['userImage'] != ""
                                              ? cData['userImage']
                                              : "https://www.w3schools.com/howto/img_avatar.png"),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(senderName,
                                                  style: const TextStyle(
                                                      color: cyanOwner,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              const SizedBox(height: 2),

                                              // যদি এটি কোনো কমেন্টের রিপ্লাই হয় তবে তার প্রিভিউ দেখাবে
                                              if (replyToName != null &&
                                                  replyToText != null)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 4),
                                                  padding:
                                                      const EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                    color: cyanOwner
                                                        .withOpacity(0.08),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                    border: const Border(
                                                      left: BorderSide(
                                                          color: cyanOwner,
                                                          width: 2),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          "Replying to $replyToName",
                                                          style: const TextStyle(
                                                              color: cyanOwner,
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                      Text(replyToText,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: const TextStyle(
                                                              color: Colors
                                                                  .white60,
                                                              fontSize: 10)),
                                                    ],
                                                  ),
                                                ),

                                              Text(commentText,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.reply,
                                            color: Colors.white24, size: 14),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      // রিপ্লাই করার সময় ইনপুট বক্সের ওপরে ট্যাগ প্রিভিউ বার
                      ValueListenableBuilder<Map<String, String>?>(
                        valueListenable: replyingToNotifier,
                        builder: (context, replyingTo, child) {
                          if (replyingTo == null)
                            return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: glassBg,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: cyanOwner.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.reply,
                                    color: cyanOwner, size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Replying to ${replyingTo['name']}",
                                    style: const TextStyle(
                                        color: cyanOwner,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    replyingToNotifier.value = null;
                                    setState(() {});
                                  },
                                  child: const Icon(Icons.close,
                                      color: Colors.white54, size: 14),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // কমেন্ট ইনপুট ও সেন্ড বাটন সেকশন
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.06),
                                  hintText: replyingToNotifier.value != null
                                      ? "Write a reply..."
                                      : "Add a comment...",
                                  hintStyle: const TextStyle(
                                      color: Colors.white38, fontSize: 12),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(22),
                                      borderSide: BorderSide(
                                        color: premiumGold.withOpacity(0.2),
                                        width: 0.8,
                                      )),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(22),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 0.8,
                                      )),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(22),
                                      borderSide: const BorderSide(
                                        color: cyanOwner,
                                        width: 1,
                                      )),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [
                                  cyanOwner,
                                  cyanOwner.withOpacity(0.6)
                                ]),
                                boxShadow: [
                                  BoxShadow(
                                    color: cyanOwner.withOpacity(0.3),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.send_rounded,
                                    color: Colors.black, size: 18),
                                onPressed: () {
                                  if (_commentController.text.trim().isEmpty)
                                    return;

                                  Map<String, String>? currentReply =
                                      replyingToNotifier.value;
                                  _submitCommentWithReply(
                                    pId,
                                    _commentController.text.trim(),
                                    _commentController,
                                    postOwnerId,
                                    currentReply,
                                  );

                                  replyingToNotifier.value = null;
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

// কমেন্ট ও নোটিফিকেশন সাবমিট করার মূল মেথড (লেটেস্ট নাম, ছবি ও রিপ্লাই ডাটা সহ)
  void _submitCommentWithReply(
      String pId,
      String text,
      TextEditingController controller,
      String postOwnerId,
      Map<String, String>? replyInfo) async {
    if (text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // ইউজারের লেটেস্ট নাম ও ছবি নেওয়ার জন্য ফায়ারস্টোর থেকে কুয়েরি করা
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();

      String name = "User";
      String image = "";

      if (userQuery.docs.isNotEmpty) {
        var userData = userQuery.docs.first.data();
        name = userData['name'] ?? "User";
        image = userData['profilePic'] ?? userData['userImage'] ?? "";
      }

      // ১. কমেন্ট বা রিপ্লাই ডাটাবেজে সাবমিট করা
      await FirebaseFirestore.instance
          .collection('stories')
          .doc(pId)
          .collection('comments')
          .add({
        'uid': user.uid,
        'userName': name,
        'userImage': image,
        'text': text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'replyToId': replyInfo != null ? replyInfo['id'] : null,
        'replyToName': replyInfo != null ? replyInfo['name'] : null,
        'replyToText': replyInfo != null ? replyInfo['text'] : null,
      });

      // ২. নোটিফিকেশন ডাটাবেজে পাঠানো (পোস্ট মালিকের কাছে)
      if (postOwnerId.isNotEmpty && postOwnerId != user.uid) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'receiverId': postOwnerId,
          'senderId': user.uid,
          'senderName': name,
          'senderPic': image,
          'type': 'comment',
          'commentText': text.trim(),
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      controller.clear();
    } catch (e) {
      // কোনো এরর হ্যান্ডেল করার প্রয়োজন হলে এখানে করতে পারেন
    }
  }
}
