import 'package:flutter/material.dart';

// 🇧🇩 [বাংলা মার্ক]: অ্যাক্টিভ লেভেল উইজেট - ভিআইপি বারের সমান সাইজ ও পারফেক্ট গ্যাপ
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
    int level = (widget.totalActiveXp ~/ 1000) + 1;
    if (level > 50) level = 50;
    
    int currentLevelXp = widget.totalActiveXp % 1000;
    double progress = currentLevelXp / 1000.0;

    Color heartColor = Colors.pinkAccent;
    if (level >= 10 && level < 20) heartColor = const Color(0xFFFF00FF);
    if (level >= 20 && level < 35) heartColor = Colors.redAccent;
    if (level >= 35) heartColor = const Color(0xFFFFD700);

    return Padding(
      // 📐 ভিআইপি বারের সাথে হুবহু মেলানোর জন্য ২৫ প্যাডিং দেওয়া হলো ভাই
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
          const SizedBox(width: 8), // ব্যাজ এবং বারের মধ্যকার দূরত্ব কমানো হলো ভাই

          // 🔥 আগুনের মতো প্রোগ্রেস বার এবং তার ভেতরের টেক্সট
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // লেবেল এবং এক্সপি কাউন্টার বারের ঠিক উপরে কাছাকাছি আনা হলো
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Active Level",
                      style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "$currentLevelXp/1000 XP",
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // প্রোগ্রেস বার (হাইট ৮ করা হলো ভিআইপি বারের সমান)
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        AnimatedBuilder(
                          animation: _fireController,
                          builder: (context, child) {
                            return Container(
                              width: MediaQuery.of(context).size.width * progress,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: const [Colors.deepOrange, Colors.redAccent, Colors.orange],
                                  begin: Alignment(-2.0 + (_fireController.value * 2), 0.0),
                                  end: Alignment(1.0 + (_fireController.value * 2), 0.0),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}