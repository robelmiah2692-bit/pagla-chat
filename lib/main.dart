import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MainNavigation()));
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _idx = 1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: _idx == 1 ? const PaglaVoiceRoom() : const Center(child: Text("অন্যান্য পেজ", style: TextStyle(color: Colors.white))),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx, onTap: (i) => setState(() => _idx = i),
        backgroundColor: const Color(0xFF101025), selectedItemColor: Colors.pinkAccent, unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "ফিড"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "চ্যাট"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}

class PaglaVoiceRoom extends StatefulWidget {
  const PaglaVoiceRoom({super.key});
  @override
  State<PaglaVoiceRoom> createState() => _PaglaVoiceRoomState();
}

class _PaglaVoiceRoomState extends State<PaglaVoiceRoom> {
  late RtcEngine _engine;
  final _dbRef = FirebaseDatabase.instance.ref().child("rooms/room_1");
  bool isJoined = false, isMuted = false, isLocked = false;
  List<bool> seats = List.generate(15, (index) => false);

  @override
  void initState() {
    super.initState();
    _initAgora();
    _listenToRoom();
  }

  void _listenToRoom() {
    _dbRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        if (mounted) setState(() { isLocked = data['isLocked'] ?? false; });
      }
    });
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: "bd010dec4aa141228c87ec2cb9d4f6e8"));
    _engine.registerEventHandler(RtcEngineEventHandler(onJoinChannelSuccess: (c, e) => setState(() => isJoined = true)));
  }

  void _handleSeat(int i) async {
    if (!seats[i]) {
      if (!isJoined) await _engine.joinChannel(token: '', channelId: "pagla", uid: 0, options: const ChannelMediaOptions(publishMicrophoneTrack: true, autoSubscribeAudio: true));
      _dbRef.child("seat_details").child("$i").set({"name": "User $i", "image": "https://i.pravatar.cc/150?u=$i"});
      setState(() => seats[i] = true);
    } else {
      await _engine.leaveChannel();
      _dbRef.child("seat_details").child("$i").remove();
      setState(() => seats[i] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 50),
          // ১. বোর্ড নামের পাশে ছবি (Header)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                const CircleAvatar(radius: 20, backgroundImage: NetworkImage("https://via.placeholder.com/150")), 
                const SizedBox(width: 10),
                const Expanded(child: Text("পাগলা আড্ডা ঘর 👑", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                IconButton(icon: Icon(isLocked ? Icons.lock : Icons.lock_open, color: Colors.white), onPressed: () => _dbRef.update({"isLocked": !isLocked})),
              ],
            ),
          ),

          // ২. ভিডিও বোর্ড (Video Player UI)
          Container(
            margin: const EdgeInsets.all(15),
            height: 160, width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black, 
              borderRadius: BorderRadius.circular(15),
              image: const DecorationImage(image: NetworkImage("https://images.unsplash.com/photo-1611162617474-5b21e879e113?q=80&w=1000&auto=format&fit=crop"), fit: BoxFit.cover, opacity: 0.5)
            ),
            child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 50)),
          ),

          // ৩. পিকে ব্যাটল, গেম ও মিউজিক প্লেয়ার (Action Buttons)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _featureIcon(Icons.flash_on, "PK Battle", Colors.orange),
              _featureIcon(Icons.videogame_asset, "Games", Colors.blue),
              _featureIcon(Icons.music_note, "Music", Colors.green),
              _featureIcon(Icons.emoji_events, "Ranking", Colors.yellow),
            ],
          ),

          const SizedBox(height: 20),

          // ৪. সিট গ্রিড (মানুষ বসলে ছবি ও নিচে নাম)
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 20, childAspectRatio: 0.75),
            itemCount: 15, itemBuilder: (ctx, i) => _buildSeat(i),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _featureIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _buildSeat(int i) {
    return StreamBuilder(
      stream: _dbRef.child("seat_details").child("$i").onValue,
      builder: (context, snapshot) {
        String name = "${i + 1}"; String? img; bool occ = false;
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          var d = snapshot.data!.snapshot.value as Map; 
          name = d['name'] ?? "${i + 1}"; img = d['image']; occ = true;
        }
        return GestureDetector(
          onTap: () => _handleSeat(i),
          child: Column(
            children: [
              CircleAvatar(
                radius: 24, backgroundColor: occ ? Colors.pink : Colors.white10,
                backgroundImage: img != null ? NetworkImage(img) : null,
                child: !occ ? const Icon(Icons.person_add, color: Colors.white10, size: 20) : null,
              ),
              const SizedBox(height: 5),
              Text(name, style: TextStyle(color: occ ? Colors.white : Colors.white24, fontSize: 10, fontWeight: occ ? FontWeight.bold : FontWeight.normal), overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }
}
