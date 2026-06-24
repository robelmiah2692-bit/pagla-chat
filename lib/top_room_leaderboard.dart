import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class TopRoomLeaderboard extends StatefulWidget {
  const TopRoomLeaderboard({super.key});

  @override
  State<TopRoomLeaderboard> createState() => _TopRoomLeaderboardState();
}

class _TopRoomLeaderboardState extends State<TopRoomLeaderboard> {
  bool _isProcessingReward = false;
  Timer? _rewardCheckTimer;

  @override
  void initState() {
    super.initState();
    _startRewardCheckCountdown();
  }

  // ব্যাকগ্রাউন্ডে রিওয়ার্ড প্রসেস চেক করার টাইমার (UI-তে কোনো প্রভাব ফেলবে না)
  void _startRewardCheckCountdown() {
    _rewardCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final timeUntilReset = tomorrow.difference(now);

      if (timeUntilReset.inSeconds <= 0 && !_isProcessingReward) {
        _checkAndDistributeRewards();
      }
    });
  }

  @override
  void dispose() {
    _rewardCheckTimer?.cancel();
    super.dispose();
  }

  int calculateReward(int points, int rank) {
    int units = points ~/ 10000;
    if (units <= 0) return 0;
    if (rank == 1) return units * 1000;
    if (rank == 2) return units * 600;
    if (rank == 3) return units * 400;
    return 0;
  }

  Future<void> _checkAndDistributeRewards() async {
    setState(() => _isProcessingReward = true);
    final String todayKey = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));
    final systemRef = FirebaseFirestore.instance
        .collection('system_control')
        .doc('room_leaderboard_reset');

    try {
      final docSnap = await systemRef.get();
      if (docSnap.exists && docSnap.data()?['lastResetDate'] == todayKey) {
        return;
      }

      final topRoomsSnapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .orderBy('dailyPoints', descending: true)
          .get();

      final activeRooms = topRoomsSnapshot.docs
          .where((doc) {
            final data = doc.data();
            return (data['dailyPoints'] ?? 0) > 0;
          })
          .toList()
          .take(3)
          .toList();

      if (activeRooms.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();

      for (int i = 0; i < activeRooms.length; i++) {
        final roomDoc = activeRooms[i];
        final roomData = roomDoc.data();
        final String roomId = roomDoc.id;
        final String ownerId = roomData['ownerId'] ?? "";
        final int points = roomData['dailyPoints'] ?? 0;
        final int rank = i + 1;

        final int totalRewardPool = calculateReward(points, rank);
        if (totalRewardPool <= 0) continue;

        if (ownerId.isNotEmpty) {
          final ownerRef =
              FirebaseFirestore.instance.collection('users').doc(ownerId);
          batch.update(ownerRef, {
            'diamonds': FieldValue.increment(totalRewardPool),
            'vip_xp': FieldValue.increment(
                totalRewardPool ~/ 10 > 0 ? totalRewardPool ~/ 10 : 1),
          });

          _sendOfficialNotification(batch, ownerId,
              "🎉 অভিনন্দন! আপনার রুম '${roomData['roomName']}' দৈনিক লিডারবোর্ডে Rank $rank হয়েছে। আপনি পেয়েছেন $totalRewardPool ডায়মন্ড বোনাস!");
        }

        final topGiftersSnapshot = await FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomId)
            .collection('daily_gifters')
            .orderBy('giftedAmount', descending: true)
            .limit(3)
            .get();

        for (var gifterDoc in topGiftersSnapshot.docs) {
          final String gifterId = gifterDoc.id;
          if (gifterId.isNotEmpty) {
            final gifterRef =
                FirebaseFirestore.instance.collection('users').doc(gifterId);
            batch.update(gifterRef, {
              'diamonds': FieldValue.increment(totalRewardPool),
              'vip_xp': FieldValue.increment(
                  totalRewardPool ~/ 10 > 0 ? totalRewardPool ~/ 10 : 1),
            });

            _sendOfficialNotification(batch, gifterId,
                "🎉 অভিনন্দন! আপনি '${roomData['roomName']}' রুমে টপ গিফটার হিসেবে অংশ নিয়ে Rank $rank এর রিওয়ার্ড $totalRewardPool ডায়মন্ড বোনাস পেয়েছেন!");
          }
        }
      }

      for (var doc in topRoomsSnapshot.docs) {
        final data = doc.data();
        if ((data['dailyPoints'] ?? 0) > 0) {
          batch.update(doc.reference, {'dailyPoints': 0});
          final gifters = await doc.reference.collection('daily_gifters').get();
          for (var gDoc in gifters.docs) {
            batch.delete(gDoc.reference);
          }
        }
      }

      batch.set(
          systemRef, {'lastResetDate': todayKey}, SetOptions(merge: true));
      await batch.commit();
    } catch (e) {
      debugPrint("❌ Reward distribution error: ${e.toString()}");
    } finally {
      _isProcessingReward = false;
    }
  }

  void _sendOfficialNotification(
      WriteBatch batch, String userId, String messageText) {
    String chatId = "paglachat_official_$userId";
    DocumentReference chatDocRef =
        FirebaseFirestore.instance.collection('chats').doc(chatId);
    DocumentReference msgRef = chatDocRef.collection('messages').doc();

    batch.set(msgRef, {
      'senderId': 'paglachat_official',
      'receiverId': userId,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'system_msg'
    });

    batch.set(
        chatDocRef,
        {
          'lastMessage': "🎉 Room Reward Received",
          'lastTimestamp': FieldValue.serverTimestamp(),
          'users': ['paglachat_official', userId],
          'unReadCount': FieldValue.increment(1),
        },
        SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B28),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text("TOP ROOM LIVE",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      // 🔥 FutureBuilder পরিবর্তন করে StreamBuilder দেওয়া হলো যাতে রিয়ালটাইম ডাটা স্মুথলি আসে
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "🔥 স্ক্রিন এরর মেসেজ:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "❌ ডাটাবেজে কোনো রুম খুঁজে পাওয়া যায়নি!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            );
          }

          var allDocs = snapshot.data!.docs;

          var rooms = allDocs.where((doc) {
            var data = doc.data() as Map<String, dynamic>? ?? {};
            int points = data['dailyPoints'] ?? 0;
            return points > 0;
          }).toList();

          rooms.sort((a, b) {
            int pointsA =
                (a.data() as Map<String, dynamic>)['dailyPoints'] ?? 0;
            int pointsB =
                (b.data() as Map<String, dynamic>)['dailyPoints'] ?? 0;
            return pointsB.compareTo(pointsA);
          });

          if (rooms.isEmpty) {
            return Column(
              children: [
                const LiveHeaderTimer(), // কাউন্টডাউন টাইমার আলাদা উইজেট হিসেবে থাকবে
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tv_off, color: Colors.white24, size: 48),
                        SizedBox(height: 10),
                        Text("বর্তমানে কোনো রুমে লাইভ গিফটিং হচ্ছে না",
                            style:
                                TextStyle(color: Colors.white38, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              const LiveHeaderTimer(), // 🔥 শুধু এই টাইমারটুকু প্রতি সেকেন্ডে রিফ্রেশ হবে
              _buildTopWinnerCard(rooms[0], 1),
              Expanded(
                child: rooms.length > 1
                    ? ListView.builder(
                        itemCount: rooms.length - 1,
                        itemBuilder: (context, index) {
                          return _buildRoomTile(rooms[index + 1], index + 2);
                        },
                      )
                    : const Center(
                        child: Text("অন্য কোনো রুমে গিফটিং একটিভ নেই",
                            style: TextStyle(
                                color: Colors.white24, fontSize: 12))),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopWinnerCard(DocumentSnapshot doc, int rank) {
  var roomData = doc.data() as Map<String, dynamic>;
  String roomId = doc.id;
  String ownerId = roomData['ownerId'] ?? "";
  int points = roomData['dailyPoints'] ?? 0;
  int reward = calculateReward(points, rank);

  return RoomOwnerProfileBuilder(
    ownerId: ownerId,
    builder: (userData) {
      // ইউজার প্রোফাইল থেকে লেটেস্ট ডাটা নিচ্ছি
      String ownerPhoto = userData['profilePic'] ?? roomData['ownerPic'] ?? roomData['ownerImage'] ?? "";
      String ownerName = userData['name'] ?? roomData['ownerName'] ?? "Unknown";
      String frameUrl = userData['activeFrameUrl'] ?? roomData['ownerFrame'] ?? "";

      return Container(
        margin: const EdgeInsets.all(15),
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFB47C1C), Color(0xFFF9D16B), Color(0xFFB47C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 15)
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Opacity(
                opacity: 0.5,
                child: Image.network(
                    "https://cdn-icons-png.flaticon.com/512/8146/8146003.png",
                    width: 120,
                    errorBuilder: (c, e, s) => const SizedBox()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white24,
                        backgroundImage: ownerPhoto.isNotEmpty
                            ? NetworkImage(ownerPhoto)
                            : null,
                        child: ownerPhoto.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      if (frameUrl.isNotEmpty)
                        frameUrl.toLowerCase().endsWith('.json')
                            ? Lottie.network(
                                frameUrl,
                                width: 137,
                                height: 137,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const SizedBox(),
                              )
                            : Image.network(
                                frameUrl,
                                width: 137,
                                height: 137,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const SizedBox(),
                              ),
                      Positioned(
                          bottom: 0,
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Text("TOP 1",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold))))
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(roomData['roomName'] ?? "PaglaChat Room",
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3E2723)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text("ID: $roomId",
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF5D4037),
                                fontWeight: FontWeight.w600)),
                        Text("Owner: $ownerName",
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF5D4037)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text("💎 Est. Reward: $reward",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11)),
                        )
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.diamond,
                          color: Color(0xFF3E2723), size: 24),
                      const SizedBox(height: 4),
                      Text("$points",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF3E2723))),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
  Widget _buildRoomTile(DocumentSnapshot doc, int rank) {
    var roomData = doc.data() as Map<String, dynamic>;
    String roomId = doc.id;
    String ownerId = roomData['ownerId'] ?? "";
    int points = roomData['dailyPoints'] ?? 0;
    int reward = calculateReward(points, rank);

    return RoomOwnerProfileBuilder(
      ownerId: ownerId,
      builder: (userData) {
        // ইউজার ডাটা থেকে লেটেস্ট তথ্য নিচ্ছি
        String ownerPhoto = userData['profilePic'] ??
            roomData['ownerPic'] ??
            roomData['ownerImage'] ??
            "";
        String ownerName =
            userData['name'] ?? roomData['ownerName'] ?? "Unknown Owner";
        String frameUrl = userData['activeFrameUrl'] ?? roomData['ownerFrame'] ?? "";

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF161B40),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color:
                    rank <= 3 ? Colors.amber.withOpacity(0.5) : Colors.white10),
          ),
          child: Row(
            children: [
              Text("$rank",
                  style: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(width: 15),
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white12,
                    backgroundImage:
                        ownerPhoto.isNotEmpty ? NetworkImage(ownerPhoto) : null,
                    child: ownerPhoto.isEmpty
                        ? const Icon(Icons.person, color: Colors.white30)
                        : null,
                  ),
                  if (frameUrl.isNotEmpty)
                    frameUrl.toLowerCase().endsWith('.json')
                        ? Lottie.network(
                            frameUrl,
                            width: 85,
                            height: 85,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const SizedBox(),
                          )
                        : Image.network(
                            frameUrl,
                            width: 85,
                            height: 85,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const SizedBox(),
                          ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(roomData['roomName'] ?? "PaglaChat Room",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text("ID: $roomId",
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10)),
                    Text(ownerName,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.diamond,
                          color: Colors.blueAccent, size: 14),
                      const SizedBox(width: 4),
                      Text("$points",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (rank <= 3 && reward > 0)
                    Text("+$reward Reward",
                        style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}

// 🔥 কাউন্টডাউন টাইমার উইজেট সম্পূর্ণ আলাদা করা হলো যাতে পুরো বডি রিফ্রেশ না হয়
class LiveHeaderTimer extends StatefulWidget {
  const LiveHeaderTimer({super.key});

  @override
  State<LiveHeaderTimer> createState() => _LiveHeaderTimerState();
}

class _LiveHeaderTimerState extends State<LiveHeaderTimer> {
  Duration _timeUntilReset = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      if (mounted) {
        setState(() {
          _timeUntilReset = tomorrow.difference(now);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formatDuration(Duration d) {
      return "${d.inHours.toString().padLeft(2, '0')}H ${d.inMinutes.remainder(60).toString().padLeft(2, '0')}M ${d.inSeconds.remainder(60).toString().padLeft(2, '0')}S";
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Text(
            "Resets in: ${formatDuration(_timeUntilReset)}",
            style: const TextStyle(
                color: Colors.amber, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
// এটি আপনার ক্লাসের বাইরে যেকোনো জায়গায় রাখতে পারেন
class RoomOwnerProfileBuilder extends StatelessWidget {
  final String ownerId;
  final Widget Function(Map<String, dynamic> userData) builder;

  const RoomOwnerProfileBuilder({required this.ownerId, required this.builder, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(ownerId).snapshots(),
      builder: (context, snapshot) {
        // ডাটা না পেলে বা লোডিং হলে ডিফল্ট এমটি ম্যাপ পাঠাবে
        var userData = (snapshot.hasData && snapshot.data!.exists) 
            ? snapshot.data!.data() as Map<String, dynamic> 
            : <String, dynamic>{};
        return builder(userData);
      },
    );
  }
}