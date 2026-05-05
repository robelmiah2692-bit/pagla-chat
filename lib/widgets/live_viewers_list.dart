import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pagla_chat/profile_page.dart'; 

class LiveViewersList extends StatelessWidget {
  final String roomId;
  const LiveViewersList({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('viewers')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
        
        var viewers = snapshot.data?.docs ?? [];
        int count = viewers.length;

        return Row(
          children: [
            if (count > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$count",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            Expanded(
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  // ১. এখানে একটি কি (Key) যোগ করা হয়েছে যাতে লিস্টের স্টেট বজায় থাকে
                  key: const PageStorageKey('live_viewers_list'),
                  scrollDirection: Axis.horizontal,
                  itemCount: viewers.length,
                  itemBuilder: (context, index) {
                    var viewerData = viewers[index].data() as Map<String, dynamic>;
                    String viewerId = viewerData['uID'] ?? viewers[index].id; 
                    String profileImage = viewerData['profilePic'] ?? viewerData['userImage'] ?? '';

                    return Padding(
                      // ২. এখানে ValueKey যোগ করা হয়েছে যাতে ইউজারের ছবিগুলো না নাচে
                      key: ValueKey(viewerId),
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(userId: viewerId),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 16,
                          backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                          backgroundColor: Colors.grey[800],
                          child: profileImage.isEmpty ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}