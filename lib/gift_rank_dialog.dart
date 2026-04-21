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
            width: 320,
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 10, right: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.95),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.amberAccent.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "🏆 TOP WINNERS 🏆",
                  style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 25),
                
                // উইনার লিস্ট (টপ ১ ও ২)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end, // ছোট-বড় দেখানোর জন্য
                  children: [
                    // ২য় স্থান (যদি থাকে)
                    if (winners.length > 1) 
                      _buildWinnerAvatar(winners[1], "2nd", Colors.grey, 70), 
                    
                    // ১ম স্থান (যদি থাকে)
                    if (winners.isNotEmpty) 
                      _buildWinnerAvatar(winners[0], "1st", Colors.amber, 95), 
                  ],
                ),
                
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
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
              child: const Icon(Icons.stars, color: Colors.white, size: 45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerAvatar(Map<String, dynamic> user, String rank, Color frameColor, double size) {
    // এখানে আপনার ডাটাবেসের ফিল্ডের নাম অনুযায়ী ভ্যালু নেওয়া হচ্ছে
    String name = user['name'] ?? user['userName'] ?? 'User';
    String photo = user['profilePic'] ?? user['avatar'] ?? '';
    int giftCount = user['totalPrice'] ?? user['diamonds'] ?? 0;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // গোল্ডেন/সিলভার ফ্রেম (অ্যানিমেটেড লুকের জন্য)
            Container(
              width: size + 8,
              height: size + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(colors: [frameColor, Colors.white, frameColor, Colors.white10, frameColor]),
              ),
            ),
            // ইউজারের ছবি
            CircleAvatar(
              radius: size / 2,
              backgroundColor: Colors.grey[900],
              backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
              child: photo.isEmpty ? const Icon(Icons.person, color: Colors.white24) : null,
            ),
            // র‍্যাঙ্ক ব্যাজ
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: frameColor, 
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 5)]
                ),
                child: Text(rank, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 100,
          child: Text(
            name, 
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
          ),
        ),
        Text("💎 $giftCount", style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
