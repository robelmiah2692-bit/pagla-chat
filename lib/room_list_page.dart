import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'dart:math'; // ইউনিক আইডির জন্য
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
    "https://images.unsplash.com/photo-1493225255756-d9584f8606e9?w=500",
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

  // --- নতুন রুম তৈরির লজিক (ইউনিক ৫ ডিজিট আইডি এবং ownerId সহ) ---
  Future<void> _createNewRoomLogic(String roomName) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // ইউনিক ৫ ডিজিট আইডি তৈরি (যেমন: ৪২১৮৪)
    String newUniqueRoomId = (10000 + Random().nextInt(90000)).toString();

    try {
      // .doc(newUniqueRoomId) দিয়ে ডকুমেন্ট আইডি সেট করা হলো
      await FirebaseFirestore.instance.collection('rooms').doc(newUniqueRoomId).set({
        'roomId': newUniqueRoomId,
        'roomName': roomName,
        'ownerId': uid, // এখন থেকে সব জায়গায় ownerId ব্যবহার হবে
        'userCount': 1,
        'isLive': true,
        'admins': [], // মালিক এডমিন লিস্টে থাকবে না
        'createdAt': FieldValue.serverTimestamp(),
        'roomImage': defaultRoomImages[DateTime.now().millisecond % defaultRoomImages.length],
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("রুম সফলভাবে তৈরি হয়েছে!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ভুল হয়েছে: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  // --- নতুন রুম বানানোর ডায়ালগ ---
  void _showCreateRoomDialog() {
    TextEditingController roomNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151525),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("নতুন রুম তৈরি করুন", style: TextStyle(color: Colors.white, fontSize: 18)),
        content: TextField(
          controller: roomNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "রুমের নাম দিন...",
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.pinkAccent.withOpacity(0.5))),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.pinkAccent)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("বাতিল", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            onPressed: () {
              if (roomNameController.text.trim().isNotEmpty) {
                _createNewRoomLogic(roomNameController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("তৈরি করুন", style: TextStyle(color: Colors.white)),
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

  // --- ২. ফলোয়িং রুম লিস্ট (uid এবং uID সাপোর্টেড লজিক) ---
  Widget _buildFollowingRoomList() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const SizedBox();
        var userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        
        // আপনার ডাটাবেস অনুযায়ী followerList বা following চেক করবে
        List followedIds = userData?['following'] ?? userData?['followerList'] ?? [];

        if (followedIds.isEmpty) {
          return const Center(child: Text("কাউকে ফলো করা নেই", style: TextStyle(color: Colors.white38)));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rooms')
              .where('ownerId', whereIn: followedIds)
              .snapshots(),
          builder: (context, roomSnapshot) {
            if (!roomSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
            if (roomSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text("ফলো করা কেউ এখন লাইভে নেই", style: TextStyle(color: Colors.white38)));
            }
            return _buildGrid(roomSnapshot.data!.docs);
          },
        );
      },
    );
  }

  // --- ৩. মাই রুম লিস্ট (পুরাতন ডাটাবেস এর uid/uID ফিক্স সহ) ---
  Widget _buildMyRoomList() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text("লগইন করুন"));

    return StreamBuilder<QuerySnapshot>(
      // এখানে সব ধরণের মালিকের আইডি ফিল্ড চেক করার জন্য ওনার লজিক রাখা হয়েছে
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('ownerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
        
        var docs = snapshot.data!.docs;

        if (docs.isNotEmpty) {
          return _buildGrid(docs, isMyRoom: true);
        }

        // যদি ownerId দিয়ে না পাওয়া যায়, তবে adminId দিয়ে চেক করবে (পুরাতন রুমের জন্য)
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rooms')
              .where('adminId', isEqualTo: uid)
              .snapshots(),
          builder: (context, oldSnapshot) {
            if (oldSnapshot.hasData && oldSnapshot.data!.docs.isNotEmpty) {
              return _buildGrid(oldSnapshot.data!.docs, isMyRoom: true);
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.meeting_room_outlined, color: Colors.white12, size: 80),
                  const SizedBox(height: 15),
                  const Text("আপনার কোনো রুম নেই", style: TextStyle(color: Colors.white38)),
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
          }
        );
      },
    );
  }

  // --- গ্রিড এবং কার্ড ডিজাইন ---
  Widget _buildGrid(List<DocumentSnapshot> docs, {bool isMyRoom = false}) {
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

        return _buildPremiumGlassCard(roomId, name, count, image, isMyRoom);
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
              color: isMyRoom ? Colors.pinkAccent.withOpacity(0.5) : Colors.white.withOpacity(0.1), 
              width: isMyRoom ? 2.0 : 1.5
            ),
            image: DecorationImage(image: NetworkImage(finalImage), fit: BoxFit.cover, opacity: 0.5),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: isMyRoom ? Colors.pinkAccent.withOpacity(0.05) : Colors.black.withOpacity(0.3),
              padding: const EdgeInsets.all(12),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(isMyRoom ? "মালিক মোড" : "লাইভ", 
                        style: TextStyle(color: isMyRoom ? Colors.cyanAccent : Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 12, color: Colors.greenAccent),
                          Text(" $count", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  if (isMyRoom)
                    const Positioned(
                      top: 0, left: 0,
                      child: Icon(Icons.stars, color: Colors.amber, size: 18),
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
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 10)],
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("পাগলা আড্ডায় জয়েন হও", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("আড্ডা দাও মন খুলে", style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesSection() {
    final List<Map<String, dynamic>> games = [
      {"name": "Ludo", "icon": Icons.casino, "color": Colors.orange},
      {"name": "Spin", "icon": Icons.ads_click, "color": Colors.blue},
      {"name": "Lucky Fruit", "icon": Icons.apple, "color": Colors.redAccent},
      {"name": "Crazy Super", "icon": Icons.bolt, "color": Colors.yellow},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Text("Games", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 85,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: games.length,
            itemBuilder: (context, index) {
              return Container(
                width: 85,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(games[index]['icon'], color: games[index]['color'], size: 28),
                    const SizedBox(height: 5),
                    Text(games[index]['name'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
        scale: Tween(begin: 1.0, end: 1.2).animate(_bubbleController),
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VoiceRoom(roomId: activeRoomId!))),
          child: Container(
            width: 65, height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.pinkAccent, width: 2),
              boxShadow: [BoxShadow(color: Colors.pinkAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)],
              image: DecorationImage(image: NetworkImage(activeRoomImage ?? defaultRoomImages[0]), fit: BoxFit.cover),
            ),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.multitrack_audio, size: 12, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
