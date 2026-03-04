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
          
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.red, fontSize: 10)));
          }

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
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white10,
            child: Icon(Icons.person, color: Colors.white24, size: 30),
          ),
          const SizedBox(height: 6),
          const Text("Your Story", style: TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
