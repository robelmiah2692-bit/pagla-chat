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
        unselectedItemColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mic_none_rounded), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.diamond_outlined), label: "স্টোর"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}

class VoiceRoom extends StatelessWidget {
  const VoiceRoom({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("পাগলা ড্রিম রুম", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 30),
              itemCount: 10,
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
            Container(
              width: 75, height: 75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // এখানে gold এর বদলে amber ব্যবহার করা হয়েছে
                border: Border.all(color: index == 0 ? Colors.amber : Colors.blueAccent, width: 3),
              ),
            ),
            const CircleAvatar(radius: 32, backgroundColor: Colors.white12, child: Icon(Icons.person, color: Colors.white)),
            if (index == 0) const Positioned(top: 0, child: Icon(Icons.workspace_premium, color: Colors.amber, size: 18)),
          ],
        ),
        const SizedBox(height: 5),
        Text(index == 0 ? "Host" : "Seat ${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.black45,
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline, color: Colors.white70),
          const SizedBox(width: 15),
          Expanded(child: Container(height: 40, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)))),
          const SizedBox(width: 15),
          const Icon(Icons.card_giftcard, color: Colors.amber, size: 30),
        ],
      ),
    );
  }
}

class DiamondStore extends StatelessWidget {
  const DiamondStore({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF1A1A2E), body: const Center(child: Text("কয়েন স্টোর", style: TextStyle(color: Colors.white))));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF121212), body: const Center(child: Text("প্রোফাইল পেজ", style: TextStyle(color: Colors.white))));
}
