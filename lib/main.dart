import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen()));

// ১. স্প্ল্যাশ স্ক্রিন
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation())));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(child: Image.asset('assets/logo.jpg', width: 150, errorBuilder: (c, e, s) => const Icon(Icons.stars, size: 100, color: Colors.amber))),
    );
  }
}

// ২. মেইন নেভিগেশন (৪টি ভাগ)
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
        backgroundColor: const Color(0xFF1A1A2E),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "হোম"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: "ইনবক্স"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}

// --- ৩. হোম পেজ (গেমস ও অফার) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text("পাগলা চ্যাট হোম")),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          _buildBox("আজকের অফার: ৫০০ কয়েন কিনলে ১০০ ফ্রি!", Colors.purple),
          const SizedBox(height: 20),
          const Text("গেমস জোন", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _gameIcon(Icons.casino, "লুডু", Colors.blue),
              _gameIcon(Icons.rotate_right, "স্পিন", Colors.orange),
              _gameIcon(Icons.card_giftcard, "গিফট", Colors.green),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildBox(String txt, Color clr) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: clr.withOpacity(0.2), borderRadius: BorderRadius.circular(15), border: Border.all(color: clr)), child: Text(txt, style: const TextStyle(color: Colors.white)));
  Widget _gameIcon(IconData i, String n, Color c) => Column(children: [CircleAvatar(radius: 25, backgroundColor: c, child: Icon(i, color: Colors.white)), Text(n, style: const TextStyle(color: Colors.white70, fontSize: 12))]);
}

// --- ৪. রুম (আড্ডা + রিয়েল মিউজিক) ---
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  late RtcEngine _engine;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isJoined = false, _isMuted = false, _isPlaying = false;
  String songName = "গান নেই";
  List<String> chats = [];
  final TextEditingController _ctrl = TextEditingController();

  @override
  void initState() { super.initState(); _initAgora(); }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.storage].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: "348a9f9d55b14667891657dfc53dfbeb"));
    _engine.registerEventHandler(RtcEngineEventHandler(onJoinChannelSuccess: (c, e) => setState(() => _isJoined = true), onLeaveChannel: (c, s) => setState(() => _isJoined = false)));
    await _engine.enableAudio();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)], begin: Alignment.topCenter)),
      child: Column(
        children: [
          const SizedBox(height: 50),
          ListTile(
            title: const Text("পাগলা আড্ডা বোর্ড", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: IconButton(icon: const Icon(Icons.library_music, color: Colors.cyanAccent), onPressed: () async {
              FilePickerResult? r = await FilePicker.platform.pickFiles(type: FileType.audio);
              if (r != null) {
                setState(() { songName = r.files.single.name; _isPlaying = true; });
                await _audioPlayer.play(DeviceFileSource(r.files.single.path!));
                await _engine.startAudioMixing(filePath: r.files.single.path!, loopback: false, cycle: -1);
              }
            }),
          ),
          Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5), itemCount: 10, itemBuilder: (c, i) => Column(children: [CircleAvatar(backgroundColor: (_isJoined && i==0)? Colors.pink : Colors.white10, child: const Icon(Icons.person, color: Colors.white)), Text("সিট ${i+1}", style: const TextStyle(color: Colors.white38, fontSize: 10))]))),
          Expanded(child: ListView.builder(itemCount: chats.length, itemBuilder: (c, i) => Text(chats[i], style: const TextStyle(color: Colors.white70)))),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(children: [
              IconButton(icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: Colors.white), onPressed: () { setState(() => _isMuted = !_isMuted); _engine.muteLocalAudioStream(_isMuted); }),
              Expanded(child: TextField(controller: _ctrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "লিখুন...", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))))),
              IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: () { if(_ctrl.text.isNotEmpty) { setState(() { chats.insert(0, "আপনি: ${_ctrl.text}"); _ctrl.clear(); }); } }),
              ElevatedButton(onPressed: () async { if(_isJoined) await _engine.leaveChannel(); else await _engine.joinChannel(token: "", channelId: "room1", uid: 0, options: const ChannelMediaOptions()); }, style: ElevatedButton.styleFrom(backgroundColor: _isJoined ? Colors.red : Colors.green), child: Text(_isJoined ? "নামুন" : "বসুন"))
            ]),
          )
        ],
      ),
    );
  }
}

// --- ৫. ইনবক্স ---
class InboxPage extends StatelessWidget {
  const InboxPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF0F0F1E), appBar: AppBar(backgroundColor: Colors.transparent, title: const Text("ইনবক্স")), body: const Center(child: Text("আপনার ব্যক্তিগত চ্যাট এখানে", style: TextStyle(color: Colors.white54))));
}

// --- ৬. প্রোফাইল (ডাটা সেভ + স্টোরি) ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "লোডিং...";
  File? img;
  List<File> stories = [];

  @override
  void initState() { super.initState(); _loadData(); }

  _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? "পাগলা ইউজার";
      String? path = prefs.getString('image');
      if (path != null) img = File(path);
    });
  }

  _save(String k, String v) async { final prefs = await SharedPreferences.getInstance(); prefs.setString(k, v); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 60),
          GestureDetector(
            onTap: () async {
              final x = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (x != null) { setState(() => img = File(x.path)); _save('image', x.path); }
            },
            child: CircleAvatar(radius: 50, backgroundImage: img != null ? FileImage(img!) : null, child: img == null ? const Icon(Icons.camera_alt) : null),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 22)),
            IconButton(icon: const Icon(Icons.edit, color: Colors.pinkAccent), onPressed: () {
              TextEditingController c = TextEditingController(text: name);
              showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("নাম পরিবর্তন"), content: TextField(controller: c), actions: [TextButton(onPressed: () { setState(() => name = c.text); _save('name', c.text); Navigator.pop(context); }, child: const Text("সেভ"))]));
            })
          ]),
          const Divider(color: Colors.white10),
          ListTile(title: const Text("আমার স্টোরি", style: TextStyle(color: Colors.white)), trailing: IconButton(icon: const Icon(Icons.add_a_photo, color: Colors.cyanAccent), onPressed: () async {
            final x = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (x != null) setState(() => stories.insert(0, File(x.path)));
          })),
          SizedBox(height: 150, child: stories.isEmpty ? const Center(child: Text("পোস্ট নেই", style: TextStyle(color: Colors.white24))) : ListView.builder(scrollDirection: Axis.horizontal, itemCount: stories.length, itemBuilder: (c, i) => Container(width: 100, margin: const EdgeInsets.all(10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), image: DecorationImage(image: FileImage(stories[i]), fit: BoxFit.cover))))),
        ]),
      ),
    );
  }
}
