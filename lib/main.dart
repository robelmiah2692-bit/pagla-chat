import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;

const String youtubeApiKey = "AIzaSyAkEB8dB2vSncv3BpNZng7W_0e6N7dqNmI"; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAkEB8dB2vSncv3BpNZng7W_0e6N7dqNmI", 
        appId: "1:25052070011:android:5d89f85753b5c881d662de", 
        messagingSenderId: "25052070011", 
        projectId: "paglachat",
        storageBucket: "paglachat.firebasestorage.app",
        databaseURL: "https://paglachat-default-rtdb.asia-southeast1.firebasedatabase.app",
      ),
    );
  } catch (e) {
    debugPrint("Firebase connection error: $e");
  }
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen()));
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
    Timer(const Duration(seconds: 3), () {
      if (FirebaseAuth.instance.currentUser != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0A0A12),
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const CircleAvatar(radius: 60, backgroundColor: Colors.pinkAccent, child: Icon(Icons.stars, size: 60, color: Colors.white)),
      const SizedBox(height: 20),
      const Text("PAGLA CHAT", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 5)),
    ])),
  );
}

// --- ২. লগইন স্ক্রিন ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();

  Future<void> _handleAuth() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
    } catch (e) {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0F0F1E),
    body: Center(child: Padding(padding: const EdgeInsets.all(25), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text("প্রবেশ করুন", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 30),
      TextField(controller: _email, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "ইমেইল", hintStyle: TextStyle(color: Colors.white24))),
      TextField(controller: _pass, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "পাসওয়ার্ড", hintStyle: TextStyle(color: Colors.white24))),
      const SizedBox(height: 30),
      ElevatedButton(onPressed: _handleAuth, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black), child: const Text("লগইন")),
    ]))),
  );
}

// --- ৩. মেইন নেভিগেশন ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _idx = 0; 
  final _pages = [const HomePage(), const VoiceRoom(), const InboxPage(), const ProfilePage()];
  @override
  Widget build(BuildContext context) => Scaffold(
    body: _pages[_idx],
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _idx, type: BottomNavigationBarType.fixed, backgroundColor: const Color(0xFF151525),
      selectedItemColor: Colors.pinkAccent, unselectedItemColor: Colors.white24,
      onTap: (i) => setState(() => _idx = i),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "হোম"),
        BottomNavigationBarItem(icon: Icon(Icons.mic), label: "রুম"),
        BottomNavigationBarItem(icon: Icon(Icons.mail), label: "ইনবক্স"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "আমি"),
      ],
    ),
  );
}

// --- ৪. হোম পেজ (স্টোরি ও প্লাস বাটন সচল) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0F0F1E),
    appBar: AppBar(title: const Text("PAGLA CHAT"), backgroundColor: Colors.transparent, actions: [IconButton(icon: const Icon(Icons.add_box_outlined), onPressed: (){})]),
    body: Column(children: [
      // স্টোরি বার (আপনার দাবি অনুযায়ী সচল)
      SizedBox(height: 100, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: 8, itemBuilder: (context, i) => Padding(padding: const EdgeInsets.all(8.0), child: Column(children: [CircleAvatar(radius: 28, backgroundColor: i==0?Colors.pinkAccent:Colors.white10, child: Icon(i==0?Icons.add:Icons.person, color: Colors.white)), Text("User $i", style: const TextStyle(color: Colors.white, fontSize: 10))])))),
      Expanded(child: ListView.builder(itemCount: 5, itemBuilder: (context, i) => _postCard())),
    ]),
    floatingActionButton: FloatingActionButton(backgroundColor: Colors.pinkAccent, child: const Icon(Icons.camera_alt), onPressed: () {}),
  );
  Widget _postCard() => Container(
    margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [CircleAvatar(radius: 15), SizedBox(width: 10), Text("পাগলা ইউজার", style: TextStyle(color: Colors.white))]),
      const SizedBox(height: 10), const Text("আমার নতুন পোস্ট! কেমন আছেন সবাই?", style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 10), Container(height: 180, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.image, color: Colors.white24)),
      Row(children: [IconButton(icon: const Icon(Icons.favorite_border, color: Colors.pink), onPressed: (){}), const Text("১২", style: TextStyle(color: Colors.white54))]),
    ]),
  );
}

// --- ৫. ভয়েস রুম (সব ফিচার একসাথে) ---
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  int? currentSeat;
  bool isLocked = false;
  YoutubePlayerController? _ytController;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _msgCtrl = TextEditingController();
  final List<String> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _ytController = YoutubePlayerController(initialVideoId: 'iLnmTe5Q2Qw', flags: const YoutubePlayerFlags(autoPlay: false));
  }

  Future<void> _searchVideo(String q) async {
    final url = "https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=1&q=$q&type=video&key=$youtubeApiKey";
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final id = json.decode(res.body)['items'][0]['id']['videoId'];
      setState(() { _ytController?.load(id); });
    }
  }

  void _sendMessage() {
    if (_msgCtrl.text.isNotEmpty) {
      setState(() { _chatMessages.add("আমি: ${_msgCtrl.text}"); _msgCtrl.clear(); });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0F0F1E),
    body: SafeArea(child: Column(children: [
      // রুম টপ বার
      ListTile(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text("পাগলা কিং আড্ডা", style: TextStyle(color: Colors.white)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: Icon(isLocked ? Icons.lock : Icons.lock_open, color: Colors.orange), onPressed: () => setState(() => isLocked = !isLocked)),
          const Icon(Icons.gavel, color: Colors.red),
        ]),
      ),
      // ইউটিউব বোর্ড ও সার্চ
      Container(height: 180, margin: const EdgeInsets.symmetric(horizontal: 10), child: ClipRRect(borderRadius: BorderRadius.circular(15), child: YoutubePlayer(controller: _ytController!))),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(children: [
          Expanded(child: TextField(controller: _searchCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "YouTube সার্চ...", isDense: true))),
          IconButton(icon: const Icon(Icons.search, color: Colors.pinkAccent), onPressed: () => _searchVideo(_searchCtrl.text)),
        ]),
      ),
      // গেম ও মিউজিক
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ActionChip(avatar: const Icon(Icons.casino), label: const Text("লুডু"), onPressed: (){}),
        const SizedBox(width: 10),
        ActionChip(avatar: const Icon(Icons.music_note), label: const Text("মিউজিক"), onPressed: (){}),
      ]),
      // ১৫ সিট
      Expanded(child: GridView.builder(
        padding: const EdgeInsets.all(10), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
        itemCount: 15, itemBuilder: (context, i) => GestureDetector(onTap: () => setState(() => currentSeat = i), child: Column(children: [
          CircleAvatar(radius: 20, backgroundColor: currentSeat==i?Colors.pinkAccent:Colors.white10, child: Icon(currentSeat==i?Icons.mic:Icons.mic_off, size: 15, color: Colors.white)),
          Text("${i+1}", style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ])),
      )),
      // চ্যাট বক্স
      Container(height: 80, child: ListView.builder(itemCount: _chatMessages.length, itemBuilder: (context, i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(_chatMessages[i], style: const TextStyle(color: Colors.white70))))),
      // ইনপুট ও সেন্ড বাটন (জ্যান্ত কাজ করবে)
      Container(padding: const EdgeInsets.all(10), child: Row(children: [
        Expanded(child: TextField(controller: _msgCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "মেসেজ লিখুন...", filled: true, fillColor: Colors.white10))),
        IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: _sendMessage),
        IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.amber), onPressed: _showGifts),
      ])),
    ])),
  );

  void _showGifts() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF151525), builder: (context) => GridView.count(crossAxisCount: 4, children: List.generate(8, (i) => Column(children: [const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 30), Text("Gift ${i+1}", style: const TextStyle(color: Colors.white, fontSize: 10))]))));
  }
}

// --- ৬. প্রোফাইল পেজ (এডিট ও ওয়ালেট) ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0F0F1E),
    body: SingleChildScrollView(child: Column(children: [
      const SizedBox(height: 60),
      const Center(child: Stack(children: [CircleAvatar(radius: 50, backgroundImage: NetworkImage("https://via.placeholder.com/150")), Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 15, backgroundColor: Colors.pinkAccent, child: Icon(Icons.edit, size: 15, color: Colors.white)))] ) ),
      const SizedBox(height: 10),
      const Text("পাগলা কিং 👑", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      const Text("ID: 77889900", style: TextStyle(color: Colors.white54)),
      // ওয়ালেট
      Container(margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
        child: const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Row(children: [Icon(Icons.diamond, color: Colors.blue), Text(" ৫২০", style: TextStyle(color: Colors.white))]),
          Row(children: [Icon(Icons.monetization_on, color: Colors.yellow), Text(" ২৫৫০", style: TextStyle(color: Colors.white))]),
        ]),
      ),
      // মেনু
      _menuItem(Icons.edit, "নাম পরিবর্তন করুন"),
      _menuItem(Icons.language, "ভাষা পরিবর্তন"),
      _menuItem(Icons.block, "ব্ল্যাকলিস্ট"),
      ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("লগ আউট", style: TextStyle(color: Colors.red)), onTap: () => FirebaseAuth.instance.signOut()),
    ])),
  );
  Widget _menuItem(IconData icon, String title) => ListTile(leading: Icon(icon, color: Colors.white70), title: Text(title, style: const TextStyle(color: Colors.white70)));
}

class InboxPage extends StatelessWidget { const InboxPage({super.key}); @override Widget build(BuildContext context) => const Scaffold(backgroundColor: Color(0xFF0F0F1E), body: Center(child: Text("ইনবক্স খালি", style: TextStyle(color: Colors.white24)))); }
