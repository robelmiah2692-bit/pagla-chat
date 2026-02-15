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
import 'package:image_picker/image_picker.dart';

// গ্লোবাল ইউটিউব এপিআই কী
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(child: Padding(padding: const EdgeInsets.all(25), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("নিরাপদ লগইন", style: TextStyle(color: Colors.white70, fontSize: 18)),
        const SizedBox(height: 30),
        TextField(controller: _email, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Email", hintStyle: TextStyle(color: Colors.white24))),
        TextField(controller: _pass, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Password", hintStyle: TextStyle(color: Colors.white24))),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          icon: const Icon(Icons.g_mobiledata, size: 40),
          label: const Text("প্রবেশ করুন"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
          onPressed: _handleAuth,
        ),
      ]))),
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

// --- ৪. হোম পেজ (স্টোরি প্লাস ও পোস্ট জ্যান্ত) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(title: const Text("PAGLA HOME"), backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        children: [
          // স্টোরি সেকশন
          SizedBox(height: 100, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: 6, itemBuilder: (context, i) => Padding(padding: const EdgeInsets.all(8.0), child: Column(children: [
            CircleAvatar(radius: 28, backgroundColor: i==0?Colors.pinkAccent:Colors.white10, child: Icon(i==0?Icons.add:Icons.person, color: Colors.white)),
            Text(i==0?"Add Story":"User $i", style: const TextStyle(color: Colors.white, fontSize: 10))
          ])))),
          Expanded(child: ListView.builder(itemCount: 5, itemBuilder: (context, index) => _postCard())),
        ],
      ),
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.pinkAccent, child: const Icon(Icons.add), onPressed: () {}),
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
      Container(height: 150, width: double.infinity, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.image, color: Colors.white24)),
      const SizedBox(height: 10),
      const Row(children: [Icon(Icons.favorite, color: Colors.pink, size: 20), SizedBox(width: 5), Text("১২", style: TextStyle(color: Colors.white54)), SizedBox(width: 20), Icon(Icons.comment, color: Colors.white54, size: 20)]),
    ]),
  );
}

// --- ৫. ভয়েস রুম (সব মৃত ফিচার জ্যান্ত করা হয়েছে) ---
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  int? currentSeat;
  bool isMicOn = false;
  bool isLocked = false;
  YoutubePlayerController? _ytController;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _msgCtrl = TextEditingController();
  final List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    _ytController = YoutubePlayerController(initialVideoId: 'iLnmTe5Q2Qw', flags: const YoutubePlayerFlags(autoPlay: false));
  }

  void _searchVideo(String q) async {
    final url = "https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=1&q=$q&type=video&key=$youtubeApiKey";
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final id = json.decode(res.body)['items'][0]['id']['videoId'];
      setState(() { _ytController?.load(id); });
    }
  }

  void _sendMessage() {
    if (_msgCtrl.text.isNotEmpty) {
      setState(() { _messages.insert(0, "আপনি: ${_msgCtrl.text}"); _msgCtrl.clear(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: Column(children: [
          // রুম টপ বার
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.pinkAccent, child: Icon(Icons.mic, color: Colors.white)),
            title: const Text("পাগলা কিং আড্ডা", style: TextStyle(color: Colors.white)),
            subtitle: const Text("ID: 550889 | 🌐 অনলাইন: ২৫", style: TextStyle(color: Colors.white54, fontSize: 10)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: Icon(isLocked ? Icons.lock : Icons.lock_open, color: Colors.orange), onPressed: () => setState(() => isLocked = !isLocked)),
              const SizedBox(width: 10), 
              const Icon(Icons.gavel, color: Colors.red)
            ]),
          ),
          
          // ভিডিও বোর্ড ও সার্চ (জ্যান্ত YouTube)
          Container(height: 160, margin: const EdgeInsets.all(10), child: ClipRRect(borderRadius: BorderRadius.circular(15), child: YoutubePlayer(controller: _ytController!))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 15), child: Row(children: [
            Expanded(child: TextField(controller: _searchCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "গান সার্চ করুন...", hintStyle: TextStyle(color: Colors.white24)))),
            IconButton(icon: const Icon(Icons.search, color: Colors.pinkAccent), onPressed: () => _searchVideo(_searchCtrl.text)),
          ])),

          // মাইক, লুডু ও মিউজিক (মাঝখানে জ্যান্ত মাইক বাটন)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton.icon(onPressed: (){}, icon: const Icon(Icons.casino), label: const Text("লুডু")),
            const SizedBox(width: 10),
            CircleAvatar(backgroundColor: isMicOn ? Colors.pinkAccent : Colors.white10, child: IconButton(icon: Icon(isMicOn ? Icons.mic : Icons.mic_off, color: Colors.white), onPressed: () => setState(() => isMicOn = !isMicOn))),
            const SizedBox(width: 10),
            ElevatedButton.icon(onPressed: (){}, icon: const Icon(Icons.music_note), label: const Text("মিউজিক")),
          ]),

          // ১৫ সিট
          Expanded(child: GridView.builder(
            padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 15),
            itemCount: 15, itemBuilder: (context, i) => GestureDetector(onTap: () => setState(() => currentSeat = i), child: Column(children: [
              CircleAvatar(radius: 22, backgroundColor: currentSeat == i ? Colors.pinkAccent : (i < 5 ? Colors.amber.withOpacity(0.2) : Colors.white10), child: Icon(currentSeat == i ? Icons.mic : Icons.mic_off, size: 18, color: i < 5 ? Colors.amber : Colors.white24)),
              Text(i < 5 ? "VIP" : "${i+1}", style: TextStyle(color: i < 5 ? Colors.amber : Colors.white38, fontSize: 8)),
            ])),
          )),

          // চ্যাট ডিসপ্লে ও জ্যান্ত সেন্ড বাটন
          Container(height: 60, padding: const EdgeInsets.symmetric(horizontal: 10), child: ListView.builder(reverse: true, itemCount: _messages.length, itemBuilder: (context, i) => Text(_messages[i], style: const TextStyle(color: Colors.pinkAccent, fontSize: 12)))),
          Container(padding: const EdgeInsets.all(10), child: Row(children: [
            Expanded(child: TextField(controller: _msgCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "মেসেজ লিখুন...", filled: true, fillColor: Colors.white10))),
            IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: _sendMessage),
            IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 30), onPressed: _showGifts),
          ])),
        ]),
      ),
    );
  }
  void _showGifts() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF151525), builder: (context) => GridView.count(crossAxisCount: 4, children: List.generate(8, (i) => Column(children: [const Icon(Icons.stars, color: Colors.amber, size: 40), Text("Gift ${i+1}", style: const TextStyle(color: Colors.white, fontSize: 10))]))));
  }
}

// --- ৬. প্রোফাইল পেজ (XP, ফলোয়ার, এডিট জ্যান্ত করা হয়েছে) ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameCtrl = TextEditingController(text: "পাগলা কিং 👑");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 60),
          Center(child: Stack(children: [
            const CircleAvatar(radius: 55, backgroundColor: Colors.pinkAccent, child: CircleAvatar(radius: 50, backgroundImage: NetworkImage("https://via.placeholder.com/150"))),
            Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 15, backgroundColor: Colors.pinkAccent, child: IconButton(icon: const Icon(Icons.edit, size: 12, color: Colors.white), onPressed: (){})))
          ])),
          const SizedBox(height: 10),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 50), child: TextField(controller: _nameCtrl, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center, decoration: const InputDecoration(border: InputBorder.none))),
          const Text("ID: 77889900", style: TextStyle(color: Colors.white54)),
          
          // ভিআইপি এক্সপি প্রগ্রেস বার
          const SizedBox(height: 15),
          Container(margin: const EdgeInsets.symmetric(horizontal: 50), height: 8, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.6, child: Container(decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 4)])))),
          const Text("VIP Level 5 (XP: 600/1000)", style: TextStyle(color: Colors.amber, fontSize: 10)),
          
          const SizedBox(height: 20),
          // ফলোয়ার ফলোইং কাউন্টার
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _stat("১২.৫K", "ফলোয়ার"),
            _stat("৪৮০", "ফলোয়িং"),
            _stat("৫", "লেভেল"),
          ]),

          // ডায়মন্ড ও কয়েন (কিনার অপশন সহ)
          Container(margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                Row(children: [const Icon(Icons.diamond, color: Colors.blue, size: 20), const Text(" ৫২০", style: TextStyle(color: Colors.white)), const Text(" (Buy: \$10)", style: TextStyle(color: Colors.white24, fontSize: 9))]),
                const Row(children: [Icon(Icons.monetization_on, color: Colors.yellow, size: 20), Text(" ২৫৫০", style: TextStyle(color: Colors.white))]),
              ]),
            ]),
          ),

          _menuItem(Icons.wc, "লিঙ্গ ও বয়স পরিবর্তন"),
          _menuItem(Icons.language, "ভাষা (বাংলা/English)"),
          _menuItem(Icons.block, "ব্ল্যাকলিস্ট"),
          ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text("লগ আউট", style: TextStyle(color: Colors.redAccent)), onTap: () => FirebaseAuth.instance.signOut()),
        ]),
      ),
    );
  }
  Widget _stat(String v, String l) => Column(children: [Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(l, style: const TextStyle(color: Colors.white54, fontSize: 12))]);
  Widget _menuItem(IconData icon, String title) => ListTile(leading: Icon(icon, color: Colors.white70), title: Text(title, style: const TextStyle(color: Colors.white70)), trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white24));
}

class InboxPage extends StatelessWidget { const InboxPage({super.key}); @override Widget build(BuildContext context) => const Scaffold(backgroundColor: Color(0xFF0F0F1E), body: Center(child: Text("ইনবক্স খালি", style: TextStyle(color: Colors.white24)))); }
