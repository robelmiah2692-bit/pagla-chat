import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'story_view_page.dart';

class StorySection extends StatelessWidget {
  const StorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190, 
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: StreamBuilder<QuerySnapshot>(
        // ✅ লেটেস্ট স্টোরি সবার আগে দেখাবে
        stream: FirebaseFirestore.instance
            .collection('stories')
            .orderBy('timestamp', descending: true)
            .snapshots(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pinkAccent));
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
    final String caption = data['caption'] ?? ""; // আপনার সার্ভিস ফাইল অনুযায়ী 'caption'

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
          color: const Color(0xFF242526), // ছবি না থাকলে এই ডার্ক কালার দেখাবে
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10, width: 0.5),
          image: storyImg.isNotEmpty 
              ? DecorationImage(
                  image: NetworkImage(storyImg),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            // নিচের নাম ফুটে ওঠার জন্য গ্রেডিয়েন্ট
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

            // ✅ যদি ছবি না থাকে, তবে কার্ডের মাঝখানে টেক্সট দেখাবে
            if (storyImg.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    caption,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
              ),

            // ২. গোল প্রোফাইল পিকচার
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
                  radius: 15,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: (userImg.isNotEmpty && userImg.startsWith('http'))
                      ? NetworkImage(userImg)
                      : const NetworkImage("https://via.placeholder.com/150"),
                ),
              ),
            ),

            // ৩. ইউজারের নাম
            Positioned(
              bottom: 10,
              left: 8,
              right: 8,
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 10, 
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 3, color: Colors.black)],
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

  // ৪. স্টোরি যোগ করার বাটন কার্ড
  Widget _buildAddStoryCard(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2F),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.pinkAccent, 
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
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
