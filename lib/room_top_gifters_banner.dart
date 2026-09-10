import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RoomTopGiftersBanner extends StatefulWidget {
  final String roomId;
  final Map<String, dynamic> roomData;

  const RoomTopGiftersBanner({
    super.key,
    required this.roomId,
    required this.roomData,
  });

  @override
  State<RoomTopGiftersBanner> createState() => _RoomTopGiftersBannerState();
}

class _RoomTopGiftersBannerState extends State<RoomTopGiftersBanner>
    with SingleTickerProviderStateMixin {
  PageController? _pageController;
  Timer? _autoScrollTimer;
  Timer? _rotatorTimer;
  List<Map<String, dynamic>> _topGifters = [];
  StreamSubscription<QuerySnapshot>? _giftersSubscription;

  late AnimationController _shimmerController;
  static const String _cacheKeyPrefix = 'cached_top_spenders_';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _loadFromCacheFirst();
    _listenTopSpenders();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _rotatorTimer?.cancel();
    _giftersSubscription?.cancel();
    _pageController?.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadFromCacheFirst() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? cachedData = prefs.getString('$_cacheKeyPrefix${widget.roomId}');
      if (cachedData != null) {
        List<dynamic> decodedList = jsonDecode(cachedData);
        List<Map<String, dynamic>> gifters =
            decodedList.map((e) => Map<String, dynamic>.from(e)).toList();

        if (mounted && gifters.isNotEmpty && _topGifters.isEmpty) {
          setState(() {
            _topGifters = gifters;
          });
          _startAutoSlide();
        }
      }
    } catch (e) {
      debugPrint("❌ Cache load error: $e");
    }
  }

  Future<void> _saveToCache(List<Map<String, dynamic>> gifters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          '$_cacheKeyPrefix${widget.roomId}', jsonEncode(gifters));
    } catch (e) {
      debugPrint("❌ Cache save error: $e");
    }
  }

  void _listenTopSpenders() {
    // এখানে ২০ জনের ডাটা নিয়ে আসার জন্য limit(20) করে দেওয়া হয়েছে
    _giftersSubscription = FirebaseFirestore.instance
        .collection('users')
        .orderBy('totalSpent', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      List<Map<String, dynamic>> gifters = [];

      for (int i = 0; i < snapshot.docs.length; i++) {
        var doc = snapshot.docs[i];
        var userData = doc.data() as Map<String, dynamic>;

        gifters.add({
          'uid': doc.id,
          'name': userData['name'] ?? userData['userName'] ?? 'User',
          'avatar': userData['profilePic'] ?? userData['avatar'] ?? '',
          'frame': userData['activeFrameUrl'] ?? '',
          'amount': userData['totalSpent'] ?? userData['giftedAmount'] ?? 0,
          'rank': i + 1,
        });
      }

      if (mounted) {
        if (gifters.isNotEmpty) {
          setState(() {
            _topGifters = gifters;
          });
          _saveToCache(gifters);
          _startAutoSlide();
        }
      }
    }, onError: (e) {
      debugPrint("❌ Firestore error: $e");
    });
  }

  // ১ সেকেন্ড পরপর অটো স্লাইড করার লজিক
  void _startAutoSlide() {
    _autoScrollTimer?.cancel();
    if (_topGifters.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _pageController != null && _pageController!.hasClients) {
        int nextPage = (_pageController!.page?.toInt() ?? 0) + 1;
        if (nextPage >= _topGifters.length) {
          nextPage = 0;
        }

        _pageController!.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _navigateToProfile(BuildContext context, String uId) {
    if (uId.isEmpty) return;
    debugPrint("Navigate to profile: $uId");
  }

  @override
  Widget build(BuildContext context) {
    bool showBanner = widget.roomData['showBanner'] ?? true;
    if (!showBanner) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 150, // চিকন সাইজ
        height: 38, // লম্বাটে ও কম উচ্চতা যাতে সিট ঢাকা না পরে
        child: PageView.builder(
          controller: _pageController,
          itemCount: _topGifters.isNotEmpty ? _topGifters.length : 1,
          physics:
              const NeverScrollableScrollPhysics(), // ইউজার যেন হাত দিয়ে টানতে না পারে
          itemBuilder: (context, index) {
            var gifter = _topGifters.isNotEmpty
                ? _topGifters[index]
                : {'name': 'Top Spender', 'avatar': '', 'rank': 1, 'uid': ''};

            return GestureDetector(
              onTap: () => _navigateToProfile(context, gifter['uid'] ?? ''),
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF12711), Color(0xFFF5AF19)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amberAccent, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 5,
                          spreadRadius: 0.5,
                        )
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Align(
                              alignment: Alignment(
                                (_shimmerController.value * 4) - 2,
                                0,
                              ),
                              child: Container(
                                width: 30,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.0),
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 3),
                          child: Row(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                    ),
                                    child: ClipOval(
                                      child: gifter['avatar'] != "" &&
                                              gifter['avatar'] != null
                                          ? CachedNetworkImage(
                                              imageUrl: gifter['avatar'],
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  const CircularProgressIndicator(
                                                      strokeWidth: 1),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.person,
                                                          color: Colors.white,
                                                          size: 16),
                                            )
                                          : const Icon(Icons.person,
                                              color: Colors.white, size: 18),
                                    ),
                                  ),
                                  if (gifter['rank'] != null &&
                                      gifter['rank'] > 0)
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.amber,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        "${gifter['rank']}",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize
                                      .min, // অতিরিক্ত জায়গা নেওয়া বন্ধ করবে
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // প্রথমে "Top Spender #X" লেখাটি উপরে থাকবে
                                    Text(
                                      gifter['rank'] != null &&
                                              gifter['rank'] > 0
                                          ? "Top Spender #${gifter['rank']}"
                                          : "Top Spender",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        height:
                                            1.0, // লেখার ভেতরের গ্যাপ কমানোর জন্য
                                      ),
                                    ),
                                    const SizedBox(
                                        height:
                                            2), // গ্যাপ একদম সর্বনিম্ন রাখা হলো
                                    // ইউজারনেমটি ঠিক তার নিচে দেখাবে
                                    Text(
                                      gifter['name'] ?? 'User',
                                      maxLines: 1,
                                      overflow: TextOverflow
                                          .ellipsis, // নাম বড় হলে ডট ডট (...) হয়ে ভেতরেই থাকবে, ধাক্কা দিয়ে বের হবে না
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        height:
                                            1.0, // লেখার ভেতরের গ্যাপ কমানোর জন্য
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
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
