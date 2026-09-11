import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'soulmate_service.dart';

class SoulmateDetailPage extends StatelessWidget {
  final Map<String, dynamic> soulmateData;
  final String uIDValue; // এই লাইনটি যোগ করুন

  const SoulmateDetailPage(
      {Key? key, required this.soulmateData, required this.uIDValue})
      : super(key: key); // এখানেও পাস করুন

  @override
  Widget build(BuildContext context) {
    final data = soulmateData ?? {};

    var rawGift = data['soulmateTotalGift'];
    int totalGift = 0;
    if (rawGift != null) {
      totalGift = int.tryParse(rawGift.toString()) ?? 0;
    }

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
      friendshipDate =
          DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
    }
// আপনার বর্তমান কোডটি এভাবে গুছিয়ে নিন:
    String partnerId = (soulmateData['partnerId'] ?? '').toString().trim();
    String partnerName = soulmateData['partnerName'] ?? 'Unknown';
    String partnerImage = soulmateData['partnerImage'] ?? '';
// ডাটাবেস থেকে পাওয়া আইডিগুলো স্ট্রিং হিসেবে নিন
    String myId = uIDValue.toString().trim();
    String dbOwnerId = (soulmateData['ownerId'] ?? '').toString().trim();
    String dbPartnerId = (soulmateData['partnerId'] ?? '').toString().trim();

// এখানে চেক করুন বর্তমান ইউজার কি owner নাকি partner
    bool isPartner = (myId == dbOwnerId || myId == dbPartnerId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      // 🔥 পুরো স্ক্রিনজুড়ে গ্রেডিয়েন্ট রাখার জন্য Stack ব্যবহার করা হয়েছে
      body: Stack(
        children: [
          // ১. ফুল স্ক্রিন গ্রেডিয়েন্ট ব্যাকগ্রাউন্ড
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF8B005D), // বাঁ দিকের ম্যাজেন্টা/পিংক শেড
                  Color(0xFF2C105C), // মাঝখানের পার্পল শেড
                  Color(0xFF0A0F24), // ডান দিকের ডিপ ব্লু শেড
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ২. মেইন কন্টেন্ট এবং অ্যাপবার
          Column(
            children: [
              AppBar(
                title: const Text("Soulmate Details",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // 🔥 লেভেলের কালার ছবির নিয়ন থিমের সাথে মিলিয়ে দেওয়া হলো
                      Text("✨ Soulmate Lv.$level ✨",
                          style: const TextStyle(
                              color: Color(0xFFFF75B4), // উজ্জ্বল নিয়ন পিংক
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(myId)
                                  .get(),
                              builder: (context, snapshot) {
                                String myName = "Loading...";
                                String myImage = "";
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  var userData = snapshot.data!.data()
                                      as Map<String, dynamic>;
                                  myName = userData['name'] ?? 'No Name';
                                  myImage = userData['profilePic'] ??
                                      userData['image'] ??
                                      '';
                                }
                                return Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFFF007F),
                                            Color(0xFF00FFFF)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                          radius: 40,
                                          backgroundColor: Colors.grey[900],
                                          child: ClipOval(
                                              child: myImage.isEmpty
                                                  ? const Icon(Icons.person,
                                                      color: Colors.white,
                                                      size: 40)
                                                  : Image.network(myImage,
                                                      width: 80,
                                                      height: 80,
                                                      fit: BoxFit.cover))),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(myName,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                  ],
                                );
                              },
                            ),
                          ),
                          const Icon(Icons.favorite,
                              color: Color(0xFFFF4081), size: 40),
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFFF007F),
                                        Color(0xFF00FFFF)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                      radius: 40,
                                      backgroundColor: Colors.grey[900],
                                      child: ClipOval(
                                          child: partnerImage.isEmpty
                                              ? const Icon(Icons.person,
                                                  color: Colors.white, size: 40)
                                              : Image.network(partnerImage,
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover))),
                                ),
                                const SizedBox(height: 10),
                                Text(partnerName,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1))),
                        child: Column(
                          children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Level Progress",
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 13)),
                                  Text("$remainingXp / $currentLevelBase XP",
                                      style: const TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
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
                                    backgroundColor: Colors.white10,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Color(0xFFFF007F)),
                                  ),
                                ),
                                const Positioned(
                                  right: -5,
                                  top: -5,
                                  child: Icon(Icons.favorite,
                                      color: Color(0xFFFF75B4), size: 22),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1))),
                        child: Row(children: [
                          const Icon(Icons.calendar_month,
                              color: Color(0xFF00FFFF), size: 24),
                          const SizedBox(width: 15),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Start Hart:",
                                    style: TextStyle(
                                        color: Colors.white60, fontSize: 12)),
                                Text(friendshipDate,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                              ]),
                        ]),
                      ),

                      // 🎯 শুধুমাত্র পার্টনার হলে ব্রেকআপ বাটন দেখাবে
                      if (isPartner) ...[
                        const SizedBox(height: 50),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15))),
                          icon: const Icon(Icons.heart_broken,
                              color: Colors.white),
                          label: const Text("End Hart (50000 💎)",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          onPressed: () =>
                              _showBreakupDetailPageDialog(context, partnerId),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBreakupDetailPageDialog(BuildContext context, String partnerId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1035),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Sure end relationship ?",
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text("End relationship need 50000 daimond",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              String response =
                  await SoulmateService().breakRelation(partnerId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(response), backgroundColor: Colors.pinkAccent));
            },
            child: const Text("Yes", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
