import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart'; // রিয়েল-টাইম ডাটার জন্য
import 'screens/voice_room.dart'; 

// গ্লোবাল ভেরিয়েবল যাতে রুমের বাইরে আসলেও ভাসমান বাবল দেখানো যায়
String? activeRoomId;
String? activeRoomName;

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
      body: Stack(
        children: [
          Column(
            children: [
              _buildBanner(), // আপনার অরিজিনাল বড় ব্যানার
              const SizedBox(height: 15),
              _buildFeaturedRooms(), // আপনার অরিজিনাল ফিচারড রুম
              const SizedBox(height: 15),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLiveRoomList(), // ১. শুধু একটিভ ইউজার থাকা রুম
                    _buildFollowingRoomList(), // ২. ফলো করা রুম + কাউন্ট
                    _buildMyRoomList(), // ৩. নিজের রুম + এডমিন রুম
                  ],
                ),
              ),
            ],
          ),
          // 🛡️ ভাসমান লাইভ ইন্ডিকেটর (যদি ইউজার কোন রুমে থাকে)
          if (activeRoomId != null) _buildFloatingLiveStatus(),
        ],
      ),
    );
  }

  // --- প্রিমিয়াম ব্যানার ফিচার (আপনার অরিজিনাল কোড) ---
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

  // --- ফিচারড রুম সেকশন (আপনার অরিজিনাল কোড) ---
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

  // --- ১. লাইভ রুম গ্রিড (শুধু একটিভ রুমগুলো দেখাবে) ---
  Widget _buildLiveRoomList() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('rooms').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Center(child: Text("No Live Rooms", style: TextStyle(color: Colors.white54)));
        }
        Map<dynamic, dynamic> rooms = snapshot.data!.snapshot.value as Map;
        List<Map<String, dynamic>> activeRooms = [];

        rooms.forEach((key, value) {
          var seats = value['seats'] as Map?;
          if (seats != null) {
            activeRooms.add({
              'id': key,
              'name': value['roomName'] ?? "Public Room",
              'count': seats.length,
            });
          }
        });

        if (activeRooms.isEmpty) return const Center(child: Text("সব রুম খালি", style: TextStyle(color: Colors.white54)));

        return _buildGenericGrid(activeRooms, "live");
      },
    );
  }

  // --- ২. ফলোয়িং রুম লিস্ট (রিয়েল টাইম কাউন্ট সহ) ---
  Widget _buildFollowingRoomList() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        List followedIds = (snapshot.data?.data()?['following'] ?? []);
        
        return StreamBuilder(
          stream: FirebaseDatabase.instance.ref('rooms').onValue,
          builder: (context, dbSnapshot) {
            Map rooms = (dbSnapshot.data?.snapshot.value as Map?) ?? {};
            List<Map<String, dynamic>> followedRooms = [];

            for (var id in followedIds) {
              var data = rooms[id.toString()];
              followedRooms.add({
                'id': id,
                'name': data?['roomName'] ?? "Room $id",
                'count': (data?['seats'] as Map?)?.length ?? 0,
              });
            }
            return _buildGenericGrid(followedRooms, "following");
          },
        );
      },
    );
  }

  // --- ৩. মাই রুম এবং এডমিন রুম লজিক ---
  Widget _buildMyRoomList() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return FutureBuilder(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        String? myRoomId = snapshot.data?.data()?['myRoomId'];
        List<Map<String, dynamic>> myRooms = [];
        
        if (myRoomId != null) {
          myRooms.add({'id': myRoomId, 'name': "My Room", 'count': 0});
        }
        // এখানে আপনি চাইলে আপনার এডমিন রুমগুলোও কুয়েরি করে অ্যাড করতে পারেন
        return _buildGenericGrid(myRooms, "my_room");
      },
    );
  }

  // --- কমন গ্রিড বিল্ডার (আপনার অরিজিনাল কার্ড ডিজাইন বজায় রেখে) ---
  Widget _buildGenericGrid(List<Map<String, dynamic>> roomList, String type) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1,
      ),
      itemCount: roomList.length,
      itemBuilder: (context, index) {
        var room = roomList[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              activeRoomId = room['id'];
              activeRoomName = room['name'];
            });
            Navigator.push(context, MaterialPageRoute(builder: (context) => VoiceRoom(roomId: room['id'])));
          },
          child: _buildRoomCardWithCount(room['name'], room['count'], type),
        );
      },
    );
  }

  // --- আপনার অরিজিনাল কার্ড ডিজাইনে কাউন্ট যুক্ত করা ---
  Widget _buildRoomCardWithCount(String name, int count, String type) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(15),
        border: type == "my_room" ? Border.all(color: Colors.pinkAccent.withOpacity(0.5), width: 1.5) : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type == "my_room" ? Icons.stars : Icons.meeting_room,
                  color: type == "my_room" ? Colors.amber : Colors.pinkAccent,
                  size: 30,
                ),
                const SizedBox(height: 10),
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // রিয়েল টাইম মেম্বার কাউন্ট ব্যাজ
          if (type != "my_room")
            Positioned(
              top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 12, color: Colors.greenAccent),
                    Text(" $count", style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- ভাসমান লাইভ বাবল (Floating UI) ---
  Widget _buildFloatingLiveStatus() {
    return Positioned(
      bottom: 20, right: 20,
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VoiceRoom(roomId: activeRoomId!))),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.pinkAccent,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
          ),
          child: const Icon(Icons.multitrack_audio_sharp, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
