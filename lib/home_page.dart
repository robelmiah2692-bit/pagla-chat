import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pagla_chat/utils/daily_bonus_popup.dart';
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

  // 🇧🇩 [বাংলা মার্ক]: মেইন পেজ থেকে টাইমার ও ব্যানারের লিস্ট সম্পূর্ণ ডিলিট করে দেওয়া হয়েছে পারফরম্যান্সের জন্য

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
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final docId = querySnapshot.docs.first.id;

          setState(() {
            myCustomDocId = docId;
            currentUserData = querySnapshot.docs.first.data();
          });

          // এখানে নিশ্চিত ভাবে নন-নাল docId পাঠানো হচ্ছে
          DailyBonusPopup.show(context, docId); 
          
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
  // 🛑 [ভিআইপি ও এক্সপি ক্যালকুলেশন - ফিক্সড লজিক: 'vip_xp' এবং 'vip_expiry' দিয়ে চেক করা হচ্ছে]
  // প্রথমে ডাটাবেসের 'vip_xp' চেক করবে, না পেলে ব্যাকআপ হিসেবে 'xp' চেক করবে
  int vipXp = currentUserData?['vip_xp'] ?? currentUserData?['xp'] ?? 0;
  int vipExpiry = currentUserData?['vipExpiry'] ?? 0;
  int currentTime = DateTime.now().millisecondsSinceEpoch;

  // যদি মেয়াদ শেষ হয়ে যায়, তবে VIP ০, অন্য and লেভেল কাউন্ট হবে
  int vipLevel = 0;
  if (!(vipExpiry != 0 && currentTime > vipExpiry)) {
    if (vipXp >= 35000) {
      vipLevel = 8;
    } else if (vipXp >= 30000) {
      vipLevel = 7;
    } else if (vipXp >= 25000) {
      vipLevel = 6;
    } else if (vipXp >= 20000) {
      vipLevel = 5;
    } else if (vipXp >= 13000) {
      vipLevel = 4;
    } else if (vipXp >= 9000) {
      vipLevel = 3;
    } else if (vipXp >= 5000) {
      vipLevel = 2;
    } else if (vipXp >= 2500) {
      vipLevel = 1;
    }
  }

  // মোডাল ওপেন করার আগে রিসেট করে নেওয়া
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
                          Icon(Icons.videocam, color: Colors.cyanAccent, size: 40),
                          SizedBox(height: 8),
                          Text("Video Selected Successfully",
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
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

            // ভিডিও পিক বাটন (এখানে সরাসরি সঠিক vipLevel চেক করা হচ্ছে)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Icon(
                  vipLevel > 0 ? Icons.videocam : Icons.lock,
                  color: vipLevel > 0 ? Colors.cyanAccent : Colors.redAccent,
                ),
              ),
              title: Row(
                children: [
                  const Text("Add gallery video",
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  if (vipLevel <= 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: const Text("VIP LOCKED",
                          style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ]
                ],
              ),
              onTap: () {
                // 🛑 ইউজার ভিআইপি না হলে (vipLevel < 1) ভিডিও সিলেক্ট করতে বাধা দিবে
                if (vipLevel < 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("🔒 Only VIP users can post videos! 🌟"),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                // ভিআইপি হলে ভিডিও সিলেক্ট করার ফাংশন কল হবে
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
                
                // সাবমিট করার সময়ও এক্সট্রা চেক
                if (_pickedVideo != null && vipLevel < 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("🔒 Only VIP users can post videos! 🌟"),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                if (_pickedImage != null || _pickedVideo != null || text.isNotEmpty) {
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

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: const HomeBanner(),
                    ),
                  ),

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