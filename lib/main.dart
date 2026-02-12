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
  // আপনার দেওয়া অরিজিনাল ফায়ারবেস অপশন
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAkEB8dB2vSncv3BpNZng7W_0e6N7dqNmI",
      appId: "1:25052070011:android:5d89f85753b5c881d662de",
      messagingSenderId: "25052070011",
      projectId: "paglachat",
      storageBucket: "paglachat.firebasestorage.app",
    ),
  );
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen()));
}

// --- ১. স্প্ল্যাশ স্ক্রিন (অক্ষুণ্ণ) ---
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

// --- ২. গুগল লগইন (রিয়েল কানেকশন) ---
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  Future<void> _signIn(context) async {
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? gAuth = await gUser?.authentication;
    final cred = GoogleAuthProvider.credential(accessToken: gAuth?.accessToken, idToken: gAuth?.idToken);
    UserCredential user = await FirebaseAuth.instance.signInWithCredential(cred);
    await FirebaseFirestore.instance.collection('users').doc(user.user!.uid).set({
      'name': user.user!.displayName,
      'photo': user.user!.photoURL,
      'id': '7788${user.user!.uid.substring(0, 4)}',
      'diamonds': 520,
    }, SetOptions(merge: true));
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: const Color(0xFF0F0F1E), body: Center(child: ElevatedButton(onPressed: () => _signIn(context), child: const Text("Google Login"))));
  }
}

// --- ৩. মেইন নেভিগেশন (অক্ষুণ্ণ) ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _idx = 1; // সরাসরি ভয়েস রুমে নিয়ে যাবে
  final _pages = [const Center(child: Text("Home", style: TextStyle(color: Colors.white))), const VoiceRoom(), const Center(child: Text("Inbox", style: TextStyle(color: Colors.white))), const ProfilePage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx, type: BottomNavigationBarType.fixed, backgroundColor: const Color(0xFF151525), selectedItemColor: Colors.pinkAccent, unselectedItemColor: Colors.white24,
        onTap: (i) => setState(() => _idx = i),
        items: const [BottomNavigationBarItem(icon: Icon(Icons.home), label: "হোম"), BottomNavigationBarItem(icon: Icon(Icons.mic), label: "রুম"), BottomNavigationBarItem(icon: Icon(Icons.mail), label: "ইনবক্স"), BottomNavigationBarItem(icon: Icon(Icons.person), label: "আমি")],
      ),
    );
  }
}

// --- ৪. ভয়েস রুম (সব ফিচার + বসা + চ্যাট + ইউটিউব + মাইক) ---
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
          _header(),
          // ইউটিউব বোর্ড (অক্ষুণ্ণ)
          Container(
            margin: const EdgeInsets.all(10), height: 160,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.pinkAccent, width: 2)),
            child: ClipRRect(borderRadius: BorderRadius.circular(13), child: YoutubePlayer(controller: _ytController, showVideoProgressIndicator: true)),
          ),
          _controls(),
          // সিট গ্রিড (অক্ষুণ্ণ ও জ্যান্ত)
          Expanded(child: _seatGrid()),
          // রিয়েল চ্যাট ডিসপ্লে
          _chatDisplay(),
          // চ্যাট ইনপুট (অক্ষুণ্ণ)
          _chatBar(),
        ]),
      ),
    );
  }

  Widget _header() => ListTile(title: const Text("পাগলা আড্ডা", style: TextStyle(color: Colors.white)), subtitle: const Text("ID: 550889 | Live", style: TextStyle(color: Colors.white54, fontSize: 10)), trailing: const Icon(Icons.lock, color: Colors.orange));

  Widget _controls() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.casino, color: Colors.blue), const SizedBox(width: 30),
    GestureDetector(
      onTap: () { setState(() => isMicOn = !isMicOn); _engine.muteLocalAudioStream(!isMicOn); },
      child: CircleAvatar(radius: 28, backgroundColor: isMicOn ? Colors.green : Colors.redAccent, child: Icon(isMicOn ? Icons.mic : Icons.mic_off, color: Colors.white)),
    ),
    const SizedBox(width: 30), const Icon(Icons.music_note, color: Colors.green),
  ]);

  Widget _seatGrid() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('rooms').doc('room1').collection('seats').snapshots(),
      builder: (context, snapshot) {
        return GridView.builder(
          padding: const EdgeInsets.all(15),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 10),
          itemCount: 15,
          itemBuilder: (context, i) {
            var seatDoc = snapshot.data?.docs.where((d) => d.id == 'seat_$i');
            var seatData = (seatDoc != null && seatDoc.isNotEmpty) ? seatDoc.first : null;
            bool isOccupied = seatData != null;
            return GestureDetector(
              onTap: () => _occupySeat(i),
              child: Column(children: [
                CircleAvatar(
                  radius: 20, 
                  backgroundColor: isOccupied ? Colors.pinkAccent : (i < 5 ? Colors.amber.withOpacity(0.2) : Colors.white10),
                  backgroundImage: isOccupied ? NetworkImage(seatData['photo']) : null,
                  child: isOccupied ? null : Icon(Icons.person, size: 15, color: i < 5 ? Colors.amber : Colors.white24),
                ),
                Text(isOccupied ? seatData['name'].split(' ')[0] : (i < 5 ? "VIP" : "${i+1}"), style: const TextStyle(color: Colors.white38, fontSize: 8), overflow: TextOverflow.ellipsis),
              ]),
            );
          },
        );
      },
    );
  }

  Widget _chatDisplay() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('rooms').doc('room1').collection('chats').orderBy('time', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          return ListView.builder(
            reverse: true,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var chat = snapshot.data!.docs[index];
              return Text("${chat['name']}: ${chat['text']}", style: const TextStyle(color: Colors.white70, fontSize: 11));
            },
          );
        },
      ),
    );
  }

  Widget _chatBar() => Container(padding: const EdgeInsets.all(10), child: Row(children: [
    const Icon(Icons.card_giftcard, color: Colors.pinkAccent), const SizedBox(width: 10),
    Expanded(child: TextField(controller: _chatController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "কথা বলুন...", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), suffixIcon: IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: _sendMsg)))),
  ]));
}

// --- ৫. প্রোফাইল (অক্ষুণ্ণ) ---
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var data = snapshot.data!;
          return Center(child: Column(children: [
            const SizedBox(height: 60),
            CircleAvatar(radius: 50, backgroundImage: NetworkImage(data['photo'] ?? "")),
            const SizedBox(height: 10),
            Text(data['name'], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text("ID: ${data['id']}", style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 20),
            Container(margin: const EdgeInsets.symmetric(horizontal: 50), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Row(children: [const Icon(Icons.diamond, color: Colors.blue), Text(" ${data['diamonds']}", style: const TextStyle(color: Colors.white))]), const Text("Lvl 1", style: TextStyle(color: Colors.amber))])),
            ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text("Log Out"), onTap: () => FirebaseAuth.instance.signOut()),
          ]));
        },
      ),
    );
  }
}
