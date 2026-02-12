import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;

// --- আপনার সেই ইউটিউব এপিআই কী এখানে বসানো হলো ---
const String youtubeApiKey = "AIzaSyB..."; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await Firebase.initializeApp(); } catch (e) { debugPrint("Firebase Error: $e"); }
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

// --- ২. গুগল লগইন ---
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  Future<void> _signIn(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? gUser = await googleSignIn.signIn();
      if (gUser == null) return;
      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final AuthCredential cred = GoogleAuthProvider.credential(accessToken: gAuth.accessToken, idToken: gAuth.idToken);
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(cred);
      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user!.displayName,
          'photo': userCredential.user!.photoURL,
          'id': '7788${userCredential.user!.uid.substring(0, 4)}',
          'diamonds': 520,
          'level': 1,
        }, SetOptions(merge: true));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
      }
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(child: ElevatedButton.icon(onPressed: () => _signIn(context), icon: const Icon(Icons.login), label: const Text("Google Login"))),
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
  final _pages = [const HomePage(), const VoiceRoom(), const Center(child: Text("Inbox Empty", style: TextStyle(color: Colors.white))), const ProfilePage()];
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

// --- ৪. হোম পেজ (পোস্ট সিস্টেম) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(title: const Text("PAGLA HOME"), backgroundColor: Colors.transparent),
      body: ListView.builder(itemCount: 3, itemBuilder: (context, index) => _postCard()),
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.pinkAccent, child: const Icon(Icons.add), onPressed: () {}),
    );
  }
  Widget _postCard() => Container(
    margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [CircleAvatar(radius: 15), SizedBox(width: 10), Text("পাগলা ইউজার", style: TextStyle(color: Colors.white))]),
      const SizedBox(height: 10),
      const Text("আজকের আড্ডাটা দারুণ হবে!", style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 10),
      Container(height: 150, width: double.infinity, color: Colors.white10, child: const Icon(Icons.image, color: Colors.white24)),
    ]),
  );
}

// --- ৫. ভয়েস রুম (১৫ সিট + ইউটিউব সার্চ + জ্যান্ত চ্যাট) ---
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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAgora();
    _ytController = YoutubePlayerController(initialVideoId: 'iLnmTe5Q2Qw', flags: const YoutubePlayerFlags(autoPlay: true));
  }

  _initAgora() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: "bd010dec4aa141228c87ec2cb9d4f6e8"));
    await _engine.enableAudio();
    await _engine.joinChannel(token: '', channelId: 'pagla_room', uid: 0, options: const ChannelMediaOptions());
  }

  Future<void> _searchVideo(String query) async {
    final url = "https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=1&q=$query&type=video&key=$youtubeApiKey";
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final id = json.decode(res.body)['items'][0]['id']['videoId'];
      _ytController.load(id);
    }
  }

  void _sendMsg() async {
    var user = FirebaseAuth.instance.currentUser;
    if (_chatController.text.isNotEmpty && user != null) {
      await FirebaseFirestore.instance.collection('rooms').doc('room1').collection('chats').add({
        'name': user.displayName, 'text': _chatController.text, 'time': FieldValue.serverTimestamp(),
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
          const ListTile(title: Text("পাগলা কিং আড্ডা", style: TextStyle(color: Colors.white)), subtitle: Text("ID: 550889 | Live", style: TextStyle(color: Colors.white54, fontSize: 10))),
          // ইউটিউব প্লেয়ার ও সার্চ
          Container(
            margin: const EdgeInsets.all(10), height: 160,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.pinkAccent)),
            child: ClipRRect(borderRadius: BorderRadius.circular(13), child: YoutubePlayer(controller: _ytController)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(children: [
              Expanded(child: TextField(controller: _searchController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "গান সার্চ করুন...", hintStyle: TextStyle(color: Colors.white24)))),
              IconButton(icon: const Icon(Icons.search, color: Colors.blueAccent), onPressed: () => _searchVideo(_searchController.text)),
            ]),
          ),
          // মাইক বাটন
          GestureDetector(
            onTap: () { setState(() => isMicOn = !isMicOn); _engine.muteLocalAudioStream(!isMicOn); },
            child: CircleAvatar(radius: 25, backgroundColor: isMicOn ? Colors.green : Colors.red, child: Icon(isMicOn ? Icons.mic : Icons.mic_off, color: Colors.white)),
          ),
          Expanded(child: _seatGrid()),
          _chatDisplay(),
          _chatInput(),
        ]),
      ),
    );
  }

  Widget _seatGrid() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('rooms').doc('room1').collection('seats').snapshots(),
      builder: (context, snapshot) {
        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 10),
          itemCount: 15,
          itemBuilder: (context, i) {
            var seat = snapshot.data?.docs.where((d) => d.id == 'seat_$i').firstOrNull;
            return Column(children: [
              CircleAvatar(radius: 20, backgroundColor: Colors.white10, backgroundImage: seat != null ? NetworkImage(seat['photo']) : null, child: seat == null ? const Icon(Icons.person, size: 15) : null),
              Text(seat != null ? seat['name'].split(' ')[0] : "${i+1}", style: const TextStyle(color: Colors.white38, fontSize: 8)),
            ]);
          },
        );
      },
    );
  }

  Widget _chatDisplay() => Container(
    height: 60, padding: const EdgeInsets.symmetric(horizontal: 15),
    child: StreamBuilder(
      stream: FirebaseFirestore.instance.collection('rooms').doc('room1').collection('chats').orderBy('time', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        return ListView.builder(reverse: true, itemCount: snapshot.data!.docs.length, itemBuilder: (context, i) {
          var chat = snapshot.data!.docs[i];
          return Text("${chat['name']}: ${chat['text']}", style: const TextStyle(color: Colors.white70, fontSize: 11));
        });
      },
    ),
  );

  Widget _chatInput() => Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(children: [
      Expanded(child: TextField(controller: _chatController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "মেসেজ...", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))))),
      IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: _sendMsg),
    ]),
  );
}

// --- ৬. প্রোফাইল পেজ ---
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
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.diamond, color: Colors.blue), Text(" 520", style: TextStyle(color: Colors.white))]),
            const SizedBox(height: 20),
            ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Log Out", style: TextStyle(color: Colors.white)), onTap: () => FirebaseAuth.instance.signOut()),
          ]));
        },
      ),
    );
  }
}
