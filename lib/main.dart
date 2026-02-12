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
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase Error: $e");
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
        Image.asset('assets/logo.png', width: 120, height: 120, 
          errorBuilder: (context, error, stackTrace) => const CircleAvatar(radius: 60, backgroundColor: Colors.pinkAccent, child: Icon(Icons.stars, size: 60, color: Colors.white))),
        const SizedBox(height: 20),
        const Text("PAGLA CHAT", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 5)),
      ])),
    );
  }
}

// --- ২. গুগল লগইন ---
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signIn(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      await googleSignIn.signOut();
      final GoogleSignInAccount? gUser = await googleSignIn.signIn();
      if (gUser == null) return;

      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final AuthCredential cred = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(cred);
      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user!.displayName,
          'photo': userCredential.user!.photoURL,
          'id': '7788${userCredential.user!.uid.substring(0, 4)}',
          'diamonds': 520, 
        }, SetOptions(merge: true));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E), 
      body: Center(child: ElevatedButton(onPressed: () => _signIn(context), child: const Text("Google Login")))
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

// --- ৪. ভয়েস রুম ---
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
          const ListTile(title: Text("পাগলা আড্ডা", style: TextStyle(color: Colors.white)), subtitle: Text("ID: 550889 | Live", style: TextStyle(color: Colors.white54, fontSize: 10))),
          Container(
            margin: const EdgeInsets.all(10), height: 160,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.pinkAccent, width: 2)),
            child: ClipRRect(borderRadius: BorderRadius.circular(13), child: YoutubePlayer(controller: _ytController, showVideoProgressIndicator: true)),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            GestureDetector(
              onTap: () { setState(() => isMicOn = !isMicOn); _engine.muteLocalAudioStream(!isMicOn); },
              child: CircleAvatar(radius: 28, backgroundColor: isMicOn ? Colors.green : Colors.redAccent, child: Icon(isMicOn ? Icons.mic : Icons.mic_off, color: Colors.white)),
            ),
          ]),
          Expanded(child: _seatGrid()),
          _chatDisplay(),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(children: [
              Expanded(child: TextField(controller: _chatController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "কথা বলুন...", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))))),
              IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: _sendMsg)
            ]),
          ),
        ]),
      ),
    );
  }

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
                CircleAvatar(radius: 20, backgroundColor: isOccupied ? Colors.pinkAccent : Colors.white10, backgroundImage: isOccupied ? NetworkImage(seatData['photo']) : null, child: isOccupied ? null : const Icon(Icons.person, size: 15, color: Colors.white24)),
                Text(isOccupied ? seatData['name'].split(' ')[0] : "${i+1}", style: const TextStyle(color: Colors.white38, fontSize: 8), overflow: TextOverflow.ellipsis),
              ]),
            );
          },
        );
      },
    );
  }

  Widget _chatDisplay() {
    return Container(
      height: 80, padding: const EdgeInsets.symmetric(horizontal: 15),
      child: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('rooms').doc('room1').collection('chats').orderBy('time', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          return ListView.builder(
            reverse: true, itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var chat = snapshot.data!.docs[index];
              return Text("${chat['name']}: ${chat['text']}", style: const TextStyle(color: Colors.white70, fontSize: 11));
            },
          );
        },
      ),
    );
  }
}

// --- ৫. প্রোফাইল পেজ ---
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
            Text(data['name'] ?? "User", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text("ID: ${data['id'] ?? "7788"}", style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.diamond, color: Colors.blue), Text(" ${data['diamonds'] ?? 0}", style: const TextStyle(color: Colors.white))]),
            const SizedBox(height: 20),
            ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text("Log Out", style: TextStyle(color: Colors.white)), onTap: () => FirebaseAuth.instance.signOut()),
          ]));
        },
      ),
    );
  }
}
