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
        
        // ভিউয়ার লিস্ট বের করা
        var viewers = snapshot.data?.docs ?? [];
        int count = viewers.length; // এটিই আপনার বর্তমান ভিউয়ার সংখ্যা

        return Row(
          children: [
            // ১. এখানে ভিউয়ার কাউন্ট দেখাবে (যেমন: "12 Viewers")
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
                    "$count", // এখানে শুধু সংখ্যাটি দেখাবে
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            // ২. ভিউয়ারদের প্রোফাইল ছবিগুলো
            Expanded(
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: viewers.length,
                  itemBuilder: (context, index) {
                    var viewerData = viewers[index].data() as Map<String, dynamic>;
                    String viewerId = viewerData['uID'] ?? viewers[index].id; 
                    String profileImage = viewerData['profilePic'] ?? viewerData['userImage'] ?? '';

                    return Padding(
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
