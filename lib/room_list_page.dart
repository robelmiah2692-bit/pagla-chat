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
    if (user == null || user.email == null) return;

    try {
      // ১. ইমেইল দিয়ে ইউজারের ৬-ডিজিটের uID এবং ডাটা সংগ্রহ
      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email) // ইমেইল দিয়ে সার্চ
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Dont find user!"), backgroundColor: Colors.red),
          );
        }
        return;
      }

      var userData = userQuery.docs.first.data();
      String mySixDigitID = userData['uID']?.toString() ?? "";
      String currentUserName = userData['name'] ?? "Pagla User";
      String currentUserPic = userData['profilePic'] ?? "";
      String authuID = user.uid; // ফায়ারবেস অথ আইডি

      if (mySixDigitID.isEmpty) return;

      // ২. ইউজার কি আগে রুম বানিয়েছে? (লিমিট চেক)
      var existingRoom = await FirebaseFirestore.instance
          .collection('rooms')
          .where('ownerId', isEqualTo: mySixDigitID)
          .limit(1)
          .get();

      if (existingRoom.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Alrady you have room!"), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      // ৩. ইউনিক ৫ ডিজিটের রুম আইডি জেনারেশন
      String newUniqueRoomId = "";
      bool isUnique = false;
      while (!isUnique) {
        newUniqueRoomId = (10000 + Random().nextInt(90000)).toString();
        var roomCheck = await FirebaseFirestore.instance.collection('rooms').doc(newUniqueRoomId).get();
        if (!roomCheck.exists) isUnique = true;
      }

      // ৪. রুমের মেইন ডাটা সেভ
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(newUniqueRoomId);
      
      await roomRef.set({
        'roomId': newUniqueRoomId,
        'roomName': roomName,
        'ownerId': mySixDigitID,      // ৬-ডিজিটের আইডি
        'ownerAuthId': authuID,       // অথ আইডি ব্যাকআপ
        'ownerName': currentUserName,
        'ownerPic': currentUserPic,
        'userCount': 1,
        'isLive': true,
        'role': 'owner',
        'admins': [],
        'followers': [],
        'createdAt': FieldValue.serverTimestamp(),
        'roomImage': defaultRoomImages[Random().nextInt(defaultRoomImages.length)],
      });

      // ৫. সিট লিস্ট জেনারেট (১৫টি খালি সিট শুরুতেই তৈরি হবে)
      final seatsRef = roomRef.collection('seats');
      for (int i = 0; i < 15; i++) {
        await seatsRef.doc(i.toString()).set({
          'index': i,
          'isOccupied': false,
          'userId': '',
          'uID': '',
          'name': '',
          'profilePic': '',
          'status': 'empty',
          'isMicOn': false,
          'isTalking': false,
          'userFrame': '',
        });
      }

      // ৬. ভিউয়ার লিস্ট ইনিশিয়ালাইজ (ওনারকে প্রথম ভিউয়ার হিসেবে রাখা)
      await roomRef.collection('viewers').doc(mySixDigitID).set({
        'uID': mySixDigitID,
        'name': currentUserName,
        'profilePic': currentUserPic,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rady your room!"), backgroundColor: Colors.green),
        );
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
        title: const Text("Create Your Fixed Room", style: TextStyle(color: Colors.white, fontSize: 18)),
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
      // একদম নিচের লেয়ারের ব্যাকগ্রাউন্ড
      backgroundColor: const Color(0xFF02020A), 
      appBar: AppBar(
        // অ্যাপবারকে একটু বেগুনি আভাযুক্ত ডার্ক করা হয়েছে
        backgroundColor: const Color(0xFF0A0A25),
        elevation: 0,
        title: const Text("𝐏𝐚𝐠𝐥𝐚𝐂𝐡𝐚𝐭🥳𝐋𝐢𝐯𝐞ღ`◕‿♫", style: TextStyle(color: Color.fromARGB(255, 226, 242, 5), fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purpleAccent, // ছবির বেগুনি থিমের সাথে মিল রেখে
          labelColor: Colors.purpleAccent,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: "Live Room"),
            Tab(text: "Following"),
            Tab(text: "My Room"),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // ছবিগুলোর মতো পার্পেল ও নেভি ব্লু গ্রেডিয়েন্ট
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29), // গাঢ় নীল
              Color(0xFF302B63), // বেগুনি আভা
              Color(0xFF24243E), // নেভি ব্লু
            ],
          ),
        ),
        child: Stack(
          children: [
            // ১. ছবির মতো নেবুলা ইফেক্ট (হালকা ঝাপসা কালার প্যাচ)
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purple.withOpacity(0.2),
                  boxShadow: [
                    BoxShadow(color: Colors.purpleAccent.withOpacity(0.1), blurRadius: 100, spreadRadius: 50)
                  ],
                ),
              ),
            ),

            // ২. গ্যালাক্সি তারা (Glowing Stars) - ছবির মতো ছড়িয়ে ছিটিয়ে থাকা
            ...List.generate(50, (index) {
              double size = Random().nextDouble() * 2.5;
              return Positioned(
                top: Random().nextDouble() * MediaQuery.of(context).size.height,
                left: Random().nextDouble() * MediaQuery.of(context).size.width,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(Random().nextDouble()),
                    boxShadow: [
                      BoxShadow(
                        color: index % 7 == 0 ? Colors.purpleAccent : Colors.white70,
                        blurRadius: index % 10 == 0 ? 4 : 0,
                        spreadRadius: 0.5,
                      )
                    ],
                  ),
                ),
              );
            }),

            // ৩. ওপর থেকে আলোর বৃষ্টি (Light Strings) - আপনার প্রথম ছবির স্টাইল
            ...List.generate(12, (index) => Positioned(
              top: -10,
              left: (index * 45.0) % MediaQuery.of(context).size.width,
              child: Container(
                width: 1.2,
                height: 100 + (index * 15.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blueAccent.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            )),

            // মেইন কন্টেন্ট লেয়ার
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Login to see following", style: TextStyle(color: Colors.white38)));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('followers', arrayContains: user.uid) 
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return const Center(child: Text("Please Login", style: TextStyle(color: Colors.white)));

    return FutureBuilder<QuerySnapshot>(
      // এখানেও ইমেইল দিয়ে uID খোঁজার রাস্তা রাখা হয়েছে
      future: FirebaseFirestore.instance.collection('users').where('email', isEqualTo: user.email).limit(1).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
        if (userSnapshot.data!.docs.isEmpty) return const Center(child: Text("User profile not found"));

        String myuID = userSnapshot.data!.docs.first['uID'].toString();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('rooms').where('ownerId', isEqualTo: myuID).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
            var myRooms = snapshot.data!.docs;

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
      },
    );
  }

  Widget _buildGrid(List<DocumentSnapshot> docs, {bool isMyRoomList = false}) {
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
        
        return _buildPremiumGlassCard(roomId, name, count, image, isMyRoomList);
      },
    );
  }

 Widget _buildPremiumGlassCard(String id, String name, int count, String? image, bool isMyRoom) {
    String finalImage = (image != null && image.isNotEmpty) ? image : defaultRoomImages[0];

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
            // এখানে ছবির opacity বাড়িয়ে ০.৯ বা ১.০ করে দিন যাতে পরিষ্কার দেখা যায়
            image: DecorationImage(
              image: NetworkImage(finalImage), 
              fit: BoxFit.cover, 
              opacity: 0.9 // ০.৬ থেকে বাড়িয়ে ০.৯ করা হলো
            ),
          ),
          child: Container(
            // BackdropFilter বাদ দেওয়া হয়েছে যাতে ছবি ঝাপসা না হয়
            decoration: BoxDecoration(
              // ছবির ওপর হালকা একটি গ্রাডিয়েন্ট শ্যাডো যাতে নিচের লেখা স্পষ্ট হয়
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
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
                      style: TextStyle(color: isMyRoom ? Colors.amberAccent : Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold)),
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
      child: const Padding(
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
