import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// 🇧🇩 [বাংলা মার্ক]: অ্যাক্টিভ লেভেল উইজেট - নতুন গাণিতিক সূত্র এবং গ্লো পয়েন্ট ১০০% ফিক্সড ভাই
class ActiveLevelBar extends StatefulWidget {
  final int totalActiveXp;

  const ActiveLevelBar({super.key, required this.totalActiveXp});

  @override
  State<ActiveLevelBar> createState() => _ActiveLevelBarState();
}

class _ActiveLevelBarState extends State<ActiveLevelBar> with SingleTickerProviderStateMixin {
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
    int xpValue = widget.totalActiveXp; // ডাটাবেজ থেকে আসা টোটাল অ্যাক্টিভ এক্সপি

    // 🎯 ১ থেকে ৫০ লেভেল পর্যন্ত ২০০ করে বাড়ার গাণিতিক সূত্র ভাই
    int level = 1;
    int remainingXp = xpValue;
    int currentLevelRequiredXp = 1000; // লেভেল ১ এর জন্য বেস ১০০০ এক্সপি

    // লুপ চালিয়ে প্রতি লেভেলের ২০০ বাড়তি টার্গেট মাইনাস করে নিখুঁত কারেন্ট লেভেল বের করা ভাই
    while (remainingXp >= currentLevelRequiredXp && level < 50) {
      remainingXp -= currentLevelRequiredXp;
      level++;
      currentLevelRequiredXp = 1000 + ((level - 1) * 200); // প্রতি লেভেলে টার্গেট ২০০ করে বাড়বে
    }

    // যদি ইউজার সর্বোচ্চ ৫০ লেভেলে পৌঁছে যায়
    if (level >= 50) {
      level = 50;
      currentLevelRequiredXp = 1000 + (49 * 200); // ৫০ লেভেলের টার্গেট (১০,৮০০ এক্সপি)
      remainingXp = currentLevelRequiredXp; // বার ফুল দেখাবে ভাই
    }

    // 🇧🇩 [বাংলা মার্ক]: int টু double নিখুঁত রেশিও কনভার্ট ভাই (যাতে বার ০ না দেখায়)
    double progress = (currentLevelRequiredXp > 0)
        ? (remainingXp.toDouble() / currentLevelRequiredXp.toDouble()).clamp(0.0, 1.0)
        : 0.0;

    // 🇧🇩 [মাস্টার প্রিন্ট]: অ্যাক্টিভ এক্সপির লাইভ ট্র্যাকিং লগ ভাই
    debugPrint("======== ❤️ [PaglaChat Active Level System] ========");
    debugPrint("📥 ইনপুট প্রাপ্ত totalActiveXp: $xpValue");
    debugPrint("🆙 বর্তমান অ্যাক্টিভ লেভেল: Lv.$level");
    debugPrint("📊 লেভেলের এক্সপি প্রোগ্রেস: $remainingXp / $currentLevelRequiredXp XP");
    debugPrint("📈 বারের পারসেন্টেজ (Ratio): ${(progress * 100).toStringAsFixed(1)}%");
    debugPrint("====================================================");

    Color heartColor = Colors.pinkAccent;
    if (level >= 10 && level < 20) heartColor = const Color(0xFFFF00FF);
    if (level >= 20 && level < 35) heartColor = Colors.redAccent;
    if (level >= 35) heartColor = const Color(0xFFFFD700);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      child: Row(
        children: [
          // ❤️ ডাইনামিক লাভ ব্যাজ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: heartColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: heartColor.withOpacity(0.6), width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite, size: 12, color: heartColor),
                const SizedBox(width: 2),
                Text(
                  "Lv.$level",
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                      "Active Level",
                      style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "$remainingXp/$currentLevelRequiredXp XP",
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // 🎨 প্রোগ্রেস বার লজিক (লেআউট উইডথ বাগ ফিক্সড)
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
                        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // ১. পুরাতন স্থির কমলা-লাল গ্রেডিয়েন্ট (আপনার ডিজাইন ভাই)
                            if (progress > 0)
                              Container(
                                width: barWidth,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.deepOrange, Colors.redAccent, Colors.orange],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            
                            // ২. 🔥 মাথার ঠিক শেষ প্রান্তে আগুনের জ্বলজ্বলে ঝলক (Glow Point)
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
                                            color: Colors.redAccent.withOpacity(0.8),
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