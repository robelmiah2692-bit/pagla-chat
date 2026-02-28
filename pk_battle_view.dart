import 'package:flutter/material.dart';

class PKBattleView extends StatelessWidget {
  final int bluePoints;
  final int redPoints;
  // --- এই দুটি নতুন লাইন যোগ করা হলো ---
  final int pkSeconds; 
  final dynamic pkManager; 

  const PKBattleView({
    super.key,
    required this.bluePoints,
    required this.redPoints,
    // --- Constructor-এ এগুলোকে রিকোয়ার্ড করে দিলাম ---
    required this.pkSeconds,
    required this.pkManager,
  });

  @override
  Widget build(BuildContext context) {
    // পয়েন্টের অনুপাত বের করা
    double total = (bluePoints + redPoints).toDouble();
    double progressValue = total == 0 ? 0.5 : bluePoints / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        children: [
          // নীল এবং লাল টিমের পয়েন্ট টেক্সট
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _pointText("BLUE", bluePoints, Colors.blue),
              const Text("VS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontStyle: FontStyle.italic)),
              _pointText("RED", redPoints, Colors.red),
            ],
          ),
          const SizedBox(height: 5),

          // মেইন পিকে প্রোগ্রেস বার
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
                backgroundColor: Colors.red,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ),
          
          const SizedBox(height: 5),

          // এটি এখন সুন্দরভাবে কাজ করবে কারণ আমরা উপরে pkManager এবং pkSeconds ডিফাইন করেছি
          Text(
            pkManager.formatTime(pkSeconds), 
            style: const TextStyle(color: Colors.white70, fontSize: 12)
          ),
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
