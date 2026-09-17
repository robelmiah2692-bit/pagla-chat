import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';

class EventRewardsPage extends StatefulWidget {
  final String userId;

  const EventRewardsPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<EventRewardsPage> createState() => _EventRewardsPageState();
}

class _EventRewardsPageState extends State<EventRewardsPage> {
  // ইভেন্ট টায়ার বা টেমপ্লেট লিস্ট
  final List<Map<String, dynamic>> eventTiers = [
    {
      'target': 50000,
      'title': '50K Event',
      'diamonds': 2000,
      'xp': 0,
      'hasFrame': true,
      'hasEntry': false,
      'hasGiftBox': false,
      'frameUrl': 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/newanimeframe/lovlybluflawer.webp',
    },
    {
      'target': 100000,
      'title': '100K Event',
      'diamonds': 4000,
      'xp': 10,
      'hasFrame': true,
      'hasEntry': false,
      'hasGiftBox': false,
      'frameUrl': 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/newanimeframe/dolphin_flower.webp',
    },
    {
      'target': 200000,
      'title': '200K Royal Event',
      'diamonds': 6000,
      'xp': 20,
      'hasFrame': true,
      'hasEntry': true,
      'hasGiftBox': false,
      'entryUrl': 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/entry%20(12).json',
      'frameUrl': 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/newanimeframe/cupaleframe.webp',
    },
    {
      'target': 300000,
      'title': '300K Royal Event',
      'diamonds': 8000,
      'xp': 50,
      'hasFrame': true,
      'hasEntry': true,
      'hasGiftBox': true,
      'entryUrl': 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/entry%20(8).json',
      'frameUrl': 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/newanimeframe/redrose.webp',
    },
    {
      'target': 500000,
      'title': '500K Royal Event',
      'diamonds': 15000,
      'xp': 200,
      'hasFrame': true,
      'hasEntry': true,
      'hasGiftBox': true,
      'entryUrl': 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/entry%20(15).json',
      'frameUrl': 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/newanimeframe/kingframe.webp',
    },
  ];

  // বর্তমান সপ্তাহের রবিবার বের করার ফাংশন
  String _getCurrentWeekKey() {
    DateTime now = DateTime.now();
    int daysToSubtract = now.weekday % 7; 
    DateTime sunday = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
    String weekKey = "${sunday.year}-${sunday.month}-${sunday.day}";
    print("DEBUG: Current WeekKey -> $weekKey");
    return weekKey;
  }
// কালেকশন গ্রুপ কুয়েরি ব্যবহার করে দ্রুত ইভেন্ট কাউন্ট করার ফাংশন
  Future<int> _calculateDynamicEventCount(int targetIndex) async {
    try {
      int lowerLimit = eventTiers[targetIndex]['target'];
      int upperLimit;

      if (targetIndex < eventTiers.length - 1) {
        upperLimit = eventTiers[targetIndex + 1]['target'];
      } else {
        upperLimit = 999999999; // শেষেরটার জন্য সর্বোচ্চ লিমিট
      }

      print("DEBUG ---> Checking Tier: ${eventTiers[targetIndex]['title']} | Target/Lower: $lowerLimit | Upper: $upperLimit | UserID: ${widget.userId}");

      // আলাদা করে রুম লুপ না চালিয়ে সরাসরি collectionGroup দিয়ে সব রুমের room_events একসাথে কুয়েরি করা
      QuerySnapshot eventsSnapshot = await FirebaseFirestore.instance
          .collectionGroup('room_events')
          .where('createdBy', isEqualTo: widget.userId)
          .get();
      
      int matchedCount = 0;

      for (var eventDoc in eventsSnapshot.docs) {
        var data = eventDoc.data() as Map<String, dynamic>;
        int totalDiamonds = data['totalDiamonds'] ?? data['diamonds'] ?? 0;

        print("DEBUG: Found Event -> EventID: ${eventDoc.id}, totalDiamonds: $totalDiamonds");

        if (totalDiamonds >= lowerLimit && totalDiamonds < upperLimit) {
          matchedCount++;
          print("MATCHED! Count increased to: $matchedCount for Tier ${eventTiers[targetIndex]['title']}");
        }
      }

      print("DEBUG ---> Final Matched Count for ${eventTiers[targetIndex]['title']}: $matchedCount\n");
      return matchedCount;
    } catch (e) {
      print("ERROR in _calculateDynamicEventCount: $e");
      return 0;
    }
  }
  // রিওয়ার্ড ক্লেইম করার লজিক
  Future<void> _claimReward(Map<String, dynamic> tier, int calculatedCount) async {
    int target = tier['target'];
    String weekKey = _getCurrentWeekKey();
    print("DEBUG: Attempting to claim reward for target: $target with count: $calculatedCount");
    
    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);
        if (!snapshot.exists) {
          print("ERROR: User document does not exist!");
          return;
        }

        var userData = snapshot.data() as Map<String, dynamic>;
        int currentDiamonds = userData['diamonds'] ?? 0;
        int currentXp = userData['totalActiveXp'] ?? 0;

        int newDiamonds = currentDiamonds + (tier['diamonds'] as int);
        int newXp = currentXp + (tier['xp'] as int);

        transaction.update(userRef, {
          'diamonds': newDiamonds,
          'totalActiveXp': newXp,
        });

        if (tier['hasFrame'] == true) {
          DocumentReference frameRef = userRef.collection('my_frames').doc();
          transaction.set(frameRef, {
            'name': '${tier['title']} Frame',
            'image_url': tier['frameUrl'],
            'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
          });
        }

        if (tier['hasEntry'] == true) {
          DocumentReference entryRef = userRef.collection('myEntries').doc();
          transaction.set(entryRef, {
            'name': '${tier['title']} Entry',
            'url': tier['entryUrl'] ?? '',
            'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
          });
        }

        if (tier['hasGiftBox'] == true) {
          DocumentReference giftBoxRef = userRef.collection('free_gift_boxes').doc();
          transaction.set(giftBoxRef, {
            'name': '${tier['title']} Gift Box',
            'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
            'status': 'unopened',
          });
        }

        DocumentReference progressRef = userRef.collection('event_progress').doc('${weekKey}_$target');
        transaction.set(progressRef, {
          'count': calculatedCount,
          'status': 'claimed',
          'target': target,
          'weekKey': weekKey,
        }, SetOptions(merge: true));
      });

      print("DEBUG: Reward claimed successfully!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Successfully claimed your royal rewards! 🎉"), backgroundColor: Colors.green),
      );
      setState(() {});
    } catch (e) {
      print("ERROR during claim transaction: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to claim: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String weekKey = _getCurrentWeekKey();

    return Scaffold(
      backgroundColor: const Color(0xFF0F051D),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, userSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .collection('event_progress')
                .where('weekKey', isEqualTo: weekKey)
                .snapshots(),
            builder: (context, progressSnapshot) {
              Map<int, Map<String, dynamic>> progressMap = {};
              if (progressSnapshot.hasData) {
                for (var doc in progressSnapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  int target = data['target'] ?? 0;
                  progressMap[target] = data;
                }
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: eventTiers.length,
                itemBuilder: (context, index) {
                  var tier = eventTiers[index];
                  int target = tier['target'];

                  var userTierProgress = progressMap[target] ?? {};
                  String savedStatus = userTierProgress['status'] ?? 'ongoing';

                  return FutureBuilder<int>(
                    future: _calculateDynamicEventCount(index),
                    builder: (context, countSnapshot) {
                      int currentCount = countSnapshot.data ?? 0;
                      String status = savedStatus;

                      if (currentCount >= 3 && status != 'claimed') {
                        status = 'getable';
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2A0845), Color(0xFF1B143F), Color(0xFF0A2540)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: status == 'claimed' ? Colors.grey : Colors.cyanAccent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pinkAccent.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Colors.cyanAccent, Colors.pinkAccent, Colors.amberAccent],
                                  ).createShader(bounds),
                                  child: Text(
                                    tier['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amberAccent),
                                  ),
                                  child: Text(
                                    "Progress: $currentCount/3",
                                    style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(color: Colors.white24, height: 1),
                            ),
                            Row(
                              children: [
                                if (tier['hasFrame'] == true) ...[
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: tier['frameUrl'],
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        errorWidget: (context, url, error) => const Icon(Icons.card_giftcard, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (tier['hasEntry'] == true && tier['entryUrl'] != null) ...[
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Lottie.network(
                                        tier['entryUrl'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.animation, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Colors.white, Colors.cyanAccent],
                                    ).createShader(bounds),
                                    child: Text(
                                      "Rewards: ${tier['diamonds']} 💎 | ${tier['xp']} XP"
                                      "${tier['hasEntry'] == true ? ' | Entry' : ''}"
                                      "${tier['hasGiftBox'] == true ? ' | Gift Box' : ''}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (status == 'claimed')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text("Claimed", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                  )
                                else if (status == 'getable')
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.greenAccent,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _claimReward(tier, currentCount),
                                    child: const Text("Get", style: TextStyle(fontWeight: FontWeight.bold)),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.orangeAccent),
                                    ),
                                    child: const Text("Ongoing", style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}