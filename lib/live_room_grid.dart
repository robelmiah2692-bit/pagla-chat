import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pagla_chat/screens/voice_room.dart';

class LiveRoomGrid extends StatelessWidget {
  const LiveRoomGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
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
                  MaterialPageRoute(
                    builder: (context) => VoiceRoom(
                      roomId: roomId,
                      // অপশনাল: রুমের নাম আগে থেকে পাঠিয়ে দিতে পারেন
                      // roomName: roomData['roomName'] ?? "আড্ডা ঘর",
                    )
                  ),
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
      clipBehavior: Clip.antiAlias, // ইমেজ রেডিয়াস ঠিক রাখার জন্য
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white10,
      ),
      child: Stack(
        children: [
          // রুমের কভার ফটো
          Positioned.fill(
            child: Image.network(
              data['roomImage'] ?? "https://picsum.photos/200",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => 
                  const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
            ),
          ),
          
          // LIVE ইন্ডিকেটর
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent, // লাইভ সাধারণত লাল হয়
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sensors, size: 10, color: Colors.white),
                  SizedBox(width: 4),
                  Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // ভিউয়ার কাউন্ট (যদি আপনার ডাটাতে থাকে)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.remove_red_eye, size: 10, color: Colors.white),
                  const SizedBox(width: 4),
                  Text("${data['viewerCount'] ?? 0}", style: const TextStyle(color: Colors.white, fontSize: 10)),
                ],
              ),
            ),
          ),

          // রুমের নাম (নিচে শ্যাডোসহ)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
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
