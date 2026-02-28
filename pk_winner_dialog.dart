import 'package:flutter/material.dart';

class PKWinnerDialog extends StatelessWidget {
  final String winnerTeam; // "BLUE" বা "RED"
  final int bluePoints;
  final int redPoints;

  const PKWinnerDialog({
    super.key,
    required this.winnerTeam,
    required this.bluePoints,
    required this.redPoints,
  });

  @override
  Widget build(BuildContext context) {
    Color teamColor = winnerTeam == "BLUE" ? Colors.blue : Colors.red;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // পেছনের গ্লোয়িং ইফেক্ট
          Container(
            width: 280,
            height: 350,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: teamColor.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(color: teamColor.withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
                const SizedBox(height: 10),
                Text(
                  "$winnerTeam TEAM WINS!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: teamColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                // পয়েন্ট ব্রেকডাউন
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _scoreChip("BLUE", bluePoints, Colors.blue),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("VS", style: TextStyle(color: Colors.white38)),
                    ),
                    _scoreChip("RED", redPoints, Colors.red),
                  ],
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teamColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("অসাধারণ!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreChip(String label, int score, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        Text("$score", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
