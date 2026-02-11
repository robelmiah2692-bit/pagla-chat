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
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: PaglaVoiceRoom()));
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
  String myName = "আপনার নাম"; // এখানে আপনার নাম দিন
  String myImg = "https://i.pravatar.cc/150?u=9"; 

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  // ৯টি ফিচার ঠিক রেখে ভয়েস চালু করা
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
      debugPrint("Agora error: $e");
    }
  }

  // সিটে বসার সাথে সাথে ভয়েস ও ডাটাবেস আপডেট
  void _handleSeat(int i, bool isOccupied) async {
    if (!isOccupied) {
      if (!isJoined) {
        await _engine?.joinChannel(token: '', channelId: "pagla", uid: 0, options: const ChannelMediaOptions(publishMicrophoneTrack: true, autoSubscribeAudio: true));
      }
      _dbRef.child("seat_details").child("$i").set({"name": myName, "image": myImg});
    } else {
      _dbRef.child("seat_details").child("$i").remove();
      // ইচ্ছা করলে এখানে লিভ বাটনও রাখা যায়
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ১. নামের পাশে ছবি (Header)
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    CircleAvatar(radius: 20, backgroundImage: NetworkImage(myImg)),
                    const SizedBox(width: 10),
                    const Expanded(child: Text("পাগলা আড্ডা ঘর 👑", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                    const Icon(Icons.settings, color: Colors.white),
                  ],
                ),
              ),

              // ২. ভিডিও দেখা বোর্ড
              
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                height: 160,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
                child: const Center(child: Icon(Icons.video_collection, color: Colors.white24, size: 40)),
              ),

              // ৩. পিকে ব্যাটল, মিউজিক, গেম (Action Buttons)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _fBtn(Icons.flash_on, "PK", Colors.orange),
                    _fBtn(Icons.games, "Game", Colors.blue),
                    _fBtn(Icons.music_note, "Music", Colors.green),
                    _fBtn(Icons.emoji_events, "Ranking", Colors.yellow),
                  ],
                ),
              ),

              // ৪. সিট গ্রিড (ছবি ও নাম সহ)
              
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 20, childAspectRatio: 0.7),
                itemCount: 15,
                itemBuilder: (ctx, i) => _buildSeat(i),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fBtn(IconData icon, String txt, Color col) {
    return Column(children: [CircleAvatar(backgroundColor: col.withOpacity(0.1), child: Icon(icon, color: col, size: 20)), Text(txt, style: const TextStyle(color: Colors.white54, fontSize: 10))]);
  }

  Widget _buildSeat(int i) {
    return StreamBuilder(
      stream: _dbRef.child("seat_details").child("$i").onValue,
      builder: (context, snapshot) {
        String name = "${i + 1}"; String? img; bool occ = false;
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          var d = snapshot.data!.snapshot.value as Map;
          name = d['name'] ?? name; img = d['image']; occ = true;
        }
        return GestureDetector(
          onTap: () => _handleSeat(i, occ),
          child: Column(
            children: [
              CircleAvatar(radius: 24, backgroundColor: occ ? Colors.pink : Colors.white10, backgroundImage: img != null ? NetworkImage(img) : null, child: !occ ? const Icon(Icons.add, color: Colors.white10) : null),
              const SizedBox(height: 4),
              Text(name, style: TextStyle(color: occ ? Colors.white : Colors.white24, fontSize: 10), overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }
}
