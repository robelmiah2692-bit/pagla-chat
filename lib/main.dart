import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:agora_rtc_engine/agora_rtc_engine.dart'; 
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen()));

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
      body: Center(child: Image.asset('assets/logo.jpg', width: 120, errorBuilder: (c, e, s) => const Icon(Icons.stars, size: 100, color: Colors.amber))),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = [const VoiceRoom(), const DiamondStore(), const ProfilePage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A2E),
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white70,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "স্টোর"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}

// ৩. ভয়েস রুম (সব ফিচার সহ)
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  late RtcEngine _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isPlayingMusic = false;
  String groupName = "পাগলা আড্ডা গ্রুপ";
  List<Map<String, String>> messages = [];
  final TextEditingController _msgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.storage].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: "348a9f9d55b14667891657dfc53dfbeb")); 
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (c, e) => setState(() => _isJoined = true),
      onLeaveChannel: (c, s) => setState(() => _isJoined = false),
    ));
    await _engine.enableAudio();
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.setDefaultAudioRouteToSpeakerphone(true);
  }

  void _toggleMusic() async {
    if (!_isJoined) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("মিউজিক বাজাতে আগে সিটে বসুন")));
      return;
    }
    if (_isPlayingMusic) {
      await _engine.stopAudioMixing();
    } else {
      // রিয়েল মিউজিক টেস্ট লিঙ্ক (সবাই শুনতে পাবে)
      await _engine.startAudioMixing(filePath: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3", loopback: false, cycle: -1);
    }
    setState(() => _isPlayingMusic = !_isPlayingMusic);
  }

  void _editGroupName() {
    TextEditingController _gc = TextEditingController(text: groupName);
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("বোর্ডের নাম"),
      content: TextField(controller: _gc),
      actions: [TextButton(onPressed: () { setState(() => groupName = _gc.text); Navigator.pop(context); }, child: const Text("সেভ"))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)], begin: Alignment.topCenter)),
        child: Column(
          children: [
            const SizedBox(height: 50),
            // বোর্ড নাম ও ফলো বাটন
            ListTile(
              onTap: _editGroupName,
              leading: const CircleAvatar(backgroundImage: AssetImage('assets/logo.jpg')),
              title: Text(groupName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent), onPressed: () {}, child: const Text("Follow")),
            ),
            // ১০ জনের বোর্ড
            SizedBox(
              height: 200,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                itemCount: 10,
                itemBuilder: (context, index) => Column(
                  children: [
                    CircleAvatar(radius: 22, backgroundColor: (_isJoined && index == 0) ? Colors.greenAccent : Colors.white10, child: const Icon(Icons.person, color: Colors.white, size: 20)),
                    const Text("Seat", style: TextStyle(color: Colors.white70, fontSize: 8)),
                  ],
                ),
              ),
            ),
            // চ্যাট এরিয়া
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) => ListTile(dense: true, title: Text("${messages[index]["user"]}: ${messages[index]["msg"]}", style: const TextStyle(color: Colors.white))),
              ),
            ),
            // কন্ট্রোল বার (মিউজিক, সেন্ড ও বসুন বাটন)
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black45,
              child: Row(
                children: [
                  IconButton(icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: Colors.white), onPressed: () => setState(() { _isMuted = !_isMuted; _engine.muteLocalAudioStream(_isMuted); })),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "কিছু লিখুন...", filled: true, fillColor: Colors.white10,
                        suffixIcon: IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: () {
                          if (_msgController.text.isNotEmpty) {
                            setState(() => messages.insert(0, {"user": "আপনি", "msg": _msgController.text}));
                            _msgController.clear();
                          }
                        }),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                  IconButton(icon: Icon(_isPlayingMusic ? Icons.pause_circle : Icons.play_circle, color: Colors.cyanAccent), onPressed: _toggleMusic),
                  const SizedBox(width: 5),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _isJoined ? Colors.red : Colors.green),
                    onPressed: () async {
                      if (_isJoined) { await _engine.leaveChannel(); }
                      else { await _engine.joinChannel(token: "", channelId: "pagla_room_1", uid: 0, options: const ChannelMediaOptions()); }
                    },
                    child: Text(_isJoined ? "নামুন" : "বসুন"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ৫. প্রোফাইল পেজ (সব পুরাতন ফিচার সহ)
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "পাগলা ইউজার";
  String userId = (Random().nextInt(899999) + 100000).toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Column(
        children: [
          const SizedBox(height: 50),
          // কয়েন ও সেটিংস
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [const Icon(Icons.monetization_on, color: Colors.amber), const Text(" ১০০", style: TextStyle(color: Colors.white))]),
                const Icon(Icons.settings, color: Colors.white54),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // ছবি পরিবর্তন
          const Stack(alignment: Alignment.bottomRight, children: [
            CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            CircleAvatar(radius: 15, backgroundColor: Colors.blue, child: Icon(Icons.camera_alt, size: 15, color: Colors.white)),
          ]),
          const SizedBox(height: 10),
          // নাম এডিট
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.white54), onPressed: () {}),
          ]),
          Text("ID: $userId", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          // ফলোয়ার ও ফলোইং
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(children: [Text("০", style: TextStyle(color: Colors.white)), Text("ফলোয়ার", style: TextStyle(color: Colors.grey, fontSize: 12))]),
              SizedBox(width: 50),
              Column(children: [Text("০", style: TextStyle(color: Colors.white)), Text("ফলোইং", style: TextStyle(color: Colors.grey, fontSize: 12))]),
            ],
          ),
          const Divider(color: Colors.white10, height: 40),
          // লেভেল
          ListTile(leading: const Icon(Icons.star, color: Colors.amber), title: const Text("Level: 0", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}

class DiamondStore extends StatelessWidget {
  const DiamondStore({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(backgroundColor: Color(0xFF0F0F1E), body: Center(child: Text("ডায়মন্ড স্টোর", style: TextStyle(color: Colors.white))));
}
