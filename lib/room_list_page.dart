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

class _RoomListPageState extends State<RoomListPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _bubbleController;
  late AnimationController _colorAnimationController;
  late Animation<Color?> _colorTween;
  String? currentLoggedInUID;
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

    // 🇧🇩 [বাংলা মার্ক - অটো কালার চেঞ্জিং অ্যানিমেশন শুরু]:
    // অ্যাপবারের টেক্সট ৩ সেকেন্ড পর পর অটো স্মুথ কালার চেঞ্জ করার জন্য কন্ট্রোলার ভাই
    _colorAnimationController = AnimationController(
      duration: const Duration(seconds: 3), 
      vsync: this,
    )..repeat(reverse: true); // কালার লুপ আকারে চলতেই থাকবে

    // 🎨 আপনার সেই হলুদ কালার থেকে নিয়ন স্কাই ব্লু কালারের ট্রানজিশন
    _colorTween = ColorTween(
      begin: const Color.fromARGB(255, 226, 242, 5), 
      end: Colors.cyanAccent, 
    ).animate(_colorAnimationController);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bubbleController.dispose();
    
    // 🇧🇩 [বাংলা মার্ক - মেমোরি ক্লিনআপ]:
    // অ্যাপবারের কালার অ্যানিমেশন কন্ট্রোলারটি মেমোরি থেকে সম্পূর্ণ রিলিজ করে দেওয়া হলো ভাই
    _colorAnimationController.dispose(); 
    
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
            const SnackBar(
                content: Text("Dont find user!"), backgroundColor: Colors.red),
          );
        }
        return;
      }

      var userData = userQuery.docs.first.data();
      String mySixDigitID = userData['uID']?.toString() ?? "";
      String currentUserName = userData['name'] ?? "Pagla User";
      String currentUserPic = userData['profilePic'] ?? "";
      String authUID = user.uid; // ফায়ারবেস অথ আইডি
      String currentUserFrame = userData['activeFrameUrl'] ?? "";
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
            const SnackBar(
                content: Text("Alrady you have room!"),
                backgroundColor: Colors.orange),
          );
        }
        return;
      }

      // ৩. ইউনিক ৫ ডিজিটের রুম আইডি জেনারেশন
      String newUniqueRoomId = "";
      bool isUnique = false;
      while (!isUnique) {
        newUniqueRoomId = (10000 + Random().nextInt(90000)).toString();
        var roomCheck = await FirebaseFirestore.instance
            .collection('rooms')
            .doc(newUniqueRoomId)
            .get();
        if (!roomCheck.exists) isUnique = true;
      }

      // ৪. রুমের মেইন ডাটা সেভ
      final roomRef =
          FirebaseFirestore.instance.collection('rooms').doc(newUniqueRoomId);

      await roomRef.set({
        'roomId': newUniqueRoomId,
        'roomName': roomName,
        'ownerId': mySixDigitID, // ৬-ডিজিটের আইডি
        'ownerAuthId': authUID, // অথ আইডি ব্যাকআপ
        'ownerName': currentUserName,
        'ownerPic': currentUserPic,
        'ownerFrame': currentUserFrame,
        'dailyPoints': 0,
        'userCount': 1,
        'isLive': true,
        'role': 'owner',
        'admins': [],
        'followers': [],
        'createdAt': FieldValue.serverTimestamp(),
        'roomImage':
            defaultRoomImages[Random().nextInt(defaultRoomImages.length)],
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Rady your room!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error: $e"), backgroundColor: Colors.redAccent),
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
        title: const Text("Create Your Fixed Room",
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: TextField(
          controller: roomNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter room name...",
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Colors.pinkAccent.withOpacity(0.5))),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.pinkAccent)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel",
                  style: TextStyle(color: Colors.white54))),
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
      backgroundColor: const Color(0xFF02020A),
      
     // 🧱 [appBar আপডেট]: আপনার হোম পেজের মতো হুবহু গ্লাস ক্যাপসুল ও রেনবো টেক্সট ডিজাইন
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A25),
        elevation: 0,
        centerTitle: true, // টাইটেলটি একদম মাঝখানে থাকবে ভাই
        
        // ✨ [গ্লাস ক্যাপসুল ডিজাইন]: হোম পেজের মতো সুন্দর রাউন্ড বর্ডার ও কাঁচের ব্যাকগ্রাউন্ড
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white.withOpacity(0.08), // হালকা সাদা গ্লাস অপাসিটি
            border: Border.all(
              color: Colors.white.withOpacity(0.15), // চারপাশের গ্লাস বর্ডার
              width: 1.2,
            ),
          ),
          
          // 🔮 [অটো কালার শিফটিং লজিক]: ShaderMask দিয়ে কালারগুলো লেখার ওপর দিয়ে নেচে বেড়াবে
          child: AnimatedBuilder(
            animation: _colorAnimationController, // আপনার তৈরি করা সেই কন্ট্রোলার
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: const [
                    Colors.amberAccent,
                    Colors.cyanAccent,
                    Colors.purpleAccent,
                    Colors.amberAccent
                  ],
                  stops: [
                    _colorAnimationController.value - 0.2,
                    _colorAnimationController.value,
                    _colorAnimationController.value + 0.2,
                    _colorAnimationController.value + 0.4
                  ],
                ).createShader(bounds),
                child: const Text(
                  "𝐏𝐚𝐠𝐥𝐚𝐂𝐡𝐚𝐭🥳𝐋𝐢𝐯𝐞ღ`◕‿♫",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.white, // ShaderMask এর কারণে এটি রেনবো কালার হয়ে যাবে
                    letterSpacing: 1.1,
                  ),
                ),
              );
            },
          ),
        ),
        
        // 📏 [ট্যাব বার ও নিচের গ্লাস বর্ডার]:
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              // আপনার হোম পেজের নিচের দিকের সেই সুন্দর চিকন কাঁচের বর্ডার রেখা ভাই
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.12), 
                  width: 1.2,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.purpleAccent, 
              labelColor: Colors.purpleAccent,
              unselectedLabelColor: Colors.white38,
              tabs: const [
                Tab(text: "Live Room"),
                Tab(text: "Following"),
                Tab(text: "My Room"),
              ],
            ),
          ),
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
                    BoxShadow(
                        color: Colors.purpleAccent.withOpacity(0.1),
                        blurRadius: 100,
                        spreadRadius: 50)
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
                        color: index % 7 == 0
                            ? Colors.purpleAccent
                            : Colors.white70,
                        blurRadius: index % 10 == 0 ? 4 : 0,
                        spreadRadius: 0.5,
                      )
                    ],
                  ),
                ),
              );
            }),

            // ৩. ওপর থেকে আলোর বৃষ্টি (Light Strings) - আপনার প্রথম ছবির স্টাইল
            ...List.generate(
                12,
                (index) => Positioned(
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
                     _buildFollowingRoomList(currentLoggedInUID),
                      _buildMyRoomList(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveRoomList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent));
        var docs = snapshot.data!.docs;
        return _buildGrid(docs);
      },
    );
  }

 // 🇧🇩 [বাংলা মার্ক]: নতুন ১০০% ফিক্সড ফলোইং রুম মেথড (কোনো আইডি লেট বা নাল প্রবলেম হবে না)
  Widget _buildFollowingRoomList(String? targetUID) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      return const Center(
          child: Text("Login to see following",
              style: TextStyle(color: Colors.white38)));
    }

    // 🎯 এখানে আমরা ডিরেক্ট FutureBuilder দিয়ে ইউজারের ইমেইল দিয়ে ফায়ারস্টোর থেকে তার uID (যেমন: 454488) ইনস্ট্যান্ট তুলে আনবো ভাই
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent));
        }

        if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("User profile not found", style: TextStyle(color: Colors.white38)));
        }

        // 🚀 ইউজারের আসল শর্ট uID (যেমন: "454488") সফলভাবে সংগৃহীত হলো ভাই
        String liveUserUID = userSnapshot.data!.docs.first['uID'].toString();
        
        debugPrint("🎉 [PaglaChat Master] ইনস্ট্যান্ট uID পাওয়া গেছে: $liveUserUID");

        // 🎯 এখন এই uID দিয়ে আমরা সরাসরি রুমের ফলোয়ার লিস্টের স্ট্রিম চালাবো
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rooms')
              .where('followers', arrayContains: liveUserUID)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.pinkAccent));
            }

            if (!snapshot.hasData) {
              return const Center(
                  child: Text("No data found", style: TextStyle(color: Colors.white38)));
            }

            var docs = snapshot.data!.docs;

            debugPrint("🎉 [PaglaChat Master] ফলো করা মোট রুম সংখ্যা: ${docs.length} টি");

            if (docs.isEmpty) {
              return const Center(
                  child: Text("No rooms followed",
                      style: TextStyle(color: Colors.white38)));
            }

            return _buildGrid(docs);
          },
        );
      },
    );
  }
  Widget _buildMyRoomList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null)
      return const Center(
          child: Text("Please Login", style: TextStyle(color: Colors.white)));

    return FutureBuilder<QuerySnapshot>(
      // এখানেও ইমেইল দিয়ে uID খোঁজার রাস্তা রাখা হয়েছে
      future: FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData)
          return const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent));
        if (userSnapshot.data!.docs.isEmpty)
          return const Center(child: Text("User profile not found"));

        String myuID = userSnapshot.data!.docs.first['uID'].toString();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rooms')
              .where('ownerId', isEqualTo: myuID)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(
                  child: CircularProgressIndicator(color: Colors.pinkAccent));
            var myRooms = snapshot.data!.docs;

            if (myRooms.isNotEmpty) {
              return _buildGrid(myRooms, isMyRoomList: true);
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.meeting_room_outlined,
                      color: Colors.white12, size: 80),
                  const SizedBox(height: 15),
                  const Text("You don't have any room",
                      style: TextStyle(color: Colors.white38)),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    onPressed: _showCreateRoomDialog,
                    icon: const Icon(Icons.add),
                    label: const Text("Create Your Room"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
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

  // 🇧🇩 [বাংলা মার্ক]: গ্রিড ভিউ মেথড
  Widget _buildGrid(List<DocumentSnapshot> docs, {bool isMyRoomList = false}) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
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

  // 🇧🇩 [বাংলা মার্ক - ১০০% লাইভ কাউন্ট, লাল/সবুজ ইন্ডিকেটর ও LIVE টেক্সট ফিক্সড]
  Widget _buildPremiumGlassCard(
      String id, String name, int count, String? image, bool isMyRoom) {
    String finalImage =
        (image != null && image.isNotEmpty) ? image : defaultRoomImages[0];

    return GestureDetector(
      onTap: () {
        setState(() {
          activeRoomId = id;
          activeRoomName = name;
          activeRoomImage = finalImage;
        });
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => VoiceRoom(roomId: id)));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: isMyRoom
                    ? Colors.amber.withOpacity(0.8)
                    : Colors.white.withOpacity(0.1),
                width: isMyRoom ? 2.5 : 1.5),
            image: DecorationImage(
                image: NetworkImage(finalImage),
                fit: BoxFit.cover,
                opacity: 0.9),
          ),
          child: Container(
            decoration: BoxDecoration(
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
                // 🇧🇩 বাম পাশের নিচে রুমের নাম ও টাইটেল
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(isMyRoom ? "MY ROOM" : "PAGLA LIVE",
                        style: TextStyle(
                            color: isMyRoom
                                ? Colors.amberAccent
                                : Colors.pinkAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),

                // 🎯 [ডান পাশের টপ কর্নার]: আপনার চাহিদামতো রিয়েল-টাইম লাইভ ইন্ডিকেটর লেআউট
                Positioned(
                  top: 0,
                  right: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // ১. কাউন্ট এবং ডায়নামিক লাল/সবুজ লাইট বক্স
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 🟢/🔴 লাইভ ইন্ডিকেটর: মানুষ থাকলে সবুজ (Green), ০ জন হলে লাল (Red)
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: count > 0 ? Colors.greenAccent : Colors.redAccent,
                            ),
                            const SizedBox(width: 5),
                            // লাইভ মানুষের আসল কাউন্ট সংখ্যা
                            Text("$count",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // ২. কাউন্টের ঠিক নিচে আপনার বলা সুন্দর 'LIVE' ব্যাজ টেক্সট
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: count > 0 ? Colors.red.withOpacity(0.85) : Colors.grey.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "LIVE",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (isMyRoom)
                  const Positioned(
                    top: 0,
                    left: 0,
                    child: Icon(Icons.workspace_premium,
                        color: Colors.amber, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🇧🇩 [বাংলা মার্ক - প্রিমিয়াম গ্লাস বর্ডার ও ওয়ার্ল্ড ম্যাপ আইকন ব্যানার ফিক্স]
  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // 🎨 আপনার স্ক্রিনশটের মতো নিখুঁত পার্পেল-ব্লু মিক্সড গ্রাডিয়েন্ট
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // ✨ [গ্লাস বর্ডার ইফেক্ট]: হালকা ও উজ্জ্বল নিয়ন শেডের মিক্স বর্ডার, যা গ্লাসের মতো রিফ্লেক্ট করবে
        border: Border.all(
          color: Colors.white.withOpacity(0.2), 
          width: 1.5,
        ),
        // হালকা নিয়ন গ্লো শ্যাডো
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E2DE2).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 🎯 ডান পাশের খালি জায়গায় ওয়ার্ল্ড ম্যাপ আইকন (আপনার স্ক্রিনশটের ডিজাইনের মতো)
          Positioned(
            right: 15,
            top: 0,
            bottom: 0,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // আইকনের পেছনের হালকা গ্লোয়িং কক্ষপথ সার্কেল
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  // 🌍 মূল ওয়ার্ল্ড ম্যাপ গ্লোয়িং আইকন
                  Icon(
                    Icons.public, // বিশ্ব মানচিত্রের আইকন
                    size: 48,
                    color: Colors.cyanAccent.withOpacity(0.75), // স্ক্রিনশটের মতো নিয়ন লাইট ব্লু শেড
                  ),
                ],
              ),
            ),
          ),

          // 📝 বাম পাশের টেক্সট এরিয়া
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Pagla Chat World",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    // টেক্সটের নিচে হালকা শ্যাডো যাতে প্রফেশনাল লাগে
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Connect with voice & fun",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85), 
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
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
          child: Text("Fun Zone",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
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
                    Icon(games[index]['icon'],
                        color: games[index]['color'], size: 24),
                    const SizedBox(height: 5),
                    Text(games[index]['name'],
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 10)),
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
}
