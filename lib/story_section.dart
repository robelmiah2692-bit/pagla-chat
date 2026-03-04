import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stories_service.dart';

class StorySection extends StatelessWidget {
  const StorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: StreamBuilder<QuerySnapshot>(
        // 🔥 নিশ্চিত করুন StoriesService().getStories() এ কোনো .orderBy নেই
        stream: StoriesService().getStories(), 
        builder: (context, snapshot) {
          
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red, fontSize: 10)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pinkAccent));
          }

          // স্টোরি ডাটা লিস্ট নেওয়া
          final stories = snapshot.data?.docs ?? [];

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            // ১টি বাটন সব সময় থাকবে + যতগুলো স্টোরি আছে
            itemCount: stories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildAddStoryButton(context);
              
              // ডাটাবেস থেকে পাওয়া ডকুমেন্ট
              final doc = stories[index - 1];
              final data = doc.data() as Map<String, dynamic>;
              
              // ডাটাবেসের ফিল্ডের নামগুলো চেক করে ডাটা নেওয়া
              final String name = data['userName'] ?? "User";
              final String userImg = data['userImage'] ?? "";
              
              return _buildStoryCircle(userImg, name);
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
              backgroundColor: Colors.black,
              backgroundImage: NetworkImage(
                userImg.isNotEmpty ? userImg : "https://www.w3schools.com/howto/img_avatar.png"
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 65,
            child: Text(
              name, 
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddStoryButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
