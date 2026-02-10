import 'package:flutter/material.dart';
import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart'; // ভয়েস সার্ভার
import 'package:permission_handler/permission_handler.dart'; // মাইক্রোফোন পারমিশন
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SplashScreen(),
  ));
}

// ১. স্প্ল্যাশ স্ক্রিন (পুরোনো ডাটা অক্ষত)
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
            const SizedBox(height: 20),
            const Text("পাগলা চ্যাট", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: Colors.pinkAccent),
          ],
        ),
      ),
    );
  }
}

// ২. মেইন নেভিগেশন (রুম, স্টোর, প্রোফাইল)
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

// ৩. ভয়েস রুম (১০ জনের বোর্ড + সবাই বলতে ও শুনতে পারবে)
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  late RtcEngine _engine;
  bool _isJoined = false;
  bool _isMicMuted = false;
  Set<int> _remoteUsers = {}; // রুমে যারা আছে তাদের আইডি

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    // মাইক্রোফোন পারমিশন নেয়া
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: "YOUR_APP_ID", // এখানে তোমার Agora App ID বসাও
    ));

    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        setState(() => _isJoined = true);
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        setState(() => _remoteUsers.add(remoteUid)); // নতুন কেউ এলে লিস্টে যোগ হবে
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        setState(() => _remoteUsers.remove(remoteUid)); // কেউ চলে গেলে রিমুভ হবে
      },
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        setState(() { _isJoined = false; _remoteUsers.clear(); });
      },
    ));

    await _engine.enableAudio();
    // এই লাইনটি সবাইকে কথা বলার অনুমতি দেয় (Broadcaster Mode)
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
  }

  // সিটে বসা বা সিট ছাড়ার ফাংশন
  Future<void> _toggleSeat() async {
    if (_isJoined) {
      await _engine.leaveChannel();
    } else {
      await _engine.joinChannel(
        token: "", // টোকেন আপাতত খালি
        channelId: "pagla_room_01", 
        uid: 0, 
        options: const ChannelMediaOptions(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        title: const Text("লাইভ আড্ডা রুম", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.music_note, color: Colors.cyanAccent), onPressed: () {})],
      ),
      body: Column(
        children: [
          // ১০ জন বসার বোর্ড ডিজাইন (আগের ডাটা অনুযায়ী)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 15),
              itemCount: 10,
              itemBuilder: (context, index) {
                // সিট একটিভ কি না তার লজিক
                bool isBroadcasting = _isJoined && (index == 0 || index <= _remoteUsers.length);
                return GestureDetector(
                  onTap: _toggleSeat,
                  child: Column(
                    children: [
                      Container(
                        width: 75, height: 75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isBroadcasting ? Colors.greenAccent : (index == 0 ? Colors.amber : Colors.blueAccent), width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 32, 
                          backgroundColor: Colors.white10, 
                          child: Icon(isBroadcasting ? Icons.mic : Icons.person_outline, color: Colors.white)
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
          // কন্ট্রোল বার
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
            child: Text(_isJoined ? "সিট ছাড়ুন" : "সিটে বসুন"),
          ),
          const Icon(Icons.card_giftcard, color: Colors.amber, size: 30),
        ],
      ),
    );
  }
}

// ৪. ডায়মন্ড স্টোর (পুরোনো ডাটা অক্ষত)
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
          _buildItem("১০০ কয়েন", "৳ ১০০", Icons.diamond),
          _buildItem("৫০০ কয়েন", "৳ ৪৫০", Icons.auto_awesome),
        ],
      ),
    );
  }
  Widget _buildItem(String title, String price, IconData icon) => Card(
    color: Colors.white10,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 40),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(color: Colors.white)),
        ElevatedButton(onPressed: () {}, child: Text(price)),
      ],
    ),
  );
}

// ৫. প্রোফাইল পেজ (পুরোনো ডাটা অক্ষত)
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 80),
            Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.pinkAccent, width: 3))),
            const SizedBox(height: 20),
            const Text("পাগলা ইউজার", style: TextStyle(color: Colors.white, fontSize: 22)),
            const Text("ID: 2692001", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
