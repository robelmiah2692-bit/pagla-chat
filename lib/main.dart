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
  int _currentIndex = 0; 
  final List<Widget> _pages = [
    const VoiceRoom(), 
    const Center(child: Text("স্টোর (শীঘ্রই আসছে)", style: TextStyle(color: Colors.white54))), 
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F0F1E),
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white54,
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

// --- রুম সেকশন (স্ক্রিনশট অনুযায়ী ডিজাইন) ---
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  late RtcEngine _engine;
  bool _isJoined = false;
  int? _mySeatIndex;
  int userDiamonds = 100;
  List<Map<String, String?>> seats = List.generate(10, (index) => {"name": null});

  @override
  void initState() { super.initState(); _initAgora(); _loadData(); }

  _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userDiamonds = prefs.getInt('diamonds') ?? 100);
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: "348a9f9d55b14667891657dfc53dfbeb"));
    _engine.enableAudio();
  }

  void _openGiftPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(15),
          height: 400,
          child: Column(children: [
            const Text("গিফট পাঠান", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                children: [
                  _giftItem("🌹", "Rose", 10), _giftItem("🍫", "Choco", 20),
                  _giftItem("🍦", "Ice", 50), _giftItem("💍", "Ring", 100),
                  _giftItem("👑", "Crown", 500), _giftItem("🚗", "Car", 1000),
                  _giftItem("✈️", "Plane", 2000), _giftItem("🏰", "Castle", 5000),
                  _giftItem("💎", "Gem", 100), _giftItem("🔥", "Fire", 30),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _giftItem(String icon, String name, int price) {
    return GestureDetector(
      onTap: () async {
        if (userDiamonds >= price) {
          setState(() => userDiamonds -= price);
          final prefs = await SharedPreferences.getInstance();
          prefs.setInt('diamonds', userDiamonds);
          Navigator.pop(context);
        }
      },
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 25)),
        Text(name, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        Text("$price 💎", style: const TextStyle(color: Colors.cyanAccent, fontSize: 10)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: const CircleAvatar(backgroundColor: Colors.white12, child: Icon(Icons.camera_alt, color: Colors.white)),
        title: const Text("পাগলা আড্ডা বোর্ড", style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [const Icon(Icons.add_box, color: Colors.cyanAccent), const SizedBox(width: 10), const Icon(Icons.music_video, color: Colors.white), const SizedBox(width: 10)],
      ),
      body: Column(children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.8),
            itemCount: 10,
            itemBuilder: (context, index) => Column(children: [
              const CircleAvatar(radius: 20, backgroundColor: Colors.white12, child: Icon(Icons.person, color: Colors.white24, size: 20)),
              Text("Seat ${index + 1}", style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            const Icon(Icons.mic_none, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(25)), child: const TextField(decoration: InputDecoration(border: InputBorder.none, hintText: "কিছু লিখুন...", hintStyle: TextStyle(color: Colors.white24))))),
            IconButton(onPressed: _openGiftPanel, icon: const Icon(Icons.card_giftcard, color: Colors.amber)),
            ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: StadiumBorder()), child: const Text("বসুন")),
          ]),
        )
      ]),
    );
  }
}

// --- প্রোফাইল সেকশন (স্ক্রিনশট অনুযায়ী ফলো ও স্টোরি পোস্ট সহ) ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "পাগলা ইউজার";
  int diamonds = 100;
  String id = "910506";

  @override
  void initState() { super.initState(); _loadData(); }
  _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? "পাগলা ইউজার";
      diamonds = prefs.getInt('diamonds') ?? 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: Container(margin: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)), child: Row(children: [const Icon(Icons.monetization_on, color: Colors.amber, size: 15), Text(" $diamonds", style: const TextStyle(fontSize: 12))])),
        actions: const [Icon(Icons.settings, color: Colors.white), SizedBox(width: 15)],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 20),
          const CircleAvatar(radius: 50, backgroundColor: Color(0xFFE5D5FF), child: Icon(Icons.camera_alt, color: Colors.black45)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const Icon(Icons.edit, color: Colors.pinkAccent, size: 18)]),
          Text("ID: $id", style: const TextStyle(color: Colors.white38)),
          const SizedBox(height: 15),
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, minimumSize: const Size(120, 40), shape: StadiumBorder()), child: const Text("Follow")),
          const Divider(color: Colors.white10, height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("আপনার স্টোরি পোস্ট", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const Icon(Icons.add_a_photo, color: Colors.cyanAccent)]),
          ),
          const SizedBox(height: 50),
          const Text("এখনো কোনো পোস্ট নেই", style: TextStyle(color: Colors.white24)),
        ]),
      ),
    );
  }
}
