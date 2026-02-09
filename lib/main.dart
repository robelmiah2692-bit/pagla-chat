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
      // প্রথমে স্প্ল্যাশ স্ক্রিন দেখাবে
      home: const SplashScreen(),
    );
  }
}

// ১. স্প্ল্যাশ স্ক্রিন (লোগো এখানে দেখাবে)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // ৩ সেকেন্ড পর মেইন স্ক্রিনে যাবে
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const MainScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // আপনার assets ফোল্ডারের লোগো
            Image.asset('assets/logo.jpg', width: 180), 
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.indigo),
            const SizedBox(height: 10),
            const Text("পাগলা চ্যাট লোড হচ্ছে...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ২. মেইন স্ক্রিন (চ্যাট এবং মাল্টি-মাইক কল)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final String appId = "348a9f9d55b14667891657dfc53dfbeb";
  late RtcEngine _engine;
  bool _isCalling = false;
  List<int> _remoteUsers = [];
  final List<String> _messages = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) => setState(() => _isCalling = true),
        onUserJoined: (connection, remoteUid, elapsed) => setState(() => _remoteUsers.add(remoteUid)),
        onUserOffline: (connection, remoteUid, reason) => setState(() => _remoteUsers.remove(remoteUid)),
        onLeaveChannel: (connection, stats) => setState(() { _isCalling = false; _remoteUsers.clear(); }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("পাগলা চ্যাট ও কল"),
        actions: [
          IconButton(
            icon: Icon(_isCalling ? Icons.call_end : Icons.call, color: _isCalling ? Colors.red : Colors.green),
            onPressed: () async {
              if (_isCalling) {
                await _engine.leaveChannel();
              } else {
                await _engine.joinChannel(token: '', channelId: "pagla_room", uid: 0, 
                  options: const ChannelMediaOptions(clientRoleType: ClientRoleType.clientRoleBroadcaster, channelProfile: ChannelProfileType.channelProfileCommunication));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isCalling)
            Container(
              height: 120,
              color: Colors.indigo[50],
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(10),
                children: [
                  _userIcon("আপনি", Colors.blue),
                  ..._remoteUsers.map((uid) => _userIcon("ইউজার $uid", Colors.green)),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) => ListTile(
                title: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                    decoration: BoxDecoration(color: Colors.indigo[100], borderRadius: BorderRadius.circular(12)),
                    child: Text(_messages[index]),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: "মেসেজ লিখুন...", border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30)))),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.indigo),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      setState(() { _messages.add(_controller.text); _controller.clear(); });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _userIcon(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          CircleAvatar(radius: 25, backgroundColor: color, child: const Icon(Icons.mic, color: Colors.white)),
          Text(name, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
