import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pagla_chat/services/diamond_recharge_view.dart';

class ActiveLevelBar extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ActiveLevelBar({super.key, required this.userData});

  @override
  State<ActiveLevelBar> createState() => _ActiveLevelBarState();
}

class _ActiveLevelBarState extends State<ActiveLevelBar>
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

  // লেভেল অনুযায়ী সঠিক অ্যাসেট ব্যাজ পাথ রিটার্ন করার ফাংশন
  String getActiveBadgePath(int level) {
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
    // আপনার পুরোনো ১০০% কাজ করা সঠিক এক্সপি লজিক
    int xpValue = widget.userData['total_active_xp'] ??
        widget.userData['totalActiveXp'] ??
        0;

    // লেভেল ক্যালকুলেশন লজিক
    int level = 1;
    int currentLevelRequiredXp = 8000;

    int remainingXp = xpValue;
    while (remainingXp >= currentLevelRequiredXp && level < 50) {
      remainingXp -= currentLevelRequiredXp;
      level++;
      currentLevelRequiredXp += 2000; // প্রতি লেভেলে ২০০০ করে বাড়ছে
    }

    // সর্বোচ্চ লেভেল ৫০ লিমিট করা
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

    // বর্তমান লেভেলের জন্য অ্যাসেট ব্যাজ পাথ
    String badgePath = getActiveBadgePath(level);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00B4DB),
              Color(0xFF0083B0),
              Color(0xFF4A00E0),
              Color(0xFF190033),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text(
                  "Active Level (Lv.$level)",
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
                    border:
                        Border.all(color: Colors.amberAccent.withOpacity(0.3)),
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
                                  "Active Level Progress",
                                  style: TextStyle(
                                      color:
                                          Colors.amberAccent.withOpacity(0.9),
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          // 🔥 ব্যাজ এবং লেভেল টেক্সট একসাথে দেখানোর জন্য Stack
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // লোকাল ব্যাজ ইমেজ
                              Image.asset(
                                badgePath,
                                width: 55,
                                height: 55,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.stars,
                                        color: Colors.amberAccent, size: 32),
                              ),
                              // 🔥 লেভেল টেক্সট (এখন ডিজাইনের খালি জায়গায় নয়, ব্যাজের ওপরে বসানো হয়েছে)
                              Positioned(
                                bottom: 6, // ব্যাজের নিচের দিকে বসার জন্য
                                child: Text(
                                  "Lv.$level",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    // টেক্সট স্পষ্ট করার জন্য শ্যাডো
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
                                      "Active Level",
                                      style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "$remainingXp / $currentLevelRequiredXp XP",
                                      style: const TextStyle(
                                          color: Colors.cyanAccent,
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
                                                      Colors.deepOrange,
                                                      Colors.redAccent,
                                                      Colors.orange
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
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors.orange,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors
                                                                .redAccent
                                                                .withOpacity(
                                                                    0.8),
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
           
              // গ্রিড কার্ডস
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _buildFeatureCard(Icons.crop_original, "Profile Frame",
                          "Exclusive custom frame"),
                      _buildFeatureCard(Icons.bolt, "Room Entry Effect",
                          "Special animation on join"),
                      _buildFeatureCard(Icons.stars, "Active Badge",
                          "High-tier active level badge"),
                      _buildActiveLevelBadgeCard(context),
                      _buildFeatureCard(Icons.local_fire_department,
                          "XP Boost Privilege", "Faster milestone unlocks"),
                      _buildFeatureCard(Icons.verified_user, "Active Perks",
                          "Special room & chat features"),
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
                    child: const Text("Recharge Now (Get XP)",
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
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amberAccent.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.amberAccent, size: 26),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

// --- অ্যাক্টিভ লেভেল ব্যাজ প্রিভিউ কার্ড (সচ্ছ গ্লাস ইফেক্ট এবং দুই লাইনে সাজানো) ---
  Widget _buildActiveLevelBadgeCard(BuildContext context) {
    final List<String> badgeAssetPaths = [
      'assets/images/activelavel/Lva.webp',
      'assets/images/activelavel/Lva1.webp',
      'assets/images/activelavel/Lva2.webp',
      'assets/images/activelavel/Lva3.webp',
      'assets/images/activelavel/Lva4.webp',
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
              Icon(Icons.military_tech, color: Colors.amberAccent, size: 20),
              SizedBox(width: 6),
              Text(
                "Active Badges",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 🔥 ব্যাজগুলো দুই লাইনে সুন্দরভাবে দেখানোর জন্য Wrap উইজেট
          Expanded(
            child: Center(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: badgeAssetPaths.map((assetPath) {
                  return Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // 🔥 ট্রান্সপারেন্ট ব্যাকগ্রাউন্ড ও হালকা বর্ডার
                      color: Colors.transparent,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Image.asset(
                      assetPath,
                      width: 35,
                      height: 35,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error, size: 14, color: Colors.red),
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
