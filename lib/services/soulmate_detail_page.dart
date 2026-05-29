import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'soulmate_service.dart';

class SoulmateDetailPage extends StatelessWidget {
  final Map<String, dynamic> soulmateData;

  const SoulmateDetailPage({Key? key, required this.soulmateData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🎯 নতুন লেভেল লজিক: লেভেল ১ = ৮০০০, এরপর প্রতি লেভেলে ২০০০ করে বাড়বে
    int totalGift = soulmateData['totalGift'] ?? 0;
    int level = 1;
    int currentLevelBase = 8000;
    int remainingXp = totalGift;

    while (remainingXp >= currentLevelBase && level < 50) {
      remainingXp -= currentLevelBase;
      level++;
      currentLevelBase += 2000;
    }

    if (level >= 50) {
      level = 50;
      currentLevelBase = 8000 + (49 * 2000);
      remainingXp = currentLevelBase;
    }

    double progressPercent = (remainingXp / currentLevelBase).clamp(0.0, 1.0);

    String friendshipDate = "Unknown";
    if (soulmateData['createdAt'] != null) {
      Timestamp timestamp = soulmateData['createdAt'];
      friendshipDate = DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
    }

    String partnerId = soulmateData['partnerId'] ?? '';
    String partnerName = soulmateData['partnerName'] ?? 'Unknown';
    String partnerImage = soulmateData['partnerImage'] ?? '';
    String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    // 🎯 লজিক: বর্তমান ইউজার কি এই রিলেশনের পার্টনার?
    // আমরা soulmateData থেকে 'uid' (যে সোলমেট রিকোয়েস্ট পাঠিয়েছিল) এবং 'partnerId' চেক করছি
    String ownerId = soulmateData['uid'] ?? '';
    bool isPartner = (myUid == ownerId || myUid == partnerId);

    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        title: const Text("Soulmate Details", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E2F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text("✨ Soulmate Lv.$level ✨",
                style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance.collection('users').where('uid', isEqualTo: myUid).limit(1).get(),
                    builder: (context, userSnapshot) {
                      String myName = "Loading...";
                      String myImage = "";
                      if (userSnapshot.hasData && userSnapshot.data!.docs.isNotEmpty) {
                        var userData = userSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                        myName = userData['name'] ?? 'No Name';
                        myImage = userData['profilePic'] ?? userData['image'] ?? '';
                      }
                      return Column(
                        children: [
                          CircleAvatar(radius: 40, backgroundColor: Colors.grey[900], child: ClipOval(child: myImage.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 40) : Image.network(myImage, width: 80, height: 80, fit: BoxFit.cover))),
                          const SizedBox(height: 10),
                          Text(myName, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      );
                    },
                  ),
                ),
                const Icon(Icons.favorite, color: Colors.pinkAccent, size: 40),
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(radius: 40, backgroundColor: Colors.grey[900], child: ClipOval(child: partnerImage.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 40) : Image.network(partnerImage, width: 80, height: 80, fit: BoxFit.cover))),
                      const SizedBox(height: 10),
                      Text(partnerName, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: const Color(0xFF1E1E2F), borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("Level Progress (Lv.$level)", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    Text("$remainingXp / $currentLevelBase XP", style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 15),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progressPercent,
                          minHeight: 12,
                          backgroundColor: Colors.grey[800],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                        ),
                      ),
                      Positioned(
                        right: -5,
                        top: -5,
                        child: Icon(Icons.favorite, color: Colors.redAccent, size: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: const Color(0xFF1E1E2F), borderRadius: BorderRadius.circular(15)),
              child: Row(children: [
                const Icon(Icons.calendar_month, color: Colors.pinkAccent, size: 24),
                const SizedBox(width: 15),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Start Hart:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(friendshipDate, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                ]),
              ]),
            ),
            
            // 🎯 শুধুমাত্র পার্টনার হলে ব্রেকআপ বাটন দেখাবে
            if (isPartner) ...[
              const SizedBox(height: 50),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                icon: const Icon(Icons.heart_broken, color: Colors.white),
                label: const Text("End Hart (1500 💎)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => _showBreakupDetailPageDialog(context, partnerId),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBreakupDetailPageDialog(BuildContext context, String partnerId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Sure end relationship ?", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text("End relationship need 1500 daimond", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              String response = await SoulmateService().breakRelation(partnerId);
              Navigator.pop(context); 
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response), backgroundColor: Colors.pinkAccent));
            },
            child: const Text("Yes", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}