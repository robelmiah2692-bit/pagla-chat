import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart'; // রিয়েল-টাইম ডাটার জন্য
import 'screens/voice_room.dart'; 

// গ্লোবাল ভেরিয়েবল যাতে রুমের বাইরে আসলেও ভাসমান বাবল দেখানো যায়
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
              _buildBanner(), // আপনার অরিজিনাল বড় ব্যানার
              const SizedBox(height: 15),
              _buildFeaturedRooms(), // আপনার অরিজিনাল ফিচারড রুম
              const SizedBox(height: 15),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLiveRoomList(), // ১. লাইভ রুম গ্রিড
                    _buildFollowingRoomList(), // ২. ফলো করা রুম
                    _buildMyRoomList(), // ৩. নিজের রুম
                  ],
                ),
              ),
            ],
          ),
          // 🛡️ ভাসমান লাইভ ইন্ডিকেটর
          if (activeRoomId != null) _buildFloatingLiveStatus(),
        ],
      ),
    );
  }

  // --- প্রিমিয়াম ব্যানার ফিচার (অক্ষত রাখা হয়েছে) ---
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

  // --- ফিচারড রুম সেকশন (অক্ষত রাখা হয়েছে) ---
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

  // --- ১. লাইভ রুম গ্রিড (সচল করা হয়েছে) ---
  Widget _buildLiveRoomList() {
    return StreamBuilder<QuerySnapshot>(
      // Firestore থেকে সরাসরি রুমগুলো লোড করা হচ্ছে
      stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("সব রুম খালি", style: TextStyle(color: Colors.white54)));

        List<Map<String, dynamic>> activeRooms = docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': data['roomName'] ?? "Public Room",
            'count': data['userCount'] ?? 0,
          };
        }).toList();

        return _buildGenericGrid(activeRooms, "live");
      },
    );
  }

  // --- ২. ফলোয়িং রুম লিস্ট (সচল করা হয়েছে) ---
  Widget _buildFollowingRoomList() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var userData = snapshot.data?.data() as Map<String, dynamic>?;
        List followedIds = userData?['following'] ?? [];
        
        if (followedIds.isEmpty) {
          return const Center(child: Text("কাউকে ফলো করা নেই", style: TextStyle(color: Colors.white54)));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rooms')
              .where(FieldPath.documentId, whereIn: followedIds)
              .snapshots(),
          builder: (context, roomSnapshot) {
            if (!roomSnapshot.hasData) return const SizedBox();
            
            List<Map<String, dynamic>> followedRooms = roomSnapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                'name': data['roomName'] ?? "Room",
                'count': data['userCount'] ?? 0,
              };
            }).toList();

            return _buildGenericGrid(followedRooms, "following");
          },
        );
      },
    );
  }

  // --- ৩. মাই রুম লিস্ট (অক্ষত রাখা হয়েছে) ---
  Widget _buildMyRoomList() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var userData = snapshot.data?.data() as Map<String, dynamic>?;
        String? myRoomId = userData?['myRoomId'];
        List<Map<String, dynamic>> myRooms = [];
        
        if (myRoomId != null) {
          myRooms.add({'id': myRoomId, 'name': "My Room", 'count': 0});
        }
        return _buildGenericGrid(myRooms, "my_room");
      },
    );
  }

  // --- কমন গ্রিড বিল্ডার (ডিজাইন অক্ষত রাখা হয়েছে) ---
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

  // --- কার্ড ডিজাইন (অক্ষত রাখা হয়েছে) ---
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

  // --- ভাসমান বাবল (অক্ষত রাখা হয়েছে) ---
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
