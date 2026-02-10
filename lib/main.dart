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
  int _currentIndex = 0; // অ্যাপ ওপেন হয়ে হোমে থাকবে
  final List<Widget> _pages = [
    const HomePage(), 
    const VoiceRoom(), 
    const Center(child: Text("ইনবক্স", style: TextStyle(color: Colors.white54))), 
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

// --- ১. হোম (লোগো) ---
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
            const Icon(Icons.bolt_rounded, size: 100, color: Colors.pinkAccent),
            const SizedBox(height: 20),
            const Text("PAGLA CHAT", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}

// --- ২. রুম (ফিক্সড ফিচার) ---
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
  List<String> messages = []; // চ্যাট মেসেজ লিস্ট
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

  void _pickRoomImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x != null) {
      final p = await SharedPreferences.getInstance();
      p.setString('roomImage', x.path);
      setState(() => roomImage = x.path);
    }
  }

  void _toggleSeat(int index) {
    setState(() {
      if (_mySeatIndex == index) {
        seats[index] = {"name": null, "img": null};
        _mySeatIndex = null;
      } else if (seats[index]["name"] == null) {
        if (_mySeatIndex != null) seats[_mySeatIndex!] = {"name": null, "img": null};
        _mySeatIndex = index;
        seats[index] = {"name": myName, "img": myImage};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: GestureDetector(
          onTap: _pickRoomImage,
          child: Padding(padding: const EdgeInsets.all(8.0), child: CircleAvatar(backgroundImage: roomImage != null ? FileImage(File(roomImage!)) : null, backgroundColor: Colors.white12, child: roomImage == null ? const Icon(Icons.camera_alt, size: 18, color: Colors.white) : null)),
        ),
        title: Text(roomName, style: const TextStyle(fontSize: 16, color: Colors.white)),
        actions: const [Icon(Icons.add_box, color: Colors.cyanAccent), SizedBox(width: 15), Icon(Icons.more_vert, color: Colors.white), SizedBox(width: 15)],
      ),
      body: Column(children: [
        Expanded(
          flex: 2,
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.7),
            itemCount: 10,
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => _toggleSeat(i),
              child: Column(children: [
                CircleAvatar(radius: 22, backgroundColor: Colors.white10, backgroundImage: seats[i]["img"] != null ? FileImage(File(seats[i]["img"]!)) : null, child: seats[i]["img"] == null ? const Icon(Icons.person, color: Colors.white24) : null),
                Text(seats[i]["name"] ?? "Seat ${i+1}", style: const TextStyle(color: Colors.white38, fontSize: 9), overflow: TextOverflow.ellipsis),
              ]),
            ),
          ),
        ),
        Expanded(flex: 3, child: ListView.builder(itemCount: messages.length, itemBuilder: (ctx, i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2), child: Text(messages[i], style: const TextStyle(color: Colors.white70))))),
        _bottomActionBar(),
      ]),
    );
  }

  Widget _bottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(color: Color(0xFF1A1A2E), borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
      child: Row(children: [
        IconButton(icon: Icon(isMicMuted ? Icons.mic_off : Icons.mic, color: isMicMuted ? Colors.redAccent : Colors.greenAccent), onPressed: () => setState(() => isMicMuted = !isMicMuted)),
        Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)), child: TextField(controller: _chatController, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: const InputDecoration(border: InputBorder.none, hintText: "বলুন কিছু...", hintStyle: TextStyle(color: Colors.white24))))),
        IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: () {
          if(_chatController.text.isNotEmpty) {
            setState(() { messages.add("$myName: ${_chatController.text}"); _chatController.clear(); });
          }
        }),
        IconButton(icon: const Icon(Icons.music_note, color: Colors.cyanAccent), onPressed: () {
          showModalBottomSheet(context: context, builder: (ctx) => const SizedBox(height: 100, child: Center(child: Text("মিউজিক প্লেয়ার"))));
        }),
        IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.amber), onPressed: _openGiftPanel),
      ]),
    );
  }

  void _openGiftPanel() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A2E), builder: (ctx) => GridView.count(crossAxisCount: 4, children: List.generate(10, (i) => Column(children: [const Text("🌹", style: TextStyle(fontSize: 25)), Text("${(i+1)*10} 💎", style: const TextStyle(color: Colors.cyanAccent, fontSize: 10))]))));
  }
}

// --- ৩. প্রোফাইল (ফিক্সড নাম-ছবি সেভ ও স্টোরি) ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "পাগলা ইউজার"; String? imgPath; int diamonds = 100, followers = 0, following = 0;
  List<Map<String, String>> myStories = [];

  @override
  void initState() { super.initState(); _loadData(); }
  _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? "পাগলা ইউজার";
      diamonds = prefs.getInt('diamonds') ?? 100;
      imgPath = prefs.getString('image');
      followers = prefs.getInt('followers') ?? 0;
      following = prefs.getInt('following') ?? 0;
    });
  }

  _editProfile() async {
    TextEditingController c = TextEditingController(text: name);
    String? tempImg = imgPath;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("প্রোফাইল এডিট"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c, decoration: const InputDecoration(labelText: "নাম")),
        TextButton(onPressed: () async {
          final x = await ImagePicker().pickImage(source: ImageSource.gallery);
          if (x != null) { tempImg = x.path; }
        }, child: const Text("ছবি পাল্টান")),
      ]),
      actions: [
        TextButton(onPressed: () async {
          final p = await SharedPreferences.getInstance();
          await p.setString('name', c.text);
          if(tempImg != null) await p.setString('image', tempImg!);
          setState(() { name = c.text; imgPath = tempImg; });
          Navigator.pop(ctx);
        }, child: const Text("সব সেভ করুন")),
      ],
    ));
  }

  _postStory() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x != null) {
      TextEditingController tc = TextEditingController();
      showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text("স্টোরি পোস্ট"),
        content: TextField(controller: tc, decoration: const InputDecoration(hintText: "কিছু লিখুন...")),
        actions: [TextButton(onPressed: () {
          setState(() { myStories.insert(0, {"img": x.path, "text": tc.text}); });
          Navigator.pop(ctx);
        }, child: const Text("পোস্ট"))],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(10), padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(15)),
          child: Row(children: [
            Text("$diamonds", style: const TextStyle(color: Colors.white, fontSize: 12)),
            const Icon(Icons.add_circle, color: Colors.amber, size: 16),
          ]),
        ),
        leadingWidth: 80,
        actions: const [Icon(Icons.settings, color: Colors.white70), SizedBox(width: 15)],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 20),
          GestureDetector(onTap: _editProfile, child: CircleAvatar(radius: 60, backgroundImage: imgPath != null ? FileImage(File(imgPath!)) : null, child: imgPath == null ? const Icon(Icons.person, size: 50) : null)),
          const SizedBox(height: 15),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _countStat("Followers", followers),
            const SizedBox(width: 30),
            _countStat("Following", following),
          ]),
          const Divider(color: Colors.white10, height: 40),
          ListTile(title: const Text("স্টোরি পোস্ট", style: TextStyle(color: Colors.white)), trailing: IconButton(icon: const Icon(Icons.add_a_photo, color: Colors.cyanAccent), onPressed: _postStory)),
          
          myStories.isEmpty ? const Text("পোস্ট নেই", style: TextStyle(color: Colors.white24)) :
          ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: myStories.length, itemBuilder: (ctx, i) => Column(children: [
            Image.file(File(myStories[i]["img"]!), height: 200, width: double.infinity, fit: BoxFit.cover),
            Padding(padding: const EdgeInsets.all(8.0), child: Text(myStories[i]["text"]!, style: const TextStyle(color: Colors.white))),
          ]))
        ]),
      ),
    );
  }

  Widget _countStat(String label, int count) => Column(children: [
    Text("$count", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
  ]);
}
