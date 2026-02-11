import 'package:flutter/material.dart';

// --- গ্লোবাল ডাটা ও সেটিংস ---
class PaglaAppConfig {
  static bool isLocked = false;
  static bool isMusicPlaying = false;
  static double diamonds = 500.0;
  static List<String?> seatUsers = List.filled(20, null);
}

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false, 
  home: MainNavigation()
));

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1;
  final _screens = [
    const HomeFeedScreen(),
    const PaglaVoiceRoom(),
    const Center(child: Text("মেসেজ বক্স", style: TextStyle(color: Colors.white))),
    const PaglaProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF101025),
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_mosaic), label: "ফিড"),
          BottomNavigationBarItem(icon: Icon(Icons.mic_none_rounded), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.mail_outline), label: "চ্যাট"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}

// --- ১. হোম ফিড (সাদা স্ক্রিন সমস্যা নাই এখন) ---
class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A15),
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text("পাগলা চ্যাট ফিড")),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add_a_photo),
        onPressed: () {},
      ),
      body: const Center(child: Text("এখানে সবার স্টোরি ও পোস্ট দেখা যাবে", style: TextStyle(color: Colors.white24))),
    );
  }
}

// --- ২. ২০ সিটের ভয়েস রুম (ফুল ফিচার) ---
class PaglaVoiceRoom extends StatefulWidget {
  const PaglaVoiceRoom({super.key});
  @override
  State<PaglaVoiceRoom> createState() => _PaglaVoiceRoomState();
}

class _PaglaVoiceRoomState extends State<PaglaVoiceRoom> {
  
  void _toggleRoomLock() {
    setState(() => PaglaAppConfig.isLocked = !PaglaAppConfig.isLocked);
    Navigator.pop(context);
  }

  void _showRoomMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(PaglaAppConfig.isLocked ? Icons.lock_open : Icons.lock, color: Colors.white),
            title: Text(PaglaAppConfig.isLocked ? "রুম আনলক" : "রুম লক", style: const TextStyle(color: Colors.white)),
            onTap: _toggleRoomLock,
          ),
          const ListTile(leading: Icon(Icons.color_lens, color: Colors.white), title: Text("রুম ব্যাকগ্রাউন্ড থিম", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(children: [
          const Text("পাগলা আড্ডা ঘর", style: TextStyle(fontSize: 16)),
          const SizedBox(width: 5),
          if(PaglaAppConfig.isLocked) const Icon(Icons.lock, color: Colors.red, size: 16),
        ]),
        actions: [IconButton(icon: const Icon(Icons.more_vert), onPressed: _showRoomMenu)],
      ),
      body: Column(
        children: [
          // ইউটিউব এরিয়া
          Container(
            height: 160, width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
            child: const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library, color: Colors.red, size: 40),
                Text("এখানে ভিডিও প্লে হবে", style: TextStyle(color: Colors.white24, fontSize: 12)),
              ],
            )),
          ),
          // ২০ সিট গ্রিড
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 12, crossAxisSpacing: 12),
              itemCount: 20,
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => setState(() => PaglaAppConfig.seatUsers[i] = PaglaAppConfig.seatUsers[i] == null ? "U" : null),
                child: Column(children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: PaglaAppConfig.seatUsers[i] != null ? Colors.pink : Colors.white10,
                    child: Icon(i < 5 ? Icons.stars : Icons.person_outline, color: Colors.white24, size: 20),
                  ),
                  Text("${i+1}", style: const TextStyle(color: Colors.white30, fontSize: 10)),
                ]),
              ),
            ),
          ),
          // অ্যাকশন বার (পিকে, মিউজিক, গেমস, গিফট)
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: const BoxDecoration(color: Color(0xFF151525), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            _iconAction(Icons.bolt, "PK", Colors.purple),
            const SizedBox(width: 20),
            _iconAction(Icons.music_note, "মিউজিক", Colors.blue),
            const SizedBox(width: 20),
            _iconAction(Icons.videogame_asset, "লুডু", Colors.orange),
          ]),
          _iconAction(Icons.card_giftcard, "গিফট", Colors.pink),
        ],
      ),
    );
  }

  Widget _iconAction(IconData i, String l, Color c) => Column(children: [Icon(i, color: c), Text(l, style: const TextStyle(color: Colors.white54, fontSize: 10))]);
}

// --- ৩. প্রোফাইল স্ক্রিন (ডায়মন্ড স্টোর, ফলোয়ার, সেটিং সহ) ---
class PaglaProfileScreen extends StatelessWidget {
  const PaglaProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Column(
        children: [
          const SizedBox(height: 70),
          const Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(radius: 50, backgroundColor: Colors.amber, child: CircleAvatar(radius: 47, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 50))), // ফ্রেম সহ প্রোফাইল
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text("পাগলা ইউজার", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("ID: 10002026", style: TextStyle(color: Colors.white38)),
          const SizedBox(height: 20),
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Column(children: [Text("৫০০", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("ফলোয়ার", style: TextStyle(color: Colors.white38, fontSize: 12))]),
            SizedBox(width: 40),
            Column(children: [Text("১০০", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("ফলোয়িং", style: TextStyle(color: Colors.white38, fontSize: 12))]),
          ]),
          const SizedBox(height: 30),
          // ডায়মন্ড স্টোর (+) বাটন
          Container(
            padding: const EdgeInsets.all(15), margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(15)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [const Icon(Icons.diamond, color: Colors.cyan), Text(" ${PaglaAppConfig.diamonds}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
              const Icon(Icons.add_circle, color: Colors.green, size: 28), // স্টোর প্লাস বাটন
            ]),
          ),
          const ListTile(leading: Icon(Icons.settings, color: Colors.white70), title: Text("ইউজার সেটিং", style: TextStyle(color: Colors.white))),
          const ListTile(leading: Icon(Icons.history, color: Colors.white70), title: Text("গিফটিং হিস্ট্রি", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
