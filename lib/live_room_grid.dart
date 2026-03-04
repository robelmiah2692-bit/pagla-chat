import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/voice_room.dart'; // আপনার ভয়েস রুমের পাথ

class LiveRoomGrid extends StatelessWidget {
  const LiveRoomGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // 🔥 শুধুমাত্র একটিভ রুমগুলো ফায়ারবেস থেকে আনবে
      stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("এখন কেউ লাইভে নেই", style: TextStyle(color: Colors.white54)),
          );
        }

        var rooms = snapshot.data!.docs;

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
            String roomId = rooms[index].id;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VoiceRoom(roomId: roomId)),
                );
              },
              child: _buildLiveCard(roomData),
            );
          },
        );
      },
    );
  }

  // আলাদা ডিজাইন ফাংশন (সবুজ LIVE ট্যাগসহ)
  Widget _buildLiveCard(Map<String, dynamic> data) {
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
          // 🟢 সবুজ LIVE ট্যাগ
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.greenAccent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, size: 6, color: Colors.white),
                  SizedBox(width: 4),
                  Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          // রুমের নাম
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              child: Text(
                data['roomName'] ?? "আড্ডা ঘর",
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
