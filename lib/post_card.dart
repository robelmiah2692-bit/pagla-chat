import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const PostCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // 🔥 এখানে ডাটাবেসের সঠিক নামগুলো ব্যবহার করা হয়েছে
    // আপনার StoriesService এ আমরা 'userName' এবং 'userImage' নামেই ডাটা পাঠাচ্ছি
    final String userName = data['userName']?.toString() ?? "User";
    final String userProfileImg = data['userImage']?.toString() ?? ""; 
    final String postMainImg = data['storyImage']?.toString() ?? "";
    final String caption = data['caption']?.toString() ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      color: Colors.black, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ১. ইউজারের রিয়েল প্রোফাইল ও নাম (ফেসবুক স্টাইল)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[800],
                  // 🔥 এখানে ডাটাবেস থেকে আসা আপনার প্রোফাইল পিকচার লোড হবে
                  backgroundImage: (userProfileImg.isNotEmpty && userProfileImg.startsWith('http')) 
                      ? NetworkImage(userProfileImg) 
                      : const NetworkImage("https://www.w3schools.com/howto/img_avatar.png"),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName, // 🔥 ডাটাবেস থেকে আসা আপনার আসল নাম
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)
                    ),
                    const Text("Just now", style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.more_horiz, color: Colors.white70),
              ],
            ),
          ),

          // ২. ক্যাপশন
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text(caption, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),

          // ৩. বড় পোস্ট ইমেজ (পুরো স্ক্রিন জুড়ে)
          if (postMainImg.isNotEmpty)
            Image.network(
              postMainImg, // 🔥 ফায়ারবেস থেকে আসা বড় ছবি
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.grey[900],
                child: const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
              ),
            ),

          // ৪. লাইক, কমেন্ট ও শেয়ার সেকশন
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(Icons.favorite_border, "Like", Colors.white70),
                _buildActionButton(Icons.mode_comment_outlined, "Comment", Colors.white70),
                _buildActionButton(Icons.share_outlined, "Share", Colors.white70),
              ],
            ),
          ),
          const Divider(color: Colors.white10, thickness: 6), 
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}
