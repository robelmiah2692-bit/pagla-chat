import 'package:flutter/material.dart';
import 'dart:io';
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
  // ৪টি পাতা: হোম, রুম, ইনবক্স, প্রোফাইল
  final List<Widget> _pages = [const HomePage(), const VoiceRoom(), const Center(child: Text("ইনবক্স মেসেজ", style: TextStyle(color: Colors.white))), const ProfilePage()];

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

// --- ১. হোম স্ক্রিন (ফিক্সড ছবি) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        SizedBox.expand(child: Image.network("https://i.ibb.co/5XPJS3x3/94e336499de49a794948d2ddf0aea5a5-1.jpg", fit: BoxFit.cover)),
        Container(color: Colors.black45),
        const Center(child: Text("PAGLA CHAT", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4))),
      ]),
    );
  }
}

// --- ২. রুম স্ক্রিন (এডিট, ফলো +, চ্যাট, গিফট, মিউজিক এড/ডিলিট) ---
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isMicMuted = true, isFollowed = false;
  String roomName = "পাগলা আড্ডা বোর্ড", currentSongName = "গান চলছে না";
  String? roomImage;
  List<String> messages = [];
  List<Map<String, String>> userPlaylist = [];
  final TextEditingController _chatController = TextEditingController();

  // রুম এডিট ফাংশন (ছবি ও নাম)
  void _editRoom() async {
    TextEditingController c = TextEditingController(text: roomName);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text("রুম এডিট", style: TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "রুমের নাম")),
        TextButton(onPressed: () async {
          final x = await ImagePicker().pickImage(source: ImageSource.gallery);
          if (x != null) setState(() => roomImage = x.path);
        }, child: const Text("ছবি পাল্টান"))
      ]),
      actions: [TextButton(onPressed: () { setState(() => roomName = c.text); Navigator.pop(ctx); }, child: const Text("সেভ"))],
    ));
  }

  // গিফট বক্স (আইটেম ও দামসহ)
  void _showGifts() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A2E), builder: (ctx) => GridView.count(
      crossAxisCount: 4, padding: const EdgeInsets.all(15),
      children: [_giftItem("💎", "10"), _giftItem("🌹", "50"), _giftItem("🚗", "500"), _giftItem("👑", "1000")],
    ));
  }
  Widget _giftItem(String icon, String price) => Column(children: [Text(icon, style: const TextStyle(fontSize: 30)), Text("$price 💎", style: const TextStyle(color: Colors.white54, fontSize: 10))]);

  // মিউজিক প্লেয়ার (অ্যাড ও ডিলিট অপশনসহ)
  void _showMusicPlayer() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A2E), builder: (ctx) => StatefulBuilder(builder: (context, setModalState) => Column(
      children: [
        ListTile(title: const Text("প্লেয়ার", style: TextStyle(color: Colors.white)), trailing: IconButton(icon: const Icon(Icons.add_circle, color: Colors.cyanAccent), onPressed: () async {
          FilePickerResult? r = await FilePicker.platform.pickFiles(type: FileType.audio);
          if (r != null) setModalState(() => userPlaylist.add({"name": r.files.single.name, "path": r.files.single.path!}));
        })),
        Expanded(child: ListView.builder(itemCount: userPlaylist.length, itemBuilder: (ctx, i) => ListTile(
          title: Text(userPlaylist[i]["name"]!, style: const TextStyle(color: Colors.white, fontSize: 12)),
          trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setModalState(() => userPlaylist.removeAt(i))),
          onTap: () async { await _audioPlayer.play(DeviceFileSource(userPlaylist[i]["path"]!)); setState(() => currentSongName = userPlaylist[i]["name"]!); },
        ))),
      ],
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: GestureDetector(onTap: _editRoom, child: Padding(padding: const EdgeInsets.all(8.0), child: CircleAvatar(backgroundImage: roomImage != null ? FileImage(File(roomImage!)) : null, child: roomImage == null ? const Icon(Icons.camera_alt) : null))),
        title: Row(children: [
          GestureDetector(onTap: _editRoom, child: Text(roomName, style: const TextStyle(fontSize: 15))),
          const SizedBox(width: 5),
          GestureDetector(onTap: () => setState(() => isFollowed = !isFollowed), child: Icon(isFollowed ? Icons.check_circle : Icons.add_circle, color: Colors.pinkAccent, size: 20)),
        ]),
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(itemCount: messages.length, itemBuilder: (ctx, i) => ListTile(title: Text(messages[i], style: const TextStyle(color: Colors.white70))))),
        _bottomBar(),
      ]),
    );
  }

  Widget _bottomBar() {
    return Container(padding: const EdgeInsets.all(10), color: const Color(0xFF1A1A2E), child: Row(children: [
      IconButton(icon: Icon(isMicMuted ? Icons.mic_off : Icons.mic, color: Colors.red), onPressed: () => setState(() => isMicMuted = !isMicMuted)),
      Expanded(child: TextField(controller: _chatController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "মেসেজ...", border: InputBorder.none))),
      IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: () { if(_chatController.text.isNotEmpty) { setState(() => messages.add("আমি: ${_chatController.text}")); _chatController.clear(); } }),
      IconButton(icon: const Icon(Icons.music_note, color: Colors.cyanAccent), onPressed: _showMusicPlayer),
      IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.amber), onPressed: _showGifts),
    ]));
  }
}

// --- ৩. প্রোফাইল (সেটিংস, ডায়মন্ড শপ +, ফলো কাউন্টার, স্টোরি নিচে) ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int diamonds = 100, followers = 1200, following = 500;
  List<String> stories = [];

  void _diamondShop() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text("ডায়মন্ড কিনুন", style: TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: const Text("১০০ 💎"), trailing: const Text("৳ ১০০", style: TextStyle(color: Colors.cyanAccent))),
        ListTile(title: const Text("৫০০ 💎"), trailing: const Text("৳ ৪৫০", style: TextStyle(color: Colors.cyanAccent))),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Row(children: [const SizedBox(width: 10), Text("$diamonds", style: const TextStyle(color: Colors.white)), GestureDetector(onTap: _diamondShop, child: const Icon(Icons.add_circle, color: Colors.amber, size: 18))]),
        actions: [const Icon(Icons.settings, color: Colors.white70), const SizedBox(width: 15)],
      ),
      body: Column(children: [
        const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
        const SizedBox(height: 10),
        const Text("পাগলা ইউজার", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _count("ফলোয়ার", followers), const SizedBox(width: 40), _count("ফলোইং", following),
        ]),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton(onPressed: () {}, child: const Text("Follow")),
          const SizedBox(width: 10),
          OutlinedButton(onPressed: () {}, child: const Text("Message", style: TextStyle(color: Colors.white))),
        ]),
        const Spacer(),
        const Divider(color: Colors.white24),
        const Text("স্টোরি বোর্ড", style: TextStyle(color: Colors.white70)),
        SizedBox(height: 100, child: ListView(scrollDirection: Axis.horizontal, children: [
          GestureDetector(onTap: () async {
            final x = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (x != null) setState(() => stories.add(x.path));
          }, child: Container(width: 70, margin: const EdgeInsets.all(5), color: Colors.white10, child: const Icon(Icons.add, color: Colors.white))),
          ...stories.map((s) => Container(width: 70, margin: const EdgeInsets.all(5), child: Image.file(File(s), fit: BoxFit.cover))),
        ])),
        const SizedBox(height: 10),
      ]),
    );
  }
  Widget _count(String t, int n) => Column(children: [Text("$n", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(t, style: const TextStyle(color: Colors.white54, fontSize: 12))]);
}
