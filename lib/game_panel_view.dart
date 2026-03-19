import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';

class GamePanelView extends StatefulWidget {
  final String roomId;
  final bool isAdmin; 
  const GamePanelView({super.key, required this.roomId, this.isAdmin = false});

  @override
  State<GamePanelView> createState() => _GamePanelViewState();
}

class _GamePanelViewState extends State<GamePanelView> {
  late DatabaseReference _gameRef;
  late DatabaseReference _userRef;
  StreamSubscription? _subscription;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // সাউন্ড লিংক
  final String spinSound = "https://www.soundjay.com/misc/sounds/bell-ringing-01.mp3";
  final String winSound = "https://www.soundjay.com/human/sounds/applause-01.mp3";
  final String loseSound = "https://www.soundjay.com/buttons/sounds/button-10.mp3";
  final String diceSound = "https://www.soundjay.com/misc/sounds/dice-roll-01.mp3";

  String activeGame = "LUDO";
  bool isSpinning = false;
  bool isFullScreen = false;
  int diceNumber = 1;
  int userBalance = 0;
  int betAmount = 100; 
  String winLoseStatus = ""; 

  List<Map<dynamic, dynamic>> players = [];
  List<Map<dynamic, dynamic>> luckyBets = [];
  double _rotationAngle = 0;
  int _countdown = 15;
  Timer? _spinTimer;

  final List<Map<String, dynamic>> wheelSegments = [
    {"label": "777", "mult": 25, "deg": 0},
    {"label": "Grapes", "mult": 2, "deg": 60},
    {"label": "Apple", "mult": 3, "deg": 120},
    {"label": "Plum", "mult": 4, "deg": 180},
    {"label": "Strawberry", "mult": 5, "deg": 240},
    {"label": "Watermelon", "mult": 1, "deg": 300},
  ];

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _gameRef = FirebaseDatabase.instance.ref("games/${widget.roomId}");
    // ইউজার ব্যালেন্সের পাথ নিশ্চিত করুন
    _userRef = FirebaseDatabase.instance.ref("users/$uid");
    
    _listenToData();
    _fetchUserBalance();
    _startLuckyTimer();
  }

  // রিয়েল টাইম ব্যালেন্স ফেচ
  void _fetchUserBalance() {
    _userRef.child("diamonds").onValue.listen((event) {
      if (mounted) {
        setState(() {
          userBalance = int.tryParse(event.snapshot.value.toString()) ?? 0;
        });
      }
    });
  }

  void _listenToData() {
    _subscription = _gameRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;
      if (mounted) {
        setState(() {
          activeGame = data['type'] ?? "LUDO";
          diceNumber = data['diceNumber'] ?? 1;
          if (data['players'] != null) {
            players = (data['players'] as Map).values.map((e) => e as Map).toList();
          }
          if (data['luckyBets'] != null) {
            luckyBets = (data['luckyBets'] as Map).values.map((e) => e as Map).toList();
          }
        });
      }
    });
  }

  void _playGameSound(String url) async {
    await _audioPlayer.play(UrlSource(url));
  }

  void _startLuckyTimer() {
    _spinTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (activeGame == "LUCKY" && !isSpinning) {
        if (_countdown > 0) {
          setState(() => _countdown--);
        } else {
          _performSpin();
          setState(() => _countdown = 15);
        }
      }
    });
  }

  Future<void> _performSpin() async {
    if (isSpinning) return;
    _playGameSound(spinSound);
    setState(() {
      isSpinning = true;
      winLoseStatus = "";
    });

    int winIdx = Random().nextInt(wheelSegments.length);
    var winResult = wheelSegments[winIdx];
    double targetRot = (2 * pi * 5) + (winResult['deg'] * pi / 180);
    setState(() => _rotationAngle += targetRot);

    Future.delayed(const Duration(seconds: 3), () async {
      final myId = FirebaseAuth.instance.currentUser?.uid;
      int totalWin = 0;
      bool won = false;

      for (var bet in luckyBets) {
        if (bet['id'] == myId && bet['slot'] == winResult['label']) {
          won = true;
          totalWin += (bet['amount'] as int) * (winResult['mult'] as int);
        }
      }

      if (won) {
        _playGameSound(winSound);
        setState(() => winLoseStatus = "WIN! +💎$totalWin");
        await _userRef.update({"diamonds": userBalance + totalWin});
      } else if (luckyBets.any((b) => b['id'] == myId)) {
        _playGameSound(loseSound);
        setState(() => winLoseStatus = "LOSE!");
      }

      await _gameRef.child("luckyBets").remove();
      setState(() => isSpinning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: isFullScreen ? MediaQuery.of(context).size.height : 580,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _buildTopBar(),
              _buildGameSelector(),
              Expanded(child: activeGame == "LUDO" ? _buildLudoView() : _buildLuckyView()),
            ],
          ),
          // ক্লোজ বাটন পজিশন ঠিক করা হয়েছে
          Positioned(
            top: 15, right: 15,
            child: IconButton(
              icon: Icon(isFullScreen ? Icons.close_fullscreen : Icons.cancel, color: Colors.white, size: 28),
              onPressed: () {
                if (isFullScreen) {
                  setState(() => isFullScreen = false);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 60, 10), // ক্লোজ বাটনের জন্য গ্যাপ রাখা হয়েছে
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.diamond, color: Colors.cyanAccent, size: 18),
                const SizedBox(width: 5),
                Text("$userBalance", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (activeGame == "LUCKY") 
            Row(
              children: [
                IconButton(onPressed: () => setState(() => betAmount = max(100, betAmount - 100)), icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20)),
                Text("$betAmount", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => setState(() => betAmount += 100), icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent, size: 20)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLuckyView() {
    return Column(
      children: [
        if (winLoseStatus.isNotEmpty)
          Text(winLoseStatus, style: TextStyle(color: winLoseStatus.contains("WIN") ? Colors.greenAccent : Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedRotation(
              turns: _rotationAngle / (2 * pi),
              duration: const Duration(seconds: 3),
              curve: Curves.easeOutCubic,
              child: Image.asset("assets/images/lucky_wheel.png", width: 170),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.red, size: 40),
            CircleAvatar(radius: 18, backgroundColor: Colors.black54, child: Text("$_countdown", style: const TextStyle(color: Colors.white, fontSize: 12))),
          ],
        ),
        const SizedBox(height: 10),
        _buildLuckyBetGrid(),
      ],
    );
  }

  Widget _buildLuckyBetGrid() {
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.2, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: wheelSegments.length,
      itemBuilder: (context, index) {
        String slot = wheelSegments[index]['label'];
        return GestureDetector(
          onTap: () async {
            if (userBalance < betAmount) return;
            _playGameSound(spinSound);
            await _userRef.update({"diamonds": userBalance - betAmount});
            await _gameRef.child("luckyBets").push().set({
              "id": FirebaseAuth.instance.currentUser?.uid,
              "name": FirebaseAuth.instance.currentUser?.displayName,
              "slot": slot,
              "amount": betAmount
            });
          },
          child: Container(
            decoration: BoxDecoration(color: Colors.white10, border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text("$slot\n${wheelSegments[index]['mult']}x", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11))),
          ),
        );
      },
    );
  }

  Widget _buildLudoView() {
    return Column(
      children: [
        const SizedBox(height: 10),
        InkWell(
          onTap: () => setState(() => isFullScreen = true),
          child: Container(
            width: isFullScreen ? 350 : 250,
            height: isFullScreen ? 350 : 250,
            decoration: const BoxDecoration(image: DecorationImage(image: AssetImage("assets/images/ludo_preview.png"), fit: BoxFit.contain)),
            child: Stack(
              children: [
                for (int i = 0; i < players.length; i++) ..._buildPlayerTokens(i, players[i]['photo']),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        if (widget.isAdmin) 
          GestureDetector(
            onTap: () {
              _playGameSound(diceSound);
              _gameRef.update({"diceNumber": Random().nextInt(6) + 1});
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Icon(_getDiceIcon(diceNumber), size: 55, color: Colors.black),
            ),
          ),
        const SizedBox(height: 15),
        _buildPlayerNamesList(),
      ],
    );
  }

  // ১৬টি ঘুঁটি দেখানোর লজিক
  List<Widget> _buildPlayerTokens(int playerIdx, String? photo) {
    List<Alignment> baseAligns = [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight];
    List<Offset> offsets = [const Offset(0, 0), const Offset(25, 0), const Offset(0, 25), const Offset(25, 25)];
    
    return List.generate(4, (i) {
      return Align(
        alignment: baseAligns[playerIdx % 4],
        child: Transform.translate(
          offset: offsets[i].scale(isFullScreen ? 1.4 : 1.0, isFullScreen ? 1.4 : 1.0),
          child: Padding(
            padding: EdgeInsets.all(isFullScreen ? 40 : 25),
            child: CircleAvatar(
              radius: isFullScreen ? 12 : 9,
              backgroundColor: Colors.white,
              child: CircleAvatar(radius: isFullScreen ? 10 : 7, backgroundImage: NetworkImage(photo ?? "")),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPlayerNamesList() {
    return Wrap(
      spacing: 20,
      children: players.map((p) => Column(
        children: [
          CircleAvatar(radius: 18, backgroundImage: NetworkImage(p['photo'] ?? "")),
          const SizedBox(height: 4),
          Text(p['name']?.split(' ')[0] ?? "User", style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      )).toList(),
    );
  }

  IconData _getDiceIcon(int num) {
    List<IconData> icons = [Icons.looks_one, Icons.looks_two, Icons.looks_3, Icons.looks_4, Icons.looks_5, Icons.looks_6];
    return icons[num - 1];
  }

  Widget _buildGameSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ["LUDO", "LUCKY"].map((g) {
        bool active = activeGame == g;
        return GestureDetector(
          onTap: () => _gameRef.update({"type": g}),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(color: active ? Colors.cyanAccent : Colors.white10, borderRadius: BorderRadius.circular(20)),
            child: Text(g, style: TextStyle(color: active ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _subscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
