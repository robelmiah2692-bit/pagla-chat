import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

// --- ১. আপনার দেওয়া Agora ID দিয়ে সেটিংস ---
class PaglaAgoraConfig {
  static const String appId = "348a9f9d55b14667891657dfc53dfbeb"; 
  static bool isJoined = false;
  static bool isMuted = false;
  static bool isLocked = false;
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
  int _idx = 1;
  final _screens = [
    const Center(child: Text("হোম ফিড", style: TextStyle(color: Colors.white))),
    const PaglaVoiceRoom(),
    const Center(child: Text("মেসেজ", style: TextStyle(color: Colors.white))),
    const Center(child: Text("প্রোফাইল", style: TextStyle(color: Colors.white))),
  ];

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
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "ফিড"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "চ্যাট"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}

// --- ২. রিয়েল ভয়েস রুম ও সব ফিচার ---
class PaglaVoiceRoom extends StatefulWidget {
  const PaglaVoiceRoom({super.key});
  @override
  State<PaglaVoiceRoom> createState() => _PaglaVoiceRoomState();
}

class _PaglaVoiceRoomState extends State<PaglaVoiceRoom> {
  late RtcEngine _engine;
  final List<String?> seats = List.filled(20, null);

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  // অ্যাগোরা ইঞ্জিন সেটআপ
  Future<void> _initAgora() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: PaglaAgoraConfig.appId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() => PaglaAgoraConfig.isJoined = true);
        },
        onUserJoined: (connection, remoteUid, elapsed) {},
        onLeaveChannel: (connection, stats) {
          setState(() => PaglaAgoraConfig.isJoined = false);
        },
      ),
    );

    await _engine.enableAudio();
    await _engine.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine.setClientRole(ClientRoleType.clientRoleBroadcaster);
  }

  // রুমে জয়েন/লিভ লজিক
  void _toggleJoin() async {
    if (!PaglaAgoraConfig.isJoined) {
      await _engine.joinChannel(token: '', channelId: "pagla_room_1", uid: 0, options: const ChannelMediaOptions());
    } else {
      await _engine.leaveChannel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          const Text("পাগলা আড্ডা ঘর", style: TextStyle(fontSize: 16)),
          const SizedBox(width: 5),
          if(PaglaAgoraConfig.isLocked) const Icon(Icons.lock, color: Colors.red, size: 16),
        ]),
        actions: [
          IconButton(
            icon: Icon(PaglaAgoraConfig.isLocked ? Icons.lock : Icons.lock_open, color: Colors.white),
            onPressed: () => setState(() => PaglaAgoraConfig.isLocked = !PaglaAgoraConfig.isLocked),
          ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // ভিডিও/ইউটিউব স্ক্রিন (সক্রিয় হবে পরের ধাপে)
          Container(
            height: 150, width: double.infinity, margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
            child: const Center(child: Icon(Icons.video_library, color: Colors.red, size: 50)),
          ),
          
          // ২০ সিট গ্রিড (চাপ দিলে ইউজার বসবে)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
              itemCount: 20,
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => setState(() => seats[i] = seats[i] == null ? "U" : null),
                child: Column(children: [
                  CircleAvatar(
                    backgroundColor: seats[i] != null ? Colors.pink : Colors.white10,
                    child: Icon(i < 5 ? Icons.stars : Icons.person, color: Colors.white24, size: 20),
                  ),
                  Text("${i+1}", style: const TextStyle(color: Colors.white30, fontSize: 10)),
                ]),
              ),
            ),
          ),

          // চ্যাট লিস্ট ও কন্ট্রোল বার
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(color: Color(0xFF151525), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // জয়েন/লিভ কল বাটন
              IconButton(
                icon: Icon(PaglaAgoraConfig.isJoined ? Icons.call_end : Icons.add_call, color: PaglaAgoraConfig.isJoined ? Colors.red : Colors.green, size: 30),
                onPressed: _toggleJoin,
              ),
              // মাইক বাটন
              IconButton(
                icon: Icon(PaglaAgoraConfig.isMuted ? Icons.mic_off : Icons.mic, color: Colors.white70),
                onPressed: () {
                  setState(() => PaglaAgoraConfig.isMuted = !PaglaAgoraConfig.isMuted);
                  _engine.muteLocalAudioStream(PaglaAgoraConfig.isMuted);
                },
              ),
              const Icon(Icons.card_giftcard, color: Colors.pink),
              const Icon(Icons.videogame_asset, color: Colors.orange),
              const Icon(Icons.music_note, color: Colors.blue),
            ],
          ),
          const SizedBox(height: 10),
          const Text("💬 চ্যাট করার জন্য এখানে লিখুন...", style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }
}
