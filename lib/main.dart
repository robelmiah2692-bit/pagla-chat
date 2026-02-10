import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MainNavigation()));

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = [const VoiceChatRoom(), const DiamondStore(), const ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A2E),
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white,
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

// ভয়েস রুম স্ক্রিন
class VoiceChatRoom extends StatelessWidget {
  const VoiceChatRoom({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text("পাগলা ড্রিম রুম", style: TextStyle(color: Colors.white))),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 30),
              itemCount: 10,
              itemBuilder: (context, index) => Column(
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: index == 0 ? Colors.gold : Colors.cyan, width: 3)),
                    child: const CircleAvatar(radius: 30, backgroundColor: Colors.white12, child: Icon(Icons.person, color: Colors.white)),
                  ),
                  Text(index == 0 ? "Host" : "Seat ${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 10)),
                ],
              ),
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }
  Widget _bottomBar() => Container(padding: const EdgeInsets.all(15), color: Colors.white10, child: const Row(children: [Icon(Icons.chat, color: Colors.white), Spacer(), Icon(Icons.card_giftcard, color: Colors.yellow, size: 30)]));
}

// ডায়মন্ড স্টোর এবং প্রোফাইল পেজ (সংক্ষেপে)
class DiamondStore extends StatelessWidget { const DiamondStore({super.key}); @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF1A1A2E), body: const Center(child: Text("কয়েন স্টোর কামিং সুন", style: TextStyle(color: Colors.white)))); }
class ProfilePage extends StatelessWidget { const ProfilePage({super.key}); @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF1A1A2E), body: const Center(child: Text("প্রোফাইল ও ফ্রেম সেকশন", style: TextStyle(color: Colors.white)))); }
