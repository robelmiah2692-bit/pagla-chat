import 'package:flutter/material.dart';
import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SplashScreen(),
  ));
}

// ১. স্প্ল্যাশ স্ক্রিন (লোগো সহ)
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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset('assets/logo.jpg', width: 140, height: 140, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.stars, size: 100, color: Colors.amber)),
            ),
            const SizedBox(height: 25),
            const Text("পাগলা চ্যাট", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: Colors.pinkAccent),
          ],
        ),
      ),
    );
  }
}

// ২. মেইন নেভিগেশন
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

// ৩. ভয়েস রুম (১০ জন কথা বলতে পারবে)
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  late RtcEngine _engine;
  bool _isJoined = false;
  bool _isMicMuted = false;
  Set<int> _remoteUsers = {}; 

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    
    // তোমার Agora App ID এখানে বসাও
    await _engine.initialize(const RtcEngineContext(appId: "YOUR_APP_ID")); 

    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        setState(() => _isJoined = true);
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        setState(() => _remoteUsers.add(remoteUid));
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        setState(() => _remoteUsers.remove(remoteUid));
      },
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        setState(() { _isJoined = false; _remoteUsers.clear(); });
      },
    ));

    await _engine.enableAudio();
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
  }

  Future<void> _toggleSeat() async {
    if (_isJoined) {
      await _engine.leaveChannel();
    } else {
      await _engine.joinChannel(token: "", channelId: "pagla_room_01", uid: 0, options: const ChannelMediaOptions());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text("লাইভ আড্ডা")),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 15),
              itemCount: 10,
              itemBuilder: (context, index) {
                bool active = _isJoined && (index == 0 || index <= _remoteUsers.length);
                return GestureDetector(
                  onTap: _toggleSeat,
                  child: Column(
                    children: [
                      Container(
                        width: 75, height: 75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: active ? Colors.greenAccent : (index == 0 ? Colors.amber : Colors.blueAccent), width: 3),
                        ),
                        child: CircleAvatar(radius: 32, backgroundColor: Colors.white10, child: Icon(active ? Icons.mic : Icons.person, color: Colors.white)),
                      ),
                      Text(index == 0 ? "Host" : "Seat ${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildControlBar(),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.black45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(_isMicMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
            onPressed: () {
              setState(() {
                _isMicMuted = !_isMicMuted;
                _engine.muteLocalAudioStream(_isMicMuted);
              });
            },
          ),
          ElevatedButton(
            onPressed: _toggleSeat, 
            style: ElevatedButton.styleFrom(backgroundColor: _isJoined ? Colors.red : Colors.blueAccent),
            child: Text(_isJoined ? "সিট ছাড়ুন" : "সিটে বসুন")
          ),
          const Icon(Icons.card_giftcard, color: Colors.amber, size: 30),
        ],
      ),
    );
  }
}

// ৪. স্টোর ও ৫. প্রোফাইল
class DiamondStore extends StatelessWidget {
  const DiamondStore({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF1A1A2E), 
    appBar: AppBar(title: const Text("কয়েন স্টোর")),
    body: const Center(child: Text("ডায়মন্ড প্যাকেজ লোড হচ্ছে...", style: TextStyle(color: Colors.white)))
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF121212), 
    body: Column(
      children: [
        const SizedBox(height: 80),
        Center(child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.pinkAccent, width: 3)))),
        const SizedBox(height: 20),
        const Text("পাগলা ইউজার", style: TextStyle(color: Colors.white, fontSize: 22)),
        const Text("ID: 2692001", style: TextStyle(color: Colors.grey)),
      ],
    )
  );
}
