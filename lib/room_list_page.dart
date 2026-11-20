import 'dart:async';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pagla_chat/banner_feature_page.dart';
import 'package:pagla_chat/profile_page.dart';
import 'package:pagla_chat/services/search_helper.dart';
import 'package:pagla_chat/widgets/room_settings_handler.dart';
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
  final PageController _pageController = PageController();
  Timer? _timer;
  final List<String> _bannerUrls = [
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/roomlistbenar.jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/roomlistbenar2.jpg", // এখানে দ্বিতীয় লিংক বসান
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/daimondbenar.jpg", // এখানে তৃতীয় লিংক বসান
  ];

  late final Stream<QuerySnapshot> _topGiftersStream;
  List<QueryDocumentSnapshot> _cachedTopGifters = [];
  @override
  void initState() {
    super.initState();
    _topGiftersStream = FirebaseFirestore.instance
      .collection('users')
      .orderBy('totalSpent', descending: true)
      .limit(10)
      .snapshots();
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

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_pageController.page?.toInt() ?? 0) + 1;
        if (nextPage >= _bannerUrls.length) nextPage = 0;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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

      // ✅ ১৬০০০ এক্সপি চেক কন্ডিশনটি এখানে বাদ দেওয়া হয়েছে

      String mySixDigitID = userData['uID']?.toString() ?? "";
      String currentUserName = userData['name'] ?? "Pagla User";
      String currentUserPic = userData['profilePic'] ?? "";
      String authUID = user.uid; // ফায়ারবেস অথ আইডি
      String currentUserFrame = userData['activeFrameUrl'] ?? "";
      if (mySixDigitID.isEmpty) return;

      // ২. ইউজার কি আগে রুম বানিয়েছে? (লিমিট চেক)
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

      // ৩. ইউনিক ৬ ডিজিটের রুম আইডি জেনারেশন
      String newUniqueRoomId = "";
      bool isUnique = false;
      while (!isUnique) {
        newUniqueRoomId = (100000 + Random().nextInt(900000)).toString();
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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 🔥 ১. একদম নিচে পুরো স্ক্রিন জুড়ে অ্যাসেট ওয়ালপেপার ইমেজ (অ্যাপবার সহ পুরো পেইজে থাকবে)
          Positioned.fill(
            child: Image.asset(
              'assets/images/wallpaperlist.webp', // আপনার অ্যাসেট পাথ
              fit: BoxFit.cover,
            ),
          ),

          // ২. মূল লেআউট (AppBar এবং Body একসাথে সাজানো যাতে কোনো লেআউট ত্রুটি বা কালো স্ক্রিন না আসে)
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // কাস্টম AppBar-এর বিকল্প Container ডিজাইন (যাতে লেআউট সাইজ নিয়ে কোনো সমস্যা না হয়)
                Container(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // উপরের মেইন রো (Leading, Title, Actions)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // বাম দিকের অনলাইন ইউজারদের ৩টি ফ্রেম অবতার
                          SizedBox(
                            width:
                                162, // রিপেল যেন না কাটে তাই সামান্য বাড়ানো হয়েছে
                            height: 48,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6.0),
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .where('isOnline', isEqualTo: true)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  List<String> avatarUrls = [];
                                  if (snapshot.hasData &&
                                      snapshot.data!.docs.isNotEmpty) {
                                    for (var doc in snapshot.data!.docs) {
                                      var data =
                                          doc.data() as Map<String, dynamic>;
                                      if (data['profilePic'] != null &&
                                          data['profilePic']
                                              .toString()
                                              .isNotEmpty) {
                                        avatarUrls.add(data['profilePic']);
                                      }
                                    }
                                  }

                                  List<String> fallbackAvatars = [
                                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
                                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
                                    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
                                    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100',
                                  ];

                                  if (avatarUrls.length < 3) {
                                    avatarUrls.addAll(fallbackAvatars);
                                  }

                                  avatarUrls.shuffle();
                                  List<String> displayAvatars =
                                      avatarUrls.take(3).toList();

                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: displayAvatars
                                        .map((url) => RainbowRippleAvatar(
                                            imageUrl: url, size: 34))
                                        .toList(),
                                  );
                                },
                              ),
                            ),
                          ),
                          // মাঝখানের সার্চ বক্স (ইমেজ ডিজাইন)
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  _showSearchDialog(context);
                                },
                                child: Image.asset(
                                  'assets/images/search_bar.webp', // আপনার সার্চ ইমেজের পাথ
                                  height: 38,
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                          ),

                          // ডান দিকের রুম তৈরির ইমেজ বাটন
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: GestureDetector(
                              onTap: () {
                                _showCreateRoomDialog();
                              },
                              child: Image.asset(
                                'assets/images/create_room.webp', // আপনার ইমেজের সঠিক পাথ দিন
                                width: 42,
                                height: 42,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // নিচের ট্যাব বার (Live Room, Following, My Room)
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(4),
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1.0,
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.purpleAccent, Colors.cyanAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purpleAccent.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.white70,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 13,
                          ),
                          tabs: const [
                            Tab(
                              child: Align(
                                alignment: Alignment.center,
                                child: Text("Live Room"),
                              ),
                            ),
                            Tab(
                              child: Align(
                                alignment: Alignment.center,
                                child: Text("Following"),
                              ),
                            ),
                            Tab(
                              child: Align(
                                alignment: Alignment.center,
                                child: Text("My Room"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // বডির বাকি অংশ (Banner, Spenders, TabBarView)
                Expanded(
                  child: Column(
                    children: [
                      _buildBanner(),
                      _buildTopSpendersSection(),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// সাহায্যকারী সার্চ ডায়ালগ বা মেথড
  void _showSearchDialog(BuildContext context) {
    SearchHelper.showSearchDialog(context);
  }

  Widget _buildLiveRoomList() {
    return StreamBuilder<QuerySnapshot>(
      // এখানে 'where' ফিল্টার যোগ করা হয়েছে যা শুধুমাত্র isActive = true রুমগুলো আনবে
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("No live rooms at the moment",
                  style: TextStyle(color: Colors.white70)));
        }

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
              child: Text("User profile not found",
                  style: TextStyle(color: Colors.white38)));
        }

        // 🚀 ইউজারের আসল শর্ট uID (যেমন: "454488") সফলভাবে সংগৃহীত হলো ভাই
        String liveUserUID = userSnapshot.data!.docs.first['uID'].toString();

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
                  child: Text("No data found",
                      style: TextStyle(color: Colors.white38)));
            }

            var docs = snapshot.data!.docs;

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
          // পুরো কালেকশন থেকে ডাটা আনছি যেন ক্লায়েন্ট সাইডে ফিল্টার করতে পারি
          stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(
                  child: CircularProgressIndicator(color: Colors.pinkAccent));

            // এখানে ফিল্টার করছি: ইউজার কি owner? নাকি admin লিস্টে আছে?
            var myRooms = snapshot.data!.docs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String ownerId = data['ownerId']?.toString() ?? "";
              List<dynamic> admins = data['admins'] ?? [];
              List<String> adminList = admins.map((e) => e.toString()).toList();

              return ownerId == myuID || adminList.contains(myuID);
            }).toList();

            if (myRooms.isNotEmpty) {
              return _buildGrid(myRooms, isMyRoomList: true);
            }

            // রুম না থাকলে আগের ডিজাইনটিই দেখাবে
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

  // 🇧🇩 [বাংলা মার্ক]: লম্বা ব্যানার স্টাইল রুম লিস্ট মেথড
  Widget _buildGrid(List<DocumentSnapshot> docs, {bool isMyRoomList = false}) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        var data = docs[index].data() as Map<String, dynamic>;
        String roomId = data['roomId'] ?? docs[index].id;
        String name = data['roomName'] ?? "Public Room";
        int count = data['userCount'] ?? 0;
        String? image = data['roomImage'];
        String description = data['description'] ??
            "Welcome to this amazing voice room! Drop your mic and join the fun.";

        return _buildPremiumGlassCard(
            roomId, name, description, count, image, isMyRoomList);
      },
    );
  }

  // আপনার আগের কোডের জায়গায় এই নতুন প্রিমিয়াম লম্বা গ্লাস কার্ড ভার্সনটি ব্যবহার করুন
  Widget _buildPremiumGlassCard(String id, String name, String description,
      int count, String? image, bool isMyRoom) {
    String finalImage =
        (image != null && image.isNotEmpty) ? image : defaultRoomImages[0];

    // ডাটাবেস থেকে রিয়েল-টাইম আপডেট পাওয়ার জন্য StreamBuilder ব্যবহার করছি
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('rooms').doc(id).snapshots(),
      builder: (context, snapshot) {
        bool isLocked = false;
        String roomPassword = "";

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          isLocked = data['isLocked'] ?? false;
          roomPassword = data['password'] ?? "";
        }

        return GestureDetector(
          onTap: () {
            if (isLocked) {
              // লক থাকলে পাসওয়ার্ড চাইবে
              RoomSettingsHandler.showJoinPasswordDialog(
                  context, id, roomPassword, () {
                // সঠিক পাসওয়ার্ড দিলে রুমে ঢুকবে
                _navigateToRoom(id, name, finalImage);
              });
            } else {
              // লক না থাকলে সরাসরি ঢুকবে
              _navigateToRoom(id, name, finalImage);
            }
          },
          child: Container(
            height: 100, // লম্বা কার্ডের প্রিমিয়াম উচ্চতা
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  Colors.white.withOpacity(0.07), // গ্লাস ইফেক্ট ব্যাকগ্রাউন্ড
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isMyRoom
                    ? Colors.amber.withOpacity(0.8)
                    : Colors.white.withOpacity(0.15),
                width: isMyRoom ? 2.5 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // ১. রুমের গোল ছবি (ঘুরে ঘুরে রংধনু বর্ডার ও রিপেলসহ)
                RainbowBoxRippleAvatar(
                  imageUrl: finalImage,
                  size: 64,
                ),

                const SizedBox(width: 12),

                // ২. রুমের নাম, ডেসক্রিপশন ও অন্যান্য তথ্য
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // রুমের নাম, সবুজ/সোনালী স্ট্যাটাস টেক্সট ও লাইভ ইউজার কাউন্ট
                      Row(
                        children: [
                          if (isMyRoom)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(Icons.workspace_premium,
                                  color: Colors.amber, size: 14),
                            ),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // রুমের নামের পাশে সবুজ ব্লিংকিং ডট + LIVE + স্ট্রিমিং ওয়েভ এনিমেশন
                          LiveStatusBadge(isMyRoom: isMyRoom),
                          const SizedBox(width: 6),
                          // লাইভ ইউজার কাউন্ট ব্যাজ
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle,
                                    size: 8,
                                    color: count > 0
                                        ? Colors.greenAccent
                                        : Colors.redAccent),
                                const SizedBox(width: 4),
                                Text(
                                  "$count",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // ডেসক্রিপশন টেক্সট
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 9,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // নিচের অংশ (লক থাকলে শুধু লক আইকন/স্ট্যাটাস দেখাবে, পাবলিক রুম লেখা বাদ)
                      Row(
                        children: [
                          if (isLocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color:
                                        Colors.purpleAccent.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.lock,
                                    color: Colors.amber,
                                    size: 10,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Locked Room",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// রুমে নেভিগেট করার জন্য এই আলাদা মেথডটি তৈরি রাখুন
  void _navigateToRoom(String id, String name, String image) {
    setState(() {
      activeRoomId = id;
      activeRoomName = name;
      activeRoomImage = image;
    });
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => VoiceRoom(roomId: id)));
  }

  // ৪. ব্যানার বিল্ড ফাংশনটি এভাবে আপডেট করুন
  Widget _buildBanner() {
    return SizedBox(
      height: 100,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _bannerUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // যেকোনো ব্যানারে ক্লিক করলেই নতুন ট্যাব পেজ ওপেন হবে
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BannerFeaturePage(),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.amber.shade700,
                  width: 2,
                ),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(_bannerUrls[index]),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopSpendersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Text("Top Live Gifters",
              style: TextStyle(
                  color: Color.fromARGB(255, 6, 250, 209),
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        // গোল্ডেন ফ্রেম ব্যাকগ্রাউন্ড (লোকাল অ্যাসেট এবং webp ফরম্যাটে আপডেট করা হলো)
        Container(
          height: 110,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(
              horizontal: 8), // সাইড গ্যাপ ঠিক রাখা হলো
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage("assets/images/topuser.webp"),
              fit: BoxFit.fill,
            ),
            border: Border.all(color: Colors.amber.shade700, width: 2),
            borderRadius: BorderRadius.circular(20),
            color: Colors.black.withOpacity(0.3),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: _topGiftersStream,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final newDocs = snapshot.data!.docs;
                bool changed = newDocs.length != _cachedTopGifters.length;
                if (!changed) {
                  for (int i = 0; i < newDocs.length; i++) {
                    if (newDocs[i].id != _cachedTopGifters[i].id) {
                      changed = true;
                      break;
                    }
                    final a =
                        _cachedTopGifters[i].data() as Map<String, dynamic>?;
                    final b = newDocs[i].data() as Map<String, dynamic>?;
                    if (a?['totalSpent'] != b?['totalSpent'] ||
                        a?['name'] != b?['name'] ||
                        a?['profilePic'] != b?['profilePic']) {
                      changed = true;
                      break;
                    }
                  }
                }
                if (changed) {
                  _cachedTopGifters = List<QueryDocumentSnapshot>.from(newDocs);
                }
              }

              if (_cachedTopGifters.isEmpty && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return Padding(
                padding: const EdgeInsets.only(left: 10),
                child: RotatingTopGiftersRow(
                  docs: _cachedTopGifters,
                  onUserTap: (ctx, id) => _navigateToProfile(ctx, id),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  // প্রোফাইলে নেভিগেট করার কার্যকরী ফাংশন (আপনার কোড অনুযায়ী যুক্ত করা হয়েছে)
  Future<void> _navigateToProfile(BuildContext context, String uId) async {
    String finalIdToPass = uId;
    try {
      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: uId)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        finalIdToPass = userQuery.docs.first.data()['uID']?.toString() ??
            userQuery.docs.first.id;
      }
    } catch (e) {
      debugPrint("❌ Users কালেকশন থেকে uID লোড করতে ব্যর্থ: $e");
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: finalIdToPass),
      ),
    );
  }
}

class RainbowRippleAvatar extends StatefulWidget {
  final String imageUrl;
  final double size;

  const RainbowRippleAvatar({
    super.key,
    required this.imageUrl,
    this.size = 36,
  });

  @override
  State<RainbowRippleAvatar> createState() => _RainbowRippleAvatarState();
}

class _RainbowRippleAvatarState extends State<RainbowRippleAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const List<Color> _rainbowColors = [
    Color(0xFFFF004C),
    Color(0xFFFF7A00),
    Color(0xFFFFE600),
    Color(0xFF00F57A),
    Color(0xFF00D2FF),
    Color(0xFF7B2CBF),
    Color(0xFFFF004C),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double outerSize = widget.size + 12;

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double progress = _controller.value;
          final double rippleScale = 1.0 + (progress * 0.28);
          final double rippleOpacity = (1.0 - progress).clamp(0.0, 1.0) * 0.65;

          return Stack(
            alignment: Alignment.center,
            children: [
              // 🌊 বাইরে ছড়িয়ে পড়া রংধনু রিপেল রিং
              Transform.scale(
                scale: rippleScale,
                child: Opacity(
                  opacity: rippleOpacity,
                  child: Container(
                    width: widget.size + 4,
                    height: widget.size + 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: _rainbowColors[
                            (progress * (_rainbowColors.length - 1)).floor()],
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
              ),

              // 🌈 ঘুরে ঘুরে চলা রংধনু বর্ডার
              Transform.rotate(
                angle: progress * 6.28318530718, // 2 * pi
                child: Container(
                  width: widget.size + 4,
                  height: widget.size + 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    gradient: const SweepGradient(
                      colors: _rainbowColors,
                    ),
                  ),
                ),
              ),

              // 🖼️ ভেতরের মূল অবতার ছবি (সোজা থাকবে)
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.white12,
                      child: const Center(
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.cyanAccent,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class RainbowBoxRippleAvatar extends StatefulWidget {
  final String imageUrl;
  final double size;

  const RainbowBoxRippleAvatar({
    super.key,
    required this.imageUrl,
    this.size = 64,
  });

  @override
  State<RainbowBoxRippleAvatar> createState() => _RainbowBoxRippleAvatarState();
}

class _RainbowBoxRippleAvatarState extends State<RainbowBoxRippleAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const List<Color> _rainbowColors = [
    Color(0xFFFF004C),
    Color(0xFFFF7A00),
    Color(0xFFFFE600),
    Color(0xFF00F57A),
    Color(0xFF00D2FF),
    Color(0xFF7B2CBF),
    Color(0xFFFF004C),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double outerSize = widget.size + 16;

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double progress = _controller.value;
          final double rippleScale = 1.0 + (progress * 0.22);
          final double rippleOpacity = (1.0 - progress).clamp(0.0, 1.0) * 0.65;

          return Stack(
            alignment: Alignment.center,
            children: [
              // 🌊 বাইরে ছড়িয়ে পড়া রংধনু বক্স রিপেল
              Transform.scale(
                scale: rippleScale,
                child: Opacity(
                  opacity: rippleOpacity,
                  child: Container(
                    width: widget.size + 6,
                    height: widget.size + 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _rainbowColors[
                            (progress * (_rainbowColors.length - 1)).floor()],
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
              ),

              // 🌈 ঘুরে ঘুরে চলা রংধনু বক্স বর্ডার
              Transform.rotate(
                angle: progress * 6.28318530718, // 2 * pi
                child: Container(
                  width: widget.size + 6,
                  height: widget.size + 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const SweepGradient(
                      colors: _rainbowColors,
                    ),
                  ),
                ),
              ),

              // 🖼️ ভেতরের রুম প্রফাইল ছবি (বক্স শেপ, একদম স্থির)
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(widget.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class RoyalLightningRippleAvatar extends StatefulWidget {
  final String imageUrl;
  final double radius;
  final int rank; // 0 = 1st place (সবচেয়ে রাজকীয়), 1..4 = বাকি টপ গিফটার

  const RoyalLightningRippleAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24,
    this.rank = 0,
  });

  @override
  State<RoyalLightningRippleAvatar> createState() =>
      _RoyalLightningRippleAvatarState();
}

class _RoyalLightningRippleAvatarState extends State<RoyalLightningRippleAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.rank == 0 ? 1500 : 1900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double boxSize = (widget.radius * 2) + 22;

    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // ⚡ রাজকীয় বিজলি চমক ও রিপেল ক্যানভাস
              CustomPaint(
                size: Size(boxSize, boxSize),
                painter: _RoyalLightningPainter(
                  progress: _controller.value,
                  radius: widget.radius,
                  isTopOne: widget.rank == 0,
                ),
              ),

              // 👑 ইউজারের প্রোফাইল ছবি
              Container(
                width: widget.radius * 2,
                height: widget.radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[900],
                  border: Border.all(
                    color: widget.rank == 0
                        ? const Color(0xFFFFD700)
                        : const Color(0xFF00F5D4).withOpacity(0.85),
                    width: widget.rank == 0 ? 1.8 : 1.3,
                  ),
                  image: widget.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(widget.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: widget.imageUrl.isEmpty
                    ? const Icon(Icons.person, size: 22, color: Colors.white)
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoyalLightningPainter extends CustomPainter {
  final double progress;
  final double radius;
  final bool isTopOne;

  _RoyalLightningPainter({
    required this.progress,
    required this.radius,
    required this.isTopOne,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    // ১. রাজকীয় রিপেল রিং (বাইরে ছড়িয়ে গিয়ে মিলিয়ে যাবে)
    final double rippleProgress = progress;
    final double rippleRadius = radius + 1.5 + (rippleProgress * 7.5);
    final double rippleOpacity =
        ((1.0 - rippleProgress) * 0.75).clamp(0.0, 1.0);

    final Color primaryGlow =
        isTopOne ? const Color(0xFFFFD700) : const Color(0xFF00F5D4);
    final Color secondaryGlow =
        isTopOne ? const Color(0xFFFF6B00) : const Color(0xFF9B5DE5);

    final Paint ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isTopOne ? 1.8 : 1.3
      ..color = Color.lerp(primaryGlow, secondaryGlow, rippleProgress)!
          .withOpacity(rippleOpacity);

    canvas.drawCircle(center, rippleRadius, ripplePaint);

    // ২. বিজলি চমকানোর মতো আঁকাবাঁকা স্পার্ক রেখা (প্রতি চক্রে ঝলক দিয়ে জ্বলে উঠবে)
    final double flashIntensity = math.sin(progress * math.pi).clamp(0.0, 1.0);
    if (flashIntensity > 0.15) {
      final int boltCount = isTopOne ? 4 : 3;
      final int seedBase = (progress * 12).floor();

      for (int b = 0; b < boltCount; b++) {
        final double baseAngle =
            (b * (2 * math.pi / boltCount)) + (progress * math.pi * 0.8);
        _drawLightningBolt(
          canvas: canvas,
          center: center,
          startRadius: radius + 1.0,
          endRadius: radius + (isTopOne ? 9.5 : 7.5),
          baseAngle: baseAngle,
          intensity: flashIntensity,
          seed: seedBase + b * 37,
          boltColor: b.isEven ? primaryGlow : const Color(0xFFFFF3B0),
        );
      }
    }
  }

  void _drawLightningBolt({
    required Canvas canvas,
    required Offset center,
    required double startRadius,
    required double endRadius,
    required double baseAngle,
    required double intensity,
    required int seed,
    required Color boltColor,
  }) {
    final math.Random rng = math.Random(seed);
    final int steps = 4;
    final Path boltPath = Path();

    for (int i = 0; i <= steps; i++) {
      final double t = i / steps;
      final double r = startRadius + ((endRadius - startRadius) * t);
      final double jitter =
          (i == 0 || i == steps) ? 0.0 : (rng.nextDouble() - 0.5) * 0.36;
      final double angle = baseAngle + jitter;

      final double x = center.dx + r * math.cos(angle);
      final double y = center.dy + r * math.sin(angle);

      if (i == 0) {
        boltPath.moveTo(x, y);
      } else {
        boltPath.lineTo(x, y);
      }
    }

    // বিজলির গ্লো
    final Paint glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2)
      ..color = boltColor.withOpacity((0.65 * intensity).clamp(0.0, 1.0));

    // বিজলির উজ্জ্বল কোর
    final Paint corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter
      ..color = Colors.white.withOpacity((0.9 * intensity).clamp(0.0, 1.0));

    canvas.drawPath(boltPath, glowPaint);
    canvas.drawPath(boltPath, corePaint);
  }

  @override
  bool shouldRepaint(covariant _RoyalLightningPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.radius != radius ||
        oldDelegate.isTopOne != isTopOne;
  }
}

class LiveStatusBadge extends StatefulWidget {
  final bool isMyRoom;

  const LiveStatusBadge({
    super.key,
    required this.isMyRoom,
  });

  @override
  State<LiveStatusBadge> createState() => _LiveStatusBadgeState();
}

class _LiveStatusBadgeState extends State<LiveStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor =
        widget.isMyRoom ? Colors.amberAccent : Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accentColor.withOpacity(0.4),
          width: 0.8,
        ),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double v = _controller.value;
          // সবুজ লাইটের মতো জ্বলা-নেভা (0.35 থেকে 1.0 এর মধ্যে স্মুথ পাল্স)
          final double blinkGlow =
              0.35 + (0.65 * (0.5 + 0.5 * math.sin(v * 2 * math.pi)));

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🟢 জ্বলবে-নিভবে এমন সবুজ গোল ফোটা
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(blinkGlow.clamp(0.0, 1.0)),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor
                          .withOpacity((blinkGlow * 0.85).clamp(0.0, 1.0)),
                      blurRadius: 5 * blinkGlow,
                      spreadRadius: 1 * blinkGlow,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // 📝 শুধু LIVE (অথবা MY ROOM)
              Text(
                widget.isMyRoom ? "MY ROOM" : "LIVE",
                style: TextStyle(
                  color: accentColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // 📡 মিক্স কালার লাইভ স্ট্রিমিং ওয়েভ এনিমেশন (LIVE লেখার পরে)
              if (!widget.isMyRoom) ...[
                const SizedBox(width: 3),
                CustomPaint(
                  size: const Size(15, 11),
                  painter: _LiveBroadcastWavePainter(
                    progress: v,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _LiveBroadcastWavePainter extends CustomPainter {
  final double progress;

  static const List<Color> _waveMixColors = [
    Color(0xFFFF2E93), // হট পিংক / ক্রিমসন
    Color(0xFF00E5FF), // ব্রাইট সায়ান
    Color(0xFFFFD600), // গোল্ডেন ইয়েলো
  ];

  _LiveBroadcastWavePainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    // ৩টি স্তরের মিক্স কালার ওয়েভ আর্ক (বাম ও ডান উভয় পাশে)
    for (int i = 0; i < 3; i++) {
      final double wavePhase = (progress + (i * 0.33)) % 1.0;
      final double opacity = ((1.0 - wavePhase) * 0.98).clamp(0.0, 1.0);
      final double radius = 2.6 + (i * 2.1) + (wavePhase * 0.9);

      final Color baseWaveColor = _waveMixColors[i % _waveMixColors.length];

      final Paint arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25
        ..strokeCap = StrokeCap.round
        ..color = baseWaveColor.withOpacity(opacity);

      // ডান দিকের আর্ক
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -0.55,
        1.1,
        false,
        arcPaint,
      );

      // বাম দিকের আর্ক
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi - 0.55,
        1.1,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiveBroadcastWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
class RotatingTopGiftersRow extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  final void Function(BuildContext context, String userId) onUserTap;

  const RotatingTopGiftersRow({
    super.key,
    required this.docs,
    required this.onUserTap,
  });

  @override
  State<RotatingTopGiftersRow> createState() => _RotatingTopGiftersRowState();
}

class _RotatingTopGiftersRowState extends State<RotatingTopGiftersRow> {
  Timer? _timer;
  int _activeBatch = 0; // 0 = প্রথম ৫ জন (0..4), 1 = পরের ৫ জন (5..9)
  late List<QueryDocumentSnapshot> _stableDocs;

  @override
  void initState() {
    super.initState();
    _stableDocs = List<QueryDocumentSnapshot>.from(widget.docs);
    _syncRotationState();
  }

  @override
  void didUpdateWidget(covariant RotatingTopGiftersRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasDocsChanged(oldWidget.docs, widget.docs)) {
      _stableDocs = List<QueryDocumentSnapshot>.from(widget.docs);
      _syncRotationState();
    }
  }

  // আসলেই ডেটা বা র‍্যাঙ্ক বা স্কোর বদলেছে কি না তা যাচাই
  bool _hasDocsChanged(
    List<QueryDocumentSnapshot> prev,
    List<QueryDocumentSnapshot> next,
  ) {
    if (prev.length != next.length) return true;
    for (int i = 0; i < next.length; i++) {
      if (prev[i].id != next[i].id) return true;
      final Map<String, dynamic>? a = prev[i].data() as Map<String, dynamic>?;
      final Map<String, dynamic>? b = next[i].data() as Map<String, dynamic>?;
      if (a?['totalSpent'] != b?['totalSpent'] ||
          a?['name'] != b?['name'] ||
          a?['profilePic'] != b?['profilePic']) {
        return true;
      }
    }
    return false;
  }

  void _syncRotationState() {
    _timer?.cancel();
    if (_stableDocs.length <= 5) {
      if (_activeBatch != 0 && mounted) {
        setState(() => _activeBatch = 0);
      }
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        _activeBatch = _activeBatch == 0 ? 1 : 0;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int total = _stableDocs.length;
    if (total == 0) return const SizedBox.shrink();

    final int startIndex = (_activeBatch == 1 && total > 5) ? 5 : 0;
    final int endIndex = (startIndex + 5).clamp(0, total);
    final List<QueryDocumentSnapshot> batchDocs =
        _stableDocs.sublist(startIndex, endIndex);

    final double itemWidth = (MediaQuery.of(context).size.width - 60) / 5;

    return RepaintBoundary(
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            final bool isIncoming = child.key == ValueKey<int>(_activeBatch);

            final Offset beginOffset = isIncoming
                ? const Offset(0.0, 0.65) // নতুন ৫ জন নিচ থেকে উঠবে
                : const Offset(0.0, -0.55); // আগের ৫ জন সরে গিয়ে হাইড হবে

            return SlideTransition(
              position: Tween<Offset>(
                begin: beginOffset,
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: Row(
            key: ValueKey<int>(_activeBatch),
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(batchDocs.length, (i) {
              final int actualRank = startIndex + i;
              final QueryDocumentSnapshot doc = batchDocs[i];
              final Map<String, dynamic> userData =
                  doc.data() as Map<String, dynamic>;

              final String uId = doc.id;
              final String name = userData['name'] ?? "User";
              final String pic = userData['profilePic'] ?? "";

              return SizedBox(
                width: itemWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => widget.onUserTap(context, uId),
                      child: RoyalLightningRippleAvatar(
                        imageUrl: pic,
                        radius: 23,
                        rank: actualRank,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}