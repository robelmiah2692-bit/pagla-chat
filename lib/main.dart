import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen()));

// ১. লোগো স্ক্রিন (Splash Screen)
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.jpg', width: 150, errorBuilder: (c, e, s) => const Icon(Icons.stars, size: 100, color: Colors.amber)),
            const SizedBox(height: 20),
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

// ২. ভয়েস রুম ও বোর্ড এডিট
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  late RtcEngine _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isBoardFollowed = false;
  String groupName = "পাগলা আড্ডা বোর্ড";
  File? _boardImage;
  List<Map<String, String>> messages = [];
  final TextEditingController _msgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.storage, Permission.camera].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: "348a9f9d55b14667891657dfc53dfbeb"));
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (c, e) => setState(() => _isJoined = true),
      onLeaveChannel: (c, s) => setState(() => _isJoined = false),
    ));
    await _engine.enableAudio();
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
  }

  Future<void> _pickBoardImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _boardImage = File(pickedFile.path));
  }

  void _editBoard() {
    TextEditingController _c = TextEditingController(text: groupName);
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text("বোর্ড সেটিংস", style: TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(onTap: _pickBoardImage, child: CircleAvatar(radius: 40, backgroundImage: _boardImage != null ? FileImage(_boardImage!) : null, child: _boardImage == null ? const Icon(Icons.camera_alt) : null)),
        TextField(controller: _c, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "বোর্ডের নাম", labelStyle: TextStyle(color: Colors.pinkAccent))),
      ]),
      actions: [TextButton(onPressed: () { setState(() => groupName = _c.text); Navigator.pop(context); }, child: const Text("সেভ"))],
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
            ListTile(
              onTap: _editBoard,
              leading: CircleAvatar(backgroundImage: _boardImage != null ? FileImage(_boardImage!) : null, child: _boardImage == null ? const Icon(Icons.group) : null),
              title: Row(children: [
                Text(groupName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_isBoardFollowed ? Icons.check_box : Icons.add_box, color: Colors.cyanAccent),
                  onPressed: () => setState(() => _isBoardFollowed = !_isBoardFollowed),
                )
              ]),
            ),
            // সিট বোর্ড
            Expanded(
              flex: 2,
              child: GridView.builder(
                padding: const EdgeInsets.all(15),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                itemCount: 10,
                itemBuilder: (context, index) => Column(
                  children: [
                    CircleAvatar(radius: 24, backgroundColor: (_isJoined && index == 0) ? Colors.pinkAccent : Colors.white10, child: const Icon(Icons.person, color: Colors.white)),
                    Text("Seat ${index+1}", style: const TextStyle(color: Colors.white54, fontSize: 8)),
                  ],
                ),
              ),
            ),
            // মেসেজ বক্স
            Expanded(
              flex: 3,
              child: ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) => ListTile(dense: true, title: Text("${messages[index]["user"]}: ${messages[index]["msg"]}", style: const TextStyle(color: Colors.white70))),
              ),
            ),
            // কন্ট্রোল বার
            Container(
              padding: const EdgeInsets.all(10), color: Colors.black45,
              child: Row(children: [
                IconButton(icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: Colors.white), onPressed: () => setState(() { _isMuted = !_isMuted; _engine.muteLocalAudioStream(_isMuted); })),
                Expanded(child: TextField(controller: _msgController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "কিছু লিখুন...", filled: true, fillColor: Colors.white10, suffixIcon: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.pinkAccent), onPressed: () {
                  if (_msgController.text.isNotEmpty) { setState(() => messages.insert(0, {"user": "আপনি", "msg": _msgController.text})); _msgController.clear(); }
                }), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _isJoined ? Colors.red : Colors.green, shape: const StadiumBorder()),
                  onPressed: () async {
                    if (_isJoined) { await _engine.leaveChannel(); }
                    else { await _engine.joinChannel(token: "", channelId: "pagla_room_1", uid: 0, options: const ChannelMediaOptions()); }
                  },
                  child: Text(_isJoined ? "নামুন" : "বসুন"),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ৩. প্রোফাইল পেজ (ফলো ও এডিট অপশন)
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = "পাগলা ইউজার";
  String userId = (Random().nextInt(899999) + 100000).toString();
  File? _userImage;
  bool _isFollowed = false;

  Future<void> _pickUserImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _userImage = File(pickedFile.path));
  }

  void _editProfile() {
    TextEditingController _uc = TextEditingController(text: userName);
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text("প্রোফাইল এডিট"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(onTap: _pickUserImage, child: CircleAvatar(radius: 40, backgroundImage: _userImage != null ? FileImage(_userImage!) : null, child: _userImage == null ? const Icon(Icons.person_add) : null)),
        TextField(controller: _uc, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "আপনার নাম")),
      ]),
      actions: [TextButton(onPressed: () { setState(() => userName = _uc.text); Navigator.pop(context); }, child: const Text("সেভ"))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Column(
        children: [
          const SizedBox(height: 50),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [const Icon(Icons.monetization_on, color: Colors.amber), Text(" ১০০", style: const TextStyle(color: Colors.white))]),
            const Icon(Icons.settings, color: Colors.white54),
          ])),
          const SizedBox(height: 30),
          GestureDetector(onTap: _editProfile, child: CircleAvatar(radius: 55, backgroundImage: _userImage != null ? FileImage(_userImage!) : null, child: _userImage == null ? const Icon(Icons.person, size: 50) : null)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(userName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.pinkAccent), onPressed: _editProfile),
          ]),
          Text("ID: $userId", style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _isFollowed ? Colors.white12 : Colors.pinkAccent),
            onPressed: () => setState(() => _isFollowed = !_isFollowed),
            child: Text(_isFollowed ? "Unfollow" : "Follow"),
          ),
          const SizedBox(height: 25),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildStat(_isFollowed ? "১" : "০", "ফলোয়ার"),
            const SizedBox(width: 50),
            _buildStat("০", "ফলোইং"),
          ]),
          const Divider(color: Colors.white10, height: 40),
          const ListTile(leading: Icon(Icons.military_tech, color: Colors.amber), title: Text("লেভেল: ০", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildStat(String count, String label) {
    return Column(children: [Text(count, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))]);
  }
}

class DiamondStore extends StatelessWidget {
  const DiamondStore({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(backgroundColor: Color(0xFF0F0F1E), body: Center(child: Text("স্টোর", style: TextStyle(color: Colors.white))));
}
