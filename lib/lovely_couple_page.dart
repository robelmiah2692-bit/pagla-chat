import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';

import 'package:pagla_chat/profile_page.dart';

class LovelyCouplePage extends StatelessWidget {
  const LovelyCouplePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('marriages').snapshots(),
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

          var coupleDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: coupleDocs.length,
            itemBuilder: (context, index) {
              var data = coupleDocs[index].data() as Map<String, dynamic>;

              String myAuthUID = data['myAuthUID'] ?? '';
              String partnerAuthUID = data['partnerAuthUID'] ?? '';
              String ringIconUrl = data['ringIcon'] ?? '';

              // আমরা আলাদা উইজেট ব্যবহার করছি যাতে দুই ইউজারের লাইভ ডাটা (current name & image) রিয়েল-টাইমে লোড হয়
              return _CoupleCardItem(
                myAuthUID: myAuthUID,
                partnerAuthUID: partnerAuthUID,
                ringIconUrl: ringIconUrl,
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

// 🌟 একটি আলাদা উইজেট যা ইউজারের লাইভ প্রোফাইল ডাটা (`users` কালেকশন থেকে) স্ট্রিম করবে
class _CoupleCardItem extends StatelessWidget {
  final String myAuthUID;
  final String partnerAuthUID;
  final String ringIconUrl;
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
        // ডাটা আসার আগ L পর্যন্ত মেরিজ কালেকশনের ডাটা ফলব্যাক হিসেবে দেখাবে
        String myName = fallbackMyName;
        String myImage = fallbackMyImage;
        String partnerName = fallbackPartnerName;
        String partnerImage = fallbackPartnerImage;

        if (userSnapshot.hasData && userSnapshot.data != null) {
          var myDoc = userSnapshot.data![0];
          var partnerDoc = userSnapshot.data![1];

          if (myDoc.exists && myDoc.data() != null) {
            var myData = myDoc.data() as Map<String, dynamic>;
            myName = myData['name'] ?? myName;
            myImage = myData['profilePic'] ?? myImage;
          }

          if (partnerDoc.exists && partnerDoc.data() != null) {
            var partnerData = partnerDoc.data() as Map<String, dynamic>;
            partnerName = partnerData['name'] ?? partnerName;
            partnerImage = partnerData['profilePic'] ?? partnerImage;
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade900.withOpacity(0.7),
                Colors.pink.shade900.withOpacity(0.5),
                Colors.deepOrange.shade900.withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.pinkAccent.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // ১. প্রথম ইউজার
                        GestureDetector(
                          onTap: () => onNavigateProfile(myAuthUID),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.cyanAccent, width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.grey[800],
                                  backgroundImage: myImage.isNotEmpty
                                      ? CachedNetworkImageProvider(myImage)
                                      : null,
                                  child: myImage.isEmpty
                                      ? const Icon(Icons.person, color: Colors.white)
                                      : null,
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

                        // মাঝখানে অ্যানিমেটেড রিং
                        _InfiniteRingAnimator(ringIconUrl: ringIconUrl),

                        // ২. পার্টনার ইউজার
                        GestureDetector(
                          onTap: () => onNavigateProfile(partnerAuthUID),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.pinkAccent, width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.grey[800],
                                  backgroundImage: partnerImage.isNotEmpty
                                      ? CachedNetworkImageProvider(partnerImage)
                                      : null,
                                  child: partnerImage.isEmpty
                                      ? const Icon(Icons.person, color: Colors.white)
                                      : null,
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

  // ফায়ারস্টোর থেকে অথ ইউআইডি দিয়ে ইউজারের ডকুমেন্ট খুঁজে আনা
  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserDoc(String authUid) async {
    if (authUid.isEmpty) {
      // যদি সরাসরি ডকুমেন্ট আইডি হয়
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

    // ফলব্যাক হিসেবে সরাসরি ডক আইডি ধরে ট্রাই করবে
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