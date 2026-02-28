import 'package:flutter/material.dart';

class PKBattleView extends StatelessWidget {
  final int bluePoints;
  final int redPoints;

  const PKBattleView({
    super.key,
    required this.bluePoints,
    required this.redPoints,
  });

  @override
  Widget build(BuildContext context) {
    // পয়েন্টের অনুপাত বের করা (যাতে প্রোগ্রেস বার নড়ে)
    double total = (bluePoints + redPoints).toDouble();
    double progressValue = total == 0 ? 0.5 : bluePoints / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        children: [
          // নীল এবং লাল টিমের পয়েন্ট টেক্সট
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _pointText("BLUE", bluePoints, Colors.blue),
              const Text("VS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontStyle: FontStyle.italic)),
              _pointText("RED", redPoints, Colors.red),
            ],
          ),
          const SizedBox(height: 5),

          // মেইন পিকে প্রোগ্রেস বার (গ্লাস বর্ডার সহ)
          Container(
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.red, // ডান পাশের লাল কালার
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue), // বাম পাশের নীল কালার
              ),
            ),
          ),
          
          // নিচে ছোট টাইম কাউন্টার (পিকে কতক্ষণ চলবে)
          const Text("04:59", style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _pointText(String team, int score, Color color) {
    return Column(
      children: [
        Text(team, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        Text("$score", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
