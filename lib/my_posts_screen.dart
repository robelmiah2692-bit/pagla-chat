import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pagla_chat/video_player_screen.dart';


class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF190033),
      appBar: AppBar(
        title: const Text("My Posts", style: TextStyle(color: Colors.cyanAccent)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00B4DB),
              Color(0xFF0083B0),
              Color(0xFF4A00E0),
              Color(0xFF190033),
            ],
          ),
        ),
        child: Stack(
          children: [
            ...List.generate(
              15,
              (index) => Positioned(
                top: (index * 50.0) % 500,
                left: (index * 80.0) % 380,
                child: Icon(
                  Icons.star,
                  size: index % 3 == 0 ? 12 : 6,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('stories')
                  .where('authUID', isEqualTo: currentUid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.redAccent)));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No posts found",
                          style: TextStyle(color: Colors.white70, fontSize: 16)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    
                    String imageUrl = data['storyImage'] ?? "";
                    String videoUrl = data['videoUrl'] ?? "";
                    String caption = data['caption'] ?? "";

                    bool hasImage = imageUrl.isNotEmpty;
                    bool hasVideo = videoUrl.isNotEmpty;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // যদি ইমেজ থাকে
                          if (hasImage)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(15)),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 200,
                                  color: Colors.white12,
                                  child: const Center(
                                      child: CircularProgressIndicator(color: Colors.cyanAccent)),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 200,
                                  color: Colors.white12,
                                  child: const Icon(Icons.broken_image,
                                      size: 50, color: Colors.white54),
                                ),
                              ),
                            ),

                          // যদি শুধু ভিডিও থাকে, তবে GestureDetector দিয়ে ভিডিও প্লেয়ার স্ক্রিনে যাওয়ার ব্যবস্থা করা হলো
                          if (hasVideo && !hasImage)
                            GestureDetector(
                              onTap: () {
                                if (videoUrl.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VideoPlayerScreen(videoUrl: videoUrl),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(15)),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.play_circle_fill,
                                    size: 64,
                                    color: Colors.cyanAccent,
                                  ),
                                ),
                              ),
                            ),

                          // যদি ইমেজ ও ভিডিও দুটোই থাকে, আলাদাভাবে ভিডিও চালানোর বাটন বা প্রিভিউ রাখতে পারেন
                          if (hasVideo && hasImage)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                                  foregroundColor: Colors.cyanAccent,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VideoPlayerScreen(videoUrl: videoUrl),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.play_arrow),
                                label: const Text("Play Video"),
                              ),
                            ),

                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (caption.isNotEmpty)
                                  Text(caption,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14)),
                                if (caption.isNotEmpty)
                                  const Divider(color: Colors.white24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _showComments(context, doc.id),
                                      icon: const Icon(Icons.comment,
                                          color: Colors.cyanAccent),
                                      label: const Text("Comments",
                                          style: TextStyle(color: Colors.cyanAccent)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => doc.reference.delete(),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

 
  void _showComments(BuildContext context, String storyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // গ্রেডিয়েন্ট দেখানোর জন্য
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF00B4DB),
                Color(0xFF0083B0),
                Color(0xFF4A00E0),
                Color(0xFF190033),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Comments",
                    style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('stories')
                      .doc(storyId)
                      .collection('comments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text("No comments yet",
                              style: TextStyle(color: Colors.white70)));
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var comment = snapshot.data!.docs[index];
                        var data = comment.data() as Map<String, dynamic>;

                        String userName = data['userName'] ?? "User";
                        String commentText = data['text'] ?? "";
                        String userImage = data['userImage'] ?? "";

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white24,
                            backgroundImage: userImage.isNotEmpty
                                ? NetworkImage(userImage)
                                : const NetworkImage(
                                    "https://www.w3schools.com/howto/img_avatar.png"),
                          ),
                          title: Text(userName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(commentText,
                              style: const TextStyle(color: Colors.white70)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}