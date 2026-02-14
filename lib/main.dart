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

// --- আপনার ইউটিউব এপিআই কী ---
const String youtubeApiKey = "AIzaSyB..."; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ফায়ারবেস ম্যানুয়াল ইনিশিয়ালাইজেশন (লগইন এরর চিরতরে ফিক্স করার জন্য)
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

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false, 
    home: SplashScreen()
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
    Timer(const Duration(seconds: 3), () => _checkUserStatus());
  }

  void _checkUserStatus() {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    } catch (e) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CircleAvatar(radius: 60, backgroundColor: Colors.pinkAccent, child: Icon(Icons.stars, size: 60, color: Colors.white)),
        const SizedBox(height: 20),
        const Text("PAGLA CHAT", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 5)),
        const SizedBox(height: 20),
        const CircularProgressIndicator(color: Colors.pinkAccent),
      ])),
    );
  }
}

// --- ২. ইমেইল-পাসওয়ার্ড লগইন ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleAuth() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      UserCredential user;
      try {
        user = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      } catch (e) {
        user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      }

      if (user.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.user!.uid).set({
          'name': _emailCtrl.text.split('@')[0],
          'photo': "https://ui-avatars.com/api/?name=${_emailCtrl.text}",
          'id': '7788${user.user!.uid.substring(0, 4)}',
          'diamonds': 520,
          'level': 1,
          'xp': 0,
          'isVIP': false,
        }, SetOptions(merge: true));

        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text("PAGLA LOGIN", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          TextField(controller: _emailCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Email", hintStyle: TextStyle(color: Colors.white24))),
          TextField(controller: _passCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Password", hintStyle: TextStyle(color: Colors.white24))),
          const SizedBox(height: 30),
          _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _handleAuth, child: const Text("Login / Sign Up")),
        ]),
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
  int _idx = 1;
  final _pages = [const HomePage(), const VoiceRoom(), const Center(child: Text("ইনবক্স ফাঁকা", style: TextStyle(color: Colors.white))), const ProfilePage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx, type: BottomNavigationBarType.fixed, backgroundColor: const Color(0xFF151525),
        selectedItemColor: Colors.pinkAccent, unselectedItemColor: Colors.white24,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "হোম"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: "ইনবক্স"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "প্রোফাইল")
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
      body: ListView.builder(itemCount: 3, itemBuilder: (context, index) => _postCard()),
    );
  }
  Widget _postCard() => Container(
    margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [CircleAvatar(radius: 15, backgroundColor: Colors.blueAccent), SizedBox(width: 10), Text("পাগলা ইউজার", style: TextStyle(color: Colors.white))]),
      const SizedBox(height: 10),
      const Text("আজকের আড্ডাটা দারুণ হবে!", style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 10),
      Container(height: 150, width: double.infinity, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.image, color: Colors.white24)),
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
  bool isMicOn = false;
  RtcEngine? _engine;
  YoutubePlayerController? _ytController;
  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAgora();
    _ytController = YoutubePlayerController(initialVideoId: 'iLnmTe5Q2Qw', flags: const YoutubePlayerFlags(autoPlay: false, mute: false));
  }

  _initAgora() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(appId: "bd010dec4aa141228c87ec2cb9d4f6e8"));
    await _engine!.enableAudio();
    await _engine!.joinChannel(token: '', channelId: 'pagla_room', uid: 0, options: const ChannelMediaOptions());
  }

  Future<void> _searchVideo(String query) async {
    if (query.isEmpty) return;
    final url = "https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=1&q=$query&type=video&key=$youtubeApiKey";
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final id = json.decode(res.body)['items'][0]['id']['videoId'];
        _ytController?.load(id);
      }
    } catch (e) { debugPrint("YouTube Search Error: $e"); }
  }

  void _sendMsg() async {
    var user = FirebaseAuth.instance.currentUser;
    if (_chatController.text.isNotEmpty && user != null) {
      await FirebaseFirestore.instance.collection('rooms').doc('room1').collection('chats').add({
        'name': user.email!.split('@')[0], 'text': _chatController.text, 'time': FieldValue.serverTimestamp(),
      });
      _chatController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: Column(children: [
          const ListTile(title: Text("পাগলা কিং আড্ডা", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: Text("ID: 550889 | Live", style: TextStyle(color: Colors.pinkAccent, fontSize: 10))),
          if (_ytController != null) Container(margin: const EdgeInsets.symmetric(horizontal: 10), height: 160, child: ClipRRect(borderRadius: BorderRadius.circular(15), child: YoutubePlayer(controller: _ytController!))),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(child: TextField(controller: _searchController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "গান সার্চ..."))),
              IconButton(icon: const Icon(Icons.search, color: Colors.blueAccent), onPressed: () => _searchVideo(_searchController.text)),
            ]),
          ),
          GestureDetector(onTap: () { setState(() => isMicOn = !isMicOn); _engine?.muteLocalAudioStream(!isMicOn); }, child: CircleAvatar(backgroundColor: isMicOn ? Colors.green : Colors.red, child: Icon(isMicOn ? Icons.mic : Icons.mic_off, color: Colors.white))),
          Expanded(child: _seatGrid()),
          _chatDisplay(), _chatInput(),
        ]),
      ),
    );
  }

  Widget _seatGrid() => GridView.builder(
    padding: const EdgeInsets.all(10), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.8),
    itemCount: 15, itemBuilder: (context, i) => Column(children: [const CircleAvatar(radius: 20, backgroundColor: Colors.white10, child: Icon(Icons.person, color: Colors.white24)), Text("${i+1}", style: const TextStyle(color: Colors.white54, fontSize: 9))])
  );

  Widget _chatDisplay() => Container(height: 70, child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('rooms').doc('room1').collection('chats').orderBy('time', descending: true).snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox();
      return ListView.builder(reverse: true, itemCount: snapshot.data!.docs.length, itemBuilder: (context, i) => Text(" ${snapshot.data!.docs[i]['name']}: ${snapshot.data!.docs[i]['text']}", style: const TextStyle(color: Colors.white, fontSize: 11)));
    },
  ));

  Widget _chatInput() => Row(children: [Expanded(child: TextField(controller: _chatController, style: const TextStyle(color: Colors.white))), IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: _sendMsg)]);
}

// --- ৬. প্রোফাইল পেজ (VIP, XP, Diamonds সব আছে) ---
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var data = snapshot.data!.data() as Map<String, dynamic>?;
          return Center(child: Column(children: [
            const SizedBox(height: 80),
            CircleAvatar(radius: 50, backgroundImage: NetworkImage(data?['photo'] ?? "")),
            const SizedBox(height: 10),
            Text(data?['name'] ?? "ইউজার", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Level: ${data?['level'] ?? 1} | XP: ${data?['xp'] ?? 0}", style: const TextStyle(color: Colors.amber, fontSize: 12)),
            if (data?['isVIP'] == true) const Text("💎 VIP MEMBER 💎", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.diamond, color: Colors.blue), Text(" ${data?['diamonds'] ?? 0}", style: const TextStyle(color: Colors.white, fontSize: 18))]),
            const Spacer(),
            ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("লগ আউট", style: TextStyle(color: Colors.white)), onTap: () => FirebaseAuth.instance.signOut()),
            const SizedBox(height: 50),
          ]));
        }
      ),
    );
  }
}
