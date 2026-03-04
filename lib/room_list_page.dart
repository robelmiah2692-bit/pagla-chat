import 'package:flutter/material.dart';
import 'screens/voice_room.dart'; // এইটা লিখে দিন
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 এটি উপরে যোগ করুন
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomListPage extends StatefulWidget {
  const RoomListPage({super.key});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String displayRoomID = "123456";
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Rooms", style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.pinkAccent,
          labelColor: Colors.pinkAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: "Live Room"),
            Tab(text: "Following"),
            Tab(text: "My Room"),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildBanner(),
          const SizedBox(height: 15),
          _buildFeaturedRooms(),
          const SizedBox(height: 15),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRoomGrid("live"),
                _buildRoomGrid("following"),
                _buildRoomGrid("my_room"), // মাই রুম সেকশন
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ১. প্রিমিয়াম ব্যানার (সঠিক বানান)
  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "পাগলা আড্ডায় জয়েন হও",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  "আড্ডা দাও মন খুলে",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: const Text("Join Now", style: TextStyle(color: Color(0xFF2575FC), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ২. ফিচারড রুম
  Widget _buildFeaturedRooms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Text("Featured Rooms", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: const DecorationImage(
                    image: NetworkImage("https://picsum.photos/200"),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ৩. রুম গ্রিড লজিক (যেখানে মাই রুম ঠিক করা হয়েছে)
  Widget _buildRoomGrid(String type) {
  return GridView.builder(
    padding: const EdgeInsets.all(10),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.9,
    ),
    itemCount: (type == "my_room") ? 1 : 10,
    itemBuilder: (context, index) {
      return GestureDetector(
        onTap: () async {
          String finalRoomId;

          if (type == "my_room") {
            // 🔥 ৫ ডিজিটের ডাইনামিক আইডি জেনারেট বা লোড করা
            final user = FirebaseAuth.instance.currentUser;
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();

            if (userDoc.exists && userDoc.data()?.containsKey('myRoomId') == true) {
              finalRoomId = userDoc.data()!['myRoomId'].toString();
            } else {
              // নতুন ৫ ডিজিটের আইডি তৈরি (যেমন: ১২৩৪৫)
              finalRoomId = (10000 + (DateTime.now().millisecondsSinceEpoch % 90000)).toString();
              // ইউজারের প্রোফাইলে সেভ করে রাখা যেন আর না বদলায়
              await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
                'myRoomId': finalRoomId,
              }, SetOptions(merge: true));
            }
          } else {
            finalRoomId = "room_$index";
          }

          if (!context.mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VoiceRoom(roomId: finalRoomId),
            ),
          );
        },
        child: _buildRoomCard(index, type),
      );
    },
  );
}

  // ৪. রুম কার্ড ডিজাইন
  Widget _buildRoomCard(int index, String type) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(15),
        border: type == "my_room" ? Border.all(color: Colors.amber, width: 1) : null,
        image: DecorationImage(
          image: NetworkImage("https://picsum.photos/id/${index + 50}/200/300"),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type == "my_room" ? "আমার আড্ডাখানা" : "রুম নাম ${index + 1}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    type == "my_room" ? "Owner: You" : "Users: 15",
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          if (type == "my_room")
            const Positioned(
              top: 8,
              left: 8,
              child: Icon(Icons.stars, color: Colors.amber, size: 20),
            ),
        ],
      ),
    );
  }
}
