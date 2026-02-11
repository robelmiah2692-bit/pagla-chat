import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MainNavigation(),
  ));
}

class PaglaConfig {
  static const String appId = "348a9f9d55b14667891657dfc53dfbeb";
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _idx = 1;
  final _screens = [
    const Center(child: Text("Home Feed", style: TextStyle(color: Colors.white))),
    const VoiceRoomScreen(),
    const Center(child: Text("Messages", style: TextStyle(color: Colors.white))),
    const Center(child: Text("Profile", style: TextStyle(color: Colors.white))),
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
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Feed"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "Room"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class VoiceRoomScreen extends StatefulWidget {
  const VoiceRoomScreen({super.key});
  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> {
  late RtcEngine _engine;
  bool isJoined = false;
  bool isMuted = false;
  final List<bool> seats = List.generate(20, (index) => false);

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: PaglaConfig.appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (mounted) setState(() => isJoined = true);
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          if (mounted) setState(() => isJoined = false);
        },
      ),
    );

    await _engine.enableAudio();
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
  }

  Future<void> _toggleCall() async {
    if (isJoined) {
      await _engine.leaveChannel();
    } else {
      await _engine.joinChannel(
        token: '',
        channelId: "pagla_room_1",
        uid: 0,
        options: const ChannelMediaOptions(
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    }
  }

  @override
  void dispose() {
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 50),
        const Text("পাগলা আড্ডা ঘর", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Container(
          height: 140,
          width: double.infinity,
          margin: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15)),
          child: const Icon(Icons.video_collection, color: Colors.red, size: 40),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 10),
            itemCount: 20,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => setState(() => seats[index] = !seats[index]),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: seats[index] ? Colors.pink : Colors.white10,
                      child: Icon(index < 5 ? Icons.star : Icons.person, size: 18, color: Colors.white54),
                    ),
                    Text("${index + 1}", style: const TextStyle(color: Colors.white30, fontSize: 10)),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(color: Color(0xFF151525), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(isJoined ? Icons.call_end : Icons.add_call, color: isJoined ? Colors.red : Colors.green, size: 30),
                onPressed: _toggleCall,
              ),
              IconButton(
                icon: Icon(isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
                onPressed: () {
                  setState(() => isMuted = !isMuted);
                  _engine.muteLocalAudioStream(isMuted);
                },
              ),
              const Icon(Icons.card_giftcard, color: Colors.pink),
              const Icon(Icons.videogame_asset, color: Colors.orange),
            ],
          ),
        ),
      ],
    );
  }
}
