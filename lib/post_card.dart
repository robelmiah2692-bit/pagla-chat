import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const PostCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final String userName = data['userName'] ?? "User";
    final String userImg = data['userImage'] ?? "";
    final String postImg = data['storyImage'] ?? ""; // আপনার ডাটাবেসের ফিল্ড অনুযায়ী
    final String caption = data['caption'] ?? "";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      color: Colors.black, // আপনার অ্যাপের থিমের সাথে মিল রেখে
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ১. ইউজারের প্রোফাইল অংশ (নাম ও ছবি)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: (userImg.isNotEmpty) 
                      ? NetworkImage(userImg) 
                      : const NetworkImage("https://cdn-icons-png.flaticon.com/512/149/149071.png"),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const Text("Just now", style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.more_horiz, color: Colors.white),
              ],
            ),
          ),

          // ২. পোস্টের ক্যাপশন (লেখা)
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(caption, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),

          // ৩. পোস্টের মেইন ছবি (বড় করে)
          if (postImg.isNotEmpty)
            Image.network(
              postImg,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

          // ৪. লাইক, কমেন্ট ও শেয়ার বাটন
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _postButton(Icons.favorite_border, "Like"),
                _postButton(Icons.comment_outlined, "Comment"),
                _postButton(Icons.share_outlined, "Share"),
              ],
            ),
          ),
          const Divider(color: Colors.white10, thickness: 5), // ফেসবুকের মতো ডিভাইডার
        ],
      ),
    );
  }

  // বাটনগুলোর জন্য ছোট হেল্পার উইজেট
  Widget _postButton(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}
