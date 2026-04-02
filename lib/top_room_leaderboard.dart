import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class TopRoomLeaderboard extends StatefulWidget {
  const TopRoomLeaderboard({super.key});

  @override
  State<TopRoomLeaderboard> createState() => _TopRoomLeaderboardState();
}

class _TopRoomLeaderboardState extends State<TopRoomLeaderboard> {
  // // রাত ১২টার কাউন্টডাউন ভেরিয়েবল
  Duration _timeUntilReset = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  // // বাংলাদেশ সময় রাত ১২টা পর্যন্ত সময় গণনা
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      setState(() {
        _timeUntilReset = tomorrow.difference(now);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // // রিওয়ার্ড ক্যালকুলেশন লজিক (প্রতি ১০ হাজার ডায়মন্ডে)
  int calculateReward(int points, int rank) {
    int units = points ~/ 10000; // // প্রতি ১০ হাজার ইউনিট
    if (rank == 1) return units * 1000;
    if (rank == 2) return units * 600;
    if (rank == 3) return units * 400;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B28), // // প্রিমিয়াম ডার্ক ব্লু থিম
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text("TOP ROOM WEEKLY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.help_outline, color: Colors.amber))
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // // গিফটিং পয়েন্টের ওপর ভিত্তি করে রিয়েল টাইম ডাটা আনা
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .orderBy('dailyPoints', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var rooms = snapshot.data!.docs;

          return Column(
            children: [
              // // ১. টপ ব্যানার ও কাউন্টডাউন
              _buildHeaderTimer(),

              // // ২. টপ উইনার বড় কার্ড (ডায়মন্ড বক্স ডিজাইন)
              if (rooms.isNotEmpty) _buildTopWinnerCard(rooms[0], 1),

              // // ৩. মেইন লিস্ট
              Expanded(
                child: ListView.builder(
                  itemCount: rooms.length > 1 ? rooms.length - 1 : 0,
                  itemBuilder: (context, index) {
                    return _buildRoomTile(rooms[index + 1], index + 2);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderTimer() {
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
            "Ends in: ${formatDuration(_timeUntilReset)}",
            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTopWinnerCard(DocumentSnapshot doc, int rank) {
    var data = doc.data() as Map<String, dynamic>;
    int points = data['dailyPoints'] ?? 0;
    int reward = calculateReward(points, rank);

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
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 15)],
      ),
      child: Stack(
        children: [
          // // ডায়মন্ড বক্স এনিমেশন ব্যাকগ্রাউন্ড (ছবি কল্পনা করে)
          Positioned(
            right: -10, bottom: -10,
            child: Opacity(
              opacity: 0.5,
              child: Image.network("https://cdn-icons-png.flaticon.com/512/8146/8146003.png", width: 120), // // ডায়মন্ড বক্স আইকন
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
                // // রুম মালিকের ছবি + ফ্রেম
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(radius: 40, backgroundImage: NetworkImage(data['ownerImage'] ?? "")),
                    if (data['ownerFrame'] != null)
                      Image.network(data['ownerFrame'], width: 100, height: 100),
                    Positioned(bottom: 0, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                      child: const Text("TOP 1", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ))
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['roomName'] ?? "", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3E2723))),
                      Text("Owner: ${data['ownerName']}", style: const TextStyle(fontSize: 13, color: Color(0xFF5D4037))),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                        child: Text("💎 Est. Reward: $reward", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.red),
                    Text("${(points / 1000).toStringAsFixed(1)}k", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTile(DocumentSnapshot doc, int rank) {
    var data = doc.data() as Map<String, dynamic>;
    int points = data['dailyPoints'] ?? 0;
    int reward = calculateReward(points, rank);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B40),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: rank <= 3 ? Colors.amber.withOpacity(0.5) : Colors.white10),
      ),
      child: Row(
        children: [
          Text("$rank", style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 15),
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(radius: 25, backgroundImage: NetworkImage(data['ownerImage'] ?? "")),
              if (data['ownerFrame'] != null)
                Image.network(data['ownerFrame'], width: 65, height: 65),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['roomName'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(data['ownerName'] ?? "", style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.diamond, color: Colors.blueAccent, size: 14),
                  const SizedBox(width: 4),
                  Text("${(points / 1000).toStringAsFixed(1)}k", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              if (rank <= 3)
                Text("+$reward Reward", style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}
