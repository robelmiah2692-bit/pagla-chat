import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/voice_room.dart'; 
import 'live_room_grid.dart';
import 'following_room_grid.dart';

class RoomListPage extends StatefulWidget {
  const RoomListPage({super.key});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
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
                // ১. লাইভ রুম (const নেই, এরর হবে না)
                LiveRoomGrid(), 

                // ২. ফলোয়িং রুম (const নেই, এরর হবে nez)
                FollowingRoomGrid(), 

                // ৩. মাই রুম সেকশন
                _buildRoomGrid("my_room"), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- প্রিমিয়াম ব্যানার ফিচার ---
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
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "পাগলা আড্ডায় জয়েন হও",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              "আড্ডা দাও মন খুলে",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // --- ফিচারড রুম সেকশন ---
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
          height: 100,
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
                  color: Colors.white12,
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

  // --- রুম গ্রিড ও আইডি জেনারেশন লজিক ---
  Widget _buildRoomGrid(String type) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: (type == "my_room") ? 1 : 10,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () async {
            String finalRoomId = "";
            if (type == "my_room") {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              
              final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
              if (userDoc.exists && userDoc.data()?.containsKey('myRoomId') == true) {
                finalRoomId = userDoc.data()!['myRoomId'].toString();
              } else {
                finalRoomId = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
                await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                  'myRoomId': finalRoomId,
                }, SetOptions(merge: true));
              }
            } else {
              finalRoomId = "public_room_$index";
            }

            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VoiceRoom(roomId: finalRoomId)),
            );
          },
          child: _buildRoomCard(index, type),
        );
      },
    );
  }

  Widget _buildRoomCard(int index, String type) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(15),
        border: type == "my_room" ? Border.all(color: Colors.amber, width: 1) : null,
      ),
      child: Center(
        child: Text(
          type == "my_room" ? "My Room" : "Room ${index + 1}",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
