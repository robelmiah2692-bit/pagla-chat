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
    _userRef = FirebaseDatabase.instance.ref("users/$uid");
    
    _listenToData();
    _fetchUserBalance();
    _startLuckyTimer();
  }

  void _fetchUserBalance() {
    _userRef.child("diamonds").onValue.listen((event) {
      if (mounted) {
        setState(() {
          // ডেটা টাইপ সেফ করার জন্য int.tryParse ব্যবহার করা হয়েছে
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
      height: isFullScreen ? MediaQuery.of(context).size.height : 600,
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
          // ক্লোজ বাটন একদম আলাদা পজিশনে রাখা হয়েছে যাতে অন্য কিছুর সাথে না মিশে
          Positioned(
            top: 15, right: 15,
            child: IconButton(
              icon: Icon(isFullScreen ? Icons.close_fullscreen : Icons.cancel, color: Colors.white, size: 30),
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

  // ডাইমন্ড এবং বেট বাটন আলাদা করা হয়েছে
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 70, 10), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.diamond, color: Colors.cyanAccent, size: 20),
                const SizedBox(width: 5),
                Text("$userBalance", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (activeGame == "LUCKY") 
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  IconButton(onPressed: () => setState(() => betAmount = max(100, betAmount - 100)), icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 22)),
                  Text("$betAmount", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => setState(() => betAmount += 100), icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent, size: 22)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLuckyView() {
    return Column(
      children: [
        if (winLoseStatus.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(winLoseStatus, style: TextStyle(color: winLoseStatus.contains("WIN") ? Colors.greenAccent : Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
        const SizedBox(height: 5),
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedRotation(
              turns: _rotationAngle / (2 * pi),
              duration: const Duration(seconds: 3),
              curve: Curves.easeOutCubic,
              child: Image.asset("assets/images/lucky_wheel.png", width: 180),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.red, size: 45),
            CircleAvatar(radius: 20, backgroundColor: Colors.black87, child: Text("$_countdown", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        const SizedBox(height: 15),
        _buildLuckyBetGrid(),
      ],
    );
  }

  Widget _buildLuckyBetGrid() {
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.2, crossAxisSpacing: 10, mainAxisSpacing: 10),
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
            decoration: BoxDecoration(color: Colors.white10, border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text("$slot\n${wheelSegments[index]['mult']}x", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12))),
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
            width: isFullScreen ? 350 : 260,
            height: isFullScreen ? 350 : 260,
            decoration: const BoxDecoration(image: DecorationImage(image: AssetImage("assets/images/ludo_preview.png"), fit: BoxFit.contain)),
            child: Stack(
              children: [
                for (int i = 0; i < players.length; i++) ..._buildPlayerTokens(i, players[i]['photo']),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (widget.isAdmin) 
          GestureDetector(
            onTap: () {
              _playGameSound(diceSound);
              _gameRef.update({"diceNumber": Random().nextInt(6) + 1});
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 10)]),
              child: Icon(_getDiceIcon(diceNumber), size: 60, color: Colors.black),
            ),
          )
        else 
          const Text("Admin is rolling dice...", style: TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 20),
        _buildPlayerNamesList(),
      ],
    );
  }

  List<Widget> _buildPlayerTokens(int playerIdx, String? photo) {
    List<Alignment> baseAligns = [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight];
    List<Offset> tokenOffsets = [const Offset(0, 0), const Offset(28, 0), const Offset(0, 28), const Offset(28, 28)];
    
    return List.generate(4, (i) {
      return Align(
        alignment: baseAligns[playerIdx % 4],
        child: Transform.translate(
          offset: tokenOffsets[i].scale(isFullScreen ? 1.5 : 1.0, isFullScreen ? 1.5 : 1.0),
          child: Padding(
            padding: EdgeInsets.all(isFullScreen ? 45 : 30),
            child: CircleAvatar(
              radius: isFullScreen ? 13 : 10,
              backgroundColor: Colors.white,
              child: CircleAvatar(radius: isFullScreen ? 11 : 8, backgroundImage: NetworkImage(photo ?? "")),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPlayerNamesList() {
    return Wrap(
      spacing: 20,
      runSpacing: 10,
      children: players.map((p) => Column(
        children: [
          CircleAvatar(radius: 22, backgroundImage: NetworkImage(p['photo'] ?? ""), backgroundColor: Colors.white10),
          const SizedBox(height: 5),
          Text(p['name']?.split(' ')[0] ?? "Player", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      )).toList(),
    );
  }

  IconData _getDiceIcon(int num) {
    List<IconData> icons = [Icons.looks_one, Icons.looks_two, Icons.looks_3, Icons.looks_4, Icons.looks_5, Icons.looks_6];
    return icons[num - 1];
  }

  Widget _buildGameSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ["LUDO", "LUCKY"].map((g) {
          bool active = activeGame == g;
          return GestureDetector(
            onTap: () => _gameRef.update({"type": g}),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: active ? Colors.cyanAccent : Colors.white10, borderRadius: BorderRadius.circular(25)),
              child: Text(g, style: TextStyle(color: active ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          );
        }).toList(),
      ),
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
