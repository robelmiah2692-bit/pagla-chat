import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { 
    await Firebase.initializeApp(); 
  } catch (e) { 
    debugPrint("Firebase Initialization Error: ${e.toString()}"); 
  }
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false, 
    home: SplashScreen()
  ));
}

// ১. ৩ সেকেন্ড লোগো স্প্ল্যাশ স্ক্রিন
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const MainNavigation())
        );
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.asset(
                'assets/logo.jpg', 
                width: 150, 
                height: 150, 
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.rocket_launch, color: Colors.pink, size: 100)
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "PAGLA CHAT", 
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 3)
            ),
          ],
        ),
      ),
    );
  }
}

// ২. মেইন নেভিগেশন (হোম, রুম, ইনবক্স, প্রোফাইল)
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // ভাই, এখানে ইনডেক্স ০ করে দিয়েছি, তাই এখন অ্যাপ খুললে আগে হোম পেজ আসবে।
  int _currentIndex = 0; 
  final List<Widget> _pages = [const HomePage(), const VoiceRoom(), const InboxPage(), const ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF151525),
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white30,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "হোম"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "ইনবক্স"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}

// --- ৩. রুম সেকশন ---
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  final _db = FirebaseDatabase.instance.ref().child("live_room");
  String currentTheme = "dark";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: currentTheme == "dark" ? const Color(0xFF0F0F1E) : Colors.deepPurple[900],
      body: SafeArea(
        child: StreamBuilder(
          stream: _db.onValue,
          builder: (context, snapshot) {
            var data = (snapshot.hasData && snapshot.data!.snapshot.value != null) ? (snapshot.data!.snapshot.value as Map) : {};
            String rName = data['name'] ?? "পাগলা আড্ডা ঘর";
            int followers = (data['followers'] is int) ? data['followers'] : 0;
            String ytUrl = data['yt_url'] ?? "https://youtube.com";

            return Column(
              children: [
                _buildHeader(rName, followers),
                _buildVideoBoard(ytUrl),
                _buildFeatureRow(),
                Expanded(child: _buildSeatGrid(data['seats'] ?? {})),
                _buildBottomBar(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String name, int followers) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          const CircleAvatar(backgroundImage: AssetImage('assets/logo.jpg'), radius: 22),
          const SizedBox(width: 5),
          IconButton(icon: const Icon(Icons.add_circle, color: Colors.pinkAccent), onPressed: () => _db.update({'followers': followers + 1})),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text("Followers: $followers", style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ])),
          IconButton(icon: const Icon(Icons.lock_outline, color: Colors.white54), onPressed: () {}),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'lock', child: Text("রুম লক")),
              const PopupMenuItem(value: 'theme', child: Text("থিম পরিবর্তন")),
              const PopupMenuItem(value: 'name', child: Text("নাম পরিবর্তন")),
            ],
            onSelected: (val) {
              if (val == 'name') _showEditDialog("রুমের নাম বদলান", "name");
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoBoard(String url) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      height: 160, width: double.infinity,
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.pinkAccent.withOpacity(0.2))),
      child: Stack(
        children: [
          const Center(child: Icon(Icons.play_circle_fill, color: Colors.white10, size: 60)),
          Positioned(bottom: 10, right: 10, child: ElevatedButton.icon(
            onPressed: () => _showEditDialog("YouTube Video ID দিন", "yt_url"),
            icon: const Icon(Icons.search, size: 16), label: const Text("Search"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          )),
        ],
      ),
    );
  }

  Widget _buildFeatureRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _fIcon(Icons.bolt, "PK", Colors.orange),
          _fIcon(Icons.videogame_asset, "Ludo", Colors.blue),
          _fIcon(Icons.music_note, "Music", Colors.green, action: () => _showMusicPlayer()),
          _fIcon(Icons.emoji_events, "Ranking", Colors.yellow),
        ],
      ),
    );
  }

  Widget _fIcon(IconData i, String l, Color c, {VoidCallback? action}) => 
    GestureDetector(onTap: action, child: Column(children: [CircleAvatar(backgroundColor: c.withOpacity(0.1), child: Icon(i, color: c, size: 22)), Text(l, style: const TextStyle(color: Colors.white54, fontSize: 10))]));

  Widget _buildSeatGrid(Map seats) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 20, childAspectRatio: 0.75),
      itemCount: 15,
      itemBuilder: (ctx, i) {
        bool occ = seats.containsKey("$i");
        return Column(children: [
          GestureDetector(
            onTap: () => _db.child("seats").child("$i").set(occ ? null : {"name": "User"}),
            child: CircleAvatar(radius: 25, backgroundColor: occ ? Colors.pink : Colors.white10, child: Icon(occ ? Icons.person : Icons.add, color: Colors.white, size: 20)),
          ),
          Text("${i + 1}", style: const TextStyle(color: Colors.white24, fontSize: 10))
        ]);
      },
    );
  }

  void _showEditDialog(String title, String key) {
    TextEditingController ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(title), content: TextField(controller: ctrl),
      actions: [TextButton(onPressed: () { _db.update({key: ctrl.text}); Navigator.pop(ctx); }, child: const Text("Save"))],
    ));
  }

  void _showMusicPlayer() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF151525), builder: (ctx) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("MUSIC PLAYER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const Divider(color: Colors.white10),
        ListTile(leading: const Icon(Icons.library_music, color: Colors.green), title: const Text("গান অ্যাড করুন", style: TextStyle(color: Colors.white)), onTap: () {}),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.skip_previous, color: Colors.white), Icon(Icons.play_circle, color: Colors.pink, size: 60), Icon(Icons.skip_next, color: Colors.white)]),
      ]),
    ));
  }

  Widget _buildBottomBar() => Container(padding: const EdgeInsets.all(15), child: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(Icons.mic_none, color: Colors.white30), Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 40), Icon(Icons.message, color: Colors.white30)]));
}

// --- ৪. অন্যান্য পেজ ---
class HomePage extends StatelessWidget { const HomePage({super.key}); @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF0F0F1E), appBar: AppBar(title: const Text("PAGLA HOME"), backgroundColor: Colors.transparent), body: Column(children: [Padding(padding: const EdgeInsets.all(10), child: Row(children: [Column(children: [const CircleAvatar(radius: 30, backgroundColor: Colors.white10, child: Icon(Icons.add, color: Colors.white)), const Text("Story", style: TextStyle(color: Colors.white54, fontSize: 10))])]))])); }
class InboxPage extends StatelessWidget { const InboxPage({super.key}); @override Widget build(BuildContext context) => const Scaffold(backgroundColor: Color(0xFF0F0F1E), body: Center(child: Text("আপনার ইনবক্স খালি", style: TextStyle(color: Colors.white24)))); }
class ProfilePage extends StatelessWidget { const ProfilePage({super.key}); @override Widget build(BuildContext context) => const Scaffold(backgroundColor: Color(0xFF0F0F1E), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircleAvatar(radius: 60, backgroundImage: AssetImage('assets/logo.jpg')), Text("পাগলা কিং 👑", style: TextStyle(color: Colors.white, fontSize: 24))]))); }
