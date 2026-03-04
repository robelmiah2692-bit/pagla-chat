import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stories_service.dart';

class StorySection extends StatelessWidget {
  const StorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: StreamBuilder<QuerySnapshot>(
        stream: StoriesService().getStories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();

          var stories = snapshot.data!.docs;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length + 1, // +1 আপনার নিজের স্টোরি দেওয়ার বাটনের জন্য
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddStoryButton(); // স্টোরি যোগ করার বাটন
              }
              var data = stories[index - 1].data() as Map<String, dynamic>;
              return _buildStoryCircle(data['userImage'], data['userName']);
            },
          );
        },
      ),
    );
  }

  Widget _buildStoryCircle(String? image, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.pinkAccent),
            child: CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(image ?? "https://picsum.photos/200"),
            ),
          ),
          const SizedBox(height: 5),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildAddStoryButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white12,
            child: Icon(Icons.add, color: Colors.pinkAccent),
          ),
          const SizedBox(height: 5),
          const Text("Your Story", style: TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}
