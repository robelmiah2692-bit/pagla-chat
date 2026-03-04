import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stories_service.dart';
import 'story_view_page.dart';

class StorySection extends StatelessWidget {
  const StorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190, // উচ্চতা বাড়িয়ে বড় কার্ড করা হয়েছে
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
              if (index == 0) return _buildAddStoryCard(context);
              
              final data = docs[index - 1].data() as Map<String, dynamic>;
              return _buildFacebookStoryCard(context, data);
            },
          );
        },
      ),
    );
  }

  // 🔥 ১. ফেসবুকের মতো লম্বা স্টোরি কার্ড
  Widget _buildFacebookStoryCard(BuildContext context, Map<String, dynamic> data) {
    final String userImg = data['userImage'] ?? "";
    final String name = data['userName'] ?? "User";
    final String storyImg = data['storyImage'] ?? "";
    final String caption = data['caption'] ?? "";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryViewPage(
              image: storyImg,
              name: name,
              caption: caption,
            ),
          ),
        );
      },
      child: Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          // স্টোরির মেইন ছবিটা কার্ডের ব্যাকগ্রাউন্ডে থাকবে
          image: DecorationImage(
            image: NetworkImage(storyImg.isNotEmpty ? storyImg : "https://via.placeholder.com/150"),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // নিচের নাম ফুটে ওঠার জন্য হালকা কালো শেড
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
            ),
            // ২. কার্ডের ওপরের কোণায় ছোট গোল প্রোফাইল পিকচার (আপনার প্রোফাইল ফটো)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent, width: 2),
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: (userImg.isNotEmpty && userImg.startsWith('http'))
                      ? NetworkImage(userImg)
                      : const NetworkImage("https://www.w3schools.com/howto/img_avatar.png"),
                ),
              ),
            ),
            // ৩. কার্ডের একদম নিচে ইউজারের নাম
            Positioned(
              bottom: 10,
              left: 8,
              right: 8,
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 11, 
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ৪. স্টোরি যোগ করার জন্য ফেসবুক স্টাইল বাটন কার্ড
  Widget _buildAddStoryCard(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 25),
          ),
          const SizedBox(height: 10),
          const Text(
            "Add Story", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
