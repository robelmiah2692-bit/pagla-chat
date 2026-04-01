import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pagla_chat/screens/voice_room.dart';

class FollowingRoomGrid extends StatelessWidget {
  const FollowingRoomGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;

    if (myUid == null) return const Center(child: Text("লগইন করুন", style: TextStyle(color: Colors.white)));

    // 🔥 সংশোধন: সরাসরি 'rooms' কালেকশনে কোয়েরি করছি যেখানে 'followers' লিস্টে myUid আছে
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('followers', arrayContains: myUid) // চেক করছে ইউজার এই রুমের ফলোয়ার কি না
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("আপনি এখনো কোনো রুম ফলো করেননি", 
            style: TextStyle(color: Colors.white54, fontSize: 14)),
          );
        }

        var rooms = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0, // কার্ডের সাইজ ঠিক করার জন্য
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
                    ),
                  ),
                );
              },
              child: _buildFollowingCard(roomData),
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
          // রুমের ছবি না থাকলে একটি ডিফল্ট ছবি দেখাবে
          image: (data['roomImage'] != null && data['roomImage'].toString().isNotEmpty)
              ? NetworkImage(data['roomImage'])
              : const NetworkImage("https://picsum.photos/200"),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // উপরে ছোট্ট ফলোয়িং ট্যাগ
          Positioned(
            top: 8, left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54, 
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.greenAccent, width: 0.5)
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.greenAccent, size: 10),
                  SizedBox(width: 4),
                  Text("FOLLOWING", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          // নিচে রুমের নাম
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
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15))
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
