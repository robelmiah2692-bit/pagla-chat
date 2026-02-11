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
        if (mounted) {
          setState(() {
            if (data['seats'] != null) seats = List<bool>.from(data['seats']);
            isLocked = data['isLocked'] ?? false;
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
      onJoinChannelSuccess: (c, e) => setState(() => isJoined = true),
      onLeaveChannel: (c, s) => setState(() => isJoined = false),
    ));
    await _engine.enableAudio();
  }

  void _handleSeatAction(int index) async {
    if (!seats[index]) {
      if (!isJoined) {
        await _engine.joinChannel(token: '', channelId: "pagla_adda", uid: 0, options: const ChannelMediaOptions(publishMicrophoneTrack: true, autoSubscribeAudio: true, clientRoleType: ClientRoleType.clientRoleBroadcaster));
      }
      Map<String, dynamic> userData = {"name": "ইউজার ${index + 1}", "image": "https://i.pravatar.cc/150?u=$index", "isOccupied": true};
      await _dbRef.child("seat_details").child("$index").set(userData);
      setState(() { seats[index] = true; isJoined = true; });
    } else {
      await _engine.leaveChannel();
      await _dbRef.child("seat_details").child("$index").remove();
      setState(() { seats[index] = false; isJoined = false; });
    }
    _dbRef.update({"seats": seats});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 50),
        // হেডার
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              const CircleAvatar(radius: 20, backgroundImage: NetworkImage("https://via.placeholder.com/150")),
              const SizedBox(width: 10),
              const Expanded(child: Text("পাগলা আড্ডা ঘর", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              IconButton(icon: Icon(isLocked ? Icons.lock : Icons.lock_open, color: Colors.white), onPressed: () => _dbRef.update({"isLocked": !isLocked})),
            ],
          ),
        ),
        // সিট গ্রিড
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 25),
            itemCount: 15,
            itemBuilder: (ctx, i) => _buildSeat(i),
          ),
        ),
        // বটম বার
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildSeat(int i) {
    return StreamBuilder(
      stream: _dbRef.child("seat_details").child("$i").onValue,
      builder: (context, snapshot) {
        String name = "${i + 1}";
        String? imageUrl;
        bool occupied = false;
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          var data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          name = data['name'] ?? "${i + 1}";
          imageUrl = data['image'];
          occupied = true;
        }
        return GestureDetector(
          onTap: () => _handleSeatAction(i),
          child: Column(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: occupied ? Colors.pinkAccent : Colors.white10,
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                child: !occupied ? const Icon(Icons.person_add, color: Colors.white24, size: 20) : null,
              ),
              const SizedBox(height: 4),
              Text(name, style: TextStyle(color: occupied ? Colors.white : Colors.white24, fontSize: 10), overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF151525),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: Icon(isMuted ? Icons.mic_off : Icons.mic, color: isJoined ? Colors.white : Colors.white10), onPressed: isJoined ? () { setState(() => isMuted = !isMuted); _engine.muteLocalAudioStream(isMuted); } : null),
          IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 30), onPressed: () {}),
          const Icon(Icons.emoji_emotions, color: Colors.yellow, size: 30),
        ],
      ),
    );
  }
}
