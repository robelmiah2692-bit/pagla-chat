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

class _RoomTopGiftersBannerState extends State<RoomTopGiftersBanner> {
  PageController? _pageController;
  Timer? _autoScrollTimer;
  Timer? _fetchIntervalTimer;
  List<Map<String, dynamic>> _topGifters = [];
  
  static const String _cacheKeyPrefix = 'cached_top_gifters_smooth_';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);

    // ১. প্রথমে ক্যাশ থেকে লোড করা যাতে অ্যাপ ওপেন হওয়ার সাথে সাথে ইনস্ট্যান্ট দেখায়
    _loadFromCacheFirst();

    // ২. ডাটাবেজে চাপ কমানোর জন্য লাইভ স্ট্রিম (snapshots) বাদ দিয়ে ৫ মিনিট পর পর ডাটা ফেচ করার লজিক দেওয়া হলো
    _fetchTopGifters();
    _fetchIntervalTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _fetchTopGifters();
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _fetchIntervalTimer?.cancel();
    _pageController?.dispose();
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

  // ডাটাবেজের ওপর চাপ কমাতে ஒன்-টাইম গেট (get()) ব্যবহার করা হলো
  Future<void> _fetchTopGifters() async {
    try {
      // আপনি চাইলে এখানে নির্দিষ্ট টাইম ফিল্টার বা টপ স্পেন্ডার কুয়েরি করতে পারেন
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('totalSpent', descending: true)
          .limit(20)
          .get();

      List<Map<String, dynamic>> gifters = [];

      for (int i = 0; i < snapshot.docs.length; i++) {
        var doc = snapshot.docs[i];
        var userData = doc.data();

        gifters.add({
          'uid': doc.id,
          'name': userData['name'] ?? userData['userName'] ?? 'User',
          'avatar': userData['profilePic'] ?? userData['avatar'] ?? '',
          'frame': userData['activeFrameUrl'] ?? '',
          'amount': userData['totalSpent'] ?? userData['giftedAmount'] ?? 0,
          'rank': i + 1,
        });
      }

      if (mounted && gifters.isNotEmpty) {
        setState(() {
          _topGifters = gifters;
        });
        _saveToCache(gifters);
        _startAutoSlide();
      }
    } catch (e) {
      debugPrint("❌ Firestore fetch error: $e");
    }
  }

  // অটো স্লাইড লজিক
  void _startAutoSlide() {
    _autoScrollTimer?.cancel();
    if (_topGifters.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _pageController != null && _pageController!.hasClients) {
        int nextPage = (_pageController!.page?.toInt() ?? 0) + 1;
        if (nextPage >= _topGifters.length) {
          nextPage = 0;
        }

        _pageController!.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
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
        width: 160,
        height: 38,
        child: PageView.builder(
          controller: _pageController,
          itemCount: _topGifters.isNotEmpty ? _topGifters.length : 1,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            var gifter = _topGifters.isNotEmpty
                ? _topGifters[index]
                : {'name': 'Top Spender', 'avatar': '', 'rank': 1, 'uid': ''};

            return GestureDetector(
              onTap: () => _navigateToProfile(context, gifter['uid'] ?? ''),
              // ভারী শিমার অ্যানিমেশন বাদ দিয়ে স্ক্রিনশটের মতো একটি প্রিমিয়াম ও হালকা ট্রান্সপারেন্ট ডিজাইন
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.amberAccent.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Row(
                    children: [
                      // অবতার ও র‍্যাংক ব্যাজ
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.amberAccent, width: 1.2),
                            ),
                            child: ClipOval(
                              child: gifter['avatar'] != "" &&
                                      gifter['avatar'] != null
                                  ? CachedNetworkImage(
                                      imageUrl: gifter['avatar'],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 1)),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.person,
                                              color: Colors.white, size: 16),
                                    )
                                  : const Icon(Icons.person,
                                      color: Colors.white, size: 16),
                            ),
                          ),
                          if (gifter['rank'] != null && gifter['rank'] > 0)
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
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      // নাম ও টপ স্পেন্ডার ইনফো
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gifter['rank'] != null && gifter['rank'] > 0
                                  ? "Top Gifter #${gifter['rank']}"
                                  : "Top Spender",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.amberAccent.withOpacity(0.9),
                                fontSize: 7.5,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              gifter['name'] ?? 'User',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}