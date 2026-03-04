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
        stream: StoriesService().getStories(), 
        builder: (context, snapshot) {
          
          // ১. যদি কোনো এরর হয় (যেমন ইন্ডেক্স বা পারমিশন), তবে স্ক্রিনে দেখাবে
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}", 
              style: const TextStyle(color: Colors.red, fontSize: 12))
            );
          }

          // ২. ডাটা লোড হওয়ার সময় ছোট একটা লোডিং দেখাবে
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          // ৩. ডাটা আসুক বা না আসুক, লিস্টটা সব সময় তৈরি হবে
          final stories = snapshot.data?.docs ?? [];

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: stories.length + 1, // বাটন + স্টোরি সংখ্যা
            itemBuilder: (context, index) {
              if (index == 0) return _buildAddStoryButton(context);
              
              // ৪. ডাটা ম্যাপ করার সময় সতর্কতা
              final doc = stories[index - 1];
              final data = doc.data() as Map<String, dynamic>;
              
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
            height: 60,
            width: 60,
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
