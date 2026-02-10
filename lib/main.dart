import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: VoiceRoomScreen()));

class VoiceRoomScreen extends StatelessWidget {
  const VoiceRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // প্রফেশনাল ডার্ক থিম
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("পাগলা ভয়েস রুম", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.store, color: Colors.gold), onPressed: () {}), // ডায়মন্ড স্টোর
          IconButton(icon: const Icon(Icons.notifications, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // ভয়েস রুমের বসার বোর্ড (১০টি সিট)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // এক লাইনে ৩ জন
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
              itemCount: 10,
              itemBuilder: (context, index) => _buildSeat(index),
            ),
          ),
          
          // নিচের গিফটিং এবং চ্যাট বার
          _buildBottomBar(),
        ],
      ),
    );
  }

  // সিট বা বোর্ড ডিজাইন
  Widget _buildSeat(int index) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // ফ্রেম অপশন (উদাহরণস্বরূপ গোল বর্ডার)
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.pinkAccent, width: 3), // ফ্রেম
              ),
            ),
            const CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage('https://via.placeholder.com/150'), // ইউজারের পিক
            ),
            if (index == 0) // হোস্টের জন্য ছোট ক্রাউন
              const Positioned(top: 0, child: Icon(Icons.workspace_premium, color: Colors.orange, size: 20)),
          ],
        ),
        const SizedBox(height: 5),
        Text("সিট ${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  // গিফট, চ্যাট এবং মিউজিক বার
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              height: 40,
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
              child: const TextField(
                decoration: InputDecoration(hintText: "কিছু বলুন...", hintStyle: TextStyle(color: Colors.white54), border: InputBorder.none),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.yellow), onPressed: () {}), // গিফটিং
          IconButton(icon: const Icon(Icons.music_note, color: Colors.cyanAccent), onPressed: () {}), // মিউজিক
        ],
      ),
    );
  }
}
