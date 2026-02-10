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
      body: Center(child: Icon(Icons.stars, size: 100, color: Colors.amber)),
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

class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  late RtcEngine _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _showMusicBar = false; 
  bool _isPaused = false;
  String currentSongName = "";
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
  }

  // মিউজিক ফাইল আনার ফাংশন
  void _pickMusic() {
    if (!_isJoined) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("মিউজিক প্লে করতে আগে সিটে বসুন")));
      return;
    }
    // ফাইল পিকার ডায়ালগ সিমুলেশন (আসল ডিভাইসে ফাইল পিকার উইন্ডো খুলবে)
    setState(() {
      _showMusicBar = true;
      _isPaused = false;
      currentSongName = "মন চায় তোরে.mp3"; // উদাহরনস্বরূপ নাম
    });
    // সবাইকে শোনানোর জন্য Agora অডিও মিক্সিং
    _engine.startAudioMixing(filePath: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3", loopback: false, cycle: -1);
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _engine.pauseAudioMixing();
      } else {
        _engine.resumeAudioMixing();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)], begin: Alignment.topCenter)),
        child: Column(
          children: [
            const SizedBox(height: 50),
            // ১. বোর্ড নাম ও মিউজিক বাটন
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.pink, child: Icon(Icons.group, color: Colors.white)),
              title: Row(children: [
                Text("পাগলা আড্ডা", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.add_box_rounded, color: Colors.cyanAccent, size: 20)
              ]),
              trailing: IconButton(icon: Icon(Icons.queue_music, color: Colors.cyanAccent, size: 30), onPressed: _pickMusic),
            ),
            
            // বসার সিটসমূহ
            Expanded(
              flex: 2,
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                itemCount: 10,
                itemBuilder: (context, index) => Column(
                  children: [
                    CircleAvatar(radius: 22, backgroundColor: (_isJoined && index == 0) ? Colors.greenAccent : Colors.white10, child: const Icon(Icons.person, color: Colors.white, size: 20)),
                    Text(index == 0 ? "Host" : "Seat ${index+1}", style: const TextStyle(color: Colors.white54, fontSize: 8)),
                  ],
                ),
              ),
            ),

            // ২. ডায়নামিক মিউজিক বার (সবাই দেখতে ও শুনতে পাবে)
            if (_showMusicBar)
              Container(
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.5))
                ),
                child: Row(
                  children: [
                    Icon(Icons.music_note, color: Colors.cyanAccent, size: 20),
                    SizedBox(width: 10),
                    Expanded(child: Text(currentSongName, style: TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis)),
                    IconButton(icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white), onPressed: _togglePause),
                    IconButton(icon: Icon(Icons.stop, color: Colors.redAccent), onPressed: () {
                      _engine.stopAudioMixing();
                      setState(() => _showMusicBar = false);
                    }),
                  ],
                ),
              ),

            // চ্যাট এরিয়া
            Expanded(
              flex: 3,
              child: ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) => ListTile(dense: true, title: Text("${messages[index]["user"]}: ${messages[index]["msg"]}", style: const TextStyle(color: Colors.white70))),
              ),
            ),

            // কন্ট্রোল বার (সেন্ড বাটন সহ)
            _buildControlBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
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
                suffixIcon: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.pinkAccent), onPressed: () {
                  if (_msgController.text.isNotEmpty) {
                    setState(() => messages.insert(0, {"user": "আপনি", "msg": _msgController.text}));
                    _msgController.clear();
                  }
                }),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _isJoined ? Colors.red : Colors.green, shape: StadiumBorder()),
            onPressed: () async {
              if (_isJoined) { await _engine.leaveChannel(); }
              else { await _engine.joinChannel(token: "", channelId: "pagla_room_1", uid: 0, options: const ChannelMediaOptions()); }
            },
            child: Text(_isJoined ? "নামুন" : "বসুন"),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Column(
        children: [
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [Icon(Icons.monetization_on, color: Colors.amber), Text(" ১০০", style: TextStyle(color: Colors.white))]),
              Icon(Icons.settings, color: Colors.white54),
            ]),
          ),
          const SizedBox(height: 40),
          CircleAvatar(radius: 55, backgroundColor: Colors.white10, child: Icon(Icons.person, size: 60, color: Colors.white)),
          const SizedBox(height: 10),
          Text("পাগলা ইউজার", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text("ID: 265977", style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 25),
          // ফলোয়ার ও ফলোইং
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStat("১২০", "ফলোয়ার"),
              Container(width: 1, height: 30, color: Colors.white10, margin: EdgeInsets.symmetric(horizontal: 30)),
              _buildStat("৪৫", "ফলোইং"),
            ],
          ),
          const SizedBox(height: 30),
          ListTile(leading: Icon(Icons.military_tech, color: Colors.amber), title: Text("লেভেল: ০", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
  Widget _buildStat(String count, String label) {
    return Column(children: [Text(count, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text(label, style: TextStyle(color: Colors.white54, fontSize: 12))]);
  }
}

class DiamondStore extends StatelessWidget {
  const DiamondStore({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(backgroundColor: Color(0xFF0F0F1E), body: Center(child: Text("স্টোর", style: TextStyle(color: Colors.white))));
}
