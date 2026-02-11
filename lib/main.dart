import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- ১. ডাটা ম্যানেজমেন্ট (ফোনে সেভ রাখার জন্য) ---
class PaglaApp {
  static SharedPreferences? prefs;
  static bool isLocked = false;
  static double diamonds = 500.0;
  static String userName = "পাগলা ইউজার";
  static String gender = "পুরুষ";
  static int age = 22;
  static String roomName = "পাগলা আড্ডা ঘর";
  static List<String> chatMessages = [];

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    diamonds = prefs!.getDouble('diamonds') ?? 500.0;
    userName = prefs!.getString('user_name') ?? "পাগলা ইউজার";
  }

  static void saveDiamonds(double val) {
    diamonds = val;
    prefs!.setDouble('diamonds', val);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PaglaApp.init();
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MainNavigation()));
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _idx = 1;
  final _screens = [const HomeFeed(), const VoiceRoom(), const Center(child: Text("মেসেজ")), const ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        backgroundColor: const Color(0xFF101025),
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.style), label: "ফিড"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "চ্যাট"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}

// --- ২. হোম ফিড (লেখা ও ছবিসহ স্টোরি) ---
class HomeFeed extends StatelessWidget {
  const HomeFeed({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A15),
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text("ফিড ও স্টোরি")),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add_comment),
        onPressed: () => _showPostSheet(context),
      ),
      body: const Center(child: Text("এখানে সবার ছবি ও লেখা পোস্ট দেখা যাবে", style: TextStyle(color: Colors.white24))),
    );
  }

  void _showPostSheet(context) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const TextField(decoration: InputDecoration(hintText: "কিছু লিখুন...")),
        ElevatedButton(onPressed: () {}, child: const Text("ছবি যোগ করুন এবং পোস্ট করুন"))
      ]),
    ));
  }
}

// --- ৩. ভয়েস রুম (চ্যাট, ইউটিউব লিংক, মিউজিক, গিফট) ---
class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});
  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  final TextEditingController _chatCtrl = TextEditingController();
  final List<String?> seats = List.filled(20, null);
  bool isMuted = false;

  void _sendChat() {
    if (_chatCtrl.text.isNotEmpty) {
      setState(() => PaglaApp.chatMessages.add(_chatCtrl.text));
      _chatCtrl.clear();
    }
  }

  void _showYoutubeDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("ইউটিউব লিংক দিন"),
      content: const TextField(decoration: InputDecoration(hintText: "https://...")),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("প্লে করুন"))],
    ));
  }

  void _showGiftBox() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A2E), builder: (ctx) => GridView.count(
      crossAxisCount: 4, padding: const EdgeInsets.all(20), children: List.generate(8, (i) => Column(children: [
        const Icon(Icons.card_giftcard, color: Colors.pink, size: 40),
        Text("${(i+1)*10} 💎", style: const TextStyle(color: Colors.white, fontSize: 10))
      ])),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(PaglaApp.roomName), actions: [
        IconButton(icon: Icon(isMuted ? Icons.mic_off : Icons.mic, color: Colors.orange), onPressed: () => setState(() => isMuted = !isMuted)),
        IconButton(icon: const Icon(Icons.video_collection, color: Colors.red), onPressed: _showYoutubeDialog),
      ]),
      body: Column(
        children: [
          // ভিডিও প্লেয়ার এরিয়া
          Container(height: 140, margin: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15)),
            child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.red, size: 50))),
          
          // ২০ সিট
          Expanded(child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
            itemCount: 20, itemBuilder: (ctx, i) => Column(children: [
              CircleAvatar(backgroundColor: Colors.white10, child: Icon(i < 5 ? Icons.stars : Icons.person, size: 18, color: Colors.white24)),
              Text("${i+1}", style: const TextStyle(color: Colors.white30, fontSize: 10))
            ]),
          )),

          // চ্যাট লিস্ট ও ইনপুট
          Container(height: 100, color: Colors.black26, child: ListView(children: PaglaApp.chatMessages.map((m) => Text(" 💬 $m", style: const TextStyle(color: Colors.white70))).toList())),
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(padding: const EdgeInsets.all(10), color: const Color(0xFF151525), child: Row(children: [
      Expanded(child: TextField(controller: _chatCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "এখানে লিখুন...", hintStyle: TextStyle(color: Colors.white24)))),
      IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: _sendChat),
      IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.orange), onPressed: _showGiftBox),
    ]));
  }
}

// --- ৪. প্রোফাইল ও সেটিংস (বয়স, জেন্ডার, নাম পরিবর্তন) ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SingleChildScrollView(child: Column(children: [
        const SizedBox(height: 60),
        const CircleAvatar(radius: 50, backgroundColor: Colors.amber, child: Icon(Icons.person, size: 50)),
        const SizedBox(height: 10),
        Text(PaglaApp.userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _buildSettingTile("নাম পরিবর্তন", Icons.edit, () {}),
        _buildSettingTile("লিঙ্গ: ${PaglaApp.gender}", Icons.face, () {
          setState(() => PaglaApp.gender = PaglaApp.gender == "পুরুষ" ? "মহিলা" : "পুরুষ");
        }),
        _buildSettingTile("বয়স: ${PaglaApp.age}", Icons.cake, () {}),
        const Divider(color: Colors.white10),
        ListTile(title: const Text("মেসেজ ও ফলো বাটন", style: TextStyle(color: Colors.white70)), trailing: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.mail, color: Colors.blue), SizedBox(width: 10), Icon(Icons.person_add, color: Colors.green)]))
      ])),
    );
  }

  Widget _buildSettingTile(String t, IconData i, VoidCallback tap) => ListTile(leading: Icon(i, color: Colors.white54), title: Text(t, style: const TextStyle(color: Colors.white)), onTap: tap);
}
