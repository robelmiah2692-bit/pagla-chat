import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pagla_chat/services/diamond_recharge_view.dart';

class CrownBenefitsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const CrownBenefitsScreen({super.key, required this.userData});

  @override
  State<CrownBenefitsScreen> createState() => _CrownBenefitsScreenState();
}

class _CrownBenefitsScreenState extends State<CrownBenefitsScreen> {
  // 👑 ৬টি ক্রাউনের লোকাল অ্যাসেট পাথ
  final Map<int, String> crownBadges = {
    1: 'assets/images/crown/crown1.webp',
    2: 'assets/images/crown/crown2.webp',
    3: 'assets/images/crown/crown3.webp',
    4: 'assets/images/crown/crown4.webp',
    5: 'assets/images/crown/crown5.webp',
    6: 'assets/images/crown/crown6.webp',
  };

  // 👑 ক্রাউন লেভেল ও এক্সপি ক্যালকুলেশন (vip_xp থেকে চেক করবে)
  int getCrownLevel(int xp) {
    if (xp >= 120000) return 6;
    if (xp >= 85000) return 5;
    if (xp >= 65000) return 4;
    if (xp >= 45000) return 3;
    if (xp >= 25000) return 2;
    if (xp >= 12000) return 1;
    return 0; // No Crown
  }

  int getNextCrownTarget(int currentXP) {
    if (currentXP < 12000) return 12000;
    if (currentXP < 25000) return 25000;
    if (currentXP < 45000) return 45000;
    if (currentXP < 65000) return 65000;
    if (currentXP < 85000) return 85000;
    if (currentXP < 120000) return 120000;
    return 120000; // Max Target
  }

  String getCrownBadge(int level) {
    return crownBadges[level] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    // সরাসরি ডাটাবেজ থেকে vip_xp নেওয়া হচ্ছে[cite: 1]
    int currentXP = widget.userData['vip_xp'] ?? 0;
    int currentLevel = getCrownLevel(currentXP);
    int targetXP = getNextCrownTarget(currentXP);
    double progress = (currentXP / targetXP).clamp(0.0, 1.0);
    // ক্রাউন ব্যাজের পাথ লোকাল ভেরিয়েবলে নিয়ে নেওয়া
    String crownPath = getCrownBadge(currentLevel);

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
                  "Crown $currentLevel",
                  style: const TextStyle(
                      color: Colors.amberAccent, fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.amberAccent),
              ),

              // 1. User Progress & Profile Card
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
                                  "Recharge Rule: 500 Diamonds = 1 XP",
                                  style: TextStyle(
                                      color:
                                          Colors.amberAccent.withOpacity(0.9),
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          // ক্রাউন ব্যাজ চেক এবং রেন্ডার
                          if (currentLevel > 0 && crownPath.isNotEmpty)
                            Image.asset(
                              crownPath,
                              width: 45,
                              height: 45,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.stars,
                                color: Colors.amberAccent,
                                size: 35,
                              ),
                            )
                          else
                            const SizedBox
                                .shrink(), // লেভেল ০ বা ব্যাজ না থাকলে ফাকা রাখবে
                        ],
                      ),
                      const SizedBox(height: 15),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white24,
                        color: Colors.amberAccent,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Crown $currentLevel",
                              style: const TextStyle(
                                  color: Colors.amberAccent,
                                  fontWeight: FontWeight.bold)),
                          Text("$currentXP / $targetXP XP",
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Privileges Grid
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
                      _buildCrownBadgeCard(context),
                      _buildFeatureCard(Icons.card_giftcard,
                          "Weekly 70% Bonus Pack", "Massive weekly rewards"),
                      _buildFeatureCard(Icons.local_fire_department,
                          "XP Boost Privilege", "Faster milestone unlocks"),
                      _buildFeatureCard(Icons.verified_user,
                          "VIP Access & Perks", "Special room & chat features"),
                    ],
                  ),
                ),
              ),

              // 3. Recharge Button
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

// --- ক্রাউন লেভেল ব্যাজ প্রিভিউ কার্ড (সচ্ছ গ্লাস ইফেক্ট এবং দুই লাইনে ৩টি করে সাজানো) ---
  Widget _buildCrownBadgeCard(BuildContext context) {
    final String assetBasePath = "assets/images/crown";

    // ১ থেকে ৬ পর্যন্ত ক্রাউন ব্যাজগুলোর লোকাল অ্যাসেট পাথ (webp ফরম্যাট)
    final List<String> row1Paths = [
      "$assetBasePath/crown1.webp",
      "$assetBasePath/crown2.webp",
      "$assetBasePath/crown3.webp",
    ];
    final List<String> row2Paths = [
      "$assetBasePath/crown4.webp",
      "$assetBasePath/crown5.webp",
      "$assetBasePath/crown6.webp",
    ];

    // একটি সিঙ্গেল ব্যাজ উইজেট তৈরির হেল্পার মেথড
    Widget buildCrownItem(String assetPath) {
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
          width: 32, // ক্রাউন ব্যাজের সাইজ
          height: 32,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.error, size: 16, color: Colors.red),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        // 🔥 সচ্ছ গ্লাস ব্যাকগ্রাউন্ড ও বর্ডার
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
              Icon(Icons.stars, color: Colors.amberAccent, size: 20),
              SizedBox(width: 6),
              Text(
                "Crown Badges",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 🔥 দুই লাইনে ৩টি করে ব্যাজ সাজানো
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // প্রথম লাইন (৩টি ক্রাউন ব্যাজ)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      row1Paths.map((path) => buildCrownItem(path)).toList(),
                ),
                const SizedBox(height: 4),
                // দ্বিতীয় লাইন (৩টি ক্রাউন ব্যাজ)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      row2Paths.map((path) => buildCrownItem(path)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
