import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MainNavigation()));

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; 
  final List<Widget> _pages = [
    const HomePage(), 
    const VoiceRoom(), 
    const Center(child: Text("ইনবক্স", style: TextStyle(color: Colors.white))), 
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

// --- ১. হোম পেজ (এখানেই আপনার লোগো আসবে) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // আপনার লোগো এখানে (বর্তমানে একটি আইকন দেওয়া আছে)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.pinkAccent.withOpacity(0.1),
              ),
              child: const Icon(Icons.bolt_rounded, size: 100, color: Colors.pinkAccent),
            ),
            const SizedBox(height: 25),
            const Text(
              "PAGLA CHAT",
              style: TextStyle(
                color: Colors.white, 
                fontSize: 28, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 4
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "আড্ডা হবে প্রাণখুলে",
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Colors.pinkAccent), // লোডিং এনিমেশন
          ],
        ),
      ),
    );
  }
}

// --- ২. ভয়েস রুম (সব ফিক্সড করা) ---
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  late RtcEngine _engine;
  bool isMicMuted = true;
  String roomName = "পাগলা আড্ডা বোর্ড";
  String? roomImage, myName, myImage;
  int? _mySeatIndex;
  final TextEditingController _chatController = TextEditingController();
  List<String> messages = [];
  List<Map<String, String?>> seats = List.generate(10, (index) => {"name": null, "img": null});

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
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: "348a9f9d55b14667891657dfc53dfbeb"));
    await _engine.enableAudio();
  }

  void _editRoomImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x != null) {
      final p = await SharedPreferences.getInstance();
      p.setString('roomImage', x.path);
      setState(() => roomImage = x.path);
    }
  }

  void _sendMessage() {
    if (_chatController.text.isNotEmpty) {
      setState(() {
        messages.add("${myName ?? 'ইউজার'}: ${_chatController.text}");
        _chatController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: GestureDetector(
          onTap: _editRoomImage, 
          child: Padding(
            padding: const EdgeInsets.all(8.0), 
            child: CircleAvatar(
              backgroundColor: Colors.white10,
              backgroundImage: roomImage != null ? FileImage(File(roomImage!)) : null, 
              child: roomImage == null ? const Icon(Icons.camera_alt, size: 18, color: Colors.white54) : null
            )
          )
        ),
        title: Text(roomName, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: Column(children: [
        Expanded(
          flex: 2,
          child: GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.8),
            itemCount: 10,
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => setState(() {
                if (_mySeatIndex == i) { seats[i] = {"name": null, "img": null}; _mySeatIndex = null; }
                else if (seats[i]["name"] == null) {
                  if (_mySeatIndex != null) seats[_mySeatIndex!] = {"name": null, "img": null};
                  _mySeatIndex = i; seats[i] = {"name": myName, "img": myImage};
                }
              }),
              child: Column(children: [
                CircleAvatar(radius: 22, backgroundColor: Colors.white12, backgroundImage: seats[i]["img"] != null ? FileImage(File(seats[i]["img"]!)) : null, child: seats[i]["img"] == null ? const Icon(Icons.person, color: Colors.white24) : null),
                Text(seats[i]["name"] ?? "Seat ${i+1}", style: const TextStyle(color: Colors.white38, fontSize: 9), overflow: TextOverflow.ellipsis),
              ]),
            ),
          ),
        ),
        Expanded(
          flex: 3, 
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
            child: ListView.builder(itemCount: messages.length, itemBuilder: (ctx, i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), child: Text(messages[i], style: const TextStyle(color: Colors.white70)))),
          )
        ),
        _bottomBar(),
      ]),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: const Color(0xFF1A1A2E),
      child: Row(children: [
        IconButton(icon: Icon(isMicMuted ? Icons.mic_off : Icons.mic, color: isMicMuted ? Colors.red : Colors.green), onPressed: () => setState(() => isMicMuted = !isMicMuted)),
        Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(25)), child: TextField(controller: _chatController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(border: InputBorder.none, hintText: "বলুন কিছু...", hintStyle: TextStyle(color: Colors.white24))))),
        IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: _sendMessage),
        IconButton(icon: const Icon(Icons.music_note, color: Colors.cyanAccent), onPressed: () {
          showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A2E), builder: (ctx) => const Center(child: Text("মিউজিক প্লেয়ার", style: TextStyle(color: Colors.white))));
        }),
        IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.amber), onPressed: () {}),
      ]),
    );
  }
}

// --- ৩. প্রোফাইল ও স্টোরি পোস্ট ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "পাগলা ইউজার"; String? imgPath;
  List<Map<String, String>> myStories = [];

  @override
  void initState() { super.initState(); _loadData(); }
  _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { name = prefs.getString('name') ?? "পাগলা ইউজার"; imgPath = prefs.getString('image'); });
  }

  _postStory() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x != null) {
      TextEditingController tc = TextEditingController();
      showDialog(context: context, builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("স্টোরি পোস্ট", style: TextStyle(color: Colors.white)),
        content: TextField(controller: tc, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "কিছু লিখুন...", hintStyle: TextStyle(color: Colors.white24))),
        actions: [TextButton(onPressed: () {
          setState(() { myStories.insert(0, {"img": x.path, "text": tc.text}); });
          Navigator.pop(ctx);
        }, child: const Text("পোস্ট", style: TextStyle(color: Colors.pinkAccent)))],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, actions: [const Icon(Icons.settings, color: Colors.white70), const SizedBox(width: 15)]),
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 20),
          CircleAvatar(radius: 60, backgroundColor: Colors.white12, backgroundImage: imgPath != null ? FileImage(File(imgPath!)) : null, child: imgPath == null ? const Icon(Icons.person, size: 50, color: Colors.white24) : null),
          const SizedBox(height: 15),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white10, height: 40),
          ListTile(
            title: const Text("আপনার স্টোরি পোস্ট", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
            trailing: IconButton(icon: const Icon(Icons.add_a_photo, color: Colors.cyanAccent), onPressed: _postStory)
          ),
          ListView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: myStories.length,
            itemBuilder: (ctx, i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(15)), child: Image.file(File(myStories[i]["img"]!), height: 200, width: double.infinity, fit: BoxFit.cover)),
                Padding(padding: const EdgeInsets.all(12), child: Text(myStories[i]["text"]!, style: const TextStyle(color: Colors.white))),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
