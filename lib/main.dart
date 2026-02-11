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
    debugPrint("Firebase missing: $e");
  }
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PaglaVoiceRoom(),
  ));
}

class PaglaVoiceRoom extends StatefulWidget {
  const PaglaVoiceRoom({super.key});
  @override
  State<PaglaVoiceRoom> createState() => _PaglaVoiceRoomState();
}

class _PaglaVoiceRoomState extends State<PaglaVoiceRoom> {
  RtcEngine? _engine;
  final _dbRef = FirebaseDatabase.instance.ref().child("rooms/room_1");
  bool isJoined = false;
  
  // প্রোফাইল তথ্য
  String myName = "পাগলা কিং";
  String myImg = "https://i.pravatar.cc/150?u=myid";

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    try {
      await [Permission.microphone].request();
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(appId: "bd010dec4aa141228c87ec2cb9d4f6e8"));
      await _engine!.enableAudio();
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (c, e) => setState(() => isJoined = true),
      ));
    } catch (e) {
      debugPrint("Agora connection error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: Column(
          children: [
            // ১. বোর্ড নামের পাশে ছবি (Header)
            _buildTopBar(),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ২. ভিডিও বোর্ড
                    _buildVideoSection(),

                    // ৩. গেম, পিকে, মিউজিক বাটন
                    _buildActionIcons(),

                    const SizedBox(height: 20),

                    // ৪. সিট গ্রিড (ছবি ও নাম সহ)
                    _buildSeatGrid(),
                  ],
                ),
              ),
            ),
            
            // ৫. বটম কন্ট্রোল বার (মিউট, গিফট)
            _buildBottomMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          CircleAvatar(radius: 18, backgroundImage: NetworkImage(myImg)),
          const SizedBox(width: 10),
          const Expanded(child: Text("পাগলা আড্ডা ঘর 👑", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          const Icon(Icons.settings, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    return Container(
      margin: const EdgeInsets.all(15),
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library, color: Colors.white24, size: 40),
            Text("মুভি বোর্ড / ভিডিও", style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _iconUnit(Icons.flash_on, "PK Battle", Colors.orange),
        _iconUnit(Icons.videogame_asset, "Ludo Game", Colors.blue),
        _iconUnit(Icons.music_note, "Music Player", Colors.green),
        _iconUnit(Icons.emoji_events, "Ranking", Colors.yellow),
      ],
    );
  }

  Widget _iconUnit(IconData icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 22, child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildSeatGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 20, childAspectRatio: 0.7),
      itemCount: 15,
      itemBuilder: (context, i) {
        return StreamBuilder(
          stream: _dbRef.child("seat_details").child("$i").onValue,
          builder: (context, snapshot) {
            bool occ = false; String name = "${i + 1}"; String? img;
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              var d = snapshot.data!.snapshot.value as Map;
              name = d['name'] ?? name; img = d['image']; occ = true;
            }
            return GestureDetector(
              onTap: () async {
                if (!occ) {
                  if (!isJoined) await _engine?.joinChannel(token: '', channelId: "pagla", uid: 0, options: const ChannelMediaOptions(publishMicrophoneTrack: true, autoSubscribeAudio: true));
                  _dbRef.child("seat_details").child("$i").set({"name": myName, "image": myImg});
                } else {
                  _dbRef.child("seat_details").child("$i").remove();
                }
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: occ ? Colors.pink : Colors.white10,
                    backgroundImage: img != null ? NetworkImage(img) : null,
                    child: !occ ? const Icon(Icons.add, color: Colors.white10, size: 18) : null,
                  ),
                  const SizedBox(height: 5),
                  Text(name, style: TextStyle(color: occ ? Colors.white : Colors.white24, fontSize: 10), overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFF151525),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: Icon(Icons.mic, color: isJoined ? Colors.white : Colors.white10), onPressed: () {}),
          const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 30),
          const Icon(Icons.emoji_emotions, color: Colors.yellow, size: 30),
          const Icon(Icons.message, color: Colors.white54, size: 25),
        ],
      ),
    );
  }
}
