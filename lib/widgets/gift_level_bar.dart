import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// 🇧🇩 [বাংলা মার্ক]: গিফট লেভেল উইজেট - লেআউট বাগ এবং গ্লো পয়েন্ট ১০০% ফিক্সড ভাই
class GiftLevelBar extends StatefulWidget {
  final int totalGiftXp;

  const GiftLevelBar({super.key, required this.totalGiftXp});

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

  @override
  Widget build(BuildContext context) {
    int xpValue = widget.totalGiftXp; // ডাটাবেজ থেকে আসা টোটাল এক্সপি

    // 🎯 ১ থেকে ৫০ লেভেল পর্যন্ত ২০০ করে বাড়ার গাণিতিক সূত্র ভাই
    int level = 1;
    int remainingXp = xpValue;
    int currentLevelRequiredXp = 1000; // লেভেল ১ এর জন্য বেস ১০০০ এক্সপি

    // লুপ চালিয়ে নিখুঁত লেভেল বের করা ভাই
    while (remainingXp >= currentLevelRequiredXp && level < 50) {
      remainingXp -= currentLevelRequiredXp;
      level++;
      currentLevelRequiredXp = 1000 + ((level - 1) * 200); // প্রতি লেভেলে ২০০ করে টার্গেট বাড়বে
    }

    // যদি ইউজার সর্বোচ্চ ৫০ লেভেলে পৌঁছে যায়
    if (level >= 50) {
      level = 50;
      currentLevelRequiredXp = 1000 + (49 * 200); // ৫০ লেভেলের টার্গেট (১০,৮০০ এক্সপি)
      remainingXp = currentLevelRequiredXp; // বার ফুল দেখাবে ভাই
    }

    // 🇧🇩 [বাংলা মার্ক]: int টু double কনভার্ট ফিক্স লজিক ভাই (এবার বার ১০০% শো করবে)
double progress = (currentLevelRequiredXp > 0)
    ? (remainingXp.toDouble() / currentLevelRequiredXp.toDouble()).clamp(0.0, 1.0)
    : 0.0;

    // 🇧🇩 [মাস্টার প্রিন্ট]: ডাটাবেজ পাথ ও রিয়েল-টাইম ডাটা ট্র্যাকিং লগ ভাই
    debugPrint("======== 👑 [PaglaChat Level System] ========");
    debugPrint("📌 ডাটা সোর্স পাথ: users -> uID / authUID / email");
    debugPrint("📥 ডাটাবেজ থেকে প্রাপ্ত totalGiftXp: $xpValue");
    debugPrint("🆙 বর্তমান লেভেল: Lv.$level");
    debugPrint("📊 লেভেলের এক্সপি প্রোগ্রেস: $remainingXp / $currentLevelRequiredXp XP");
    debugPrint("📈 বারের পারসেন্টেজ (Ratio): ${(progress * 100).toStringAsFixed(1)}%");
    debugPrint("=============================================");

    Color roseColor = Colors.purpleAccent;
    if (level >= 10 && level < 20) roseColor = const Color(0xFFFF00FF);
    if (level >= 20 && level < 35) roseColor = Colors.pinkAccent;
    if (level >= 35) roseColor = Colors.amberAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      child: Row(
        children: [
          // 🌹 ডাইমানিক গোলাপ ফুল ব্যাজ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: roseColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: roseColor.withOpacity(0.6), width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_florist, size: 12, color: roseColor),
                const SizedBox(width: 2),
                Text(
                  "Lv.$level",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 🔥 প্রোগ্রেস বার এবং টেক্সট
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Gift Level",
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "$remainingXp/$currentLevelRequiredXp XP",
                      style: const TextStyle(
                          color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // 🎨 প্রোগ্রেস বার লজিক (উইডথ বাগ ফিক্সড)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double maxWidth = constraints.maxWidth;
                    final double barWidth = maxWidth * progress;

                    return Container(
                      height: 8,
                      width: maxWidth,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1), width: 0.8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // ১. স্থির বেগুনি গ্রেডিয়েন্ট (ফ্লেক্সিবল সাইজিং লজিক ভাই)
                            if (progress > 0)
                              Container(
                                width: barWidth,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.purple,
                                      Colors.purpleAccent,
                                      Colors.deepPurpleAccent
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),

                            // ২. 🔥 মাথার শেষ প্রান্তে জ্বলজ্বলে আগুনের ঝলক (Glow Point)
                            if (barWidth > 4)
                              Positioned(
                                left: barWidth - 8,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.amber,
                                    highlightColor: const Color(0xFFFF4500),
                                    period: const Duration(milliseconds: 1000),
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.orange,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.redAccent
                                                .withOpacity(0.8),
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
    );
  }
}