import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart'; // ১. গুগল সাইন-ইন

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen()));
}

// --- ১. স্প্ল্যাশ স্ক্রিন (৩ সেকেন্ড + লোগো) ---
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
        const CircleAvatar(radius: 60, backgroundImage: AssetImage('assets/logo.jpg')),
        const SizedBox(height: 20),
        const Text("PAGLA CHAT", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 5)),
      ])),
    );
  }
}

// --- গুগল লগইন স্ক্রিন ---
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login, color: Colors.white),
          label: const Text("Sign in with Google"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation())),
        ),
      ),
    );
  }
}

// --- মেইন নেভিগেশন (হোম, রুম, ইনবক্স, প্রোফাইল) ---
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

// --- ২. হোম পেজ (স্টোরি, পোস্ট + বাটন) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(title: const Text("PAGLA HOME"), backgroundColor: Colors.transparent),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          // স্টোরি সেকশন
          SizedBox(height: 100, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: 10, itemBuilder: (c, i) => _storyCircle())),
          // পোস্ট সেকশন
          _postItem("User Name", "আজকের দিনটি খুব সুন্দর!"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.add_a_photo),
        onPressed: () => _showPostModal(context), // ছবি ও লেখা পোস্ট
      ),
    );
  }
  Widget _storyCircle() => Container(margin: const EdgeInsets.all(5), child: const CircleAvatar(radius: 35, backgroundColor: Colors.pinkAccent, child: CircleAvatar(radius: 32, backgroundImage: AssetImage('assets/user.png'))));
  Widget _postItem(String name, String text) => Container(
    margin: const EdgeInsets.all(10), padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name, style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      Text(text, style: const TextStyle(color: Colors.white70)),
      const Row(children: [Icon(Icons.favorite_border, color: Colors.white54), SizedBox(width: 20), Icon(Icons.comment_outlined, color: Colors.white54)]),
    ]),
  );
  void _showPostModal(context) => showModalBottomSheet(context: context, builder: (c) => Container(padding: const EdgeInsets.all(20), child: const Column(children: [TextField(decoration: InputDecoration(hintText: "কিছু লিখুন...")), Icon(Icons.image, size: 50)])));
}

// --- ৩. ভয়েস রুম (১৫ সিট, ভিডিও বোর্ড, কন্ট্রোল) ---
class VoiceRoom extends StatelessWidget {
  const VoiceRoom({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: Column(children: [
          _roomHeader(), // নাম, আইডি, ফলোয়ার, কিক/এডমিন বাটন
          _videoBoardWithSearch(), // ভিডিও বোর্ড + সার্চ গান/মুভি
          _actionGamerBar(), // লুডু, মিউজিক প্যানেল
          Expanded(child: _fifteenSeats()), // ১৫টি সিট (৫ VIP + ১০ Normal)
          _giftAndChatBar(), // গিফট ও চ্যাট
        ]),
      ),
    );
  }

  Widget _roomHeader() => ListTile(
    leading: const CircleAvatar(backgroundImage: AssetImage('assets/logo.jpg')),
    title: const Text("পাগলা আড্ডা", style: TextStyle(color: Colors.white, fontSize: 14)),
    subtitle: const Text("ID: 550889 | 🌐 1.2k", style: TextStyle(color: Colors.white54, fontSize: 10)),
    trailing: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock, color: Colors.orange, size: 18), Icon(Icons.gavel, color: Colors.red, size: 20)]), // কিক বাটন
  );

  Widget _videoBoardWithSearch() => Column(children: [
    Container(margin: const EdgeInsets.all(10), height: 150, color: Colors.black, child: const Center(child: Icon(Icons.play_circle, color: Colors.white24, size: 50))),
    const Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: TextField(decoration: InputDecoration(hintText: "গান বা মুভি সার্চ করুন...", hintStyle: TextStyle(color: Colors.white24)))),
  ]);

  Widget _actionGamerBar() => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
    IconButton(icon: const Icon(Icons.casino, color: Colors.blue), onPressed: (){}), // লুডু
    IconButton(icon: const Icon(Icons.library_music, color: Colors.green), onPressed: (){}), // মিউজিক ফাইল এড/প্লে
  ]);

  Widget _fifteenSeats() => GridView.builder(
    padding: const EdgeInsets.all(10),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 10),
    itemCount: 15,
    itemBuilder: (c, i) => Column(children: [
      CircleAvatar(radius: 20, backgroundColor: i < 5 ? Colors.amber : Colors.white10, child: Icon(Icons.mic_off, size: 15, color: i < 5 ? Colors.black : Colors.white24)),
      Text(i < 5 ? "VIP" : "Normal", style: const TextStyle(color: Colors.white38, fontSize: 8)),
    ]),
  );

  Widget _giftAndChatBar() => Container(
    padding: const EdgeInsets.all(10),
    child: Row(children: [
      const Expanded(child: TextField(decoration: InputDecoration(hintText: "সবাই দেখবে...", filled: true, fillColor: Colors.white10))),
      const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 35), // গিফট বাটন
    ]),
  );
}

// --- ৪. ইউজার প্রোফাইল (ID, VIP Level, Wallet, সোশ্যাল) ---
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 50),
          const CircleAvatar(radius: 50, backgroundImage: AssetImage('assets/user.png')), // নিজের ছবি টাচ করে বসানো
          const Text("পাগলা কিং 👑", style: TextStyle(color: Colors.white, fontSize: 20)),
          const Text("ID: 77889900", style: TextStyle(color: Colors.white54)), // অটো আইডি
          _levelProgressBar(), // লেভেল ও এক্সপি বার
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.stars, color: Colors.amber), Text(" VIP 1", style: TextStyle(color: Colors.amber))]), // ডায়মন্ড খরচে লেভেল আপ
          _walletBox(), // ডায়মন্ড ও কয়েন ওয়ালেট
          _socialStats(), // ফলোয়ার, ফলোয়িং
          _settingsList(context), // সেটিংস, ল্যাঙ্গুয়েজ, লগ আউট
        ]),
      ),
    );
  }

  Widget _levelProgressBar() => Container(margin: const EdgeInsets.all(15), height: 10, width: 200, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.5, child: Container(color: Colors.pinkAccent)));

  Widget _walletBox() => Container(
    margin: const EdgeInsets.all(15), padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
    child: const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      Column(children: [Icon(Icons.diamond, color: Colors.blue), Text("৫২০ ডায়মন্ড", style: TextStyle(color: Colors.white))]),
      Column(children: [Icon(Icons.monetization_on, color: Colors.yellow), Text("২৫৫০ কয়েন", style: TextStyle(color: Colors.white))]),
    ]),
  );

  Widget _socialStats() => const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [Text("ফলোয়ার: ১০০", style: TextStyle(color: Colors.white54)), Text("ফলোয়িং: ৫০", style: TextStyle(color: Colors.white54))]);

  Widget _settingsList(context) => Column(children: [
    ListTile(leading: const Icon(Icons.edit, color: Colors.white54), title: const Text("প্রোফাইল এডিট", style: TextStyle(color: Colors.white))),
    ListTile(leading: const Icon(Icons.language, color: Colors.white54), title: const Text("অ্যাপ ল্যাঙ্গুয়েজ (বাংলা/English)", style: TextStyle(color: Colors.white))),
    ListTile(leading: const Icon(Icons.block, color: Colors.white54), title: const Text("ব্ল্যাকলিস্ট", style: TextStyle(color: Colors.white))),
    ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text("লগ আউট"), onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginScreen()))),
  ]);
}

// --- ৫. ইনবক্স (রিপ্লে ও রিয়েল মেসেজ) ---
class InboxPage extends StatelessWidget {
  const InboxPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(title: const Text("ইনবক্স"), backgroundColor: Colors.transparent),
      body: ListView.builder(itemCount: 5, itemBuilder: (c, i) => ListTile(
        leading: const CircleAvatar(backgroundImage: AssetImage('assets/friend.png')),
        title: const Text("বন্ধু", style: TextStyle(color: Colors.white)),
        subtitle: const Text("কেমন আছো?", style: TextStyle(color: Colors.white38)),
        onTap: () => _showChatUI(context),
      )),
    );
  }
  void _showChatUI(context) => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => Container(height: 500, padding: const EdgeInsets.all(10), child: const Column(children: [Expanded(child: Text("চ্যাট হিস্ট্রি...")), TextField(decoration: InputDecoration(hintText: "রিপ্লে দিন..."))])));
}
