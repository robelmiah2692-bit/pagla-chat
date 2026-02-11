import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MainNavigation(),
  ));
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _idx = 1;
  final _screens = [
    const Center(child: Text("ফিড", style: TextStyle(color: Colors.white))),
    const PaglaVoiceRoom(),
    const Center(child: Text("মেসেজ", style: TextStyle(color: Colors.white))),
    const Center(child: Text("প্রোফাইল", style: TextStyle(color: Colors.white))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        backgroundColor: const Color(0xFF101025),
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white24,
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
  
  bool isJoined = false;
  bool isMuted = false;
  bool isLocked = false;
  String roomTheme = "0xFF0F0F1E";
  List<bool> seats = List.generate(15, (index) => false); // ২০টির বদলে ১৫টি দেখাচ্ছি গ্রিড সুন্দর করতে

  @override
  void initState() {
    super.initState();
    _initAgora();
    _listenToRoomData();
  }

  // ফায়ারবেস থেকে রুমের সব ডাটা শোনা
  void _listenToRoomData() {
    _dbRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        if (mounted) {
          setState(() {
            if (data['seats'] != null) {
              seats = (data['seats'] as List).map((e) => e as bool).toList();
            }
            isLocked = data['isLocked'] ?? false;
            roomTheme = data['theme'] ?? "0xFF0F0F1E";
          });
        }
      }
    });
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: "bd010dec4aa141228c87ec2cb9d4f6e8",
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (conn, elapsed) => setState(() => isJoined = true),
      onLeaveChannel: (conn, stats) => setState(() => isJoined = false),
    ));

    await _engine.enableAudio();
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
  }

  // থ্রি-ডট মেনু অপশন
  void _showRoomSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(isLocked ? Icons.lock_open : Icons.lock, color: Colors.white),
              title: Text(isLocked ? "রুম আনলক করুন" : "রুম লক করুন", style: const TextStyle(color: Colors.white)),
              onTap: () {
                _dbRef.update({"isLocked": !isLocked});
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette, color: Colors.white),
              title: const Text("রুম থিম পাল্টান", style: TextStyle(color: Colors.white)),
              onTap: () {
                _dbRef.update({"theme": "0xFF2D1B4E"}); // উদাহরণ থিম
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.amber),
              title: const Text("রুম প্রিমিয়াম করুন", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Color(int.parse(roomTheme))),
      child: Column(
        children: [
          const SizedBox(height: 50),
          // --- রুম হেডার (নাম, ছবি, ফলো, থ্রি-ডট) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage("https://via.placeholder.com/150"), // রুমের ছবি
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text("পাগলা আড্ডা ঘর", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          if(isLocked) const Icon(Icons.lock, size: 14, color: Colors.white54),
                        ],
                      ),
                      const Text("ID: 123456", style: TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
                // ফলো বাটন
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.pinkAccent, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    children: [
                      Icon(Icons.add, size: 16, color: Colors.white),
                      Text("ফলো", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // থ্রি ডট মেনু
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: _showRoomSettings,
                ),
              ],
            ),
          ),
          
          // সিট গ্রিড
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 20),
              itemCount: 15,
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () {
                  seats[i] = !seats[i];
                  _dbRef.update({"seats": seats});
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: seats[i] ? Colors.pink : Colors.white10,
                      child: Icon(i < 3 ? Icons.star : Icons.person, color: Colors.white54, size: 20),
                    ),
                    Text("${i+1}", style: const TextStyle(color: Colors.white24, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ),
          
          // বটম কন্ট্রোল বার
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF151525),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(isJoined ? Icons.call_end : Icons.add_call, color: isJoined ? Colors.red : Colors.green, size: 30),
            onPressed: () async {
               if (isJoined) {
                await _engine.leaveChannel();
              } else {
                await _engine.joinChannel(token: '', channelId: "pagla_adda", uid: 0, options: const ChannelMediaOptions(publishMicrophoneTrack: true, autoSubscribeAudio: true, clientRoleType: ClientRoleType.clientRoleBroadcaster));
              }
            },
          ),
          IconButton(
            icon: Icon(isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
            onPressed: () {
              setState(() => isMuted = !isMuted);
              _engine.muteLocalAudioStream(isMuted);
            },
          ),
          const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 30),
          const Icon(Icons.emoji_emotions, color: Colors.yellow, size: 30),
        ],
      ),
    );
  }
}
