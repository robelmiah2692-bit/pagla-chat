import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pagla_chat/screens/voice_room.dart'; // এখানে আপনার প্যাকেজের নামসহ পাথটি সঠিক করে দিলাম

class LiveRoomGrid extends StatelessWidget {
  const LiveRoomGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
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
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.greenAccent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row( // এখানে const সরিয়ে দেওয়া হয়েছে কারণ এটি ডায়নামিক হতে পারে
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 6, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    "LIVE", 
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5), // opacity সরাসরি দেওয়া নিরাপদ
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
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
