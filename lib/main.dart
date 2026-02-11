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
    // পারমিশন হ্যান্ডলিং
    await [Permission.microphone].request();

    // ইঞ্জিন তৈরি (CamelCase সঠিক করা হয়েছে)
    _engine = createAgoraRtcEngine(); 
    
    await _engine.initialize(const RtcEngineContext(
      appId: PaglaAgoraConfig.appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (mounted) setState(() => PaglaAgoraConfig.isJoined = true);
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          if (mounted) setState(() => PaglaAgoraConfig.isJoined = false);
        },
      ),
    );

    await _engine.enableAudio();
    
    // ব্রডকাস্টার রোল সেটআপ (নতুন ভার্সনের সঠিক সিনট্যাক্স)
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
  }

  void _toggleJoin() async {
    if (!PaglaAgoraConfig.isJoined) {
      await _engine.joinChannel(
        token: '', 
        channelId: "pagla_room_1", 
        uid: 0, 
        options: const ChannelMediaOptions(
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        )
      );
    } else {
      await _engine.leaveChannel();
    }
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
