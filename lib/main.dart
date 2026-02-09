import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const PaglaChatApp());
}

class PaglaChatApp extends StatelessWidget {
  const PaglaChatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const AudioCallScreen(),
    );
  }
}

class AudioCallScreen extends StatefulWidget {
  const AudioCallScreen({super.key});
  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  String appId = "348a9f9d55b14667891657dfc53dfbeb"; // আপনার দেওয়া আইডি
  String channelName = "pagla_room"; // ডিফল্ট রুম নাম
  late RtcEngine _engine;
  bool _localUserJoined = false;
  bool _isCalling = false;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    // মাইক্রোফোন পারমিশন নেওয়া
    await [Permission.microphone].request();

    // অগোরা ইঞ্জিন সেটআপ
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() { _localUserJoined = true; });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("অন্যজন কলে যুক্ত হয়েছেন!")),
          );
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          setState(() { _localUserJoined = false; });
        },
      ),
    );
  }

  Future<void> joinCall() async {
    setState(() => _isCalling = true);
    await _engine.joinChannel(
      token: '', // টেস্টিংয়ের জন্য টোকেন খালি রাখলে হবে
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  Future<void> leaveCall() async {
    await _engine.leaveChannel();
    setState(() {
      _isCalling = false;
      _localUserJoined = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("পাগলা অডিও কল")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isCalling ? Icons.mic : Icons.mic_off,
              size: 100,
              color: _isCalling ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              _isCalling ? "কল চলছে..." : "কলে নেই",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCalling ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: _isCalling ? leaveCall : joinCall,
              child: Text(
                _isCalling ? "কল শেষ করুন" : "কল শুরু করুন",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
