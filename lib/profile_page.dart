import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- ১. ইউজারের ডাটা (এগুলো ফায়ারবেস থেকে কন্ট্রোল হবে) ---
  String userName = "পাগলা ইউজার";
  String gender = "পুরুষ"; // বা "মহিলা"
  int diamonds = 200; // বোনাস ২০০ থেকে শুরু
  int xp = 0;
  int followers = 0;
  int following = 0;
  bool hasPremiumCard = false;

  // --- ২. ভিআইপি লেভেল ক্যালকুলেশন (আপনার দেওয়া লজিক) ---
  int getVipLevel() {
    if (xp >= 25000) return 8;
    if (xp >= 20000) return 7;
    if (xp >= 18000) return 6;
    if (xp >= 15000) return 5;
    if (xp >= 12000) return 4;
    if (xp >= 6000) return 3;
    if (xp >= 4000) return 2;
    if (xp >= 2000) return 1;
    return 0;
  }

  // --- ৩. ডাইমন্ড স্টোর পপ-আপ ---
  void _openDiamondStore() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2F),
      builder: (context) => Container(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            const Text("ডাইমন্ড কিনুন (বিকাশ/নগদ)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white10),
            _buildDiamondOption("৬০০০ ডাইমন্ড", "১৫০ টাকা"),
            _buildDiamondOption("১২০০০ ডাইমন্ড", "২৫০ টাকা"),
            _buildDiamondOption("২৪০০০ ডাইমন্ড", "৪৫০ টাকা"),
            _buildDiamondOption("৫০০০০০ ডাইমন্ড", "৮০০ টাকা"),
          ],
        ),
      ),
    );
  }

  Widget _buildDiamondOption(String amount, String price) {
    return ListTile(
      leading: const Icon(Icons.diamond, color: Colors.cyanAccent),
      title: Text(amount, style: const TextStyle(color: Colors.white)),
      trailing: Text(price, style: const TextStyle(color: Colors.greenAccent)),
      onTap: () {
        // এখানে বিকাশ/নগদ গেটওয়ে কানেক্ট হবে
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("পেমেন্ট সম্পন্ন হলে ফায়ারবেস থেকে ডাইমন্ড এড হবে")));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int vipLevel = getVipLevel();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children: [const Icon(Icons.diamond, color: Colors.amber, size: 16), Text(" $diamonds")]),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => _openSettings()),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ১. প্রোফাইল পিকচার ও ফ্রেম
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ভিআইপি ফ্রেম লজিক
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: vipLevel > 0 ? Colors.amber : Colors.grey, width: 4),
                    ),
                  ),
                  // অটোমেটিক ছেলে/মেয়ে পিকচার লজিক
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white10,
                    backgroundImage: NetworkImage(gender == "পুরুষ" 
                        ? "https://i.ibb.co/example/male.png" 
                        : "https://i.ibb.co/example/female.png"),
                  ),
                  // ভিআইপি ব্যাজ
                  if (vipLevel > 0) Positioned(bottom: 0, child: Container(color: Colors.amber, child: Text(" VIP $vipLevel ", style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            
            // ২. ফলোয়ার/ফলোয়িং সেকশন
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStat("ফলোয়ার", followers),
                const SizedBox(width: 30),
                _buildStat("ফলোয়িং", following),
              ],
            ),
            const SizedBox(height: 20),

            // ৩. ডিজাইন বোর্ড (ডাইমন্ড স্টোর ও প্রিমিয়াম বক্স)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionCard("ডাইমন্ড স্টোর", Icons.shopping_bag, Colors.blue, _openDiamondStore),
                _buildActionCard("প্রিমিয়াম বক্স", Icons.card_membership, Colors.purple, () {}),
              ],
            ),

            // ৪. অনলাইন রুম লিস্ট (ইউজারদের রুম শো করবে)
            const Padding(
              padding: EdgeInsets.all(15.0),
              child: Align(alignment: Alignment.centerLeft, child: Text("অনলাইন রুমসমূহ", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            ),
            _buildOnlineRooms(),
          ],
        ),
      ),
    );
  }

  // --- সেটিংস মেনু ---
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2F),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.language), title: const Text("ভাষা পরিবর্তন (বাংলা/English)"), onTap: () {}),
          ListTile(leading: const Icon(Icons.wc), title: const Text("লিঙ্গ পরিবর্তন"), onTap: () {}),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("লগ আউট"), onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int count) {
    return Column(children: [Text("$count", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white54))]);
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150, height: 100,
        decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(15), border: Border.all(color: color)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 30), const SizedBox(height: 5), Text(title, style: const TextStyle(color: Colors.white))]),
      ),
    );
  }

  Widget _buildOnlineRooms() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) => ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.pinkAccent, child: Icon(Icons.mic)),
        title: Text("আড্ডা রুম ${index + 1}", style: const TextStyle(color: Colors.white)),
        subtitle: const Text("১০ জন মানুষ আড্ডা দিচ্ছে", style: TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
        onTap: () { /* রুম এ প্রবেশ */ },
      ),
    );
  }
}
