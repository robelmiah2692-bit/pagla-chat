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
  final List<Widget> _pages = [const HomePage(), const VoiceRoom(), const Center(child: Text("ইনবক্স")), const ProfilePage()];

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

// --- ১. হোম সেকশন ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(child: Container(margin: const EdgeInsets.all(20), height: 150, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.blue, Colors.purple]), borderRadius: BorderRadius.circular(20)), child: const Center(child: Text("পাগলা চ্যাট এ স্বাগতম", style: TextStyle(color: Colors.white, fontSize: 20))))),
    );
  }
}

// --- ২. রুম সেকশন (সরাসরি বসা + রুম এডিট) ---
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  late RtcEngine _engine;
  int userDiamonds = 100;
  String roomName = "পাগলা আড্ডা বোর্ড";
  String? roomImage, myName, myImage;
  int? _mySeatIndex;
  List<Map<String, String?>> seats = List.generate(10, (index) => {"name": null, "img": null});

  @override
  void initState() { super.initState(); _initAgora(); _loadData(); }

  _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userDiamonds = prefs.getInt('diamonds') ?? 100;
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

  // সরাসরি সিটে বসার লজিক
  void _toggleSeat(int index) async {
    if (_mySeatIndex == index) {
      setState(() { seats[index] = {"name": null, "img": null}; _mySeatIndex = null; });
    } else if (seats[index]["name"] == null) {
      setState(() {
        if (_mySeatIndex != null) seats[_mySeatIndex!] = {"name": null, "img": null};
        _mySeatIndex = index;
        seats[index] = {"name": myName, "img": myImage};
      });
    }
  }

  void _editRoom() {
    TextEditingController c = TextEditingController(text: roomName);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("রুম এডিট"),
      content: TextField(controller: c, decoration: const InputDecoration(hintText: "রুমের নাম")),
      actions: [
        TextButton(onPressed: () async {
          final x = await ImagePicker().pickImage(source: ImageSource.gallery);
          if (x != null) { 
            final p = await SharedPreferences.getInstance(); 
            p.setString('roomImage', x.path); 
            setState(() => roomImage = x.path);
          }
        }, child: const Text("ছবি পাল্টান")),
        TextButton(onPressed: () async {
          final p = await SharedPreferences.getInstance();
          p.setString('roomName', c.text);
          setState(() => roomName = c.text);
          Navigator.pop(ctx);
        }, child: const Text("সেভ")),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: GestureDetector(onTap: _editRoom, child: Padding(padding: const EdgeInsets.all(8.0), child: CircleAvatar(backgroundImage: roomImage != null ? FileImage(File(roomImage!)) : null, backgroundColor: Colors.white12, child: roomImage == null ? const Icon(Icons.camera_alt, size: 18) : null))),
        title: Text(roomName, style: const TextStyle(fontSize: 16, color: Colors.white)),
        actions: [const Icon(Icons.add_box, color: Colors.cyanAccent), const SizedBox(width: 15), Text("$userDiamonds 💎", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)), const SizedBox(width: 15)],
      ),
      body: Column(children: [
        Expanded(child: GridView.builder(
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
        )),
        _bottomInputBar(),
      ]),
    );
  }

  Widget _bottomInputBar() {
    return Container(padding: const EdgeInsets.all(10), child: Row(children: [
      const Icon(Icons.mic, color: Colors.white54), const SizedBox(width: 10),
      Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(25)), child: const TextField(style: TextStyle(color: Colors.white), decoration: InputDecoration(border: InputBorder.none, hintText: "কিছু লিখুন...", hintStyle: TextStyle(color: Colors.white24))))),
      IconButton(onPressed: _openGiftPanel, icon: const Icon(Icons.card_giftcard, color: Colors.amber)),
    ]));
  }

  void _openGiftPanel() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A2E), builder: (ctx) => GridView.count(crossAxisCount: 4, children: List.generate(10, (i) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("🌹", style: TextStyle(fontSize: 25)), Text("${(i+1)*10} 💎", style: const TextStyle(color: Colors.cyanAccent, fontSize: 10))])))));
  }
}

// --- ৪. প্রোফাইল সেকশন (সব সক্রিয় ফিচার) ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "পাগলা ইউজার"; String? imgPath; int diamonds = 100, followers = 0;

  @override
  void initState() { super.initState(); _loadData(); }
  _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? "পাগলা ইউজার";
      diamonds = prefs.getInt('diamonds') ?? 100;
      imgPath = prefs.getString('image');
      followers = prefs.getInt('followers') ?? 0;
    });
  }

  _editProfile() async {
    TextEditingController c = TextEditingController(text
