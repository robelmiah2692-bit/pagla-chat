import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  final TextEditingController _captionController = TextEditingController();

  Map<String, dynamic>? currentUserData;
  String? myCustomDocId;

  // 🇧🇩 [বাংলা মার্ক]: মেইন পেজ থেকে টাইমার ও ব্যানারের লিস্ট সম্পূর্ণ ডিলিট করে দেওয়া হয়েছে পারফরম্যান্সের জন্য

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

    // 🇧🇩 [বাংলা মার্ক]: মেইন হোম পেজের initState থেকে ক্ষতিকর স্লাইডার টাইমারটি সম্পূর্ণ রিমুভ করা হয়েছে ভাই!
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            myCustomDocId = querySnapshot.docs.first.id;
            currentUserData = querySnapshot.docs.first.data();
          });
          _updateStatus(true);
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
    super
        .dispose(); // 🇧🇩 [বাংলা মার্ক]: ব্যানার টাইমারটি এখানে আর ডিসপোজ করার দরকার নেই, সেটি আলাদা ফাইলে চলে গেছে
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

  // 🇧🇩 [বাংলা মার্ক]: কাউন্ট বাটন ক্লিয়ার করার অপ্টিমাইজড মেথড (আইডি সিঙ্কড ফিক্স)
Future<void> _clearNotificationCount() async {
  // ১. কারেন্ট ইউজার অবজেক্ট নেওয়া হচ্ছে
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return; 

  try {
    // ২. সরাসরি আসল ফায়ারবেস UID (user.uid) দিয়ে কোয়েরি করা হচ্ছে ভাই
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
      debugPrint("🧹 [PaglaChat] সব আনরিড নোটিফিকেশন ক্লিয়ার করা হয়েছে ভাই!");
    }
  } catch (e) {
    debugPrint("❌ [PaglaChat] কাউন্ট ক্লিয়ার এরর: $e");
  }
}
  Future<void> _pickImage(Function setModalState) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setModalState(() {
            _webImageBytes = bytes;
            _pickedImage = image;
          });
        } else {
          setModalState(() {
            _pickedImage = image;
          });
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showPostModal() {
    _captionController.clear();
    _pickedImage = null;
    _webImageBytes = null;

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
                  if (_pickedImage != null || text.isNotEmpty) {
                    showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (c) => const Center(
                            child: CircularProgressIndicator(
                                color: Colors.cyanAccent)));

                    try {
                      await StoriesService().uploadStory(
                        _pickedImage?.path ?? "",
                        text,
                        webImageBytes: _webImageBytes,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
            ),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: StarFieldPainter(),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => _fetchUserData(),
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
                        // 🇧🇩 [মাস্টার প্রিন্ট]: লাইক ও কমেন্টের রিয়েল-টাইম লাইভ কাউন্ট ব্যাজসহ পারফেক্ট বাটন ভাই
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
                                // ১. ক্লিক করার সাথে সাথে ডাটাবেজের কাউন্ট রিড (true) হয়ে যাবে ভাই
                                _clearNotificationCount();

                                // ২. নিচ থেকে কাস্টম আলাদা ফাইলের নোটিফিকেশন বারটি ওপেন হবে
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
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),

                  // 🇧🇩 [বাংলা标记 - সম্পূর্ণ অপ্টিমাইজড ব্যানার সেকশন]:
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      // 💡 এখানে আগের সেই কাস্টম HomeBanner() উইজেটটি একদম পারফেক্টলি রাখা হয়েছে
                      child: const HomeBanner(),
                    ),
                  ),

                  // পোস্ট লিস্ট সেকশন
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('stories')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white24)),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 50),
                            child: Center(
                                child: Text("No posts found",
                                    style: TextStyle(color: Colors.white38))),
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;
                            return PostCard(
                              data: data,
                              postId: docs[index].id,
                            );
                          },
                          childCount: docs.length,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showPostModal,
        backgroundColor: Colors.cyanAccent.shade700,
        elevation: 10,
        child: const Icon(Icons.add_photo_alternate_outlined,
            size: 28, color: Colors.white),
      ),
    );
  }
}
