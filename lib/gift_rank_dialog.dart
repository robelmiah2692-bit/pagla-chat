import 'package:flutter/material.dart';

class GiftRankDialog extends StatelessWidget {
  final List<Map<String, dynamic>> winners; // টপ ২ ইউজারের ডাটা

  const GiftRankDialog({super.key, required this.winners});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // মেইন বডি (গ্লাস ডিজাইন)
          Container(
            width: 300,
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.95),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "🏆 TOP WINNERS 🏆",
                  style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 20),
                
                // উইনার লিস্ট (টপ ১ ও ২)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (winners.length > 1) _buildWinnerAvatar(winners[1], "2nd", Colors.grey, 70), // ২য় স্থান
                    if (winners.isNotEmpty) _buildWinnerAvatar(winners[0], "1st", Colors.amber, 90), // ১ম স্থান
                  ],
                ),
                
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("অভিনন্দন!", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          
          // ওপরের ডেকোরেশন আইকন
          Positioned(
            top: -40,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.amber,
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerAvatar(Map<String, dynamic> user, String rank, Color frameColor, double size) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // গোল্ডেন/সিলভার ফ্রেম
            Container(
              width: size + 10,
              height: size + 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [frameColor, Colors.white, frameColor]),
              ),
            ),
            // ইউজারের ছবি
            CircleAvatar(
              radius: size / 2,
              backgroundImage: NetworkImage(user['avatar']),
            ),
            // র‍্যাঙ্ক ব্যাজ
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: frameColor, borderRadius: BorderRadius.circular(10)),
                child: Text(rank, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(user['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text("💎 ${user['gifts']}", style: const TextStyle(color: Colors.amber, fontSize: 12)),
      ],
    );
  }
}
