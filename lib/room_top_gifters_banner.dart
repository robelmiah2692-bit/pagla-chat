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

    // 👇 আপনার assets-এ রাখা ছবির পাথ এখানে বসাবেন
    const String badgeAssetPath = 'assets/images/newbenar2.gif';

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 200,
        height: 90,
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
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // ১. আপনার দেওয়া অ্যাসেট ব্যাজ ইমেজ/GIF
                  Positioned.fill(
                    child: Image.asset(
                      badgeAssetPath,
                      fit: BoxFit.fill,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),

                  // ২. ব্যাজের ভেতরের অংশে অবতার, নাম এবং নামের ঠিক পাশেই র‍্যাংক নম্বর
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 22,
                      top: 0,
                      bottom: 8,
                    ),
                    child: Row(
                      children: [
                        // ১) অবতার
                        Container(
                          width: 24,
                          height: 24,
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
                                            width: 10,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 1)),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.person,
                                            color: Colors.white, size: 14),
                                  )
                                : const Icon(Icons.person,
                                    color: Colors.white, size: 14),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // ২) নাম এবং ৩) নামের ঠিক পরেই লাগোয়া টপ গিফটার নম্বর (মাঝখানে ফাঁকা থাকবে না)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  gifter['name'] ?? 'User',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                    shadows: [
                                      Shadow(
                                          color: Colors.black, blurRadius: 3),
                                    ],
                                  ),
                                ),
                              ),
                              if (gifter['rank'] != null &&
                                  gifter['rank'] > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  "#${gifter['rank']}",
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.visible,
                                  style: const TextStyle(
                                    color: Color(0xFFFFE082),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    height: 1.0,
                                    shadows: [
                                      Shadow(
                                          color: Colors.black, blurRadius: 3),
                                    ],
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}
