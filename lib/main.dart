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

// ১. স্প্ল্যাশ স্ক্রিন (তোমার লোগো ও নাম)
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
            const SizedBox(height: 15),
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
          BottomNavigationBarItem(icon: Icon(Icons.mic_rounded), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), label: "স্টোর"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}

// ৩. ভয়েস রুম (Agora ID সহ)
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
    
    // তোমার দেওয়া Agora App ID
    await _engine.initialize(const RtcEngineContext(
      appId: "348a9f9d55b14667891657dfc53dfbeb",
    )); 

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
      await _engine.joinChannel(
        token: "", 
        channelId: "pagla_room_01", 
        uid: 0, 
        options: const ChannelMediaOptions()
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        title: const Text("লাইভ আড্ডা রুম", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.music_note, color: Colors.cyanAccent), onPressed: () {})],
      ),
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
                          border: Border.all(
                            color: active ? Colors.greenAccent : (index == 0 ? Colors.amber : Colors.blueAccent), 
                            width: 3
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 32, 
                          backgroundColor: Colors.white10, 
                          child: Icon(active ? Icons.mic : Icons.person_outline, color: Colors.white)
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(index == 0 ? "Host" : "Seat ${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(_isMicMuted ? Icons.mic_off : Icons.mic, color: Colors.white, size: 28),
            onPressed: () {
              setState(() {
                _isMicMuted = !_isMicMuted;
                _engine.muteLocalAudioStream(_isMicMuted);
              });
            },
          ),
          ElevatedButton(
            onPressed: _toggleSeat,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isJoined ? Colors.redAccent : Colors.pinkAccent,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), // সমস্যা এখানেই ছিল, ঠিক করে দিয়েছি
            ),
            child: Text(_isJoined ? "সিট ছাড়ুন" : "সিটে বসুন", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Icon(Icons.card_giftcard, color: Colors.amber, size: 32),
        ],
      ),
    );
  }
}

// ৪. ডায়মন্ড স্টোর
class DiamondStore extends StatelessWidget {
  const DiamondStore({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(title: const Text("কয়েন স্টোর"), backgroundColor: Colors.indigo),
      body: GridView.count(
        padding: const EdgeInsets.all(15),
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
        children: [
          _buildCoinCard("১০০ ডায়মন্ড", "৳ ১০০", Icons.diamond),
          _buildCoinCard("৫০০ ডায়মন্ড", "৳ ৪৫০", Icons.auto_awesome),
        ],
      ),
    );
  }
  Widget _buildCoinCard(String title, String price, IconData icon) => Card(
    color: Colors.white10,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 40),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: () {}, child: Text(price)),
      ],
    ),
  );
}

// ৫. প্রোফাইল পেজ
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.pinkAccent, width: 4)),
              child: const CircleAvatar(radius: 60, backgroundColor: Colors.white10, child: Icon(Icons.person, size: 60, color: Colors.white24)),
            ),
          ),
          const SizedBox(height: 20),
          const Text("পাগলা ইউজার", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("ID: 2692001", style: TextStyle(color: Colors.grey)),
          const Divider(color: Colors.white10, height: 60, indent: 40, endIndent: 40),
          ListTile(leading: const Icon(Icons.grid_view_rounded, color: Colors.amber), title: const Text("আমার ফ্রেম ও ব্যাজ", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
