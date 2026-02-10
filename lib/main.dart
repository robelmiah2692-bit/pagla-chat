import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';

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

// ২. ভয়েস রুম (মিউজিক + এডিট + সিট)
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  late RtcEngine _engine;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isBoardFollowed = false;
  bool _showMusicBar = false;
  bool _isPlaying = false;
  String groupName = "পাগলা আড্ডা বোর্ড";
  String currentSong = "কোনো গান নেই";
  File? _boardImage;
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
  }

  void _editBoardName() {
    TextEditingController _c = TextEditingController(text: groupName);
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text("বোর্ডের নাম পরিবর্তন", style: TextStyle(color: Colors.white)),
      content: TextField(controller: _c, style: const TextStyle(color: Colors.white)),
      actions: [TextButton(onPressed: () { setState(() => groupName = _c.text); Navigator.pop(context); }, child: const Text("ঠিক আছে"))],
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
              leading: GestureDetector(
                onTap: () async {
                  final img = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (img != null) setState(() => _boardImage = File(img.path));
                },
                child: CircleAvatar(backgroundImage: _boardImage != null ? FileImage(_boardImage!) : null, child: _boardImage == null ? const Icon(Icons.camera_alt) : null),
              ),
              title: Row(children: [
                GestureDetector(onTap: _editBoardName, child: Text(groupName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                const SizedBox(width: 5),
                IconButton(icon: Icon(_isBoardFollowed ? Icons.check_box : Icons.add_box, color: Colors.cyanAccent), onPressed: () => setState(() => _isBoardFollowed = !_isBoardFollowed)),
              ]),
              trailing: IconButton(icon: const Icon(Icons.library_music, color: Colors.white), onPressed: () async {
                FilePickerResult? r = await FilePicker.platform.pickFiles(type: FileType.audio);
                if (r != null) {
                  setState(() { currentSong = r.files.single.name; _showMusicBar = true; _isPlaying = true; });
                  await _audioPlayer.play(DeviceFileSource(r.files.single.path!));
                  await _engine.startAudioMixing(filePath: r.files.single.path!, loopback: false, cycle: -1);
                }
              }),
            ),
            Expanded(
              flex: 2,
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                itemCount: 10,
                itemBuilder: (context, index) => Column(children: [
                  CircleAvatar(radius: 20, backgroundColor: (_isJoined && index == 0) ? Colors.pinkAccent : Colors.white10, child: const Icon(Icons.person, color: Colors.white, size: 15)),
                  Text("Seat ${index+1}", style: const TextStyle(color: Colors.white54, fontSize: 8)),
                ]),
              ),
            ),
            if (_showMusicBar)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(15)),
                child: Row(children: [
                  const Icon(Icons.music_note, color: Colors.pinkAccent, size: 20),
                  Expanded(child: Text(currentSong, style: const TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis)),
                  IconButton(icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white), onPressed: () async {
                    _isPlaying ? await _audioPlayer.pause() : await _audioPlayer.resume();
                    setState(() => _isPlaying = !_isPlaying);
                  }),
                ]),
              ),
            Expanded(flex: 3, child: ListView.builder(reverse: true, itemCount: messages.length, itemBuilder: (context, index) => ListTile(dense: true, title: Text("${messages[index]["user"]}: ${messages[index]["msg"]}", style: const TextStyle(color: Colors.white70))))),
            Container(
              padding: const EdgeInsets.all(10), color: Colors.black45,
              child: Row(children: [
                IconButton(icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: Colors.white), onPressed: () => setState(() { _isMuted = !_isMuted; _engine.muteLocalAudioStream(_isMuted); })),
                Expanded(child: TextField(controller: _msgController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "কিছু লিখুন...", filled: true, fillColor: Colors.white10, suffixIcon: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.pinkAccent), onPressed: () {
                  if (_msgController.text.isNotEmpty) { setState(() => messages.insert(0, {"user": "আপনি", "msg": _msgController.text})); _msgController.clear(); }
                }), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _isJoined ? Colors.red : Colors.green, shape: const StadiumBorder()),
                  onPressed: () async {
                    if (_isJoined) await _engine.leaveChannel();
                    else await _engine.joinChannel(token: "", channelId: "pagla_room_1", uid: 0, options: const ChannelMediaOptions());
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

// ৩. প্রোফাইল পেজ (কয়েন, সেটিংস, নাম পরিবর্তন ও স্টোরি পোস্ট)
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
  List<File> stories = [];

  void _editName() {
    TextEditingController _uc = TextEditingController(text: userName);
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text("নাম পরিবর্তন", style: TextStyle(color: Colors.white)),
      content: TextField(controller: _uc, style: const TextStyle(color: Colors.white)),
      actions: [TextButton(onPressed: () { setState(() => userName = _uc.text); Navigator.pop(context); }, child: const Text("ঠিক আছে"))],
    ));
  }

  Future<void> _postStory() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => stories.insert(0, File(img.path)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            // কয়েন ও সেটিংস বার
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                  child: const Row(children: [Icon(Icons.monetization_on, color: Colors.amber, size: 18), Text(" ১০০", style: TextStyle(color: Colors.white))]),
                ),
                IconButton(icon: const Icon(Icons.settings, color: Colors.white70), onPressed: () {}),
              ]),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                final img = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (img != null) setState(() => _userImage = File(img.path));
              },
              child: CircleAvatar(radius: 50, backgroundImage: _userImage != null ? FileImage(_userImage!) : null, child: _userImage == null ? const Icon(Icons.camera_enhance) : null),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.edit, color: Colors.pinkAccent, size: 18), onPressed: _editName),
            ]),
            Text("ID: $userId", style: const TextStyle(color: Colors.white38)),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _isFollowed ? Colors.white12 : Colors.pinkAccent),
              onPressed: () => setState(() => _isFollowed = !_isFollowed),
              child: Text(_isFollowed ? "Unfollow" : "Follow"),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            // স্টোরি পোস্ট সেকশন
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("আপনার স্টোরি পোস্ট", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add_a_photo, color: Colors.cyanAccent), onPressed: _postStory),
              ]),
            ),
            SizedBox(
              height: 150,
              child: stories.isEmpty 
                ? const Center(child: Text("এখনো কোনো পোস্ট নেই", style: TextStyle(color: Colors.white24)))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: stories.length,
                    itemBuilder: (c, i) => Container(
                      width: 100,
                      margin: const EdgeInsets.only(left: 15),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), image: DecorationImage(image: FileImage(stories[i]), fit: BoxFit.cover)),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiamondStore extends StatelessWidget {
  const DiamondStore({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(backgroundColor: Color(0xFF0F0F1E), body: Center(child: Text("ডায়মন্ড স্টোর", style: TextStyle(color: Colors.white))));
}
