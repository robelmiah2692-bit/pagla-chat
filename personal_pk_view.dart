import 'package:flutter/material.dart';

class PersonalPKView extends StatelessWidget {
  const PersonalPKView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _pkUser("You", "https://api.dicebear.com/7.x/avataaars/svg?seed=You", 1200),
              const Text("VS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20)),
              _pkUser("Opponent", "https://api.dicebear.com/7.x/avataaars/svg?seed=Opp", 950),
            ],
          ),
          const SizedBox(height: 10),
          // PK Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.6, // আপনার পয়েন্টের অনুপাত
              backgroundColor: Colors.red,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pkUser(String name, String img, int score) {
    return Row(
      children: [
        CircleAvatar(radius: 20, backgroundImage: NetworkImage(img)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
            Text("🔥 $score", style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }
}
