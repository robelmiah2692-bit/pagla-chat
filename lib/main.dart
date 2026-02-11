import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MainNavigation()));

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = [const HomePage(), const VoiceRoom(), const Center(child: Text("ইনবক্স", style: TextStyle(color: Colors.white))), const ProfilePage()];

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

// --- ১. হোম স্ক্রিন (ফিক্সড ব্যাকগ্রাউন্ড) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        SizedBox.expand(child: Image.network("https://i.ibb.co/5XPJS3x3/94e336499de49a794948d2ddf0aea5a5-1.jpg", fit: BoxFit.cover)),
        Container(color: Colors.black54),
        const Center(child: Text("PAGLA CHAT", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 5))),
      ]),
    );
  }
}

// --- ২. রাজকীয় ভয়েস রুম (ইউটিউব, ২০ সিট, অ্যাডভান্সড সেটিংস) ---
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  bool isMicMuted = true;
  String selectedLang = "বাংলা";
  String selectedGender = "উভয়";

  // রুম সেটিংস প্যানেল (ভাষা, জেন্ডার, ব্লক লিস্ট)
  void _showRoomSettings() {
    showModalBottomSheet(
      context: context, backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(builder: (context, setModalState) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("রুম ফিল্টার ও সেটিংস", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _settingTile("ভাষা", ["বাংলা", "English", "অন্যান্য"], selectedLang, (val) => setState(() => selectedLang = val!)),
          _settingTile("জেন্ডার", ["উভয়", "মহিলা ♀", "পুরুষ ♂"], selectedGender, (val) => setState(() => selectedGender = val!)),
          ListTile(leading: const Icon(Icons.block, color: Colors.redAccent), title: const Text("ব্লক লিস্ট", style: TextStyle(color: Colors.white70)), onTap: () {}),
          const SizedBox(height: 20),
        ]),
      )),
    );
  }

  Widget _settingTile(String title, List<String> opts, String current, Function(String?) onType) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(color: Colors.white70)),
      DropdownButton<String>(
        dropdownColor: const Color(0xFF1A1A2E), value: current,
        items: opts.map((String value) => DropdownMenuItem(value: value, child: Text(value, style: const TextStyle(color: Colors.pinkAccent)))).toList(),
        onChanged: onType,
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("পাগলা আড্ডা জোন", style: TextStyle(fontSize: 14)),
          Text("ID: 5896321 (নিজস্ব রুম)", style: TextStyle(fontSize: 10, color: Colors.white38)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: _showRoomSettings)],
      ),
      body: Column(children: [
        // ইউটিউব প্লেয়ার প্লেসহোল্ডার
        Container(
          margin: const EdgeInsets.all(15), height: 160,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.redAccent.withOpacity(0.5))),
          child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.play_circle_fill, color: Colors.red, size: 50), Text("YouTube Video Playing...", style: TextStyle(color: Colors.white54))])),
        ),
        // ২০টি নিওন সিট
        Expanded(child: GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.8),
          itemCount: 20,
          itemBuilder: (ctx, i) => Column(children: [
            Container(width: 45, height: 45, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)), color: Colors.white10), child: const Icon(Icons.mic_none, size: 20, color: Colors.white24)),
            Text("${i+1}", style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ]),
        )),
        _bottomMenu(),
      ]),
    );
  }

  Widget _bottomMenu() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), color: const Color(0xFF1A1A2E), child: Row(children: [
      IconButton(icon: const Icon(Icons.sentiment_satisfied, color: Colors.amber), onPressed: () {}),
      Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)), child: const TextField(decoration: InputDecoration(hintText: "মেসেজ...", border: InputBorder.none, hintStyle: TextStyle(color: Colors.white24))))),
      const Icon(Icons.grid_view_rounded, color: Colors.cyanAccent), // গেম ও ইউটিউব মেনু
      const SizedBox(width: 15),
      const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 30),
    ]));
  }
}

// --- ৩. প্রোফাইল (ব্যাজ, ফ্রেম, শুধু ডায়মন্ড) ---
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(backgroundColor: Colors.transparent, actions: [const Icon(Icons.settings), const SizedBox(width: 15)]),
      body: Column(children: [
        const SizedBox(height: 20),
        Center(child: Stack(alignment: Alignment.center, children: [
          Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.amber, width: 3))), // ভিআইপি ফ্রেম
          const CircleAvatar(radius: 45, child: Icon(Icons.person, size: 40)),
          Positioned(bottom: 0, child: Container(padding: const EdgeInsets.all(2), color: Colors.amber, child: const Text("LV.38", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)))),
        ])),
        const SizedBox(height: 10),
        const Text("পাগলা কিং", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        // শুধু ডায়মন্ড কার্ড
        Container(
          margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.pinkAccent.withOpacity(0.3))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.diamond, color: Colors.cyanAccent),
            const SizedBox(width: 10),
            const Text("2,500 Diamonds", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.add_circle, color: Colors.pinkAccent),
          ]),
        ),
        const Text("অনার ব্যাজ", style: TextStyle(color: Colors.white38, fontSize: 12)),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("🏅 👑 🛡️ 💎", style: TextStyle(fontSize: 22))]),
        const Spacer(),
        const Divider(color: Colors.white10),
        const Text("মাই স্টোরি", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 80),
      ]),
    );
  }
}
