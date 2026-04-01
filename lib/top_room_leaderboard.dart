import 'package:flutter/material.dart';

class TopRoomLeaderboard extends StatelessWidget {
  const TopRoomLeaderboard({super.key});

  @override
  Widget build(BuildContext context) {
    // ডামি ডাটা: বাস্তবে এটি আপনার ডাটাবেজ থেকে আসবে
    final List<Map<String, dynamic>> topRooms = List.generate(10, (index) => {
      "rank": index + 1,
      "roomName": "রুম নাম্বার ${index + 1}",
      "owner": "মালিক ${index + 1}",
      "points": (1000 - (index * 100)),
      "isWinner": index == 0, // ১ নাম্বার রুম স্পেশাল রিওয়ার্ড পাবে
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text("TOP 10 ROOMS", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ১ নাম্বার রুমের স্পেশাল রিওয়ার্ড ব্যানার
          _buildRewardSection(topRooms[0]),
          
          const Divider(color: Colors.white10),
          
          // বাকি ৯টি রুমের লিস্ট
          Expanded(
            child: ListView.builder(
              itemCount: topRooms.length,
              itemBuilder: (context, index) {
                final room = topRooms[index];
                return _buildRoomTile(room);
              },
            ),
          ),
        ],
      ),
    );
  }

  // রিওয়ার্ড সেকশন (১ নাম্বার রুমের জন্য)
  Widget _buildRewardSection(Map<String, dynamic> room) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.amber, Colors.orangeAccent]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, size: 50, color: Colors.white),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("আজকের বিজয়ী: ${room['roomName']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text("মালিক: ${room['owner']}", style: const TextStyle(fontSize: 14)),
                const Text("🎁 রিওয়ার্ড: ৫০০ ডায়মন্ড পাঠানো হয়েছে!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // সাধারণ রুম লিস্ট টাইল
  Widget _buildRoomTile(Map<String, dynamic> room) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: room['isWinner'] ? Colors.amber : Colors.white10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: room['isWinner'] ? Colors.amber : Colors.blueGrey,
          child: Text("${room['rank']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(room['roomName'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("মালিক: ${room['owner']}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt, color: Colors.amber, size: 16),
            Text("${room['points']}", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
