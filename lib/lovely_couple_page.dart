import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';

import 'package:pagla_chat/profile_page.dart';

class LovelyCouplePage extends StatelessWidget {
  const LovelyCouplePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // প্রতি মাসের শুরুতে XP রিসেট চেক করা
    _checkAndResetMonthlyXp();

    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        // XP অনুযায়ী সব সময় বেশি ওয়ালা উপরে থাকবে (descending: true)
        stream: FirebaseFirestore.instance
            .collection('marriages')
            .orderBy('coupleXp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color.fromARGB(255, 6, 250, 209)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "কোনো লাভলি কাপল পাওয়া যায়নি!",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          var allDocs = snapshot.data!.docs;

          // 🔹 ডাবল কার্ড ফিল্টারিং লজিক: একই কাপল উল্টো করে থাকলে একটিমাত্র রাখব
          final Map<String, QueryDocumentSnapshot> uniqueCouplesMap = {};
          for (var doc in allDocs) {
            var data = doc.data() as Map<String, dynamic>;
            String uid1 = data['myAuthUID'] ?? '';
            String uid2 = data['partnerAuthUID'] ?? '';

            if (uid1.isNotEmpty && uid2.isNotEmpty) {
              // ইউনিক পেয়ার কি তৈরি করা (ছোট আইডি আগে, বড় আইডি পরে সাজিয়ে)
              List<String> sortedUids = [uid1, uid2]..sort();
              String coupleKey = "${sortedUids[0]}_${sortedUids[1]}";

              // যেহেতু কুয়েরিটি XP descending করা, প্রথমবার আসা ডকুমেন্টটি বেশি XP ওয়ালা বা সঠিক হবে
              if (!uniqueCouplesMap.containsKey(coupleKey)) {
                uniqueCouplesMap[coupleKey] = doc;
              }
            } else {
              // যদি কোনো কারণে ফিল্ড খালি থাকে তবে আইডি দিয়েই ইউনিক ধরে রাখব
              uniqueCouplesMap[doc.id] = doc;
            }
          }

          var coupleDocs = uniqueCouplesMap.values.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: coupleDocs.length,
            itemBuilder: (context, index) {
              var data = coupleDocs[index].data() as Map<String, dynamic>;

              String myAuthUID = data['myAuthUID'] ?? '';
              String partnerAuthUID = data['partnerAuthUID'] ?? '';
              String ringIconUrl = data['ringIcon'] ?? '';
              
              // ডায়মন্ড থেকে XP হিসাব (প্রতি ২০০ ডায়মন্ডে ১ XP)
              int totalDiamonds = data['totalDiamonds'] ?? data['coupleDiamonds'] ?? 0;
              int coupleXp = data['coupleXp'] ?? (totalDiamonds ~/ 200);

              return _CoupleCardItem(
                myAuthUID: myAuthUID,
                partnerAuthUID: partnerAuthUID,
                ringIconUrl: ringIconUrl,
                coupleXp: coupleXp,
                rankIndex: index, // টপ ১, ২, ৩ নির্ধারণের জন্য
                fallbackMyName: data['myName'] ?? data['name'] ?? 'User 1',
                fallbackMyImage: data['myImage'] ?? data['profilePic'] ?? '',
                fallbackPartnerName: data['partnerName'] ?? 'User 2',
                fallbackPartnerImage: data['partnerImage'] ?? data['partnerProfilePic'] ?? '',
                onNavigateProfile: (authUid) => _navigateToProfile(context, authUid),
              );
            },
          );
        },
      ),
    );
  }

  // মাস শেষে XP রিসেট লজিক
  Future<void> _checkAndResetMonthlyXp() async {
    try {
      final prefsRef = FirebaseFirestore.instance.collection('app_settings').doc('couple_xp_reset');
      final doc = await prefsRef.get();
      
      String currentMonthYear = "${DateTime.now().year}-${DateTime.now().month}";
      
      if (!doc.exists || doc.data()?['lastResetMonth'] != currentMonthYear) {
        // নতুন মাস শুরু হয়েছে, সব ম্যারেজ ডকুমেন্টের XP রিসেট করো
        var marriages = await FirebaseFirestore.instance.collection('marriages').get();
        for (var doc in marriages.docs) {
          await doc.reference.update({'coupleXp': 0, 'totalDiamonds': 0});
        }
        // মাসের ট্যাগ আপডেট করে দাও
        await prefsRef.set({'lastResetMonth': currentMonthYear});
      }
    } catch (e) {
      debugPrint("❌ Monthly XP reset error: $e");
    }
  }

  Future<void> _navigateToProfile(BuildContext context, String authUid) async {
    if (authUid.isEmpty) return;

    String finalIdToPass = authUid;
    try {
      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: authUid)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        finalIdToPass = userQuery.docs.first.data()['uID']?.toString() ?? userQuery.docs.first.id;
      }
    } catch (e) {
      debugPrint("❌ Profile lookup error: $e");
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: finalIdToPass),
      ),
    );
  }
}

// 🌟 একটি আলাদা উইজেট যা ইউজারের লাইভ প্রোফাইল ডাটা স্ট্রিম করবে এবং XP দেখাবে
class _CoupleCardItem extends StatelessWidget {
  final String myAuthUID;
  final String partnerAuthUID;
  final String ringIconUrl;
  final int coupleXp;
  final int rankIndex;
  final String fallbackMyName;
  final String fallbackMyImage;
  final String fallbackPartnerName;
  final String fallbackPartnerImage;
  final Function(String) onNavigateProfile;

  const _CoupleCardItem({
    Key? key,
    required this.myAuthUID,
    required this.partnerAuthUID,
    required this.ringIconUrl,
    required this.coupleXp,
    required this.rankIndex,
    required this.fallbackMyName,
    required this.fallbackMyImage,
    required this.fallbackPartnerName,
    required this.fallbackPartnerImage,
    required this.onNavigateProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait([
        _getUserDoc(myAuthUID),
        _getUserDoc(partnerAuthUID),
      ]),
      builder: (context, userSnapshot) {
        String myName = fallbackMyName;
        String myImage = fallbackMyImage;
        String myFrameUrl = ''; // 🌟 [মার্ক]: প্রথম ইউজারের ফ্রেম লিংক রাখার ভেরিয়েবল
        
        String partnerName = fallbackPartnerName;
        String partnerImage = fallbackPartnerImage;
        String partnerFrameUrl = ''; // 🌟 [মার্ক]: পার্টনার ইউজারের ফ্রেম লিংক রাখার ভেরিয়েবল

        if (userSnapshot.hasData && userSnapshot.data != null) {
          var myDoc = userSnapshot.data![0];
          var partnerDoc = userSnapshot.data![1];

          if (myDoc.exists && myDoc.data() != null) {
            var myData = myDoc.data() as Map<String, dynamic>;
            myName = myData['name'] ?? myName;
            myImage = myData['profilePic'] ?? myImage;
            myFrameUrl = myData['activeFrameUrl'] ?? ''; // 🌟 [মার্ক]: ডাটাবেস থেকে প্রথম ইউজারের activeFrameUrl আনা হলো
          }

          if (partnerDoc.exists && partnerDoc.data() != null) {
            var partnerData = partnerDoc.data() as Map<String, dynamic>;
            partnerName = partnerData['name'] ?? partnerName;
            partnerImage = partnerData['profilePic'] ?? partnerImage;
            partnerFrameUrl = partnerData['activeFrameUrl'] ?? ''; // 🌟 [মার্ক]: ডাটাবেস থেকে পার্টনারের activeFrameUrl আনা হলো
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade900.withOpacity(0.8),
                Colors.pink.shade900.withOpacity(0.6),
                Colors.deepOrange.shade900.withOpacity(0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: rankIndex < 3 ? Colors.amberAccent.withOpacity(0.8) : Colors.pinkAccent.withOpacity(0.5),
              width: rankIndex < 3 ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: rankIndex < 3 ? Colors.amber.withOpacity(0.3) : Colors.pinkAccent.withOpacity(0.2),
                blurRadius: rankIndex < 3 ? 14 : 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none, // 🌟 [মার্ক]: যাতে টপ ১, ২, ৩ ব্যাজ বা রিং কার্ডের বাইরে গেলে কেটে না যায়
            children: [
              // ব্যাকগ্রাউন্ড লাভ আইকন প্যাটার্ন
              Positioned.fill(
                child: Opacity(
                  opacity: 0.08,
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: List.generate(
                      15,
                      (index) => const Icon(Icons.favorite, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),

              // 🌟 [মার্ক]: টপ ১, ২, ৩ কাপল ব্যাজ (এখানে টপ ১,২,৩ কার্ডের ভেতরে রিংয়ের কাছাকাছি বা একদম ওপরের অংশে রিংয়ের ক্ষতি না করে সুন্দরভাবে বসানো হয়েছে)
              if (rankIndex < 3)
                Positioned(
                  top: -12, // রিং বরাবর একটু উপরে বা উপরে সুন্দরভাবে প্লেস করার জন্য
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.amber, Colors.orange, Colors.amberAccent],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.amber.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)
                        ],
                      ),
                      child: Text(
                        rankIndex == 0
                            ? "🔥 Top 1 Couple"
                            : rankIndex == 1
                                ? "⭐ Top 2 Couple"
                                : "💎 Top 3 Couple",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16), // ওপরের ব্যাজের জন্য একটু প্যাডিং বাড়ানো হলো
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // ১. প্রথম ইউজার (ফ্রেমসহ)
                        GestureDetector(
                          onTap: () => onNavigateProfile(myAuthUID),
                          child: Column(
                            children: [
                              // 🌟 [মার্ক]: প্রোফাইল পিকচার এবং কাপল ফ্রেম একসাথে বসানোর জন্য Stack ব্যবহার করা হয়েছে (OverflowBox দিয়ে নাম ধাক্কা দেওয়া ফিক্স করা হলো)
                              SizedBox(
                                width: 70,
                                height: 70,
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    CircleAvatar(
                                      radius: 35,
                                      backgroundColor: Colors.grey[800],
                                      backgroundImage: myImage.isNotEmpty
                                          ? CachedNetworkImageProvider(myImage)
                                          : null,
                                      child: myImage.isEmpty
                                          ? const Icon(Icons.person, color: Colors.white)
                                          : null,
                                    ),
                                    // যদি ইউজারের activeFrameUrl থাকে তবে তা ওভারলে হিসেবে শো করবে এবং নামকে ধাক্কা দেবে না
                                    if (myFrameUrl.isNotEmpty)
                                      OverflowBox(
                                        maxWidth: 130,
                                        maxHeight: 130,
                                        child: Image.network(
                                          myFrameUrl,
                                          width: 130,
                                          height: 130,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 90,
                                child: Text(
                                  myName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // মাঝখানে অ্যানিমেটেড রিং ও গোল্ডেন মিক্স কালার XP ব্যাজ
                        Column(
                          children: [
                            _InfiniteRingAnimator(ringIconUrl: ringIconUrl),
                            const SizedBox(height: 8),
                            // গোল্ডেন মিক্স কালার ডিজাইনযুক্ত XP টেক্সট
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFF4500), Color(0xFF00FFFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                "XP : $coupleXp",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white, // ShaderMask এর জন্য কালার হোয়াইট থাকতে হবে
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ২. পার্টনার ইউজার (ফ্রেমসহ)
                        GestureDetector(
                          onTap: () => onNavigateProfile(partnerAuthUID),
                          child: Column(
                            children: [
                              // 🌟 [মার্ক]: পার্টনারের প্রোফাইল পিকচার এবং ফ্রেমের জন্য Stack
                              SizedBox(
                                width: 70,
                                height: 70,
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    CircleAvatar(
                                      radius: 35,
                                      backgroundColor: Colors.grey[800],
                                      backgroundImage: partnerImage.isNotEmpty
                                          ? CachedNetworkImageProvider(partnerImage)
                                          : null,
                                      child: partnerImage.isEmpty
                                          ? const Icon(Icons.person, color: Colors.white)
                                          : null,
                                    ),
                                    // পার্টনারের activeFrameUrl থাকলে তা এখানে রেন্ডার হবে এবং নামকে ধাক্কা দেবে না
                                    if (partnerFrameUrl.isNotEmpty)
                                      OverflowBox(
                                        maxWidth: 130,
                                        maxHeight: 130,
                                        child: Image.network(
                                          partnerFrameUrl,
                                          width: 130,
                                          height: 130,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 90,
                                child: Text(
                                  partnerName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24, thickness: 1),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.favorite, color: Colors.redAccent, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Forever Bonded Couple",
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserDoc(String authUid) async {
    if (authUid.isEmpty) {
      return await FirebaseFirestore.instance.collection('users').doc(authUid).get();
    }
    
    var query = await FirebaseFirestore.instance
        .collection('users')
        .where('authUID', isEqualTo: authUid)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }

    return await FirebaseFirestore.instance.collection('users').doc(authUid).get();
  }
}

// 💍 ইনফিনিট রিং অ্যানিমেটর উইজেট
class _InfiniteRingAnimator extends StatefulWidget {
  final String ringIconUrl;
  const _InfiniteRingAnimator({Key? key, required this.ringIconUrl}) : super(key: key);

  @override
  State<_InfiniteRingAnimator> createState() => _InfiniteRingAnimatorState();
}

class _InfiniteRingAnimatorState extends State<_InfiniteRingAnimator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.15),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.5 + (_controller.value * 0.5)),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: widget.ringIconUrl.isNotEmpty && widget.ringIconUrl.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: widget.ringIconUrl,
                    width: 40,
                    height: 40,
                    placeholder: (context, url) => const Icon(Icons.ring_volume, color: Colors.amber, size: 30),
                    errorWidget: (context, url, error) => const Icon(Icons.favorite, color: Colors.pinkAccent, size: 30),
                  )
                : const Icon(Icons.favorite, color: Colors.pinkAccent, size: 30),
          ),
        );
      },
    );
  }
}