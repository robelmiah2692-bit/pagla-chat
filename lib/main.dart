import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math'; // অটো আইডি তৈরির জন্য
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

// ৩. ভয়েস রুম (গিফটিং ও ব্যাকগ্রাউন্ড সহ)
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  late RtcEngine _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  Set<int> _remoteUsers = {}; 
  List<Map<String, String>> messages = [];
  String currentGift = ""; // গিফট এনিমেশন এর জন্য
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
      onJoinChannelSuccess: (c, e) => setState(() => _isJoined = true),
      onUserJoined: (c, uid, e) => setState(() => _remoteUsers.add(uid)),
      onUserOffline: (c, uid, r) => setState(() => _remoteUsers.remove(uid)),
    ));
    await _engine.enableAudio();
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
  }

  void _showGift(String emoji) {
    setState(() => currentGift = emoji);
    Timer(const Duration(seconds: 2), () => setState(() => currentGift = ""));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E), Color(0xFF16213E)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildAppBar(),
            _buildSeatGrid(),
            
            // গিফট এনিমেশন লেয়ার
            if (currentGift.isNotEmpty)
              TweenAnimationBuilder(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                builder: (context, double val, child) => Opacity(
                  opacity: val,
                  child: Transform.scale(scale: val * 2, child: Text(currentGift, style: const TextStyle(fontSize: 50))),
                ),
              ),

            _buildChatArea(),
            _buildControlBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return ListTile(
      leading: const CircleAvatar(backgroundColor: Colors.pinkAccent, child: Icon(Icons.group, color: Colors.white)),
      title: const Text("পাগলা আড্ডা গ্রুপ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text("${_remoteUsers.length + (_isJoined ? 1 : 0)} জন অনলাইনে", style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, shape: const CircleBorder()),
        onPressed: () {}, child: const Icon(Icons.add, size: 20),
      ),
    );
  }

  Widget _buildSeatGrid() {
    return SizedBox(
      height: 200,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
        itemCount: 10,
        itemBuilder: (context, index) {
          bool occupied = (index == 0 && _isJoined) || (index > 0 && index <= _remoteUsers.length);
          return Column(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: occupied ? Colors.greenAccent : Colors.white10,
                child: Icon(occupied ? Icons.mic : Icons.person_add, color: Colors.white, size: 20),
              ),
              Text("Seat ${index + 1}", style: TextStyle(color: occupied ? Colors.greenAccent : Colors.white54, fontSize: 9)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatArea() {
    return Expanded(
      child: ListView.builder(
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: RichText(text: TextSpan(children: [
            TextSpan(text: "${messages[index]["user"]}: ", style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
            TextSpan(text: messages[index]["msg"]!, style: const TextStyle(color: Colors.white)),
          ])),
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.black38,
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: _isMuted ? Colors.red : Colors.white),
            onPressed: () => setState(() { _isMuted = !_isMuted; _engine.muteLocalAudioStream(_isMuted); }),
          ),
          Expanded(
            child: TextField(
              controller: _msgController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(hintText: "বলুন...", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
              onSubmitted: (v) {
                if (v.isNotEmpty) {
                  setState(() => messages.insert(0, {"user": "আপনি", "msg": v}));
                  _msgController.clear();
                }
              },
            ),
          ),
          IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.amber), onPressed: () => _showGiftDialog()),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _isJoined ? Colors.red : Colors.green),
            onPressed: () async {
              if (_isJoined) { await _engine.leaveChannel(); }
              else { await _engine.joinChannel(token: "", channelId: "room1", uid: 0, options: const ChannelMediaOptions()); }
            },
            child: Text(_isJoined ? "নামুন" : "বসুন"),
          ),
        ],
      ),
    );
  }

  void _showGiftDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (context) => GridView.count(
        crossAxisCount: 4, padding: const EdgeInsets.all(20),
        children: ["🌹", "💎", "❤️", "🔥", "👑", "🍕", "🎈", "🎁"].map((e) => GestureDetector(
          onTap: () { Navigator.pop(context); _showGift(e); },
          child: Center(child: Text(e, style: const TextStyle(fontSize: 30))),
        )).toList(),
      ),
    );
  }
}

// ৫. প্রোফাইল পেজ (অটো আইডি সহ)
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "পাগলা ইউজার";
  late String userId;

  @override
  void initState() {
    super.initState();
    userId = (Random().nextInt(9000000) + 1000000).toString(); // ৭ ডিজিটের ইউনিক আইডি
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Column(
        children: [
          const SizedBox(height: 70),
          const Center(child: CircleAvatar(radius: 50, backgroundColor: Colors.white10, child: Icon(Icons.person, size: 50, color: Colors.white))),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text("ID: $userId", style: const TextStyle(color: Colors.grey)), // ইউনিক আইডি
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Stat(count: "0", label: "ফলোয়ার"),
              SizedBox(width: 40),
              _Stat(count: "0", label: "ফলোইং"),
            ],
          ),
          const Divider(color: Colors.white10, height: 50),
          ListTile(leading: const Icon(Icons.edit, color: Colors.white54), title: const Text("প্রোফাইল এডিট", style: TextStyle(color: Colors.white)), onTap: () {}),
          ListTile(leading: const Icon(Icons.settings, color: Colors.white54), title: const Text("সেটিংস", style: TextStyle(color: Colors.white)), onTap: () {}),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String count, label;
  const _Stat({required this.count, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [Text(count, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))]);
}

class DiamondStore extends StatelessWidget {
  const DiamondStore({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(backgroundColor: Color(0xFF0F0F1E), body: Center(child: Text("ডায়মন্ড স্টোর", style: TextStyle(color: Colors.white))));
}
