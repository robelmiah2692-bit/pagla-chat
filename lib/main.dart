import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // ফায়ারবেস স্টার্ট
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
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child("rooms/room_1/seats");
  
  bool isJoined = false;
  bool isMuted = false;
  List<bool> seats = List.generate(20, (index) => false);

  @override
  void initState() {
    super.initState();
    _initAgora();
    _listenToSeats();
  }

  void _listenToSeats() {
    _dbRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        List<dynamic> data = event.snapshot.value as List<dynamic>;
        if (mounted) setState(() => seats = data.map((e) => e as bool).toList());
      }
    });
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: "bd010dec4aa141228c87ec2cb9d4f6e8", // আপনার টেস্ট মোড আইডি
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (conn, elapsed) => setState(() => isJoined = true),
      onLeaveChannel: (conn, stats) => setState(() => isJoined = false),
    ));

    await _engine.enableAudio();
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
  }

  void _toggleSeat(int index) {
    seats[index] = !seats[index];
    _dbRef.set(seats); // ফায়ারবেসে আপডেট
  }

  Future<void> _toggleJoin() async {
    if (isJoined) {
      await _engine.leaveChannel();
    } else {
      await _engine.joinChannel(
        token: '',
        channelId: "pagla_adda",
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
        const Text("পাগলা আড্ডা ঘর", style: TextStyle(color: Colors.white, fontSize: 18)),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 20),
            itemCount: 20,
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => _toggleSeat(i),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: seats[i] ? Colors.pink : Colors.white10,
                    child: Icon(i < 5 ? Icons.star : Icons.person, color: Colors.white54, size: 20),
                  ),
                  Text("${i+1}", style: const TextStyle(color: Colors.white24, fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
        _buildControls(),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF151525),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(isJoined ? Icons.call_end : Icons.add_call, color: isJoined ? Colors.red : Colors.green, size: 30),
            onPressed: _toggleJoin,
          ),
          IconButton(
            icon: Icon(isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
            onPressed: () {
              setState(() => isMuted = !isMuted);
              _engine.muteLocalAudioStream(isMuted);
            },
          ),
          const Icon(Icons.card_giftcard, color: Colors.pinkAccent),
        ],
      ),
    );
  }
}
