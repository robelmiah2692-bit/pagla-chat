import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

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
  } catch (e) {
    debugPrint("Firebase connection error: $e");
  }
  runApp(const PaglaChatApp());
}

class PaglaChatApp extends StatefulWidget {
  const PaglaChatApp({super.key});
  @override
  State<PaglaChatApp> createState() => _PaglaChatAppState();
}

class _PaglaChatAppState extends State<PaglaChatApp> {
  String _language = 'bn'; 

  void _changeLang(String lang) {
    setState(() => _language = lang);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: SplashScreen(changeLang: _changeLang, currentLang: _language),
    );
  }
}

// --- ১. স্প্ল্যাশ স্ক্রিন ---
class SplashScreen extends StatefulWidget {
  final Function(String) changeLang;
  final String currentLang;
  const SplashScreen({super.key, required this.changeLang, required this.currentLang});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (FirebaseAuth.instance.currentUser != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainNavigation(changeLang: widget.changeLang, currentLang: widget.currentLang)));
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

// --- ২. লগইন স্ক্রিন (বোনাস ২০০ ডায়মন্ড সহ) ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();

  Future<void> _saveUserToFirestore(User user) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();
    if (!snapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'name': 'পাগলা ইউজার',
        'id': (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString(),
        'diamonds': 200, 
        'xp': 0,
        'vipLevel': 0,
        'followers': 0,
        'following': 0,
        'profilePic': '',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Padding(padding: const EdgeInsets.all(25), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("PAGLA LOGIN", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        TextField(controller: _email, decoration: const InputDecoration(hintText: "Email")),
        TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(hintText: "Password")),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () async {
          try {
            UserCredential user = await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text, password: _pass.text);
            await _saveUserToFirestore(user.user!);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainNavigation(changeLang: (s){}, currentLang: 'bn')));
          } catch(e) {}
        }, child: const Text("প্রবেশ করুন"))
      ])),
    );
  }
}

// --- ৩. মেইন নেভিগেশন ---
class MainNavigation extends StatefulWidget {
  final Function(String) changeLang;
  final String currentLang;
  const MainNavigation({super.key, required this.changeLang, required this.currentLang});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [const HomePage(), const VoiceRoom(), const InboxPage(), ProfilePage(changeLang: widget.changeLang, currentLang: widget.currentLang)];
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF151525),
        selectedItemColor: Colors.pinkAccent,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "Room"),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: "Inbox"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
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
      appBar: AppBar(
        title: const Text("PAGLA HOME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        itemCount: 5, // টেস্ট করার জন্য ৫টি পোস্ট দেওয়া হলো
        itemBuilder: (context, index) => _buildPostCard(),
      ),
      // আপনার স্ক্রিনশটের মতো প্লাস বাটন
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pinkAccent,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  // স্ক্রিনশটের মতো পোস্ট ডিজাইন
  Widget _buildPostCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2F), // কার্ডের ব্যাকগ্রাউন্ড
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ইউজার ইনফো (ছবি ও নাম)
          Row(children: [
            const CircleAvatar(
              radius: 20, 
              backgroundColor: Colors.pinkAccent, 
              child: Icon(Icons.person, color: Colors.white)
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("পাগলা ইউজার", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text("২ মিনিট আগে", style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ]),
          const SizedBox(height: 12),
          // পোস্টের লেখা
          const Text("আজকের আড্ডাটা দারুণ হবে! সবাই চলে আসুন। 👑", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          // পোস্টের ইমেজ বক্স (স্ক্রিনশটের মতো)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(15),
              image: const DecorationImage(
                image: NetworkImage('https://via.placeholder.com/400'), // এখানে ইউজারের পোস্ট করা ছবি আসবে
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 15),
          // লাইক ও কমেন্ট সেকশন
          Row(children: [
            const Icon(Icons.favorite_border, color: Colors.white54, size: 22),
            const SizedBox(width: 5),
            const Text("১২", style: TextStyle(color: Colors.white54)),
            const SizedBox(width: 25),
            const Icon(Icons.chat_bubble_outline, color: Colors.white54, size: 22),
            const SizedBox(width: 5),
            const Text("৫", style: TextStyle(color: Colors.white54)),
          ]),
        ],
      ),
    );
  }
}

// --- ৫. ভয়েস রুম (সব ফিচার সহ) ---
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  // এগোরা আইডি ও ইঞ্জিন
  final String agoraAppId = "bd010dec4aa141228c87ec2cb9d4f6e8";
  late RtcEngine _engine;

  @override
  void initState() {
    super.initState();
    _initWebController();
    _initAgora(); // এই লাইনটি যোগ করুন
  }

  // আগোরা সেটআপ ফাংশন
  Future<void> _initAgora() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: agoraAppId));
    await _engine.enableAudio();
    await _engine.joinChannel(token: '', channelId: 'PaglaRoom', uid: 0, options: const ChannelMediaOptions());
    await _engine.muteLocalAudioStream(true); // শুরুতে মিউট
  }
  int? currentSeat;
  bool isMicOn = false;
  bool isLocked = false;
  late WebViewController _webController;
  String currentVideoId = "iLnmTe5Q2Qw";
  String? seatEmoji;
  String roomTitle = "পাগলা কিং আড্ডা";
  File? roomImage;

  @override
  void initState() {
    super.initState();
    _initWebController();
  }

  void _initWebController() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadHtmlString('''
        <html><body style="margin:0;padding:0;background:black;">
        <iframe width="100%" height="100%" src="https://www.youtube.com/embed/$currentVideoId?autoplay=1&controls=1" frameborder="0" allowfullscreen></iframe>
        </body></html>
      ''');
  }

  Future<void> _pickRoomPic() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => roomImage = File(img.path));
  }

  void _showEmoji(String emoji) {
    setState(() => seatEmoji = emoji);
    Timer(const Duration(seconds: 3), () => setState(() => seatEmoji = null));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: Column(children: [
          // রুম বোর্ড কন্ট্রোল
          ListTile(
            leading: GestureDetector(onTap: _pickRoomPic, child: CircleAvatar(backgroundImage: roomImage != null ? FileImage(roomImage!) : null, child: roomImage == null ? const Icon(Icons.camera_alt) : null)),
            title: TextField(style: const TextStyle(color: Colors.white), decoration: const InputDecoration(border: InputBorder.none), controller: TextEditingController(text: roomTitle), onSubmitted: (v) => setState(() => roomTitle = v)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: Icon(isLocked ? Icons.lock : Icons.lock_open, color: Colors.orange), onPressed: () => setState(() => isLocked = !isLocked)),
              const Icon(Icons.person_add, color: Colors.pinkAccent),
            ]),
          ),

          // ভিডিও বোর্ড (বক্স ফিট)
          Container(
            height: 180, margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.black),
            child: ClipRRect(borderRadius: BorderRadius.circular(15), child: WebViewWidget(controller: _webController)),
          ),

          // গেম ও মাইক বাটন
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _btn(Icons.casino, "Ludo", Colors.green),
              CircleAvatar(radius: 30, backgroundColor: isMicOn ? Colors.pinkAccent : Colors.white10, child: IconButton(icon: Icon(isMicOn ? Icons.mic : Icons.mic_off), onPressed: () => setState(() => isMicOn = !isMicOn))),
              _btn(Icons.bolt, "PK Game", Colors.orange),
            ]),
          ),

          // ১৫ সিট গ্রিড
          Expanded(child: GridView.builder(
            padding: const EdgeInsets.all(10), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
            itemCount: 15, itemBuilder: (context, i) => GestureDetector(
              void _toggleMic() async {
  if (currentSeat == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("আগে সিটে বসুন!")));
    return;
  }
  setState(() => isMicOn = !isMicOn);
  await _engine.muteLocalAudioStream(!isMicOn); // রিয়েল মিউট/আনমিউট
}  
             child: Column(children: [
               Stack(alignment: Alignment.center, children: [
                    if (currentSeat == i && isMicOn)
                      Container(
                         width: 44, height: 44,
                         decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           border: Border.all(color: Colors.green, width: 2),
                         ),
                       ),
                
                 CircleAvatar(radius: 22, backgroundColor: currentSeat == i ? Colors.pinkAccent : Colors.white10, child: Icon(Icons.mic_off, size: 15, color: i < 5 ? Colors.amber : Colors.white38)),
                  if (currentSeat == i && seatEmoji != null) Text(seatEmoji!, style: const TextStyle(fontSize: 25)),
                ]),
                Text(i < 5 ? "VIP" : "${i+1}", style: TextStyle(fontSize: 8, color: i < 5 ? Colors.amber : Colors.white38))
              ]),
            ),
          )),

          // চ্যাট ও গিফট বার
          Container(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.face, color: Colors.yellow), onPressed: _showEmojiSheet),
              Expanded(child: TextField(decoration: InputDecoration(hintText: "মেসেজ লিখুন...", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))),
              IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.pinkAccent), onPressed: _showGiftSheet),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _btn(IconData i, String l, Color c) => Column(children: [CircleAvatar(backgroundColor: c, child: Icon(i, color: Colors.white)), Text(l, style: const TextStyle(fontSize: 10))]);

  void _showGiftSheet() {
    showModalBottomSheet(context: context, builder: (context) => Container(
      height: 250, color: Colors.black87,
      child: GridView.count(crossAxisCount: 4, children: [_giftItem("🌹", "10"), _giftItem("💍", "500"), _giftItem("🚗", "2000"), _giftItem("👑", "5000")]),
    ));
  }
      @override
  void dispose() {
    _engine.leaveChannel(); // চ্যানেল থেকে বের হওয়া
    _engine.release();      // এগোরা ইঞ্জিন রিলিজ করা
    _webController;         // ওয়েব ভিউ ডিসপোজ (যদি প্রয়োজন হয়)
    super.dispose();
  }
} // এইটা হলো ক্লাসের শেষ ব্র্যাকেট
  Widget _giftItem(String i, String p) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(i, style: const TextStyle(fontSize: 30)), Text("$p 💎", style: const TextStyle(fontSize: 10))]);

  void _showEmojiSheet() {
    showModalBottomSheet(context: context, builder: (context) => Container(
      height: 150, color: Colors.black87,
      child: Wrap(children: ["😊", "😭", "😡", "🤔", "👏", "😘"].map((e) => IconButton(onPressed: () { _showEmoji(e); Navigator.pop(context); }, icon: Text(e, style: const TextStyle(fontSize: 30)))).toList()),
    ));
  }
}

// --- ৬. প্রোফাইল পেজ (VIP Level: ২০০০ XP = ১ Level) ---
class ProfilePage extends StatefulWidget {
  final Function(String) changeLang;
  final String currentLang;
  const ProfilePage({super.key, required this.changeLang, required this.currentLang});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? profileImage;
  int diamonds = 200;
  int totalXp = 0; // মোট এক্সপি
  int vipLevel = 0;

  // ডায়মন্ড খরচ করলে এক্সপি ও ভিআইপি হিসাব
  void _onSpendDiamonds(int spent) {
    setState(() {
      int earnedXp = spent ~/ 200; // প্রতি ২০০ ডায়মন্ডে ১ এক্সপি
      totalXp += earnedXp;
      vipLevel = totalXp ~/ 2000; // প্রতি ২০০০ এক্সপি-তে ১ ভিআইপি লেভেল
      if (vipLevel > 50) vipLevel = 50;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 60),
          GestureDetector(
            onTap: () async {
              final img = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (img != null) setState(() => profileImage = File(img.path));
            },
            child: CircleAvatar(radius: 55, backgroundColor: Colors.pinkAccent, child: CircleAvatar(radius: 50, backgroundImage: profileImage != null ? FileImage(profileImage!) : null, child: profileImage == null ? const Icon(Icons.camera_alt) : null)),
          ),
          const SizedBox(height: 10),
          const Text("পাগলা কিং 👑", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("ID: 550889", style: TextStyle(color: Colors.white54)),
          
          // VIP Progress Bar
          Container(
            margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber.withOpacity(0.3))),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text("VIP Level $vipLevel", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                Text("XP: $totalXp / ${(vipLevel + 1) * 2000}", style: const TextStyle(fontSize: 10)),
              ]),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: (totalXp % 2000) / 2000, backgroundColor: Colors.white10, color: Colors.amber),
            ]),
          ),

          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _stat("0", "Followers"), _stat("0", "Following"), _stat("$diamonds 💎", "Diamonds")
          ]),

          const SizedBox(height: 20),
          ListTile(leading: const Icon(Icons.language), title: Text(widget.currentLang == 'bn' ? "Switch to English" : "বাংলা ভাষা করুন"), onTap: () => widget.changeLang(widget.currentLang == 'bn' ? 'en' : 'bn')),
          ListTile(leading: const Icon(Icons.block), title: const Text("Blacklist"), onTap: () {}),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Logout"), onTap: () => FirebaseAuth.instance.signOut()),
        ]),
      ),
    );
  }
  Widget _stat(String v, String l) => Column(children: [Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text(l, style: const TextStyle(color: Colors.white54, fontSize: 12))]);
}

class InboxPage extends StatelessWidget { const InboxPage({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("ইনবক্স"))); }
