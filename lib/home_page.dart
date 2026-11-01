import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pagla_chat/reels_ad_widget.dart';
import 'package:pagla_chat/reward_ads_widget.dart';
import 'package:pagla_chat/screens/voice_room.dart';
import 'package:pagla_chat/services/call_handler.dart';
import 'package:pagla_chat/utils/daily_bonus_popup.dart';
import 'package:pagla_chat/widgets/room_settings_handler.dart';
import 'dart:io' as io;
import 'dart:math';
import 'dart:async';

import 'stories_service.dart';
import 'post_card.dart';
import 'home_banner.dart'; // 🇧🇩 [বাংলা মার্ক]: আলাদা করা ব্যানারের ফাইল ইম্পোর্ট করা হলো
import 'notification_panel.dart'; // 🇧🇩 [বাংলা মার্ক]: নতুন নোটিফিকেশন বার ফাইলটি ইম্পোর্ট করা হলো ভাই

// তারার মতো ইফেক্ট তৈরির জন্য কাস্টম পেইন্টার
class StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.5);
    final random = Random();
    for (int i = 0; i < 100; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double radius = random.nextDouble() * 1.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  Uint8List? _webImageBytes;

  // 🎥 [ভিডিও পোস্ট ভেরিয়েবল]: ভিডিও সিলেক্ট করার জন্য ভেরিয়েবলগুলো যোগ করা হলো
  XFile? _pickedVideo;

  final TextEditingController _captionController = TextEditingController();

  Map<String, dynamic>? currentUserData;
  String? myCustomDocId;
// কল লিসেনার একবারই ইনিশিয়ালাইজ করার জন্য ফ্লাগ
  bool _isCallListenerInitialized = false;
  // 🇧🇩 [বাংলা মার্ক]: মেইন পেজ থেকে টাইমার ও ব্যানারের লিস্ট সম্পূর্ণ ডিলিট করে দেওয়া হয়েছে পারফরম্যান্সের জন্য
  String _selectedCategory = 'New';
  late AnimationController _colorController;
  late Animation<double> _colorAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUserData();

    _colorController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _colorAnimation =
        CurvedAnimation(parent: _colorController, curve: Curves.linear);
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        var querySnapshot;
        String email = user.email ?? '';
        String authUid = user.uid;

        // ১. প্রথমে email দিয়ে খোঁজার চেষ্টা
        if (email.isNotEmpty) {
          try {
            querySnapshot = await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: email)
                .get(const GetOptions(source: Source.server));
          } catch (_) {}
        }

        // ২. email দিয়ে না পেলে authUID দিয়ে খোঁজা
        if (querySnapshot == null || querySnapshot.docs.isEmpty) {
          try {
            querySnapshot = await FirebaseFirestore.instance
                .collection('users')
                .where('authUID', isEqualTo: authUid)
                .get(const GetOptions(source: Source.server));
          } catch (_) {}
        }

        // ৩. uID দিয়ে খোঁজা
        if (querySnapshot == null || querySnapshot.docs.isEmpty) {
          try {
            querySnapshot = await FirebaseFirestore.instance
                .collection('users')
                .where('uID', isEqualTo: authUid)
                .get(const GetOptions(source: Source.server));
          } catch (_) {}
        }

        // ৪. ছোট হাতের uid দিয়ে খোঁজা
        if (querySnapshot == null || querySnapshot.docs.isEmpty) {
          try {
            querySnapshot = await FirebaseFirestore.instance
                .collection('users')
                .where('uid', isEqualTo: authUid)
                .get(const GetOptions(source: Source.server));
          } catch (_) {}
        }

        // ৫. কুয়েরিতে না পেলে সরাসরি ডকুমেন্ট আইডি (authUid) দিয়ে চেক করা
        if (querySnapshot == null || querySnapshot.docs.isEmpty) {
          try {
            var directDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(authUid)
                .get(const GetOptions(source: Source.server));

            if (directDoc.exists) {
              final docId = directDoc.id;
              setState(() {
                myCustomDocId = docId;
                currentUserData = directDoc.data() as Map<String, dynamic>?;
              });

              if (!_isCallListenerInitialized && mounted) {
                _isCallListenerInitialized = true;
                CallHandler.listenForIncomingCalls(context, docId);
              }
              DailyBonusPopup.show(context, docId);
              _updateStatus(true);
              return;
            }
          } catch (_) {}
        }

        // চূড়ান্ত ফলাফল চেক করে ডাটা সেট করা
        if (querySnapshot != null && querySnapshot.docs.isNotEmpty) {
          final docId = querySnapshot.docs.first.id;

          setState(() {
            myCustomDocId = docId;
            currentUserData =
                querySnapshot.docs.first.data() as Map<String, dynamic>;
          });

          if (!_isCallListenerInitialized && mounted) {
            _isCallListenerInitialized = true;
            CallHandler.listenForIncomingCalls(context, docId);
          }
          DailyBonusPopup.show(context, docId);

          _updateStatus(true);
        } else {
          debugPrint(
              "User Fetch Error: No user found across email, authUID, uID, or uid.");
        }
      } catch (e) {
        debugPrint("User Fetch Error: $e");
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _captionController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateStatus(true);
    } else {
      _updateStatus(false);
    }
  }

  void _updateStatus(bool status) {
    if (myCustomDocId != null) {
      FirebaseFirestore.instance.collection('users').doc(myCustomDocId).update({
        'isOnline': status,
        'lastSeen': FieldValue.serverTimestamp(),
      }).catchError((e) => debugPrint("Status Update Error: $e"));
    }
  }

// সঠিক রুমে নেভিগেট করার ফাংশন
  void _navigateToRoom(String roomId, String roomName, String roomImage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceRoom(
          roomId: roomId,
          // আপনার VoiceRoom ক্লাসে যদি ownerId পাস করার প্রয়োজন হয়, তবে সেটি এখানে দিতে পারেন
          // ownerId: "",
        ),
      ),
    );
  }

  // 🇧🇩 [বাংলা মার্ক]: কাউন্ট বাটন ক্লিয়ার করার অপ্টিমাইজড মেথড (আইডি সিঙ্কড ফিক্স)
  Future<void> _clearNotificationCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('receiverId', isEqualTo: user.uid)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      bool hasUpdates = false;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] ?? '';
        final isRead = data['isRead'] ?? false;

        if ((type == 'like' || type == 'comment') && isRead == false) {
          batch.update(doc.reference, {'isRead': true});
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        await batch.commit();
      }
    } catch (e) {}
  }

  Future<void> _pickImage(Function setModalState) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // ছবি সিলেক্ট হলে ভিডিও রিসেট করে দেওয়া হবে
        final compressedFile = await FlutterImageCompress.compressWithFile(
          image.path,
          minWidth: 800,
          minHeight: 800,
          quality: 70,
        );

        setModalState(() {
          _pickedVideo = null; // ভিডিও ক্লিয়ার করা হলো
          if (kIsWeb) {
            _webImageBytes = compressedFile;
            _pickedImage = image;
          } else {
            _pickedImage = image;
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // 🎥 [ভিডিও পিক করার মেথড]: গ্যালারি থেকে ভিডিও সিলেক্ট করার জন্য ফাংশন
  Future<void> _pickVideo(Function setModalState) async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        setModalState(() {
          _pickedImage = null; // ছবি থাকলে তা ক্লিয়ার করা হলো
          _webImageBytes = null;
          _pickedVideo = video;
        });
      }
    } catch (e) {
      debugPrint("Error picking video: $e");
    }
  }

  void _showPostModal() {
    // মোডাল ওপেন করার আগে রিসেট করে নেওয়া
    _captionController.clear();
    _pickedImage = null;
    _webImageBytes = null;
    _pickedVideo = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2A4A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 15),
              const Text(
                "Create Your new post",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _captionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Type anything ...",
                  hintStyle:
                      const TextStyle(color: Colors.white24, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),

              // ইমেজ প্রিভিউ সেকশন
              if (_pickedImage != null)
                Stack(
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: kIsWeb
                            ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                            : Image.file(io.File(_pickedImage!.path),
                                fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: GestureDetector(
                        onTap: () => setModalState(() {
                          _pickedImage = null;
                          _webImageBytes = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    )
                  ],
                ),

              // ভিডিও প্রিভিউ সেকশন
              if (_pickedVideo != null)
                Stack(
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.3)),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam,
                                color: Colors.cyanAccent, size: 40),
                            SizedBox(height: 8),
                            Text("Video Selected Successfully",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: GestureDetector(
                        onTap: () => setModalState(() {
                          _pickedVideo = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    )
                  ],
                ),

              // ইমেজ পিক বাটন (সবাই ব্যবহার করতে পারবে)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child:
                      const Icon(Icons.photo_library, color: Colors.cyanAccent),
                ),
                title: const Text("Add gallery photos",
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () => _pickImage(setModalState),
              ),

              // ভিডিও পিক বাটন (ভিআইপি কন্ডিশন বাদ দেওয়া হয়েছে, সবাই দিতে পারবে)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Icon(
                    Icons.videocam,
                    color: Colors.cyanAccent,
                  ),
                ),
                title: const Text("Add gallery video",
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  _pickVideo(setModalState);
                },
              ),

              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.shade700,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                onPressed: () async {
                  String text = _captionController.text.trim();

                  if (_pickedImage != null ||
                      _pickedVideo != null ||
                      text.isNotEmpty) {
                    showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (c) => const Center(
                            child: CircularProgressIndicator(
                                color: Colors.cyanAccent)));

                    try {
                      await StoriesService().uploadStory(
                        _pickedImage?.path ?? _pickedVideo?.path ?? "",
                        text,
                        webFileBytes: _webImageBytes,
                        isVideo: _pickedVideo != null,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Post Successfully! 🔥"),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) Navigator.pop(context);
                      debugPrint("Upload Error: $e");
                    }
                  }
                },
                child: const Text("Post",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

// ক্যাটাগরি ট্র্যাক করার জন্য স্টেট ভেরিয়েবলটি আপনার State ক্লাসের ভেতরে উপরে এভাবে ডিক্লেয়ার করে নেবেন:
// String _selectedCategory = 'New';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔥 মেইন ব্যাকগ্রাউন্ড ওয়ালপেপার ইমেজ
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/homewallpepar.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: StarFieldPainter(),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                // রিফ্রেশ করার সময় চাইলে ক্যাটাগরি আবার 'New'-এ রিসেট করে দিতে পারেন বা আগেরটি রাখতে পারেন
                setState(() {
                  _selectedCategory = 'New';
                });
                await _fetchUserData();
              },
              color: Colors.cyanAccent,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    floating: true,
                    centerTitle: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: AnimatedBuilder(
                        animation: _colorAnimation,
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
                                _colorAnimation.value - 0.2,
                                _colorAnimation.value,
                                _colorAnimation.value + 0.2,
                                _colorAnimation.value + 0.4
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              "Welcome Pagla Chat",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: Colors.white,
                                letterSpacing: 1.1,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    actions: [
                      if (FirebaseAuth.instance.currentUser != null)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('notifications')
                              .where('receiverId',
                                  isEqualTo:
                                      FirebaseAuth.instance.currentUser!.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            int count = 0;

                            if (snapshot.hasData) {
                              count = snapshot.data!.docs.where((doc) {
                                final d = doc.data() as Map<String, dynamic>;
                                final type = d['type'] ?? '';
                                final isRead = d['isRead'] ?? false;
                                return (type == 'like' || type == 'comment') &&
                                    isRead == false;
                              }).length;
                            }

                            return IconButton(
                              onPressed: () {
                                _clearNotificationCount();

                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      const NotificationPanel(),
                                );
                              },
                              icon: Badge(
                                label: count > 0
                                    ? Text('$count',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10))
                                    : null,
                                isLabelVisible: count > 0,
                                backgroundColor: Colors.redAccent,
                                child: AnimatedBuilder(
                                  animation: _colorAnimation,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: 0.15 *
                                          sin(_colorAnimation.value *
                                              2 *
                                              3.1416),
                                      child: ShaderMask(
                                        shaderCallback: (bounds) =>
                                            LinearGradient(
                                          colors: const [
                                            Color(0xFFFFD700),
                                            Color(0xFFFFA500),
                                            Color(0xFFFFF8DC),
                                            Color(0xFFFFD700),
                                          ],
                                          stops: [
                                            _colorAnimation.value - 0.2,
                                            _colorAnimation.value,
                                            _colorAnimation.value + 0.2,
                                            _colorAnimation.value + 0.4,
                                          ],
                                          tileMode: TileMode.mirror,
                                        ).createShader(bounds),
                                        child: const Icon(
                                          Icons.notifications_active_rounded,
                                          size: 28,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),

                  // 🔥 ১. লাইভ রুম সেকশন (এখন সবার উপরে বসানো হয়েছে)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 4.0),
                      child: _buildLiveRoomsGridSection(),
                    ),
                  ),

                  // ২. হোম ব্যানার (Home Banner - এখন লাইভ রুমের নিচে চলে এসেছে)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: const HomeBanner(),
                    ),
                  ),

                  // ৩. ফিল্টার ক্যাটাগরি বাটনগুলো (New, For You, Image, Video)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 8.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildCategoryButton(
                                "New"), // ডিফল্ট বা ফিক্সড স্টার্টিং বাটন
                            const SizedBox(width: 10),
                            _buildCategoryButton("For You"),
                            const SizedBox(width: 10),
                            _buildCategoryButton("Image"),
                            const SizedBox(width: 10),
                            _buildCategoryButton("Video"),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ৪. ক্যাটাগরি অনুযায়ী ফিল্টার করা পোস্ট স্ট্রিমিং ও লজিক
                  StreamBuilder<QuerySnapshot>(
                    stream: _getFilteredQuery().snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: CircularProgressIndicator(
                                  color: Colors.cyanAccent),
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 50),
                            child: Center(
                                child: Text("No posts found in this category",
                                    style: TextStyle(color: Colors.white38))),
                          ),
                        );
                      }

                      var docs = snapshot.data!.docs;

                      if (_selectedCategory == 'New') {
                        DateTime twentyFourHoursAgo =
                            DateTime.now().subtract(const Duration(hours: 24));
                        docs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          Timestamp? timestamp =
                              data['timestamp'] as Timestamp?;
                          if (timestamp != null) {
                            DateTime postDate = timestamp.toDate();
                            return postDate.isAfter(twentyFourHoursAgo);
                          }
                          return false;
                        }).toList();
                      } else if (_selectedCategory == 'Video') {
                        docs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final vUrl = data['videoUrl']?.toString() ?? "";
                          return vUrl.isNotEmpty && vUrl != "";
                        }).toList();
                      } else if (_selectedCategory == 'Image') {
                        docs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final iUrl = data['storyImage']?.toString() ?? "";
                          return iUrl.isNotEmpty && iUrl != "";
                        }).toList();
                      }

                      if (docs.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 50),
                            child: Center(
                                child: Text("No posts found in this category",
                                    style: TextStyle(color: Colors.white38))),
                          ),
                        );
                      }

                      int totalCount = docs.length + (docs.length ~/ 4);

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            bool isAdPosition = (index + 1) % 5 == 0;

                            if (isAdPosition) {
                              return const ReelsAdWidget();
                            }

                            int postIndex = index - (index ~/ 5);

                            final data =
                                docs[postIndex].data() as Map<String, dynamic>;
                            return PostCard(
                              data: data,
                              postId: docs[postIndex].id,
                            );
                          },
                          childCount: totalCount,
                        ),
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const RewardAdsBoxWidget(),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _showPostModal,
            backgroundColor: Colors.cyanAccent.shade700,
            elevation: 10,
            child: const Icon(Icons.add_photo_alternate_outlined,
                size: 28, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // 🔥 ডাইনামিক হাইট ও রিপেল ইফেক্টযুক্ত লাইভ রুম সেকশন (৫টি রুম পর্যন্ত ১ সারিতে দেখানোর লজিক)
  Widget _buildLiveRoomsGridSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // লাইভ রুম না থাকলে জায়গা নেবে না
        }

        var docs = snapshot.data!.docs;
        // 🔥 এখানে ৪ এর জায়গায় ৫ করে দেওয়া হলো (৫টি রুম পর্যন্ত উচ্চতা ৮৫, ৫টির বেশি হলে ১৭০)
        double sectionHeight = docs.length <= 5 ? 85 : 170;

        return Container(
          height: sectionHeight,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              // 🔥 এখানেও ৪ এর জায়গায় ৫ করে দেওয়া হলো
              crossAxisCount: docs.length <= 5 ? 1 : 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 8,
              childAspectRatio: 1.15,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String roomId = data['roomId'] ?? docs[index].id;
              String name = data['roomName'] ?? "Live Room";
              String? image = data['roomImage'];
              bool isLocked = data['isLocked'] ?? false;
              String roomPassword = data['password'] ?? "";

              String finalImage = (image != null && image.isNotEmpty)
                  ? image
                  : "https://via.placeholder.com/150";

              return GestureDetector(
                onTap: () {
                  if (isLocked) {
                    RoomSettingsHandler.showJoinPasswordDialog(
                        context, roomId, roomPassword, () {
                      _navigateToRoom(roomId, name, finalImage);
                    });
                  } else {
                    _navigateToRoom(roomId, name, finalImage);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // 🌊 অবতারের চারপাশে সফট রিপেল ইফেক্ট
                          _buildWaterRipple(0.0, Colors.pinkAccent),
                          _buildWaterRipple(0.5, Colors.cyanAccent),

                          // রুম অবতার ইমেজ উইজেট
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.cyanAccent,
                                width: 2,
                              ),
                              image: DecorationImage(
                                image: CachedNetworkImageProvider(finalImage),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (isLocked)
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.5),
                              ),
                              child: const Center(
                                child: Icon(Icons.lock,
                                    color: Colors.amberAccent, size: 16),
                              ),
                            ),
                          Positioned(
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: Colors.white, width: 0.8),
                              ),
                              child: const Text(
                                "LIVE",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 65,
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // 💧 পানির মতো সফট রিপেল বিল্ডার ফাংশন
  Widget _buildWaterRipple(double delay, Color color) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        double progress = (_colorAnimation.value + delay) % 1.0;
        return Transform.scale(
          scale: 1.0 + (progress * 0.4),
          child: Opacity(
            opacity: (1.0 - progress).clamp(0.0, 1.0),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.5), width: 1.0),
                color: color.withOpacity(0.1),
              ),
            ),
          ),
        );
      },
    );
  }

  // ক্যাটাগরি ফিল্টার কুয়েরি লজিক
  Query _getFilteredQuery() {
    Query query = FirebaseFirestore.instance.collection('stories');
    return query.orderBy('timestamp', descending: true);
  }

  // ক্যাটাগরি বাটন উইজেট ডিজাইন (ব্লু মিক্স গ্লাস ইফেক্ট ও টেক্সট বর্ডারসহ)
  Widget _buildCategoryButton(String categoryName) {
    bool isSelected = _selectedCategory == categoryName;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = categoryName;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          // ব্লু মিক্স গ্লাস ইফেক্ট (সিলেক্টেড হলে ব্লু গ্রেডিয়েন্ট, আনসিলেক্টেড হলে ট্রান্সপারেন্ট গ্লাস)
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFF0284C7),
                    Color(0xFF0369A1)
                  ], // Deep Blue mix
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(22),
          // হালকা গ্লাস বর্ডার ও শ্যাডো
          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.white24,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Text(
          categoryName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
            // টেক্সটের চারপাশে হালকা শ্যাডো বা আউটলাইন ইফেক্ট যাতে স্পষ্ট দেখা যায়
            shadows: const [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Colors.black87,
              ),
              Shadow(
                offset: Offset(0, 0),
                blurRadius: 4.0,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
