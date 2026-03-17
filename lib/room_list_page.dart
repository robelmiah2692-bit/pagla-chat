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
        elevation: 0,
        title: const Text("Rooms", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                LiveRoomGrid(), 
                FollowingRoomGrid(), 
                _buildRoomGrid("my_room"), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- প্রিমিয়াম ব্যানার ফিচার ---
  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "পাগলা আড্ডায় জয়েন হও",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "আড্ডা দাও মন খুলে",
              style: TextStyle(color: Colors.white70, fontSize: 14),
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
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: 90,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white10,
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

  // --- রুম গ্রিড ও আইডি জেনারেশন লজিক (সম্পূর্ণ ফিক্সড) ---
  Widget _buildRoomGrid(String type) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: (type == "my_room") ? 1 : 10,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () async {
            String finalRoomId = "";
            
            if (type == "my_room") {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("দয়া করে আগে লগইন করুন।"))
                );
                return;
              }
              
              try {
                // ডাটাবেস চেক (নিরাপদ পদ্ধতি)
                final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                final userData = userDoc.data();

                if (userDoc.exists && userData != null && userData.containsKey('myRoomId')) {
                  finalRoomId = userData['myRoomId'].toString();
                } else {
                  // নতুন রুম আইডি তৈরি
                  finalRoomId = (100000 + (DateTime.now().millisecondsSinceEpoch % 899999)).toString();
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                    'myRoomId': finalRoomId,
                    'lastLogin': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
                }
              } catch (e) {
                debugPrint("Firestore Error: $e");
                finalRoomId = "temp_${user.uid.substring(0, 5)}";
              }
            } else {
              finalRoomId = "public_room_$index";
            }

            if (!mounted) return;
            
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
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(15),
        border: type == "my_room" ? Border.all(color: Colors.pinkAccent.withOpacity(0.5), width: 1.5) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == "my_room" ? Icons.stars : Icons.meeting_room,
            color: type == "my_room" ? Colors.amber : Colors.pinkAccent,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            type == "my_room" ? "My Room" : "Public Room ${index + 1}",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
