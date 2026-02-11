import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase Error: $e");
  }
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
  // ডিফল্ট কালার সরাসরি সেট করা হলো যাতে ফায়ারবেস কানেক্ট না হলেও স্ক্রিন সাদা না হয়
  Color currentThemeColor = const Color(0xFF0F0F1E); 
  List<bool> seats = List.generate(15, (index) => false);

  @override
  void initState() {
    super.initState();
    _initAgora();
    _listenToRoomData();
  }

  void _listenToRoomData() {
    _dbRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        if (mounted) {
          setState(() {
            if (data['seats'] != null) {
              seats = List<bool>.from(data['seats']);
            }
            isLocked = data['isLocked'] ?? false;
            // থিম ডাটা না থাকলে ডিফল্ট কালার থাকবে
            if (data['theme'] != null) {
               currentThemeColor = Color(int.parse(data['theme']));
            }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: currentThemeColor, // সরাসরি কালার অবজেক্ট ব্যবহার
      child: Column(
        children: [
          const SizedBox(height: 50),
          // রুম হেডার
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                const CircleAvatar(radius: 20, backgroundColor: Colors.pink),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text("পাগলা আড্ডা ঘর", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                if(isLocked) const Icon(Icons.lock, color: Colors.white54, size: 16),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    // সেটিংস মেনু
                  },
                )
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
                child: CircleAvatar(
                  backgroundColor: seats[i] ? Colors.pink : Colors.white10,
                  child: Icon(Icons.person, color: Colors.white54, size: 20),
                ),
              ),
            ),
          ),
          
          // কন্ট্রোল বার
          _buildControls(),
        ],
      ),
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
            icon: Icon(isJoined ? Icons.call_end : Icons.add_call, color: isJoined ? Colors.red : Colors.green),
            onPressed: () async {
              if (isJoined) await _engine.leaveChannel();
              else await _engine.joinChannel(token: '', channelId: "pagla_adda", uid: 0, options: const ChannelMediaOptions(publishMicrophoneTrack: true, autoSubscribeAudio: true, clientRoleType: ClientRoleType.clientRoleBroadcaster));
            },
          ),
          const Icon(Icons.card_giftcard, color: Colors.pinkAccent),
        ],
      ),
    );
  }
}
