import 'package:flutter/material.dart';

import 'package:pagla_chat/services/diamond_recharge_view.dart';
 // রিচার্জের জন্য

class VIPBenefitsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const VIPBenefitsScreen({super.key, required this.userData});

  @override
  State<VIPBenefitsScreen> createState() => _VIPBenefitsScreenState();
}

class _VIPBenefitsScreenState extends State<VIPBenefitsScreen> {
  // পরবর্তী লেভেলের XP টার্গেট লজিক
  int getNextLevelTarget(int currentXP) {
    if (currentXP < 1000) return 1000;
    if (currentXP < 2500) return 2500;
    if (currentXP < 5000) return 5000;
    return 10000;
  }

  @override
  Widget build(BuildContext context) {
    int currentXP = widget.userData['vip_xp'] ?? 0;
    int targetXP = getNextLevelTarget(currentXP);
    double progress = (currentXP / targetXP).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // রয়্যাল ডার্ক ব্যাকগ্রাউন্ড
      appBar: AppBar(
        title: const Text("VIP Center", style: TextStyle(color: Colors.amber)),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // ১. ইউজার প্রগ্রেস কার্ড (Screenshot_2026-07-01-12-45-23-985_com.ahchat.app.jpg এর মতো)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Row(children: [
                    CircleAvatar(backgroundImage: NetworkImage(widget.userData['profilePic'] ?? '')),
                    const SizedBox(width: 10),
                    Text(widget.userData['name'] ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 18)),
                  ]),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: progress, backgroundColor: Colors.grey, color: Colors.amber),
                  Text("$currentXP / $targetXP XP", style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
          
          // ২. প্রিভিলেজ গ্রিড (Screenshot_2026-07-01-12-45-46-745_com.ahchat.app.jpg এর মতো)
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              children: [
                _buildFeatureIcon(Icons.badge, "VIP Badge"),
                _buildFeatureIcon(Icons.crop_original, "VIP Frame"),
                _buildFeatureIcon(Icons.card_giftcard, "Exclusive Gifts"),
                _buildFeatureIcon(Icons.chat_bubble, "Chat Privileges"),
                _buildFeatureIcon(Icons.person, "Profile Show"),
                _buildFeatureIcon(Icons.mic, "Mic Protection"),
              ],
            ),
          ),

          // ৩. রিচার্জ বাটন
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () {
                  showModalBottomSheet(context: context, builder: (_) => DiamondStoreView(userData: widget.userData, isAgent: false));
                },
                child: const Text("Recharge now", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.amberAccent, size: 30),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
      ],
    );
  }
}