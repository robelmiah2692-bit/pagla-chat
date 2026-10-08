import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pagla_chat/services/diamond_recharge_view.dart';

class VIPBenefitsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const VIPBenefitsScreen({super.key, required this.userData});

  @override
  State<VIPBenefitsScreen> createState() => _VIPBenefitsScreenState();
}

class _VIPBenefitsScreenState extends State<VIPBenefitsScreen> {
  // Correct VIP Level and Target XP Calculation matching your project logic
  int getVipLevel(int xp) {
    if (xp >= 65000) return 8;
    if (xp >= 60000) return 7;
    if (xp >= 38000) return 6;
    if (xp >= 28000) return 5;
    if (xp >= 18000) return 4;
    if (xp >= 14000) return 3;
    if (xp >= 8000) return 2;
    if (xp >= 3500) return 1;
    return 0;
  }

  int getNextLevelTarget(int currentXP) {
    if (currentXP < 3500) return 3500;
    if (currentXP < 8000) return 8000;
    if (currentXP < 14000) return 14000;
    if (currentXP < 18000) return 18000;
    if (currentXP < 28000) return 28000;
    if (currentXP < 38000) return 38000;
    if (currentXP < 60000) return 60000;
    if (currentXP < 65000) return 65000;
    return 65000; // Max level target
  }

// ভিআইপি ব্যাজ পাথ পাওয়ার ফাংশন (লোকাল webp অ্যাসেট)
  String getVipBadgePath(int level) {
    if (level <= 0) return "";
    return "assets/images/vip/vip$level.webp"; // আপনার ফোল্ডার স্ট্রাকচার অনুযায়ী পাথ
  }

  @override
  Widget build(BuildContext context) {
    int currentXP = widget.userData['vip_xp'] ?? 0;
    int currentLevel = getVipLevel(currentXP);
    int targetXP = getNextLevelTarget(currentXP);
    double progress = (currentXP / targetXP).clamp(0.0, 1.0);
// বর্তমান ভিআইপি লেভেলের ব্যাজ পাথ
    String vipBadgePath = getVipBadgePath(currentLevel);
    return Scaffold(
      // Background matched with your provided design image (Blue and Purple gradient, no solid black)
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00B4DB), // Bright Cyan Blue from top curve
              Color(0xFF0083B0), // Mid Blue tone
              Color(0xFF4A00E0), // Deep Purple gradient match
              Color(0xFF190033), // Rich dark purple-blue base
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text("VIP Center (Level $currentLevel)",
                    style: const TextStyle(
                        color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.cyanAccent),
              ),
              // 1. User Progress Card with matching theme
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                  widget.userData['profilePic'] ?? '')),
                          const SizedBox(width: 10),
                          // নামের পাশেই ভিআইপি ব্যাজ ও নাম দেখানোর অংশ
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  widget.userData['name'] ?? 'User',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // যদি লেভেল ০ এর বেশি হয় তবে লোকাল ব্যাজ শো করবে
                                if (currentLevel > 0 && vipBadgePath.isNotEmpty)
                                  Image.asset(
                                    vipBadgePath,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.stars, color: Colors.amberAccent, size: 24),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white24,
                        color: Colors.cyanAccent,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Level $currentLevel",
                              style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold)),
                          Text("$currentXP / $targetXP XP",
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Expanded Privilege Grid containing both old and new features
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildVipBadgeGridCard(context),
                      _buildFeatureIcon(Icons.crop_original, "VIP Frame"),
                      _buildFeatureIcon(Icons.card_giftcard, "Exclusive Gifts"),
                      _buildFeatureIcon(Icons.chat_bubble, "Chat Privileges"),
                      _buildFeatureIcon(Icons.person, "Profile Show"),
                      _buildFeatureIcon(Icons.mic, "Mic Protection"),
                      _buildFeatureIcon(Icons.block, "Block/Unblock"),
                      _buildFeatureIcon(Icons.video_call, "Audio/Video Call"),
                      _buildFeatureIcon(Icons.star, "Super Admin Chance"),
                      _buildFeatureIcon(
                          Icons.supervisor_account, "Super Host Chance"),
                      _buildFeatureIcon(Icons.bolt, "VIP Entry"),
                      _buildFeatureIcon(
                          Icons.verified_user, "Respect Official"),
                      _buildFeatureIcon(Icons.verified, "Verified Tag"),
                      _buildFeatureIcon(
                          Icons.video_library, "Unlimited Videos"),
                      _buildFeatureIcon(
                          Icons.card_giftcard_outlined, "Video Photo Gift"),
                      _buildFeatureIcon(
                          Icons.photo_camera, "Gallery DP Upload"),
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
                      backgroundColor: Colors.cyanAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                          context: context,
                          builder: (_) => DiamondStoreView(
                              userData: widget.userData, isAgent: false));
                    },
                    child: const Text("Recharge Now",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
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

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

// --- ভিআইপি ব্যাজ প্রিভিউ কার্ড (সচ্ছ গ্লাস ইফেক্ট এবং ৩ লাইনে নির্দিষ্ট সংখ্যক ব্যাজ সাজানো) ---
  Widget _buildVipBadgeGridCard(BuildContext context) {
    final String assetBasePath = "assets/images/vip";

    // ১ থেকে ৮ পর্যন্ত ব্যাজগুলোর লোকাল অ্যাসেট পাথ আলাদা করা
    final List<String> row1Paths = [
      "$assetBasePath/vip1.webp",
      "$assetBasePath/vip2.webp",
      "$assetBasePath/vip3.webp",
    ];
    final List<String> row2Paths = [
      "$assetBasePath/vip4.webp",
      "$assetBasePath/vip5.webp",
      "$assetBasePath/vip6.webp",
    ];
    final List<String> row3Paths = [
      "$assetBasePath/vip7.webp",
      "$assetBasePath/vip8.webp",
    ];

    // একটি সিঙ্গেল ব্যাজ উইজেট তৈরির হেল্পার মেথড (লোক্যাল অ্যাসেটের জন্য)
    Widget buildBadgeItem(String assetPath) {
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
          width: 26, // কার্ডের ভেতরে সুন্দরভাবে ফিট করার জন্য সাইজ পারফেক্ট রাখা হয়েছে
          height: 26,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.error, size: 12, color: Colors.red),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // 🔥 সচ্ছ গ্লাস ব্যাকগ্রাউন্ড ও বর্ডার
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amberAccent.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // প্রথম লাইন (৩টি ব্যাজ)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row1Paths.map((path) => buildBadgeItem(path)).toList(),
          ),
          const SizedBox(height: 4),
          // দ্বিতীয় লাইন (৩টি ব্যাজ)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row2Paths.map((path) => buildBadgeItem(path)).toList(),
          ),
          const SizedBox(height: 4),
          // তৃতীয় লাইন (২টি ব্যাজ)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row3Paths.map((path) => buildBadgeItem(path)).toList(),
          ),
        ],
      ),
    );
  }
}
