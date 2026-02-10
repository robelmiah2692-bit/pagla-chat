import 'package:flutter/material.dart';
import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart'; 
import 'package:permission_handler/permission_handler.dart';

// আমরা এখানে একটি ডামি ডাটাবেস লজিক ব্যবহার করছি যা পরে Firebase-এ কানেক্ট হবে
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SplashScreen(),
  ));
}

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

// ৩. ভয়েস রুম + লাইভ চ্যাট
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  late RtcEngine _engine;
  bool _isJoined = false;
  Set<int> _remoteUsers = {}; 
  List<Map<String, String>> messages = []; // চ্যাট মেসেজ লিস্ট
  final TextEditingController _msgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: "348a9f9d55b14667891657dfc53dfbeb")); 
    
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) => setState(() => _isJoined = true),
      onUserJoined: (connection, uid, elapsed) => setState(() => _remoteUsers.add(uid)),
      onUserOffline: (connection, uid, reason) => setState(() => _remoteUsers.remove(uid)),
    ));

    await _engine.enableAudio();
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
  }

  void _sendMessage() {
    if (_msgController.text.isNotEmpty) {
      setState(() {
        messages.insert(0, {"user": "আপনি", "msg": _msgController.text});
        _msgController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text("লাইভ আড্ডা ও চ্যাট")),
      body: Column(
        children: [
          // ১০ জনের সিট বোর্ড
          SizedBox(
            height: 250,
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 10),
              itemCount: 10,
              itemBuilder: (context, index) {
                bool active = _isJoined && (index == 0 || index <= _remoteUsers.length);
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: active ? Colors.greenAccent : Colors.white10,
                      child: Icon(active ? Icons.mic : Icons.person, color: Colors.white, size: 20),
                    ),
                    Text("Seat ${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 8)),
                  ],
                );
              },
            ),
          ),
          
          // লাইভ চ্যাট এরিয়া
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
              child: ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(messages[index]["user"]!, style: const TextStyle(color: Colors.pinkAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: Text(messages[index]["msg"]!, style: const TextStyle(color: Colors.white)),
                  );
                },
              ),
            ),
          ),

          // মেসেজ ইনপুট বক্স
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "কিছু লিখুন...",
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: _sendMessage),
              ],
            ),
          ),
          
          ElevatedButton(
            onPressed: () async {
              if (_isJoined) { await _engine.leaveChannel(); } 
              else { await _engine.joinChannel(token: "", channelId: "room1", uid: 0, options: const ChannelMediaOptions()); }
            }, 
            child: Text(_isJoined ? "সিট ছাড়ুন" : "সিটে বসুন")
          ),
        ],
      ),
    );
  }
}

// ৪. ডায়মন্ড স্টোর (আগের মতো)
class DiamondStore extends StatelessWidget {
  const DiamondStore({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF1A1A2E), body: const Center(child: Text("স্টোর", style: TextStyle(color: Colors.white))));
}

// ৫. প্রোফাইল (কয়েন ও লেভেল সেভ লজিক সহ)
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int coins = 500;
  int level = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Column(
        children: [
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoCard("কয়েন", "$coins", Icons.monetization_on, Colors.amber),
              _infoCard("লেভেল", "$level", Icons.trending_up, Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 40),
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 10),
          const Text("পাগলা ইউজার", style: TextStyle(color: Colors.white, fontSize: 20)),
          const Text("Status: পাগলামিই জীবন!", style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Icon(icon, color: color),
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
