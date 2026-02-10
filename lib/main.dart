import 'package:flutter/material.dart';
import 'dart:async';
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

// ৩. ভয়েস রুম (নতুন ফিচার সহ)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.black26,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(backgroundImage: AssetImage('assets/logo.jpg')),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("পাগলা আড্ডা গ্রুপ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("${_remoteUsers.length + (_isJoined ? 1 : 0)} জন অনলাইনে", style: const TextStyle(fontSize: 10, color: Colors.greenAccent)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.pinkAccent), onPressed: () {}),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // ১০ জনের সিট বোর্ড (এনিমেশন সহ)
          Container(
            height: 220,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
              itemCount: 10,
              itemBuilder: (context, index) {
                bool isMeOnSeat = (index == 0 && _isJoined);
                bool isOtherOnSeat = (index > 0 && index <= _remoteUsers.length && _isJoined);
                bool occupied = isMeOnSeat || isOtherOnSeat;

                return Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (occupied) // সিটে কেউ থাকলে জ্বলজ্বল করবে
                          TweenAnimationBuilder(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(seconds: 1),
                            builder: (context, double val, child) => Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.greenAccent.withOpacity(1 - val), width: 4 * val),
                              ),
                            ),
                            onEnd: () => setState(() {}),
                          ),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: occupied ? Colors.blue : Colors.white10,
                          child: Icon(occupied ? Icons.mic : Icons.person, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                    Text("Seat ${index + 1}", style: TextStyle(color: occupied ? Colors.greenAccent : Colors.white54, fontSize: 9)),
                  ],
                );
              },
            ),
          ),
          
          // লাইভ চ্যাট এরিয়া
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) => ListTile(
                dense: true,
                title: Text(messages[index]["user"]!, style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
                subtitle: Text(messages[index]["msg"]!, style: const TextStyle(color: Colors.white70)),
              ),
            ),
          ),

          // কন্ট্রোল বার
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.black45,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: _isMuted ? Colors.red : Colors.white),
                  onPressed: () {
                    setState(() {
                      _isMuted = !_isMuted;
                      _engine.muteLocalAudioStream(_isMuted);
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "কিছু লিখুন...",
                      filled: true, fillColor: Colors.white10,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onSubmitted: (v) {
                      if (v.isNotEmpty) {
                        setState(() => messages.insert(0, {"user": "User", "msg": v}));
                        _msgController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
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
          ),
        ],
      ),
    );
  }
}

// ৫. প্রোফাইল পেজ (এডিট অপশন সহ)
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "পাগলা ইউজার";
  int level = 0;
  int coins = 100;

  void _showEditDialog() {
    TextEditingController _c = TextEditingController(text: name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("নাম পরিবর্তন করুন"),
        content: TextField(controller: _c),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("বাতিল")),
          TextButton(onPressed: () {
            setState(() => name = _c.text);
            Navigator.pop(context);
          }, child: const Text("সেভ")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Column(
        children: [
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [const Icon(Icons.monetization_on, color: Colors.amber), Text(" $coins", style: const TextStyle(color: Colors.white))]),
                Row(children: [const Text("Level: ", style: TextStyle(color: Colors.grey)), Text("$level", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))]),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.edit, color: Colors.white54, size: 18), onPressed: _showEditDialog),
            ],
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(children: [Text("০", style: TextStyle(color: Colors.white)), Text("ফলোয়ার", style: TextStyle(color: Colors.grey, fontSize: 10))]),
              SizedBox(width: 30),
              Column(children: [Text("০", style: TextStyle(color: Colors.white)), Text("ফলোইং", style: TextStyle(color: Colors.grey, fontSize: 10))]),
            ],
          ),
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
