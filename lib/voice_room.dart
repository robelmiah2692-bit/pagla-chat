import 'package:flutter/material.dart';
import 'dart:async';

class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});

  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  // --- ভেরিয়েবলসমূহ ---
  bool isLocked = false; 
  int diamondBalance = 1000; // ইউজারের ডাইমন্ড ব্যালেন্স
  String roomWallpaper = ""; // গ্যালারি থেকে সেট করা পেপার
  String roomName = "আপনার রুমের নাম";
  int followerCount = 150;
  
  // ১৫টি সিটের ডাটা (০-৪ ভিআইপি, ৫-১৪ নরমাল)
  List<Map<String, dynamic>> seats = List.generate(15, (index) => {
    "isOccupied": false,
    "userName": "",
    "userImage": "",
    "isVip": index < 5 ? true : false, // প্রথম ৫টি ভিআইপি
    "isMuted": false,
    "isSpeaking": false,
    "emoji": "",
  });

  // --- লক ফাংশন (৩০০ ডাইমন্ড কাটবে) ---
  void toggleLock() {
    if (!isLocked) {
      if (diamondBalance >= 300) {
        setState(() {
          isLocked = true;
          diamondBalance -= 300;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("রুম ২৪ ঘন্টার জন্য লক করা হলো (৩০০💎)")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("পর্যাপ্ত ডাইমন্ড নেই!")));
      }
    } else {
      setState(() => isLocked = false);
    }
  }

  // --- সিটে বসার লজিক ---
  void sitOnSeat(int index) {
    if (seats[index]["isVip"]) {
      // এখানে ইউজারের ভিআইপি স্ট্যাটাস চেক করতে হবে
      bool userIsVip = false; // ডামি চেক
      if (!userIsVip) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("এটি শুধু ভিআইপিদের জন্য!")));
        return;
      }
    }
    setState(() {
      seats[index]["isOccupied"] = true;
      seats[index]["userName"] = "ইউজার"; // আপনার প্রোফাইল থেকে আসবে
    });
  }

  // --- ইমোজি পপ-আপ লজিক (৩ সেকেন্ড থাকবে) ---
  void showEmojiOnSeat(int seatIndex, String emoji) {
    setState(() => seats[seatIndex]["emoji"] = emoji);
    Timer(const Duration(seconds: 3), () {
      setState(() => seats[seatIndex]["emoji"] = "");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: roomWallpaper.isEmpty 
            ? null 
            : DecorationImage(image: NetworkImage(roomWallpaper), fit: BoxFit.cover),
          color: const Color(0xFF0F0F1E),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildHeader(), // ১. রুম আইডি, নাম, লক ও ওয়ালপেপার বাটন
            _buildYoutubePlayer(), // ২. ইউটিউব সেকশন
            _buildSeatGrid(), // ৩. ১৫টি সিট (ভিআইপি ও নরমাল)
            _buildChatAndControls(), // ৪. চ্যাট, ইমোজি, গিফট, মাইক
          ],
        ),
      ),
    );
  }

  // ১. হেডার ডিজাইন
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          CircleAvatar(radius: 25, backgroundColor: Colors.white10, child: Icon(Icons.add_a_photo, size: 20)), // রুম পিক
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("ID: 556677 | Follower: $followerCount", style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle, color: Colors.pinkAccent)), // ফলো বাটন
          IconButton(onPressed: toggleLock, icon: Icon(isLocked ? Icons.lock : Icons.lock_open, color: Colors.amber)), // লক বাটন
          IconButton(onPressed: () {}, icon: const Icon(Icons.wallpaper, color: Colors.cyanAccent)), // ওয়ালপেপার
        ],
      ),
    );
  }

  // ২. ইউটিউব প্লেয়ার (সিমাবদ্ধ স্ক্রিন)
  Widget _buildYoutubePlayer() {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(10),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
      child: const Center(child: Text("YouTube Player (Locked Scale)", style: TextStyle(color: Colors.white38))),
    );
  }

  // ৩. ১৫টি সিটের গ্রিড
  Widget _buildSeatGrid() {
    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 10, crossAxisSpacing: 10),
        itemCount: 15,
        itemBuilder: (context, index) {
          var seat = seats[index];
          return GestureDetector(
            onTap: () => sitOnSeat(index),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // সিট ডিজাইন
                CircleAvatar(
                  radius: 28,
                  backgroundColor: seat["isVip"] ? Colors.amber.withOpacity(0.2) : Colors.white10,
                  child: seat["isOccupied"] 
                    ? const Icon(Icons.person, color: Colors.white) 
                    : Icon(Icons.chair, color: seat["isVip"] ? Colors.amber : Colors.white24),
                ),
                // ভিআইপি ট্যাগ
                if (seat["isVip"]) Positioned(top: 0, child: Icon(Icons.star, size: 12, color: Colors.amber)),
                // ইমোজি পপ-আপ
                if (seat["emoji"].isNotEmpty) Positioned(top: -10, child: Text(seat["emoji"], style: const TextStyle(fontSize: 24))),
                // মিউট সিগনাল
                if (seat["isOccupied"]) Positioned(bottom: 0, right: 0, child: Icon(Icons.mic_off, size: 14, color: Colors.red)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ৪. নিচের চ্যাট ও বাটন
  Widget _buildChatAndControls() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.black26,
      child: Row(
        children: [
          IconButton(onPressed: () => showEmojiOnSeat(0, "🤔"), icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.amber)),
          const Expanded(child: TextField(decoration: InputDecoration(hintText: "বলুন...", border: InputBorder.none))),
          IconButton(onPressed: () {}, icon: const Icon(Icons.videogame_asset, color: Colors.blueAccent)), // লুডু
          IconButton(onPressed: () {}, icon: const Icon(Icons.card_giftcard, color: Colors.pinkAccent)), // গিফট
        ],
      ),
    );
  }
}
