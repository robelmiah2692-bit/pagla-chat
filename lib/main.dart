import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    title: "Pagla Chat",
    home: SplashScreen(),
  ));
}

// --- ১. স্প্ল্যাশ স্ক্রিন ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CircleAvatar(radius: 60, backgroundColor: Colors.pinkAccent, child: Icon(Icons.stars, size: 60, color: Colors.white)),
        const SizedBox(height: 20),
        const Text("PAGLA CHAT", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 5)),
      ])),
    );
  }
}

// --- ২. লগইন স্ক্রিন ---
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.g_mobiledata, size: 40),
          label: const Text("Sign in with Google"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation())),
        ),
      ),
    );
  }
}

// --- ৩. মেইন নেভিগেশন ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = [const HomePage(), const VoiceRoom(), const InboxPage(), const ProfilePage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF151525),
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white24,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "হোম"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: "ইনবক্স"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "আমি"),
        ],
      ),
    );
  }
}

// --- ৪. হোম পেজ ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(title: const Text("PAGLA HOME"), backgroundColor: Colors.transparent),
      body: ListView.builder(itemCount: 5, itemBuilder: (context, index) => _postCard()),
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.pinkAccent, child: const Icon(Icons.add), onPressed: () {}),
    );
  }
  Widget _postCard() => Container(
    margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [CircleAvatar(radius: 15), SizedBox(width: 10), Text("পাগলা কিং", style: TextStyle(color: Colors.white))]),
      const SizedBox(height: 10),
      const Text("সবাইকে স্বাগতম!", style: TextStyle(color: Colors.white70)),
      const Row(children: [Icon(Icons.favorite, color: Colors.pink), SizedBox(width: 20), Icon(Icons.comment, color: Colors.white54)]),
    ]),
  );
}

// --- ৫. ভয়েস রুম ---
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  bool isMicOn = false; // মাইক স্ট্যাটাস

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: Column(children: [
          _roomTopBar(),
          _videoSection(),
          _gameButtons(),
          Expanded(child: _seatLayout()), // ১৫ সিট
          _chatAndGiftSection(), // চ্যাট সেন্ড বাটন সহ
        ]),
      ),
    );
  }

  Widget _roomTopBar() => ListTile(
    leading: const CircleAvatar(backgroundImage: AssetImage('assets/logo.jpg')),
    title: const Text("পাগলা আড্ডা", style: TextStyle(color: Colors.white)),
    subtitle: const Text("ID: 550889 | 🌐 অনলাইন: ২৫", style: TextStyle(color: Colors.white54, fontSize: 10)),
    trailing: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock, color: Colors.orange), SizedBox(width: 10), Icon(Icons.gavel, color: Colors.red)]),
  );

  Widget _videoSection() => Container(
    margin: const EdgeInsets.all(10), height: 140,
    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15)),
    child: const Center(child: Icon(Icons.play_circle, color: Colors.pinkAccent, size: 50)),
  );

  Widget _gameButtons() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    ElevatedButton.icon(onPressed: (){}, icon: const Icon(Icons.casino), label: const Text("লুডু")),
    const SizedBox(width: 15),
    // **ফিচার ১: মাইক অন-অফ বাটন**
    GestureDetector(
      onTap: () => setState(() => isMicOn = !isMicOn),
      child: CircleAvatar(
        radius: 25,
        backgroundColor: isMicOn ? Colors.green : Colors.redAccent,
        child: Icon(isMicOn ? Icons.mic : Icons.mic_off, color: Colors.white),
      ),
    ),
    const SizedBox(width: 15),
    ElevatedButton.icon(onPressed: (){}, icon: const Icon(Icons.music_note), label: const Text("মিউজিক")),
  ]);

  Widget _seatLayout() => GridView.builder(
    padding: const EdgeInsets.all(15),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 10),
    itemCount: 15,
    itemBuilder: (context, i) => Column(children: [
      CircleAvatar(radius: 20, backgroundColor: i < 5 ? Colors.amber.withOpacity(0.2) : Colors.white10, child: Icon(Icons.person, size: 15, color: i < 5 ? Colors.amber : Colors.white24)),
      Text(i < 5 ? "VIP" : "${i+1}", style: const TextStyle(color: Colors.white38, fontSize: 8)),
    ]),
  );

  Widget _chatAndGiftSection() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    child: Row(children: [
      const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 30),
      const SizedBox(width: 10),
      Expanded(
        child: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "মেসেজ লিখুন...",
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white10,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
            // **ফিচার ২: চ্যাট সেন্ড বাটন**
            suffixIcon: IconButton(
              icon: const Icon(Icons.send, color: Colors.pinkAccent),
              onPressed: () {
                // মেসেজ সেন্ড করার লজিক
              },
            ),
          ),
        ),
      ),
    ]),
  );
}

// --- ৬. প্রোফাইল ও সেটিংস ---
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 60),
          const CircleAvatar(radius: 50, backgroundColor: Colors.pinkAccent, child: Icon(Icons.person, size: 50)),
          const Text("পাগলা কিং 👑", style: TextStyle(color: Colors.white, fontSize: 22)),
          const Text("ID: 77889900", style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 20),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Column(children: [Text("১২০", style: TextStyle(color: Colors.white)), Text("ফলোয়ার", style: TextStyle(color: Colors.white54))]),
            Column(children: [Text("৪৫", style: TextStyle(color: Colors.white)), Text("ফলোয়িং", style: TextStyle(color: Colors.white54))]),
          ]),
          const SizedBox(height: 20),
          ListTile(leading: const Icon(Icons.diamond, color: Colors.blue), title: const Text("ওয়ালেট", style: TextStyle(color: Colors.white)), trailing: const Text("৫২০", style: TextStyle(color: Colors.white))),
          ListTile(leading: const Icon(Icons.settings, color: Colors.white54), title: const Text("সেটিংস", style: TextStyle(color: Colors.white))),
          ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text("লগ আউট"), onTap: () => Navigator.pop(context)),
        ]),
      ),
    );
  }
}

class InboxPage extends StatelessWidget { const InboxPage({super.key}); @override Widget build(BuildContext context) => const Scaffold(backgroundColor: Color(0xFF0F0F1E), body: Center(child: Text("ইনবক্স", style: TextStyle(color: Colors.white24)))); }
