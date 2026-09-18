import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomFloatingBox extends StatelessWidget {
  final String roomId;
  final String currentUserId; // ইউজারের নিজস্ব আইডি

  const RoomFloatingBox({super.key, required this.roomId, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 210,
      right: 15,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomId)
            .collection('room_box')
            .doc('current_box')
            .snapshots(),
        builder: (context, snapshot) {
          int totalDiamondsAllTime = 0;
          bool isBlasted = false;

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            totalDiamondsAllTime = data['totalDiamonds'] ?? 0;
            isBlasted = data['isBlasted'] ?? false;
          }

          // মডিউলাস লজিক: ১০০k পার হলে কাউন্টার আবার ০ থেকে শুরু হবে
          int currentDiamonds = totalDiamondsAllTime % 100000;
          if (totalDiamondsAllTime > 0 && currentDiamonds == 0) {
            currentDiamonds = 100000;
          }

          return GestureDetector(
            onTap: () => _showBoxRewardDialog(context, roomId, isBlasted),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Lottie.network(
                    'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/officialall/gift_box.json',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.card_giftcard, color: Colors.amber, size: 22),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber, width: 1),
                  ),
                  child: Text(
                    "$currentDiamonds/100k",
                    style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showBoxRewardDialog(BuildContext context, String roomId, bool isBlasted) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Room Treasure Box",
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Rules & Rewards:",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "• Total 100,000 Diamonds gifts will blast the box.\n"
              "• Top 1 Gifter: 3,000 Diamonds.\n"
              "• Top 2 Gifter: 1,500 Diamonds.\n"
              "• Top 3 Gifter: 500 Diamonds.\n"
              "• Other Room Users: 20 Diamonds each!\n"
              "• Resets and restarts automatically.",
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const Spacer(),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(roomId)
                  .collection('room_box')
                  .doc('current_box')
                  .snapshots(),
              builder: (context, snapshot) {
                int totalAllTime = 0;
                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  totalAllTime = data['totalDiamonds'] ?? 0;
                }
                int currentProgressVal = totalAllTime % 100000;
                double progress = (currentProgressVal / 100000).clamp(0.0, 1.0);

                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white10,
                      color: Colors.amber,
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Progress: $currentProgressVal / 100,000 Diamonds",
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}