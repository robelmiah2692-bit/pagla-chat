import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// 🇧🇩 [বাংলা মার্ক]: গিফট লেভেল উইজেট - আপডেট লজিক (Lv1=8000, +2000 per level)
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
    int xpValue = widget.totalGiftXp;

    // নতুন লজিক: লেভেল ১ = ৮০০০, লেভেল ২ = ১০০০০, লেভেল ৩ = ১২০০০...
    int level = 1;
    int currentLevelRequiredXp = 8000;
    int remainingXp = xpValue;

    // লুপ চালিয়ে নিখুঁত লেভেল ও অবশিষ্ট এক্সপি বের করা
    while (remainingXp >= currentLevelRequiredXp && level < 50) {
      remainingXp -= currentLevelRequiredXp;
      level++;
      currentLevelRequiredXp += 2000; // প্রতি লেভেলে ২০০০ করে টার্গেট বাড়বে
    }

    // যদি ইউজার সর্বোচ্চ ৫০ লেভেলে পৌঁছে যায়
    if (level >= 50) {
      level = 50;
      currentLevelRequiredXp = 8000 + (49 * 2000);
      remainingXp = currentLevelRequiredXp;
    }

    // 🇧🇩 প্রোগ্রেস ক্যালকুলেশন
    double progress = (currentLevelRequiredXp > 0)
        ? (remainingXp.toDouble() / currentLevelRequiredXp.toDouble()).clamp(0.0, 1.0)
        : 0.0;

    debugPrint("======== 👑 [PaglaChat Gift Level System] ========");
    debugPrint("📥 ইনপুট: $xpValue XP | 🆙 লেভেল: Lv.$level | 📊 প্রোগ্রেস: $remainingXp / $currentLevelRequiredXp XP");
    debugPrint("=============================================");

    Color roseColor = Colors.purpleAccent;
    if (level >= 10 && level < 20) roseColor = const Color(0xFFFF00FF);
    if (level >= 20 && level < 35) roseColor = Colors.pinkAccent;
    if (level >= 35) roseColor = Colors.amberAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      child: Row(
        children: [
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