import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // সরাসরি Firebase.initializeApp() ব্যবহার করা রিলিজ মোডের জন্য নিরাপদ
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase Initialization Error: $e");
  }
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen()));
}

// --- ১. স্প্ল্যাশ স্ক্রিন (আপনার লোগো সহ) ---
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
        // আপনার assets/logo.png ফাইলটি এখানে কাজ করবে
        Image.asset('assets/logo.png', width: 120, height: 120, 
          errorBuilder: (context, error, stackTrace) => const CircleAvatar(radius: 60, backgroundColor: Colors.pinkAccent, child: Icon(Icons.stars, size: 60, color: Colors.white))),
        const SizedBox(height: 20),
        const Text("PAGLA CHAT", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 5)),
      ])),
    );
  }
}

// --- ২. গুগল লগইন (রিলিজ ফিক্স ও SHA-1 এরর সমাধান) ---
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signIn(BuildContext context) async {
    try {
      // রিলিজ মোডে scopes ই যথেষ্ট, clientId ফায়ারবেস নিজেই খুঁজে নেবে
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      
      // সেশন ক্লিয়ার করে ফ্রেশ লগইন নিশ্চিত করা
      await googleSignIn.signOut();

      final GoogleSignInAccount? gUser = await googleSignIn.signIn();
      if (gUser == null) return;

      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final AuthCredential cred = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(cred);
      User? user = userCredential.user;

      if (user != null) {
        // নতুন আইডি জেনারেট এবং ৫২০ ডায়মন্ড সেভ
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': user.displayName,
          'photo': user.photoURL,
          'id': '7788${user.uid.substring(0, 4)}',
          'diamonds': 520, 
        }, SetOptions(merge: true));

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
      }
    } catch (e) {
      // স্ক্রিনে এরর মেসেজ দেখানো যেন সমস্যা বোঝা যায়
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Failed: $e"), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars, size: 80, color: Colors.pinkAccent),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _signIn(context), 
              icon: const Icon(Icons.login),
              label: const Text("Google Login"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
            ),
          ],
        ),
      )
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
  final _pages = [
    const Center(child: Text("Home", style: TextStyle(color: Colors.white))), 
    const VoiceRoom(), 
    const Center(child: Text("Inbox", style: TextStyle(color: Colors.white))), 
    const ProfilePage()
  ];
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "আমি")
        ],
      ),
    );
  }
}

// --- ৪. ভয়েস রুম (১৫টি সিট ও ইউটিউব) ---
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  bool isMicOn = false;
  late RtcEngine _engine;
  late YoutubePlayerController _ytController;
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAgora();
    _ytController = YoutubePlayerController(
      initialVideoId: 'iLnmTe5Q2Qw', 
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );
  }

  _initAgora() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: "bd010dec4aa141228c87ec2cb9d4f6e8"));
    await _engine.enableAudio();
    await _engine.joinChannel(token: '', channelId: 'pagla_room', uid: 0, options: const ChannelMediaOptions());
  }

  void _occupySeat(int index) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('rooms').doc('room1').collection('seats').doc('seat_$index').set({
        'name': user.displayName,
        'photo': user.photoURL,
        'uid': user.uid,
      });
    }
  }

  void _sendMsg() async {
    var user = FirebaseAuth.instance.currentUser;
    if (_chatController.text.isNotEmpty && user != null) {
      await FirebaseFirestore.instance.collection('rooms').doc('room1').collection('chats').add({
        'name': user.displayName,
        'text': _chatController.text,
        'time': FieldValue.serverTimestamp(),
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
          ListTile(title: const Text("পাগলা আড্ডা", style: TextStyle(color: Colors.white)), subtitle: const Text("ID: 550889 | Live", style: TextStyle(color: Colors.white54, fontSize: 10)), trailing: const Icon(Icons.lock, color: Colors.orange)),
          
          Container(
            margin: const EdgeInsets.all(10), height: 160,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.pinkAccent, width: 2)),
            child: ClipRRect(borderRadius: BorderRadius.circular(13), child: YoutubePlayer(controller: _ytController, showVideoProgressIndicator: true)),
          ),

          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.casino, color: Colors.blue), const SizedBox(width: 30),
            GestureDetector(
              onTap: () { setState(() => isMicOn = !isMicOn); _engine.muteLocalAudioStream(!isMicOn); },
              child: CircleAvatar(radius: 28, backgroundColor: isMicOn ? Colors.green : Colors.redAccent, child: Icon(isMicOn ? Icons.mic : Icons.mic_off, color: Colors.white)),
            ),
            const SizedBox(width: 30), const Icon(Icons.music_note, color: Colors.green),
          ]),

          Expanded(child: _seatGrid()),
          _chatDisplay(),

          Container(padding: const EdgeInsets.all(10), child: Row(children: [
            const Icon(Icons.card_giftcard, color: Colors.pinkAccent), const SizedBox(width: 10),
            Expanded(child: TextField(controller: _chatController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "কথা বলুন...", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.
