import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'dart:math'; 
import 'screens/voice_room.dart';

// গ্লোবাল ভেরিয়েবল
String? activeRoomId;
String? activeRoomName;
String? activeRoomImage;

class RoomListPage extends StatefulWidget {
  const RoomListPage({super.key});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _bubbleController;

  final List<String> defaultRoomImages = [
    "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500",
    "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500",
    "https://images. Rossi-1493225255756-d9584f8606e9?w=500",
    "https://images.unsplash.com/photo-1514525253361-bee87187046c?w=500",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bubbleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  // --- নতুন রুম তৈরির লজিক ---
   Future<void> _createNewRoomLogic(String roomName) async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    // ১. ইউজারের ডাটাবেস থেকে তার ৬-ডিজিটের uID এবং নাম সংগ্রহ
    // যেহেতু আপনার ডাটাবেস এখন ৬-ডিজিটের আইডিতে (বা authUID দিয়ে সার্চ করতে হয়)
    var userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('authUID', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) return; // ইউজার প্রোফাইল না থাকলে রুম খোলা যাবে না

    var userData = userQuery.docs.first.data();
    String mySixDigitID = userData['uID'] ?? ""; // আপনার সেই ৬ ডিজিটের আইডি
    String currentUserName = userData['name'] ?? "Pagla User";

    // ২. একদম ইউনিক ৫ বা ৬ ডিজিটের রুম আইডি জেনারেশন (লুপ ব্যবহার করে)
    String newUniqueRoomId = "";
    bool isUnique = false;
    
    while (!isUnique) {
      newUniqueRoomId = (10000 + Random().nextInt(90000)).toString(); // ৫ ডিজিট
      var roomCheck = await FirebaseFirestore.instance.collection('rooms').doc(newUniqueRoomId).get();
      if (!roomCheck.exists) isUnique = true;
    }

    // ৩. রুম ডাটা সেভ
    await FirebaseFirestore.instance.collection('rooms').doc(newUniqueRoomId).set({
      'roomId': newUniqueRoomId,
      'roomName': roomName,
      'ownerId': mySixDigitID,      // হিজিবিজি আইডি না, আপনার ইউনিক uID
      'ownerName': currentUserName,
      'userCount': 1,               // মালিক নিজে জয়েন করবে তাই ১
      'isLive': true,
      'role': 'owner',              // ওনার হিসেবে সেভ
      'admins': [], 
      'followers': [],
      'createdAt': FieldValue.serverTimestamp(),
      'roomImage': defaultRoomImages[Random().nextInt(defaultRoomImages.length)],
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("রুম তৈরি হয়েছে!"), backgroundColor: Colors.green),
      );
      // এখানে রুম পেজে নেভিগেট করার কোড লিখুন
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }
}

  void _showCreateRoomDialog() {
    TextEditingController roomNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151525),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Create New Room", style: TextStyle(color: Colors.white, fontSize: 18)),
        content: TextField(
          controller: roomNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter room name...",
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.pinkAccent.withOpacity(0.5))),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.pinkAccent)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            onPressed: () {
              if (roomNameController.text.trim().isNotEmpty) {
                _createNewRoomLogic(roomNameController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("Create", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        elevation: 0,
        title: const Text("Pagla Chat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.pinkAccent,
          labelColor: Colors.pinkAccent,
          unselectedLabelColor: Colors.white38,
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
              _buildBanner(),
              _buildGamesSection(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLiveRoomList(),
                    _buildFollowingRoomList(),
                    _buildMyRoomList(),
                  ],
                ),
              ),
            ],
          ),
          if (activeRoomId != null) _buildFloatingHeartbeatBubble(),
        ],
      ),
    );
  }

  Widget _buildLiveRoomList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
        var docs = snapshot.data!.docs;
        return _buildGrid(docs);
      },
    );
  }

  Widget _buildFollowingRoomList() {
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return const Center(child: Text("Login to see following", style: TextStyle(color: Colors.white38)));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('followers', arrayContains: myUid) 
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No rooms followed", style: TextStyle(color: Colors.white38)));
        return _buildGrid(docs);
      },
    );
  }

  Widget _buildMyRoomList() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text("Please Login", style: TextStyle(color: Colors.white)));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
        
        var myRooms = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return (data['ownerId'] == uid || data['uID'] == uid);
        }).toList();

        if (myRooms.isNotEmpty) {
          return _buildGrid(myRooms, isMyRoomList: true);
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.meeting_room_outlined, color: Colors.white12, size: 80),
              const SizedBox(height: 15),
              const Text("You don't have any room", style: TextStyle(color: Colors.white38)),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: _showCreateRoomDialog,
                icon: const Icon(Icons.add),
                label: const Text("Create Your Room"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid(List<DocumentSnapshot> docs, {bool isMyRoomList = false}) {
    final String? currentUID = FirebaseAuth.instance.currentUser?.uid;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        var data = docs[index].data() as Map<String, dynamic>;
        String roomId = data['roomId'] ?? docs[index].id;
        String name = data['roomName'] ?? "Public Room";
        int count = data['userCount'] ?? 0;
        String? image = data['roomImage'];
        
        bool isCardOwner = (data['ownerId'] == currentUID || data['uID'] == currentUID);

        return _buildPremiumGlassCard(roomId, name, count, image, isCardOwner);
      },
    );
  }

  Widget _buildPremiumGlassCard(String id, String name, int count, String? image, bool isMyRoom) {
    String finalImage = (image != null && image.isNotEmpty) ? image : defaultRoomImages[id.hashCode % defaultRoomImages.length];

    return GestureDetector(
      onTap: () {
        setState(() {
          activeRoomId = id;
          activeRoomName = name;
          activeRoomImage = finalImage;
        });
        Navigator.push(context, MaterialPageRoute(builder: (context) => VoiceRoom(roomId: id)));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isMyRoom ? Colors.amber.withOpacity(0.8) : Colors.white.withOpacity(0.1), 
              width: isMyRoom ? 2.5 : 1.5
            ),
            image: DecorationImage(image: NetworkImage(finalImage), fit: BoxFit.cover, opacity: 0.6),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              color: isMyRoom ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.4),
              padding: const EdgeInsets.all(12),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(isMyRoom ? "MY ROOM" : "LIVE", 
                        style: TextStyle(color: isMyRoom ? Colors.amberAccent : Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 12, color: Colors.greenAccent),
                          Text(" $count", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  // ওনার আইডি জেনারেট হলে স্টার আইকন দেখাবে
                  if (isMyRoom)
                    const Positioned(
                      top: 0, left: 0,
                      child: Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.all(15),
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
      ),
      child: Stack(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Pagla Chat World", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Connect with voice & fun", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Positioned(
            right: -10, bottom: -10,
            child: Icon(Icons.rocket_launch, size: 80, color: Colors.white.withOpacity(0.1)),
          )
        ],
      ),
    );
  }

  Widget _buildGamesSection() {
    final List<Map<String, dynamic>> games = [
      {"name": "Ludo", "icon": Icons.casino, "color": Colors.orange},
      {"name": "Spin", "icon": Icons.ads_click, "color": Colors.blue},
      {"name": "Fruit", "icon": Icons.apple, "color": Colors.redAccent},
      {"name": "Bolt", "icon": Icons.bolt, "color": Colors.yellow},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Text("Fun Zone", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: games.length,
            itemBuilder: (context, index) {
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(games[index]['icon'], color: games[index]['color'], size: 24),
                    const SizedBox(height: 5),
                    Text(games[index]['name'], style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildFloatingHeartbeatBubble() {
    return Positioned(
      bottom: 30, right: 20,
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.15).animate(_bubbleController),
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VoiceRoom(roomId: activeRoomId!))),
          child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.pinkAccent, width: 2),
              boxShadow: [BoxShadow(color: Colors.pinkAccent.withOpacity(0.4), blurRadius: 12)],
              image: DecorationImage(image: NetworkImage(activeRoomImage ?? defaultRoomImages[0]), fit: BoxFit.cover),
            ),
            child: const Center(
              child: Icon(Icons.multitrack_audio, size: 20, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
