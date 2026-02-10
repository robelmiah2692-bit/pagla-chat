import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MainNavigation()));

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const VoiceChatRoom(), // ১০ সিটের বোর্ড
    const DiamondStore(),  // ডায়মন্ড ও কয়েন
    const ProfilePage(),   // প্রোফাইল ও ফ্রেম
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A2E),
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.diamond), label: "স্টোর"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}

// --- ১. ভয়েস রুম (বোর্ড ও সিট) ---
class VoiceChatRoom extends StatelessWidget {
  const VoiceChatRoom({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("পাগলা ড্রিম রুম", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.games, color: Colors.greenAccent), onPressed: () {}), // গেমস
          IconButton(icon: const Icon(Icons.music_note, color: Colors.cyan), onPressed: () {}), // মিউজিক
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, 
                mainAxisSpacing: 25,
                childAspectRatio: 0.8,
              ),
              itemCount: 10, // ১০টি বসার বোর্ড
              itemBuilder: (context, index) => _buildSeat(index),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSeat(int index) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // প্রোফাইল ফ্রেম
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: index == 0 ? Colors.orange : Colors.blueAccent, width: 3),
              ),
            ),
            const CircleAvatar(radius: 34, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
            if (index == 0) const Positioned(top: 0, child: Icon(Icons.workspace_premium, color: Colors.gold, size: 20)),
          ],
        ),
        const SizedBox(height: 4),
        Text(index == 0 ? "Host" : "Seat ${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.black45,
      child: Row(
        children: [
          const Icon(Icons.chat, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 40, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)), 
          child: const TextField(decoration: InputDecoration(hintText: "কথা বলুন...", border: InputBorder.none, contentPadding: EdgeInsets.only(left: 15))))),
          IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.yellow, size: 32), onPressed: () {}), // গিফটিং
        ],
      ),
    );
  }
}

// --- ২. ডায়মন্ড স্টোর ---
class DiamondStore extends StatelessWidget {
  const DiamondStore({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(title: const Text("ডায়মন্ড ও কয়েন স্টোর"), backgroundColor: Colors.indigo),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          _buildItem("১০০ কয়েন", "৳ ১০০", Icons.diamond),
          _buildItem("৫০০ কয়েন", "৳ ৪৫০", Icons.auto_awesome),
          _buildItem("১০০০ কয়েন", "৳ ৮০০", Icons.stars),
        ],
      ),
    );
  }

  Widget _buildItem(String name, String price, IconData icon) {
    return Card(color: Colors.white10, child: ListTile(leading: Icon(icon, color: Colors.amber), title: Text(name, style: const TextStyle(color: Colors.white)), trailing: ElevatedButton(onPressed: () {}, child: Text(price))));
  }
}

// --- ৩. প্রোফাইল ও ফ্রেম ---
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          const SizedBox(height: 70),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.pink, width: 5))), // প্রফেশনাল ফ্রেম
                const CircleAvatar(radius: 55, backgroundColor: Colors.blueGrey, child: Icon(Icons.add_a_photo, size: 30)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          const Text("আপনার নাম", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("ID: 2692001", style: TextStyle(color: Colors.grey)),
          const Divider(color: Colors.white12, height: 40),
          _profileOption(Icons.image, "আমার স্টোরি"),
          _profileOption(Icons.workspace_premium, "আমার ফ্রেম ও ব্যাজ"),
          _profileOption(Icons.settings, "সেটিংস"),
        ],
      ),
    );
  }

  Widget _profileOption(IconData icon, String title) {
    return ListTile(leading: Icon(icon, color: Colors.pinkAccent), title: Text(title, style: const TextStyle(color: Colors.white)), trailing: const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.grey));
  }
}
