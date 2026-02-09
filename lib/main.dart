import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const PaglaChatApp());

class PaglaChatApp extends StatelessWidget {
  const PaglaChatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
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
            Image.asset('assets/logo.jpg', width: 200, errorBuilder: (c, e, s) => const Icon(Icons.image, size: 100)),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const Text("পাগলা চ্যাট লোড হচ্ছে...")
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final String appId = "348a9f9d55b14667891657dfc53dfbeb"; // আপনার অ্যাগোরা আইডি
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
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) => setState(() => _isCalling = true),
      onUserJoined: (connection, remoteUid, elapsed) => setState(() => _remoteUsers.add(remoteUid)),
      onUserOffline: (connection, remoteUid, reason) => setState(() => _remoteUsers.remove(remoteUid)),
      onLeaveChannel: (connection, stats) => setState(() { _isCalling = false; _remoteUsers.clear(); }),
    ));
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
              if (_isCalling) { await _engine.leaveChannel(); } 
              else { await _engine.joinChannel(token: '', channelId: "pagla_room", uid: 0, options: const ChannelMediaOptions()); }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isCalling)
            Container(
              height: 120,
              padding: const EdgeInsets.all(8),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                itemCount: _remoteUsers.length + 1,
                itemBuilder: (c, i) => Column(children: [
                  CircleAvatar(child: Icon(Icons.mic, size: 15)),
                  Text(i == 0 ? "আপনি" : "ইউজার", style: TextStyle(fontSize: 10))
                ]),
              ),
            ),
          Expanded(child: ListView.builder(itemCount: _messages.length, itemBuilder: (c, i) => ListTile(title: Text(_messages[i], textAlign: TextAlign.right)))),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: "মেসেজ লিখুন..."))),
                IconButton(icon: const Icon(Icons.send), onPressed: () {
                  if (_controller.text.isNotEmpty) { setState(() { _messages.add(_controller.text); _controller.clear(); }); }
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
