import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart'; // প্রোফাইল স্ক্রিন ইম্পোর্ট করুন

class LiveViewersList extends StatelessWidget {
  final String roomId;
  const LiveViewersList({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // যে ইউজাররা এই রুমে আড্ডা দিচ্ছে তাদের লিস্ট আনা
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('viewers')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var viewers = snapshot.data!.docs;

        return SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: viewers.length,
            itemBuilder: (context, index) {
              var viewerDoc = viewers[index];
              var viewerData = viewerDoc.data() as Map<String, dynamic>;
              String viewerId = viewerDoc.id; // ভিউয়ারের ইউআইডি

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: () {
                    // 🔥 ভিউয়ারের প্রোফাইলে যাওয়ার লজিক (শুধু দেখার জন্য)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          userId: viewerId, 
                          isReadOnly: true, // এডিট বাটন হাইড থাকবে
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(viewerData['userImage'] ?? ''),
                    backgroundColor: Colors.grey[800],
                    child: (viewerData['userImage'] == null || viewerData['userImage'] == '')
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
