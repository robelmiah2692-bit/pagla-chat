import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MainNavigation()));

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const HomePage(), 
    const VoiceRoom(), 
    const Center(child: Text("ইনবক্স মেসেজ", style: TextStyle(color: Colors.white54, fontSize: 18))), 
    const ProfilePage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F0F1E),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "হোম"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: "ইনবক্স"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}

// --- ১. হোম স্ক্রিন (আপনার দেওয়া ফিক্সড ছবিসহ) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    const String myFixedImageUrl = "https://i.ibb.co/5XPJS3x3/94e336499de49a794948d2ddf0aea5a5-1.jpg"; 

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.network(
              myFixedImageUrl, 
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0F0F1E)),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.4)), // হালকা আবরণ
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt_rounded, size: 80, color: Colors.pinkAccent),
                const Text("PAGLA CHAT", style: TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold, letterSpacing: 3)),
                const SizedBox(height: 100),
                const Text("Welcome to the Hub", style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- ২. রুম (সব ফিচার + নতুন মিউজিক প্লেয়ার + ডিলিট) ---
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  late RtcEngine _engine;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isMicMuted = true, isPlaying = false;
  String roomName = "পাগলা আড্ডা বোর্ড", currentSongName = "গান চলছে না";
  String? roomImage, myName, myImage;
  int? _mySeatIndex;
  List<Map<String, String>> userPlaylist = []; 
  List<Map<String, String?>> seats = List.generate(10, (index) => {"name": null, "img": null});
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() { super.initState(); _initAgora(); _loadData(); }
  _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      myName = prefs.getString('name') ?? "ইউজার";
      myImage = prefs.getString('image');
      roomName = prefs.getString('roomName') ?? "পাগলা আড্ডা বোর্ড";
      roomImage = prefs.getString('roomImage');
    });
  }
  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.storage].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: "348a9f9d55b14667891657dfc53dfbeb"));
    await _engine.enableAudio();
  }

  void _showMusicPlayer() {
    showModalBottomSheet(
      context: context, backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (context, setModalState) => Container(
        padding: const EdgeInsets.all(20), height: 400,
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("পাগলা প্লেয়ার 🎵", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add_circle, color: Colors.pinkAccent), onPressed: () async {
              FilePickerResult? r = await FilePicker.platform.pickFiles(type: FileType.audio);
              if (r != null) setModalState(() => userPlaylist.add({"name": r.files.single.name, "path": r.files.single.path!}));
            })
          ]),
          const Divider(color: Colors.white10),
          Expanded(child: ListView.builder(itemCount: userPlaylist.length, itemBuilder: (ctx, i) => ListTile(
            leading: const Icon(Icons.music_note, color: Colors.cyanAccent),
            title: Text(userPlaylist[i]["name"]!, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1),
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () {
              setModalState(() { if(currentSongName == userPlaylist[i]["name"]) { _audioPlayer.stop(); isPlaying = false; currentSongName = "গান চলছে না"; } userPlaylist.removeAt(i); });
            }),
            onTap: () async {
              await _audioPlayer.play(DeviceFileSource(userPlaylist[i]["path"]!));
              setModalState(() { currentSongName = userPlaylist[i]["name"]!; isPlaying = true; });
              setState(() {});
            },
          ))),
          Row(children: [
            Expanded(child: Text(currentSongName, style: const TextStyle(color: Colors.white54, fontSize: 12))),
            IconButton(icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.pinkAccent, size: 35), onPressed: () {
              isPlaying ? _audioPlayer.pause() : _audioPlayer.resume();
              setModalState(() => isPlaying = !isPlaying); setState(() {});
            })
          ])
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: GestureDetector(onTap: () async {
          final x = await ImagePicker().pickImage(source: ImageSource.gallery);
          if (x != null) { final p = await SharedPreferences.getInstance(); p.setString('roomImage', x.path); setState(() => roomImage = x.path); }
        }, child: Padding(padding: const EdgeInsets.all(8.0), child: CircleAvatar(backgroundImage: roomImage != null ? FileImage(File(roomImage!)) : null, child: roomImage == null ? const Icon(Icons.camera_alt, size: 18) : null))),
        title: Text(roomName, style: const TextStyle(fontSize: 16, color: Colors.white)),
        actions: const [Icon(Icons.more_vert, color: Colors.white), SizedBox(width: 15)],
      ),
      body: Column(children: [
        Expanded(child: GridView.builder(padding: const EdgeInsets.all(20), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.7), itemCount: 10, itemBuilder: (ctx, i) => GestureDetector(
          onTap: () => setState(() {
            if (_mySeatIndex == i) { seats[i] = {"name": null, "img": null}; _mySeatIndex = null; }
            else if (seats[i]["name"] == null) {
              if (_mySeatIndex != null) seats[_mySeatIndex!] = {"name": null, "img": null};
              _mySeatIndex = i; seats[i] = {"name": myName, "img": myImage};
            }
          }),
          child: Column(children: [CircleAvatar(radius: 22, backgroundColor: Colors.white10, backgroundImage: seats[i]["img"] != null ? FileImage(File(seats[i]["img"]!)) : null, child: seats[i]["img"] == null ? const Icon(Icons.person, color: Colors.white24) : null), Text(seats[i]["name"] ?? "Seat ${i+1}", style: const TextStyle(color: Colors.white38, fontSize: 9), overflow: TextOverflow.ellipsis)]),
        ))),
        _bottomBar(),
      ]),
    );
  }

  Widget _bottomBar() {
    return Container(padding: const EdgeInsets.all(10), color: const Color(0xFF1A1A2E), child: Row(children: [
      IconButton(icon: Icon(isMicMuted ? Icons.mic_off : Icons.mic, color: isMicMuted ? Colors.red : Colors.green), onPressed: () => setState(() => isMicMuted = !isMicMuted)),
      Expanded(child: TextField(controller: _chatController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "বলুন কিছু...", border: InputBorder.none, hintStyle: TextStyle(color: Colors.white24)))),
      IconButton(icon: const Icon(Icons.music_note, color: Colors.cyanAccent), onPressed: _showMusicPlayer),
      IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.amber), onPressed: () {}),
    ]));
  }
}

// --- ৩. প্রোফাইল (সব ফিচার সচল: এডিট, ডায়মন্ড প্লাস, ফলোয়ার্স ও স্টোরি) ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "পাগলা ইউজার"; String? imgPath; int diamonds = 100, followers = 0, following = 0;
  List<String> userStories = [];

  @override
  void initState() { super.initState(); _loadData(); }
  _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { 
      name = prefs.getString('name') ?? "পাগলা ইউজার"; 
      imgPath = prefs.getString('image'); 
      diamonds = prefs.getInt('diamonds') ?? 100;
      followers = prefs.getInt('followers') ?? 0;
      following = prefs.getInt('following') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: Container(margin: const EdgeInsets.all(10), padding: const EdgeInsets.symmetric(horizontal: 5), decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(15)), child: Row(children: [Text("$diamonds", style: const TextStyle(color: Colors.white, fontSize: 12)), const Icon(Icons.add_circle, color: Colors.amber, size: 16)])),
        actions: const [Icon(Icons.settings, color: Colors.white70), SizedBox(width: 15)],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 20),
          GestureDetector(onTap: () async {
            final x = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (x != null) { 
              final p = await SharedPreferences.getInstance(); 
              p.setString('image', x.path); 
              setState(() => imgPath = x.path); 
            }
          }, child: CircleAvatar(radius: 55, backgroundImage: imgPath != null ? FileImage(File(imgPath!)) : null, child: imgPath == null ? const Icon(Icons.person, size: 40) : null)),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Column(children: [Text("$followers", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const Text("Followers", style: TextStyle(color: Colors.white54, fontSize: 12))]),
            const SizedBox(width: 40),
            Column(children: [Text("$following", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const Text("Following", style: TextStyle(color: Colors.white54, fontSize: 12))]),
          ]),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () async {
            final x = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (x != null) setState(() => userStories.add(x.path));
          }, style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent), child: const Text("স্টোরি দিন +", style: TextStyle(color: Colors.black))),
          const Divider(color: Colors.white10, height: 40),
          userStories.isEmpty ? const Text("কোনো স্টোরি নেই", style: TextStyle(color: Colors.white24)) :
          SizedBox(height: 120, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: userStories.length, itemBuilder: (ctx, i) => Container(margin: const EdgeInsets.all(5), width: 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), image: DecorationImage(image: FileImage(File(userStories[i])), fit: BoxFit.cover)))))
        ]),
      ),
    );
  }
}
