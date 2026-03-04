import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/voice_room.dart';

class FollowingRoomGrid extends StatelessWidget {
  const FollowingRoomGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;

    if (myUid == null) return const Center(child: Text("লগইন করুন"));

    return StreamBuilder<DocumentSnapshot>(
      // ইউজারের ফলোয়িং লিস্ট ফায়ারবেস থেকে আনা
      stream: FirebaseFirestore.instance.collection('users').doc(myUid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

        // ফলো করা রুমের আইডিগুলোর লিস্ট (ধরে নিলাম field এর নাম 'followingRooms')
        List<dynamic> followingIds = (userSnapshot.data!.data() as Map<String, dynamic>?)?['followingRooms'] ?? [];

        if (followingIds.isEmpty) {
          return const Center(child: Text("আপনি কাউকে ফলো করেননি", style: TextStyle(color: Colors.white54)));
        }

        return StreamBuilder<QuerySnapshot>(
          // শুধুমাত্র সেই রুমগুলো আনা যাদের আইডি ফলোয়িং লিস্টে আছে
          stream: FirebaseFirestore.instance
              .collection('rooms')
              .where(FieldPath.documentId, whereIn: followingIds)
              .snapshots(),
          builder: (context, roomSnapshot) {
            if (!roomSnapshot.hasData) return const Center(child: CircularProgressIndicator());

            var rooms = roomSnapshot.data!.docs;

            return GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                var roomData = rooms[index].data() as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => VoiceRoom(roomId: rooms[index].id)),
                    );
                  },
                  child: _buildFollowingCard(roomData),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFollowingCard(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(
          image: NetworkImage(data['roomImage'] ?? "https://picsum.photos/200"),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8, left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: Colors.greenAccent, borderRadius: BorderRadius.circular(4)),
              child: const Text("FOLLOWING", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.vertical(bottom: Radius.circular(15))),
              child: Text(data['roomName'] ?? "আড্ডা ঘর", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
