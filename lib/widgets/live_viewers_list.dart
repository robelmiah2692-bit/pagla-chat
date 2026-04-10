import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pagla_chat/profile_page.dart'; 

class LiveViewersList extends StatelessWidget {
  final String roomId;
  const LiveViewersList({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // আপনার স্ক্রিনশট অনুযায়ী কালেকশন পাথ: rooms -> {roomId} -> viewers
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('viewers')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        var viewers = snapshot.data!.docs;

        return SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: viewers.length,
            // নতুন থেকে পুরাতন ভিউয়ার দেখানোর জন্য reverse: true ব্যবহার করতে পারেন
            itemBuilder: (context, index) {
              var viewerDoc = viewers[index];
              var viewerData = viewerDoc.data() as Map<String, dynamic>;
              
              // আপনার ফায়ারবেস স্ক্রিনশট অনুযায়ী ফিল্ডের নাম 'uID' এবং 'profilePic'
              String viewerId = viewerData['uID'] ?? viewerDoc.id; 
              String profileImage = viewerData['profilePic'] ?? '';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          userId: viewerId, 
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 16,
                    // ডাইনামিক ইমেজ লোডিং
                    backgroundImage: profileImage.isNotEmpty 
                        ? NetworkImage(profileImage) 
                        : null,
                    backgroundColor: Colors.grey[800],
                    child: profileImage.isEmpty
                        ? const Icon(Icons.person, size: 20, color: Colors.white)
                        : null,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
