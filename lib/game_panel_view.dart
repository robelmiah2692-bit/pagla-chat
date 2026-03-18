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

  // সাউন্ড লিংক (অনলাইন থেকে সরাসরি বাজবে)
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
    _userRef = FirebaseDatabase.instance.ref("users/$uid");
    
    _listenToData();
    _fetchUserBalance();
    _startLuckyTimer();
  }

  void _fetchUserBalance() {
    _userRef.child("diamonds").onValue.listen((event) {
      if (mounted) setState(() => userBalance = (event.snapshot.value as int? ?? 0));
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
      duration: const Duration(milliseconds: 500),
      height: isFullScreen ? MediaQuery.of(context).size.height : 550,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _buildTopDiamondBar(),
              _buildGameSelector(),
              Expanded(child: activeGame == "LUDO" ? _buildLudoView() : _buildLuckyView()),
            ],
          ),
          Positioned(
            top: 15, right: 15,
            child: IconButton(
              icon: const Icon(Icons.close_fullscreen, color: Colors.white, size: 28),
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

  Widget _buildTopDiamondBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
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
                IconButton(onPressed: () => setState(() => betAmount = max(100, betAmount - 100)), icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent)),
                Text("$betAmount", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => setState(() => betAmount += 100), icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent)),
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
          Text(winLoseStatus, style: TextStyle(color: winLoseStatus.contains("WIN") ? Colors.greenAccent : Colors.redAccent, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedRotation(
              turns: _rotationAngle / (2 * pi),
              duration: const Duration(seconds: 3),
              curve: Curves.easeOutCubic,
              child: Image.asset("assets/images/lucky_wheel.png", width: 180),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.red, size: 40),
            Text("$_countdown", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        _buildLuckyBetGrid(),
      ],
    );
  }

  Widget _buildLuckyBetGrid() {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.5),
      itemCount: wheelSegments.length,
      itemBuilder: (context, index) {
        String slot = wheelSegments[index]['label'];
        return GestureDetector(
          onTap: () async {
            if (userBalance < betAmount) return;
            _playGameSound(spinSound); // ক্লিক সাউন্ড হিসেবে
            await _userRef.update({"diamonds": userBalance - betAmount});
            await _gameRef.child("luckyBets").push().set({
              "id": FirebaseAuth.instance.currentUser?.uid,
              "name": FirebaseAuth.instance.currentUser?.displayName,
              "slot": slot,
              "amount": betAmount
            });
          },
          child: Container(
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: Colors.white10, border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text("$slot\n${wheelSegments[index]['mult']}x", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10))),
          ),
        );
      },
    );
  }

  Widget _buildLudoView() {
    return InkWell(
      onTap: () => setState(() => isFullScreen = true),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: isFullScreen ? 340 : 220,
            height: isFullScreen ? 340 : 220,
            decoration: const BoxDecoration(image: DecorationImage(image: AssetImage("assets/images/ludo_preview.png"), fit: BoxFit.contain)),
            child: _buildLudoPlayersDesign(),
          ),
          const SizedBox(height: 20),
          if (widget.isAdmin) 
            GestureDetector(
              onTap: () {
                _playGameSound(diceSound);
                _gameRef.update({"diceNumber": Random().nextInt(6) + 1});
              },
              child: Icon(_getDiceIcon(diceNumber), size: 70, color: Colors.white),
            )
          else 
            const Text("Waiting for Admin...", style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildLudoPlayersDesign() {
    return Stack(
      children: [
        for (int i = 0; i < players.length; i++)
          _buildAvatarPositioned(i, players[i]['photo']),
      ],
    );
  }

  Widget _buildAvatarPositioned(int index, String? photo) {
    List<Alignment> alignments = [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight];
    return Align(
      alignment: alignments[index % 4],
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: CircleAvatar(backgroundImage: NetworkImage(photo ?? ""), radius: isFullScreen ? 28 : 20),
      ),
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
        return TextButton(
          onPressed: () => _gameRef.update({"type": g}),
          child: Text(g, style: TextStyle(color: active ? Colors.cyanAccent : Colors.white54, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
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
