import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SplashScreen(),
  ));
}

// ১. স্প্ল্যাশ স্ক্রিন (লোগো দেখানোর জন্য)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                'assets/logo.jpg', // তোমার লোগো ফাইল
                width: 150,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.account_circle, size: 120, color: Colors.white24),
              ),
            ),
            const SizedBox(height: 25),
            const Text("পাগলা চ্যাট", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: Colors.pinkAccent),
          ],
        ),
      ),
    );
  }
}

// ২. মেইন নেভিগেশন (নিচের বাটনগুলো)
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const VoiceRoom(),
    const DiamondStore(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A2E),
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white70,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mic_rounded), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), label: "স্টোর"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}

// ৩. ভয়েস রুম (১০ জনের বোর্ড ও চ্যাট)
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  final List<String> _messages = [];
  final TextEditingController _chatController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("ড্রিম ভয়েস রুম", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.music_note, color: Colors.cyanAccent), onPressed: () {})],
      ),
      body: Column(
        children: [
          // ১০ জন বসার বোর্ড
          SizedBox(
            height: 320,
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10),
              itemCount: 10,
              itemBuilder: (context, index) => Column(
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: index == 0 ? Colors.amber : Colors.blueAccent, width: 3),
                    ),
                    child: const CircleAvatar(radius: 30, backgroundColor: Colors.white12, child: Icon(Icons.person, color: Colors.white)),
                  ),
                  const SizedBox(height: 4),
                  Text(index == 0 ? "Host" : "Seat ${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 10)),
                ],
              ),
            ),
          ),
          // চ্যাট মেসেজ এরিয়া
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _messages.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(text: "ইউজার: ", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
                        TextSpan(text: _messages[index], style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // চ্যাট ইনপুট ও গিফট
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.black45,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: "মেসেজ লিখুন...", hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none),
                  ),
                ),
                IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.amber), onPressed: () {}),
                IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: () {
                  if (_chatController.text.isNotEmpty) {
                    setState(() { _messages.add(_chatController.text); _chatController.clear(); });
                  }
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ৪. ডায়মন্ড স্টোর (নতুন ডিজাইন)
class DiamondStore extends StatelessWidget {
  const DiamondStore({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(title: const Text("কয়েন স্টোর"), backgroundColor: Colors.indigo),
      body: GridView.count(
        padding: const EdgeInsets.all(15),
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
        children: [
          _buildItem("১০০ কয়েন", "৳ ১০০", Icons.diamond),
          _buildItem("৫০০ কয়েন", "৳ ৪৫০", Icons.auto_awesome),
          _buildItem("১০০০ কয়েন", "৳ ৮০০", Icons.stars),
          _buildItem("৫০০০ কয়েন", "৳ ৩০০০", Icons.workspace_premium),
        ],
      ),
    );
  }
  Widget _buildItem(String title, String price, IconData icon) => Card(
    color: Colors.white10,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 40),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent), child: Text(price)),
      ],
    ),
  );
}

// ৫. প্রোফাইল ও ফ্রেম
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
                Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.pinkAccent, width: 4))),
                const CircleAvatar(radius: 55, backgroundColor: Colors.white10, child: Icon(Icons.camera_alt, color: Colors.white30, size: 30)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("পাগলা ইউজার", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("ID: 2692001", style: TextStyle(color: Colors.grey)),
          const Divider(color: Colors.white10, height: 50, indent: 40, endIndent: 40),
          _buildOption(Icons.grid_view_rounded, "আমার ফ্রেম ও ব্যাজ", Colors.amber),
          _buildOption(Icons.history, "চ্যাট হিস্টোরি", Colors.blue),
          _buildOption(Icons.settings, "সেটিংস", Colors.grey),
        ],
      ),
    );
  }
  Widget _buildOption(IconData icon, String title, Color color) => ListTile(
    leading: Icon(icon, color: color),
    title: Text(title, style: const TextStyle(color: Colors.white)),
    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
  );
}
