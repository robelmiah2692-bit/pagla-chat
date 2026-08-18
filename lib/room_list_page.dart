import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
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
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0C29),
        elevation: 0,
        centerTitle: true,

        // 🛠️ [কাস্টমাইজেশন - সাইজ]: ৩টি বড় চারকোনা ফ্রেম অবতার সমানভাবে ধরার জন্য leadingWidth ঠিক করা হয়েছে
        leadingWidth: 145,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 4, bottom: 4),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('isOnline', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              List<String> avatarUrls = [];
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  if (data['profilePic'] != null &&
                      data['profilePic'].toString().isNotEmpty) {
                    avatarUrls.add(data['profilePic']);
                  }
                }
              }

              // পর্যাপ্ত ইউজার না থাকলে রেন্ডম ফলব্যাক অবতার
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
              List<String> displayAvatars = avatarUrls.take(3).toList();

              // Row ব্যবহার করে সমান গ্যাপে ৩টি বড় চারকোনা ফ্রেম অবতার দেখানো হচ্ছে
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: displayAvatars.map((url) {
                  return Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      // 🛠️ [কাস্টমাইজেশন - চারকোনা ফ্রেম]: এখানে বর্ডার রেডিয়াস পরিবর্তন করতে পারবেন
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.cyanAccent.withOpacity(0.9),
                          width: 1.5),
                      // 🛠️ [কাস্টমাইজেশন - পানির মতো রিপেল ইফেক্ট]: মাল্টি লেয়ার শ্যাডো দিয়ে পানির মতো গ্লো তৈরি করা হয়েছে
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.3),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      // 🔥 ক্যাশড নেটওয়ার্ক ইমেজ ব্যবহার করা হলো
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.white12,
                          child: const Center(
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5, color: Colors.cyanAccent),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),

        // 🔍 [Title]: সার্চ বক্সটি একদম কাছাকাছি এবং কম্প্যাক্ট রাখা হয়েছে
        title: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () {
              _showSearchDialog(context);
            },
            child: Container(
              // 🛠️ [কাস্টমাইজেশন - সার্চ বক্সের সাইজ]: এখান থেকে প্যাডিং কন্ট্রোল করতে পারবেন
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Colors.white.withOpacity(0.08),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.search_rounded,
                      color: Colors.cyanAccent, size: 16),
                  SizedBox(width: 5),
                  Text(
                    "Search uID / Room ID",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ➕ [Actions]: ডান কোণায় রুম তৈরির প্লাস বাটন (নতুন লজিক যুক্ত করা হয়েছে)
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                _showCreateRoomDialog(); // রুম তৈরির ডায়ালগ কল করবে
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                  border: Border.all(
                    color: Colors.purpleAccent.withOpacity(0.6),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.purpleAccent,
                  size: 20,
                ),
              ),
            ),
          ),
        ],

        // 📏 [ট্যাব বার ও প্রিমিয়াম গ্লাস লুক]:
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color:
                  Colors.white.withOpacity(0.06), // হালকা গ্লাস ব্যাকগ্রাউন্ড
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1.0,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              // ডিফল্ট লাইন ইন্ডিকেটর বাদ দিয়ে ফুল ট্যাব ব্যাকগ্রাউন্ড ইন্ডিকেটর করা হয়েছে
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
              labelColor: Colors
                  .black, // সিলেক্টেড টেক্সট কালার (বোল্ড ও স্পষ্ট দেখাবে)
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
        ),
      ),

      // ফুল স্ক্রিন ব্যাকগ্রাউন্ড থিম (অ্যাপবার থেকে শুরু করে নিচ পর্যন্ত এক সমান গ্রেডিয়েন্ট)
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF302B63),
              Color(0xFF24243E),
            ],
          ),
        ),
        child: Stack(
          children: [
            // ১. নেবুলা ইফেক্ট
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

            // ২. গ্যালাক্সি তারা (Glowing Stars)
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

            // ৩. আলোর বৃষ্টি (Light Strings)
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

            // মেইন কন্টেন্ট লেয়ার
            Column(
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
          ],
        ),
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
                // ১. রুমের গোল ছবি (বর্ডারসহ)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isMyRoom
                          ? Colors.amberAccent
                          : Colors.pinkAccent.withOpacity(0.6),
                      width: 2,
                    ),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(finalImage),
                      fit: BoxFit.cover,
                    ),
                  ),
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
                          // রুমের নামের পাশে সবুজ রঙের গ্লাস স্ট্যাটাস টেক্সট (PAGLA LIVE / MY ROOM)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  (isMyRoom ? Colors.amber : Colors.greenAccent)
                                      .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (isMyRoom
                                        ? Colors.amberAccent
                                        : Colors.greenAccent)
                                    .withOpacity(0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              isMyRoom ? "MY ROOM" : "PAGLA LIVE",
                              style: TextStyle(
                                color: isMyRoom
                                    ? Colors.amberAccent
                                    : Colors.greenAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
          return Container(
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
          child: Text("Top Live Spenders",
              style: TextStyle(
                  color: Color.fromARGB(255, 6, 250, 209),
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        // গোল্ডেন ফ্রেম ব্যাকগ্রাউন্ড
        Container(
          height: 110,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(
              horizontal: 8), // সাইড গ্যাপ ঠিক রাখা হলো
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: CachedNetworkImageProvider(
                  "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/topuser.jpg"),
              fit: BoxFit.fill,
            ),
            border: Border.all(color: Colors.amber.shade700, width: 2),
            borderRadius: BorderRadius.circular(20),
            color: Colors.black.withOpacity(0.3),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('totalSpent', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var topUsers = snapshot.data!.docs;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                // গ্যাপ সমান রাখতে physics যোগ করা হয়েছে
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(left: 10),
                itemCount: topUsers.length,
                itemBuilder: (context, index) {
                  var userData = topUsers[index].data() as Map<String, dynamic>;
                  String name = userData['name'] ?? "User";
                  String pic = userData['profilePic'] ?? "";
                  String frame = userData['activeFrameUrl'] ?? "";

                  return Container(
                    width: (MediaQuery.of(context).size.width - 60) /
                        5, // স্ক্রিন অনুযায়ী সমান জায়গা ভাগ
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.grey[900],
                              backgroundImage: pic.isNotEmpty
                                  ? CachedNetworkImageProvider(pic)
                                      as ImageProvider
                                  : null,
                              child: pic.isEmpty
                                  ? const Icon(Icons.person,
                                      size: 26, color: Colors.white)
                                  : null,
                            ),
                            // ফ্রেম লজিক: Lottie অথবা CachedNetworkImage
                            if (frame.isNotEmpty)
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: frame.toLowerCase().endsWith('.json')
                                    ? Lottie.network(frame)
                                    : CachedNetworkImage(
                                        imageUrl: frame,
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) =>
                                            const SizedBox.shrink(),
                                        errorWidget: (context, error,
                                                stackTrace) =>
                                            const SizedBox.shrink(),
                                      ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
