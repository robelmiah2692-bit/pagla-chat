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
  try { 
    await Firebase.initializeApp(); 
  } catch (e) { 
    debugPrint("Firebase Error: $e"); 
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
      final AuthCredential cred = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken, 
        idToken: gAuth.idToken
      );
      
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(cred);
      if (userCredential.user != null) {
        // নতুন আইডি জেনারেট করার লজিক একটু উন্নত করা হয়েছে
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user!.displayName ?? "Anonymous",
          'photo': userCredential.user!.photoURL ?? "",
          'id': '7788${userCredential.user!.uid.substring(0, 4)}',
          'diamonds': 520,
          'level': 1,
        }, SetOptions(merge: true));
        
        if (context.mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
        }
      }
    } catch (e) { 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Failed: $e"))); 
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
          onPressed: () => _signIn(context), 
          icon: const Icon(Icons.login), 
          label: const Text("Sign in with Google")
        )
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
  final _pages = [
    const HomePage(), 
    const VoiceRoom(), 
    const Center(child: Text("ইনবক্স ফাঁকা", style: TextStyle(color: Colors.white))), 
    const ProfilePage()
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx, 
        type: BottomNavigationBarType.fixed, 
        backgroundColor: const Color(0xFF151525),
        selectedItemColor: Colors.pinkAccent, 
        unselectedItemColor: Colors.white24,
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

// --- ৪. হোম পেজ ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(title: const Text("PAGLA HOME"), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView.builder(itemCount: 3, itemBuilder: (context, index) => _postCard()),
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.pinkAccent, child: const Icon(Icons.add), onPressed: () {}),
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

// --- ৫. ভয়েস রুম (১৫ সিট + ইউটিউব + চ্যাট) ---
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
    _ytController = YoutubePlayerController(
      initialVideoId: 'iLnmTe5Q2Qw', 
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false)
    );
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    _ytController?.dispose();
    super.dispose();
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
    } catch (e) {
      debugPrint("YouTube Search Error: $e");
    }
  }

  void _sendMsg() async {
    var user = FirebaseAuth.instance.currentUser;
    if (_chatController.text.isNotEmpty && user != null) {
      await FirebaseFirestore.instance.collection('rooms').doc('room1').collection('chats').add({
        'name': user.displayName ?? "User", 
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
          const ListTile(title: Text("পাগলা কিং আড্ডা", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: Text("ID: 550889 | Live", style: TextStyle(color: Colors.pinkAccent, fontSize: 10))),
          
          if (_ytController != null) Container(
            margin: const EdgeInsets.symmetric(horizontal: 10), height: 180,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.pinkAccent.withOpacity(0.5))),
            child: ClipRRect(borderRadius: BorderRadius.circular(13), child: YoutubePlayer(controller: _ytController!)),
          ),
          
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              Expanded(child: TextField(controller: _searchController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "গান সার্চ করুন...", hintStyle: TextStyle(color: Colors.white24)))),
              IconButton(icon: const Icon(Icons.search, color: Colors.blueAccent), onPressed: () => _searchVideo(_searchController.text)),
            ]),
          ),
          
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            GestureDetector(
              onTap: () { setState(() => isMicOn = !isMicOn); _engine?.muteLocalAudioStream(!isMicOn); },
              child: CircleAvatar(radius: 25, backgroundColor: isMicOn ? Colors.green : Colors.red, child: Icon(isMicOn ? Icons.mic : Icons.mic_off, color: Colors.white)),
            ),
          ]),
          
          Expanded(child: _seatGrid()),
          _chatDisplay(),
          _chatInput(),
        ]),
      ),
    );
  }

  Widget _seatGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').doc('room1').collection('seats').snapshots(),
      builder: (context, snapshot) {
        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 10, childAspectRatio: 0.8),
          itemCount: 15,
          itemBuilder: (context, i) {
            // মেমোরি সেভ করার জন্য null check
            var seatDocs = snapshot.data?.docs;
            var seat = seatDocs != null && seatDocs.any((d) => d.id == 'seat_$i') 
                ? seatDocs.firstWhere((d) => d.id == 'seat_$i') 
                : null;
                
            return Column(children: [
              CircleAvatar(
                radius: 22, 
                backgroundColor: Colors.white10, 
                backgroundImage: (seat != null && seat['photo'] != "") ? NetworkImage(seat['photo']) : null, 
                child: (seat == null || seat['photo'] == "") ? const Icon(Icons.person, size: 20, color: Colors.white24) : null
              ),
              const SizedBox(height: 4),
              Text(seat != null ? seat['name'].toString().split(' ')[0] : "${i+1}", 
                  style: const TextStyle(color: Colors.white54, fontSize: 9), overflow: TextOverflow.ellipsis),
            ]);
          },
        );
      },
    );
  }

  Widget _chatDisplay() => Container(
    height: 80, 
    margin: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
    child: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').doc('room1').collection('chats').orderBy('time', descending: true).limit(20).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        return ListView.builder(
          reverse: true, 
          itemCount: snapshot.data!.docs.length, 
          itemBuilder: (context, i) {
            var chat = snapshot.data!.docs[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: RichText(text: TextSpan(children: [
                TextSpan(text: "${chat['name']}: ", style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                TextSpan(text: "${chat['text']}", style: const TextStyle(color: Colors.white, fontSize: 11)),
              ])),
            );
          }
        );
      },
    ),
  );

  Widget _chatInput() => Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(children: [
      Expanded(child: TextField(controller: _chatController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "মেসেজ লিখুন...", hintStyle: const TextStyle(color: Colors.white24), filled: true, fillColor: Colors.white10, contentPadding: const EdgeInsets.symmetric(horizontal: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))),
      const SizedBox(width: 5),
      CircleAvatar(backgroundColor: Colors.pinkAccent, child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _sendMsg)),
    ]),
  );
}

// --- ৬. প্রোফাইল পেজ ---
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("নট লগড ইন"));
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var data = snapshot.data!.data() as Map<String, dynamic>?;
          
          return Center(child: Column(children: [
            const SizedBox(height: 80),
            CircleAvatar(radius: 50, backgroundImage: NetworkImage(data?['photo'] ?? "")),
            const SizedBox(height: 15),
            Text(data?['name'] ?? "User", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text("ID: ${data?['id'] ?? "0000"}", style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.diamond, color: Colors.blue, size: 30),
              Text(" ${data?['diamonds'] ?? 0}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red), 
              title: const Text("লগ আউট", style: TextStyle(color: Colors.white)), 
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                await GoogleSignIn().signOut();
                if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              }
            ),
            const SizedBox(height: 40),
          ]));
        },
      ),
    );
  }
}
