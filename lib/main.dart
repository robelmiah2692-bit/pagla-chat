import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;

// গ্লোবাল ইউটিউব এপিআই কী
const String youtubeApiKey = "AIzaSyAqM0k4SqvAm1n7DosJVy6ld29nztdP2xI";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAkEB8dB2vSncv3BpNZng7W_0e6N7dqNmI",
        appId: "1:25052070011:android:5d89f85753b5c881d662de",
        messagingSenderId: "25052070011",
        projectId: "paglachat",
      ),
    );
    debugPrint("Firebase connected successfully!");
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

  Future<void> _saveUserToFirestore(User user) async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'name': 'পাগলা ইউজার',
          'id': (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString(),
          'diamonds': 0,
          'coins': 0,
          'xp': 0,
          'level': 0,
          'isVIP': false,
          'vipLevel': 0,
          'gender': 'Not Set',
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
        });
      } else {
        await userDoc.update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Firestore Save Error: $e");
    }
  }

  Future<void> _handleAuth() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text.trim()
      );
      await _saveUserToFirestore(userCredential.user!);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
    } catch (e) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _pass.text.trim()
        );
        await _saveUserToFirestore(userCredential.user!);
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
      } catch (err) {
        debugPrint("Auth Error: $err");
      }
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
          icon: const Icon(Icons.login, size: 25),
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

// --- ৪. হোম পেজ ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(title: const Text("PAGLA HOME"), backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        children: [
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

// --- ৫. ভয়েস রুম ---
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
    _ytController = YoutubePlayerController(
      initialVideoId: 'iLnmTe5Q2Qw', 
      flags: const YoutubePlayerFlags(autoPlay: false)
    );
  }

  void _searchVideo(String q) async {
    if (q.trim().isEmpty) return;
    final url = "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=1&q=${Uri.encodeComponent(q)}&key=$youtubeApiKey";
    
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          final videoId = data['items'][0]['id']['videoId'];
          setState(() {
            _ytController?.load(videoId);
          });
        }
      }
    } catch (e) {
      debugPrint("YouTube Error: $e");
    }
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: Column(children: [
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.pinkAccent, child: Icon(Icons.mic, color: Colors.white)),
            title: const Text("পাগলা কিং আড্ডা", style: TextStyle(color: Colors.white)),
            subtitle: const Text("ID: 550889 | 🌐 অনলাইন: ২৫", style: TextStyle(color: Colors.white54, fontSize: 10)),
            trailing: IconButton(icon: Icon(isLocked ? Icons.lock : Icons.lock_open, color: Colors.orange), onPressed: () => setState(() => isLocked = !isLocked)),
          ),

          // ভিডিও বোর্ড
          Container(
            height: 160,
            margin: const EdgeInsets.all(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: YoutubePlayer(controller: _ytController!, showVideoProgressIndicator: true),
            ),
          ),

          // সার্চ রো
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(children: [
              Expanded(child: TextField(controller: _searchCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "গান সার্চ করুন...", hintStyle: TextStyle(color: Colors.white24)))),
              IconButton(icon: const Icon(Icons.search, color: Colors.pinkAccent), onPressed: () => _searchVideo(_searchCtrl.text)),
            ]),
          ),

          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircleAvatar(backgroundColor: isMicOn ? Colors.pinkAccent : Colors.white10, child: IconButton(icon: Icon(isMicOn ? Icons.mic : Icons.mic_off, color: Colors.white), onPressed: () => setState(() => isMicOn = !isMicOn))),
          ]),

          Expanded(child: GridView.builder(
            padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 15),
            itemCount: 15, itemBuilder: (context, i) => GestureDetector(onTap: () => setState(() => currentSeat = i), child: Column(children: [
              CircleAvatar(radius: 22, backgroundColor: currentSeat == i ? Colors.pinkAccent : (i < 5 ? Colors.amber.withOpacity(0.2) : Colors.white10), child: Icon(currentSeat == i ? Icons.mic : Icons.mic_off, size: 18, color: i < 5 ? Colors.amber : Colors.white24)),
              Text(i < 5 ? "VIP" : "${i+1}", style: TextStyle(color: i < 5 ? Colors.amber : Colors.white38, fontSize: 8)),
            ])),
          )),

          Container(padding: const EdgeInsets.all(10), child: Row(children: [
            Expanded(child: TextField(controller: _msgCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "মেসেজ লিখুন...", filled: true, fillColor: Colors.white10))),
            IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: () {
              if (_msgCtrl.text.isNotEmpty) {
                setState(() { _messages.insert(0, "আপনি: ${_msgCtrl.text}"); _msgCtrl.clear(); });
              }
            }),
          ])),
        ]),
      ),
    );
  }
}

// --- ৬. প্রোফাইল পেজ ---
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
          const Center(child: CircleAvatar(radius: 55, backgroundColor: Colors.pinkAccent, child: CircleAvatar(radius: 50, backgroundColor: Colors.white10, child: Icon(Icons.person, size: 50, color: Colors.white24)))),
          const SizedBox(height: 10),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 50), child: TextField(controller: _nameCtrl, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center, decoration: const InputDecoration(border: InputBorder.none))),
          const Text("ID: 77889900", style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _stat("১২.৫K", "ফলোয়ার"),
            _stat("৪৮০", "ফলোয়িং"),
            _stat("৫", "লেভেল"),
          ]),
          const SizedBox(height: 30),
          ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text("লগ আউট", style: TextStyle(color: Colors.redAccent)), onTap: () => FirebaseAuth.instance.signOut()),
        ]),
      ),
    );
  }
  Widget _stat(String v, String l) => Column(children: [Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(l, style: const TextStyle(color: Colors.white54, fontSize: 12))]);
}

class InboxPage extends StatelessWidget { const InboxPage({super.key}); @override Widget build(BuildContext context) => const Scaffold(backgroundColor: Color(0xFF0F0F1E), body: Center(child: Text("ইনবক্স খালি", style: TextStyle(color: Colors.white24)))); }
