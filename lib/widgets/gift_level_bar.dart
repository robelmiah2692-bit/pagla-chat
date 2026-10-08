import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pagla_chat/services/diamond_recharge_view.dart';

class GiftLevelBar extends StatefulWidget {
  final Map<String, dynamic> userData;

  const GiftLevelBar({super.key, required this.userData});

  @override
  State<GiftLevelBar> createState() => _GiftLevelBarState();
}

class _GiftLevelBarState extends State<GiftLevelBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _fireController;

  @override
  void initState() {
    super.initState();
    _fireController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _fireController.dispose();
    super.dispose();
  }

  // লেভেল অনুযায়ী সঠিক অ্যাসেট ব্যাজ পাথ রিটার্ন করার ফাংশন (০ থেকে ৫০ পর্যন্ত ৫টি ব্যাজের সাথে মিল রেখে)
  String getGiftBadgePath(int level) {
    if (level <= 10) {
      return 'assets/images/activelavel/Lva.webp';
    } else if (level <= 20) {
      return 'assets/images/activelavel/Lva1.webp';
    } else if (level <= 30) {
      return 'assets/images/activelavel/Lva2.webp';
    } else if (level <= 40) {
      return 'assets/images/activelavel/Lva3.webp';
    } else {
      return 'assets/images/activelavel/Lva4.webp';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ইউজার ডাটা থেকে গিফট এক্সপি রিড করা
    int xpValue =
        widget.userData['total_gift_xp'] ?? widget.userData['totalGiftXp'] ?? 0;

    // নতুন লজিক: লেভেল ১ = ৮০০০, লেভেল ২ = ১০০০০, লেভেল ৩ = ১২০০০...
    int level = 1;
    int currentLevelRequiredXp = 8000;
    int remainingXp = xpValue;

    // লুপ চালিয়ে নিখুঁত লেভেল ও অবশিষ্ট এক্সপি বের করা
    while (remainingXp >= currentLevelRequiredXp && level < 50) {
      remainingXp -= currentLevelRequiredXp;
      level++;
      currentLevelRequiredXp += 2000; // প্রতি লেভেলে ২০০০ করে টার্গেট বাড়বে
    }

    // যদি ইউজার সর্বোচ্চ ৫০ লেভেলে পৌঁছে যায়
    if (level >= 50) {
      level = 50;
      currentLevelRequiredXp = 8000 + (49 * 2000);
      remainingXp = currentLevelRequiredXp;
    }

    // প্রোগ্রেস ক্যালকুলেশন
    double progress = (currentLevelRequiredXp > 0)
        ? (remainingXp.toDouble() / currentLevelRequiredXp.toDouble())
            .clamp(0.0, 1.0)
        : 0.0;

    Color roseColor = Colors.purpleAccent;
    if (level >= 10 && level < 20) roseColor = const Color(0xFFFF00FF);
    if (level >= 20 && level < 35) roseColor = Colors.pinkAccent;
    if (level >= 35) roseColor = Colors.amberAccent;

    // বর্তমান লেভেলের জন্য অ্যাসেট ব্যাজ পাথ
    String badgePath = getGiftBadgePath(level);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8E2DE2),
              Color(0xFF4A00E0),
              Color(0xFF190033),
              Color(0xFF0A0014),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text(
                  "Gift Level (Lv.$level)",
                  style: const TextStyle(
                      color: Colors.amberAccent, fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.amberAccent),
              ),

              // ইউজার প্রোগ্রেস ও প্রোফাইল কার্ড
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roseColor.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: CachedNetworkImageProvider(
                                widget.userData['profilePic'] ?? ''),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.userData['name'] ?? 'User',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Gift Level Progress",
                                  style: TextStyle(
                                      color: roseColor.withOpacity(0.9),
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          // 🔥 টেক্সট বক্সের পরিবর্তে লোকাল ব্যাজ এবং তার ওপর লেভেল কাউন্ট (Stack দিয়ে)
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                badgePath,
                                width: 55,
                                height: 55,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.stars,
                                        color: Colors.amberAccent, size: 32),
                              ),
                              Positioned(
                                bottom: 6,
                                child: Text(
                                  "Lv.$level",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 2.0,
                                        color: Colors.black,
                                        offset: Offset(1.0, 1.0),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      // এক্সপি বার ও শিমার ইফেক্ট
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Gift Level",
                                      style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "$remainingXp / $currentLevelRequiredXp XP",
                                      style: TextStyle(
                                          color: roseColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double maxWidth =
                                        constraints.maxWidth;
                                    final double barWidth = maxWidth * progress;

                                    return Container(
                                      height: 8,
                                      width: maxWidth,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.1),
                                            width: 0.8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            if (progress > 0)
                                              Container(
                                                width: barWidth,
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                    colors: [
                                                      Colors.purple,
                                                      Colors.purpleAccent,
                                                      Colors.deepPurpleAccent
                                                    ],
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            if (barWidth > 4)
                                              Positioned(
                                                left: barWidth - 8,
                                                top: 0,
                                                bottom: 0,
                                                child: Center(
                                                  child: Shimmer.fromColors(
                                                    baseColor: Colors.amber,
                                                    highlightColor:
                                                        const Color(0xFFFF4500),
                                                    period: const Duration(
                                                        milliseconds: 1000),
                                                    child: Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration:
                                                          const BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors.orange,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors
                                                                .redAccent,
                                                            blurRadius: 4,
                                                            spreadRadius: 1,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // গ্রিড কার্ডস (গিফট লেভেলের ফিচারগুলো দেখানোর জন্য)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _buildFeatureCard(Icons.card_giftcard, "Gift Effect",
                          "Special animation on gifting"),
                      _buildGiftLevelBadgeCard(context),
                      _buildFeatureCard(Icons.star_border, "Gift Glow",
                          "Special frame & glow perks"),
                      _buildFeatureCard(Icons.trending_up, "Bonus XP",
                          "Extra boost on every send"),
                      _buildFeatureCard(Icons.diamond, "Diamond Privilege",
                          "Special reward returns"),
                      _buildFeatureCard(Icons.verified, "VIP Status",
                          "Exclusive room privileges"),
                    ],
                  ),
                ),
              ),

              // রিচার্জ বাটন
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                          context: context,
                          builder: (_) => DiamondStoreView(
                              userData: widget.userData, isAgent: false));
                    },
                    child: const Text("Recharge Now (Get Gift XP)",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.purpleAccent, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

// --- গিফট লেভেল ব্যাজ প্রিভিউ কার্ড (সচ্ছ গ্লাস ইফেক্ট এবং দুই লাইনে সাজানো) ---
  Widget _buildGiftLevelBadgeCard(BuildContext context) {
    final List<String> giftBadgeAssetPaths = [
      'assets/images/giftlavel/gi.webp',
      'assets/images/giftlavel/gi1.webp',
      'assets/images/giftlavel/gi2.webp',
      'assets/images/giftlavel/gi3.webp',
      'assets/images/giftlavel/gi4.webp',
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        // 🔥 সচ্ছ গ্লাস ব্যাকগ্রাউন্ড
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amberAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Row(
            children: [
              Icon(Icons.local_florist, color: Colors.amberAccent, size: 20),
              SizedBox(width: 6),
              Text(
                "Gift Level Badges",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 🔥 গিফট ব্যাজগুলোর সাইজ বড় করে দুই লাইনে সাজানো হয়েছে
          Expanded(
            child: Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: giftBadgeAssetPaths.map((assetPath) {
                  return Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Image.asset(
                      assetPath,
                      width: 38, // ব্যাজের সাইজ
                      height: 38,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error, size: 18, color: Colors.red),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
