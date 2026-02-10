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
    const Center(child: Text("ইনবক্স (শীঘ্রই আসছে)", style: TextStyle(color: Colors.white54))), 
    const ProfilePage(),
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text("পাগলা চ্যাট হোম")),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(children: [
          Container(
            height: 150, width: double.infinity,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.purple, Colors.pink]), borderRadius: BorderRadius.circular(15)),
            child: const Center(child: Text("Pro Plus Member", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
          ),
        ]),
      ),
    );
  }
}

class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  late RtcEngine _engine;
  bool _isJoined = false;
  int? _mySeatIndex;
  int userDiamonds = 1000;
  String? myName;
  String? myImagePath;
  List<Map<String, String?>> seats = List.generate(10, (index) => {"name": null, "image": null});

  @override
  void initState() { super.initState(); _initAgora(); _loadUserData(); }

  _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      myName = prefs.getString('name') ?? "ইউজার";
      myImagePath = prefs.getString('image');
      userDiamonds = prefs.getInt('diamonds') ?? 1000;
    });
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: "348a9f9d55b14667891657dfc53dfbeb"));
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (c, e) => setState(() => _isJoined = true),
      onLeaveChannel: (c, s) => setState(() => _isJoined = false),
    ));
    await _engine.enableAudio();
  }

  void _handleSeat(int index) async {
    if (_mySeatIndex == index) {
      await _engine.leaveChannel();
      setState(() { seats[index] = {"name": null, "image": null}; _mySeatIndex = null; });
    } else if (seats[index]["name"] == null) {
      if (_isJoined) await _engine.leaveChannel();
      await _engine.joinChannel(token: "", channelId: "room1", uid: 0, options: const ChannelMediaOptions());
      setState(() {
        _mySeatIndex = index;
        seats[index] = {"name": myName, "image": myImagePath};
      });
    }
  }

  void _openGiftPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 350,
          child: Column(children: [
            const Text("গিফট পাঠান", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _giftItem("🌹", "রোজ", 200),
              _giftItem("👑", "ক্রাউন", 500),
              _giftItem("🚗", "কার", 1000),
            ]),
            const Spacer(),
            Text("ব্যালেন্স: $userDiamonds 💎", style: const TextStyle(color: Colors.amber, fontSize: 16)),
            const SizedBox(height: 10),
          ]),
        );
      },
    );
  }

  Widget _giftItem(String icon, String name, int price) {
    return GestureDetector(
      onTap: () async {
        if (userDiamonds >= price) {
          setState(() { userDiamonds -= price; });
          final prefs = await SharedPreferences.getInstance();
          prefs.setInt('diamonds', userDiamonds);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name পাঠানো হয়েছে! -$price 💎"), backgroundColor: Colors.pinkAccent));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ডায়মন্ড নেই!")));
        }
      },
      child: Column(children: [
        Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)), child: Text(icon, style: const TextStyle(fontSize: 30))),
        Text(name, style: const TextStyle(color: Colors.white70)),
        Text("$price 💎", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text("আড্ডা বোর্ড", style: TextStyle(color: Colors.white, fontSize: 18)),
        actions: [Text("$userDiamonds 💎  ", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))],
      ),
      body: Column(children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.8),
            itemCount: 10,
            itemBuilder: (context, index) {
              var user = seats[index];
              return GestureDetector(
                onTap: () => _handleSeat(index),
                child: Column(children: [
                  CircleAvatar(radius: 25, backgroundColor: Colors.white10, backgroundImage: user["image"] != null ? FileImage(File(user["image"]!)) : null, child: user["name"] == null ? const Icon(Icons.person, color: Colors.white24) : null),
                  Text(user["name"] ?? "Seat ${index + 1}", style: const TextStyle(color: Colors.white38, fontSize: 10), overflow: TextOverflow.ellipsis),
                ]),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Icon(Icons.mic, color: Colors.white54, size: 28),
            const SizedBox(width: 15),
            Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(30)), child: const TextField(style: TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "কিছু লিখুন...", border: InputBorder.none, hintStyle: TextStyle(color: Colors.white24))))),
            const SizedBox(width: 15),
            GestureDetector(onTap: _openGiftPanel, child: const Icon(Icons.card_giftcard, color: Colors.amber, size: 30)), 
            const SizedBox(width: 15),
            const Icon(Icons.send, color: Colors.pinkAccent, size: 28),
          ]),
        )
      ]),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "পাগলা ইউজার";
  File? img;
  int diamonds = 1000;

  @override
  void initState() { super.initState(); _loadData(); }

  _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? "পাগলা ইউজার";
      diamonds = prefs.getInt('diamonds') ?? 1000;
      String? path = prefs.getString('image');
      if (path != null) img = File(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircleAvatar(radius: 60, backgroundColor: Colors.white12, backgroundImage: img != null ? FileImage(img!) : null, child: img == null ? const Icon(Icons.person, size: 50, color: Colors.white24) : null),
          const SizedBox(height: 15),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text("ID: 359210", style: const TextStyle(color: Colors.white24)),
          const SizedBox(height: 10),
          Text("ব্যালেন্স: $diamonds 💎", style: const TextStyle(color: Colors.amber, fontSize: 18)),
        ]),
      ),
    );
  }
}
