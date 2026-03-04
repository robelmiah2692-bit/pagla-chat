import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stories_service.dart';

class StorySection extends StatelessWidget {
  const StorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 10),
      // 🔥 StreamBuilder ব্যবহার করায় ডাটা আসার সাথে সাথে পেজ আপডেট হবে
      child: StreamBuilder<QuerySnapshot>(
        stream: StoriesService().getStories(), // ডাটাবেস থেকে স্টোরি আনছে
        builder: (context, snapshot) {
          // যদি লোড হতে দেরি হয়
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          // যদি কোনো স্টোরি না থাকে
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return ListView(
              scrollDirection: Axis.horizontal,
              children: [_buildAddStoryButton(context)],
            );
          }

          var stories = snapshot.data!.docs;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: stories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildAddStoryButton(context);
              
              var data = stories[index - 1].data() as Map<String, dynamic>;
              
              return _buildStoryCircle(
                data['userImage'] ?? "", 
                data['userName'] ?? "User",
              );
            },
          );
        },
      ),
    );
  }

  // স্টোরি সার্কেল ডিজাইন
  Widget _buildStoryCircle(String userImg, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.pinkAccent, width: 2), // স্টোরি থাকলে বর্ডার দেখাবে
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white10,
              backgroundImage: NetworkImage(userImg.isNotEmpty ? userImg : "https://www.w3schools.com/howto/img_avatar.png"),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 60,
            child: Text(
              name, 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 10, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }

  // নতুন স্টোরি যোগ করার বাটন
  Widget _buildAddStoryButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white12,
                child: Icon(Icons.person, color: Colors.white54, size: 30),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text("Your Story", style: TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}
