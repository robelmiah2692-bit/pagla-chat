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
        // সরাসরি ফায়ারবেস কালেকশন থেকে ডাটা নিচ্ছি
        stream: FirebaseFirestore.instance.collection('stories').snapshots(), 
        builder: (context, snapshot) {
          
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red, fontSize: 10)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          // ফায়ারবেস থেকে পাওয়া স্টোরি লিস্ট
          final docs = snapshot.data?.docs ?? [];

          // যদি ডাটাবেসে ডাটা থাকে কিন্তু এখানে না দেখায়, তবে এই টেক্সটটি আসবে
          if (docs.isEmpty) {
             return ListView(
               scrollDirection: Axis.horizontal,
               children: [
                 _buildAddStoryButton(context),
                 const Center(child: Text("নো ডাটা ইন ফায়ারবেস", style: TextStyle(color: Colors.white54, fontSize: 10))),
               ],
             );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: docs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildAddStoryButton(context);
              
              // ডাটাবেস থেকে তথ্য নেওয়া
              final data = docs[index - 1].data() as Map<String, dynamic>;
              
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
              backgroundColor: Colors.grey[900],
              backgroundImage: userImg.isNotEmpty 
                  ? NetworkImage(userImg) 
                  : const NetworkImage("https://www.w3schools.com/howto/img_avatar.png"),
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
