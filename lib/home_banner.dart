import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key});

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  // 🇧🇩 [বাংলা মার্ক]: ব্যানারের লিংকগুলো এখন এই আলাদা ফাইলের ভেতরে থাকবে ভাই
  final List<String> _bannerList = [
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/premium_banner.png",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/74ed04fd0a4869652ab10f0386dd8997c1421ac5/benar%20(6).png",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/officialbenar.png",
  
  ];

  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    // 🇧🇩 [বাংলা মার্ক]: টাইমারটি মেইন পেজ থেকে এখানে চলে আসলো। এখন setState শুধু এই ব্যানার উইজেটকেই রি-বিল্ড করবে
    if (_bannerList.length > 1) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted) {
          setState(() {
            _currentBannerIndex = (_currentBannerIndex + 1) % _bannerList.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel(); // 🇧🇩 [বাংলা মার্ক]: মেমোরি লিক বন্ধ করতে টাইমার এখানে ডিসপোজ হলো
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1024 / 500, // 💡 ব্যানার নিখুঁত সাইজে রাখার রেশিও
      child: Stack(
        children: [
          // ক) মেইন ব্যানার ইমেজ (যা অন্য কাউকে ডিস্টার্ব না করে নিজে নিজে চেঞ্জ হবে)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  _bannerList[_currentBannerIndex],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white24));
                  },
                ),
              ),
            ),
          ),

          // খ) ব্যানারের ওপর ডানদিকের কোনায় লাইভ ইউজারদের ছবির স্ট্যাক ও কাউন্ট
          Positioned(
            bottom: 12,
            right: 12,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('isOnline', isEqualTo: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                  return const SizedBox();
                }

                final onlineDocs = userSnapshot.data!.docs;
                final int displayCount = onlineDocs.length > 4 ? 4 : onlineDocs.length;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: (displayCount * 18.0) + 12.0,
                        height: 28,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: List.generate(displayCount, (index) {
                            final uData = onlineDocs[index].data() as Map<String, dynamic>;
                            final userPic = uData['profilePic'] ?? uData['userImage'] ?? '';

                            return Positioned(
                              left: index * 16.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.pinkAccent, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(color: Colors.pinkAccent.withOpacity(0.4), blurRadius: 4),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black.withOpacity(0.34),
                                  child: userPic.isEmpty
                                      ? const Icon(Icons.person, size: 12, color: Colors.white)
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            userPic,
                                            width: 24,
                                            height: 24,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => const Icon(Icons.person, size: 12, color: Colors.white),
                                          ),
                                        ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${onlineDocs.length}+",
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Colors.cyan, blurRadius: 4)],
                            ),
                          ),
                          const Text(
                            "VIEWERS ONLINE",
                            style: TextStyle(color: Colors.white70, fontSize: 7, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}