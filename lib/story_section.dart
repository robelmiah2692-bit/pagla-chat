import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stories_service.dart';
import 'story_view_page.dart';

class StorySection extends StatelessWidget {
  const StorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stories').snapshots(), 
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          final docs = snapshot.data?.docs ?? [];

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: docs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildAddStoryButton(context);
              
              final data = docs[index - 1].data() as Map<String, dynamic>;
              
              // ডাটাবেস থেকে ইমেজ এবং নাম নেওয়া
              final String userImg = data['userImage'] ?? "";
              final String userName = data['userName'] ?? "User";
              
              return _buildStoryCircle(userImg, userName);
            },
          );
        },
      ),
    );
  }

  Widget _buildStoryCircle(String userImg, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Colors.purple, Colors.pinkAccent, Colors.orange]),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[800],
              // 🔥 এখানে চেক করা হচ্ছে ছবি আছে কি না
              backgroundImage: (userImg.isNotEmpty && userImg.startsWith('http'))
                  ? NetworkImage(userImg)
                  : const NetworkImage("https://www.w3schools.com/howto/img_avatar.png"), // ছবি না থাকলে এই লিঙ্কের ছবি দেখাবে
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 65,
            child: Text(
              name, 
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(color: Colors.white, fontSize: 11, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddStoryButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Container(
            height: 60, width: 60,
            decoration: BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24)
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 6),
          const Text("Your Story", style: TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
