import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MainNavigation(),
  ));
}

// --- আপনার নতুন App ID সেট করা হয়েছে ---
class PaglaConfig {
  static const String appId = "bd010dec4aa141228c87ec2cb9d4f6e8";
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
        // কথা বললে সিটে ইফেক্ট দেওয়ার জন্য এটি লাগবে
        onAudioVolumeIndication: (RtcConnection connection, List<AudioVolumeInfo> speakers, int speakerNumber, int totalVolume) {
           // এখানে কথা বলার এনিমেশন লজিক আসবে
        },
      ),
    );

    await _engine.enableAudio();
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableAudioVolumeIndication(interval: 200, smooth: 3, reportVad: true);
  }

  Future<void> _toggleCall() async {
    if (isJoined) {
      await _engine.leaveChannel();
    } else {
      await _engine.joinChannel(
        token: '', // APP ID Only মোডে এটি খালি থাকবে
        channelId: "pagla_adda", // দুই ফোনেই এই নাম এক থাকতে হবে
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
        const Text("পাগলা আড্ডা ঘর (Live)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        
        // ভিডিও/মিউজিক এরিয়া
        Container(
          height: 140, width: double.infinity, margin: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.indigo, Colors.black]),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10)
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_video, color: Colors.pinkAccent, size: 40),
              Text("Music is playing...", style: TextStyle(color: Colors.white30, fontSize: 12))
            ],
          ),
        ),
        
        // ২০টি সিট গ্রিড
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 15),
            itemCount: 20,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => setState(() => seats[index] = !seats[index]),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: seats[index] ? Colors.pinkAccent : Colors.white12,
                          child: Icon(index < 5 ? Icons.star : Icons.person, size: 20, color: Colors.white70),
                        ),
                        if(seats[index]) 
                          const Positioned(bottom: 0, right: 0, child: Icon(Icons.mic, color: Colors.green, size: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("${index + 1}", style: const TextStyle(color: Colors.white30, fontSize: 10)),
                  ],
                ),
              );
            },
          ),
        ),

        // কন্ট্রোল বার
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF151525), 
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // কল জয়েন বাটন
              GestureDetector(
                onTap: _toggleCall,
                child: CircleAvatar(
                  backgroundColor: isJoined ? Colors.red : Colors.green,
                  radius: 25,
                  child: Icon(isJoined ? Icons.call_end : Icons.add_call, color: Colors.white),
                ),
              ),
              // মাইক কন্ট্রোল
              IconButton(
                icon: Icon(isMuted ? Icons.mic_off : Icons.mic, color: isMuted ? Colors.red : Colors.white),
                onPressed: () {
                  setState(() => isMuted = !isMuted);
                  _engine.muteLocalAudioStream(isMuted);
                },
              ),
              const Icon(Icons.card_giftcard, color: Colors.orangeAccent, size: 28),
              const Icon(Icons.emoji_emotions, color: Colors.yellow, size: 28),
            ],
          ),
        ),
      ],
    );
  }
}
