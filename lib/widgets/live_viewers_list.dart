import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pagla_chat/profile_page.dart'; // পাথ সঠিক আছে কি না দেখে নিন

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
              String viewerId = viewerDoc.id; 

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: () {
                    // 🔥 ProfileScreen এর বদলে ProfilePage ব্যবহার করা হয়েছে
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          userId: viewerId, 
                          isReadOnly: true, 
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
