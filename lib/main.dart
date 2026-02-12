import 'dart:async';
import 'package:flutter/material.dart';

// নোট: আপনার pubspec.yaml ফাইলে firebase_core যুক্ত থাকতে হবে
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    title: "Pagla Chat",
    home: SplashScreen(),
  ));
}

// --- ১. স্প্ল্যাশ স্ক্রিন (৩ সেকেন্ড) ---
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

// --- গুগল লগইন সিমুলেশন ---
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("নিরাপদ লগইন", style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.g_mobiledata, size: 40),
              label: const Text("Google দিয়ে প্রবেশ করুন"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation())),
            ),
          ],
        ),
      ),
    );
  }
}

// --- মেইন নেভিগেশন ---
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

// --- ২. হোম পেজ (পোস্ট, লাইক, কমেন্ট) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(title: const Text("PAGLA HOME"), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => _postCard(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.add),
        onPressed: () {}, // এখানে ছবি ও লেখা পোস্টের প্লাস বাটন
      ),
    );
  }
  Widget _postCard() => Container(
    margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [CircleAvatar(radius: 15), SizedBox(width: 10), Text("পাগলা ইউজার", style: TextStyle(color: Colors.white))]),
      const SizedBox(height: 10),
      const Text("আজকের আড্ডাটা দারুণ হবে! #PaglaChat", style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 10),
      Container(height: 150, width: double.infinity, color: Colors.white10, child: const Icon(Icons.image, color: Colors.white24)),
      const Row(children: [Icon(Icons.favorite, color: Colors.pink, size: 20), SizedBox(width: 5), Text("১২", style: TextStyle(color: Colors.white54)), SizedBox(width: 20), Icon(Icons.comment, color: Colors.white54, size: 20)]),
    ]),
  );
}

// --- ৩. ভয়েস রুম (১৫ সিট + ভিডিও বোর্ড) ---
class VoiceRoom extends StatelessWidget {
  const VoiceRoom({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: Column(children: [
          _roomTopBar(), // আইডি, কিক বাটন
          _videoSection(), // ইউটিউব সার্চ বোর্ড
          _gameAndMusicButtons(), // লুডু ও মিউজিক
          Expanded(child: _seatLayout()), // ১৫ সিট (৫ VIP, ১০ Normal)
          _chatAndGift(), // গিফট ও চ্যাট বক্স
        ]),
      ),
    );
  }

  Widget _roomTopBar() => ListTile(
    leading: const CircleAvatar(backgroundColor: Colors.pinkAccent, child: Icon(Icons.mic, color: Colors.white)),
    title: const Text("পাগলা কিং আড্ডা", style: TextStyle(color: Colors.white)),
    subtitle: const Text("ID: 550889 | 🌐 অনলাইন: ২৫", style: TextStyle(color: Colors.white54, fontSize: 10)),
    trailing: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock, color: Colors.orange), SizedBox(width: 10), Icon(Icons.gavel, color: Colors.red)]),
  );

  Widget _videoSection() => Container(
    margin: const EdgeInsets.all(10), height: 160,
    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15)),
    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.play_circle, color: Colors.pinkAccent, size: 50),
      Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: TextField(decoration: InputDecoration(hintText: "গান বা মুভি সার্চ করুন...", hintStyle: TextStyle(color: Colors.white24)))),
    ]),
  );

  Widget _gameAndMusicButtons() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    ElevatedButton.icon(onPressed: (){}, icon: const Icon(Icons.casino), label: const Text("লুডু")),
    const SizedBox(width: 20),
    ElevatedButton.icon(onPressed: (){}, icon: const Icon(Icons.music_note), label: const Text("মিউজিক")),
  ]);

  Widget _seatLayout() => GridView.builder(
    padding: const EdgeInsets.all(15),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 15),
    itemCount: 15,
    itemBuilder: (context, i) => Column(children: [
      CircleAvatar(radius: 22, backgroundColor: i < 5 ? Colors.amber.withOpacity(0.2) : Colors.white10, child: Icon(Icons.mic_off, size: 18, color: i < 5 ? Colors.amber : Colors.white24)),
      Text(i < 5 ? "VIP" : "${i+1}", style: TextStyle(color: i < 5 ? Colors.amber : Colors.white38, fontSize: 8)),
    ]),
  );

  Widget _chatAndGift() => Container(
    padding: const EdgeInsets.all(10),
    child: Row(children: [
      const Expanded(child: TextField(decoration: InputDecoration(hintText: "মেসেজ লিখুন...", filled: true, fillColor: Colors.white10))),
      const SizedBox(width: 10),
      const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 35),
    ]),
  );
}

// --- ৪. প্রোফাইল ও সেটিংস ---
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 60),
          const CircleAvatar(radius: 55, backgroundColor: Colors.pinkAccent, child: CircleAvatar(radius: 50, backgroundImage: NetworkImage("https://via.placeholder.com/150"))),
          const SizedBox(height: 10),
          const Text("পাগলা কিং 👑", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("ID: 77889900", style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 10),
          // ভিআইপি প্রগ্রেস
          Container(margin: const EdgeInsets.symmetric(horizontal: 50), height: 8, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.4, child: Container(decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10))))),
          const Text("VIP Level 1 (XP: 400/1000)", style: TextStyle(color: Colors.amber, fontSize: 10)),
          const SizedBox(height: 20),
          // ফলোয়ার ফলোইং
          const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Column(children: [Text("১২০", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("ফলোয়ার", style: TextStyle(color: Colors.white54))]),
            Column(children: [Text("৪৫", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("ফলোয়িং", style: TextStyle(color: Colors.white54))]),
          ]),
          const SizedBox(height: 20),
          _walletSection(), // ডায়মন্ড ও কয়েন
          _menuItem(Icons.edit, "প্রোফাইল সেটিংস"),
          _menuItem(Icons.language, "ভাষা (বাংলা/English)"),
          _menuItem(Icons.block, "ব্ল্যাকলিস্ট"),
          _menuItem(Icons.logout, "লগ আউট", color: Colors.redAccent),
        ]),
      ),
    );
  }
  Widget _walletSection() => Container(
    margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
    child: const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      Row(children: [Icon(Icons.diamond, color: Colors.blue), Text(" ৫২০", style: TextStyle(color: Colors.white))]),
      Row(children: [Icon(Icons.monetization_on, color: Colors.yellow), Text(" ২৫৫০", style: TextStyle(color: Colors.white))]),
    ]),
  );
  Widget _menuItem(IconData icon, String title, {Color color = Colors.white70}) => ListTile(leading: Icon(icon, color: color), title: Text(title, style: TextStyle(color: color)));
}

class InboxPage extends StatelessWidget { const InboxPage({super.key}); @override Widget build(BuildContext context) => const Scaffold(backgroundColor: Color(0xFF0F0F1E), body: Center(child: Text("ইনবক্স খালি", style: TextStyle(color: Colors.white24)))); }
