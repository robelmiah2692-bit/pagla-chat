import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const PostCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // 🔥 ফায়ারবেসের ফিল্ডের নামগুলো এখানে খুব সাবধানে চেক করুন
    // আপনার স্ক্রিনশট অনুযায়ী 'userName', 'userImage', 'storyImage' এগুলোই কি আছে?
    final String userName = data['userName']?.toString() ?? "User";
    final String userProfileImg = data['userImage']?.toString() ?? ""; 
    final String postMainImg = data['storyImage']?.toString() ?? "";
    final String caption = data['caption']?.toString() ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      color: Colors.black, // আপনার ব্যাকগ্রাউন্ড ডার্ক থিম
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ১. ফেসবুকের মতো হেডার (প্রোফাইল ফটো ও নাম)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[800],
                  // প্রোফাইল পিকচার এখানে দেখাবে
                  backgroundImage: (userProfileImg.isNotEmpty) 
                      ? NetworkImage(userProfileImg) 
                      : const NetworkImage("https://www.w3schools.com/howto/img_avatar.png"),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName, 
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

          // ২. ক্যাপশন (যদি থাকে)
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text(caption, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),

          // ৩. বড় পোস্ট ইমেজ (পুরো স্ক্রিন জুড়ে)
          if (postMainImg.isNotEmpty)
            Image.network(
              postMainImg,
              width: double.infinity,
              fit: BoxFit.cover,
              // যদি ছবি লোড না হয় তবে এরর হ্যান্ডেল করবে
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: 100, 
                child: Center(child: Icon(Icons.broken_image, color: Colors.white24))
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
          const Divider(color: Colors.white10, thickness: 6), // ফেসবুক ডিভাইডার স্টাইল
        ],
      ),
    );
  }

  // বাটন তৈরির সহজ উইজেট
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
