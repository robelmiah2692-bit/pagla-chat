import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomFloatingBox extends StatelessWidget {
  final String roomId;

  const RoomFloatingBox({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 180, // ইনবক্স বাটনের উপরে পজিশন করা হলো
      right: 15,
      child: GestureDetector(
        onTap: () {
          // বক্সের ওপর ক্লিক করলে গিফট রিওয়ার্ড এবং প্রোগ্রেস দেখানোর পপআপ/ট্যাব ওপেন হবে
          _showBoxRewardDialog(context, roomId);
        },
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rooms')
              .doc(roomId)
              .collection('room_box')
              .doc('current_box')
              .snapshots(),
          builder: (context, snapshot) {
            int currentDiamonds = 0;
            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              currentDiamonds = data['totalDiamonds'] ?? 0;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ভাসমান অ্যানিমেটেড লটি বক্স (অনলাইন লিংক সহ)
                SizedBox(
                  width: 65,
                  height: 65,
                  child: Lottie.network(
                    'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/officialall/gift_box.json', // এখানে আপনার গিটহাবের র (Raw) লিংক বা যেকোনো অনলাইন লিংক দিন
                    fit: BoxFit.contain,
                    // যদি ইন্টারনেট স্লো থাকে বা লিংক লোড হতে সমস্যা হয়, তার জন্য হ্যান্ডলিং:
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.card_giftcard,
                            color: Colors.amber, size: 30),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 2),
                // প্রোগ্রেস কাউন্টার ব্যাজ
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber, width: 1),
                  ),
                  child: Text(
                    "$currentDiamonds/25k",
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // গিফট রিওয়ার্ড এবং ডিটেইলস দেখানোর পপআপ ট্যাব
  void _showBoxRewardDialog(BuildContext context, String roomId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.5,
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
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Rules & Rewards:",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "• Total 25,000 Diamonds gifts will blast the box.\n"
              "• #1 Top Gifter gets: Avatar Frame (Backpack) + 5,000 Diamonds.\n"
              "• Other Gifters get: Free Gifts (valid for 2 days) + 1,000 Diamonds.\n"
              "• All active room users get: 10 Diamonds each!\n"
              "• Resets every 24 hours.",
              style:
                  TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
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
                int total = 0;
                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  total = data['totalDiamonds'] ?? 0;
                }
                // 🔥 এখানে ১৫ হাজারের জায়গায় ২৫,০০০ দিয়ে প্রোগ্রেস ক্যালকুলেট করা হলো
                double progress = (total / 25000).clamp(0.0, 1.0);

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
                      "Progress: $total / 25,000 Diamonds",
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
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
