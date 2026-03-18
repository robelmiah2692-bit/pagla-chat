import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';

class GamePanelView extends StatefulWidget {
  final String roomId;
  final bool isAdmin; // রুম ওনার বা এডমিন কি না
  const GamePanelView({super.key, required this.roomId, this.isAdmin = false});

  @override
  State<GamePanelView> createState() => _GamePanelViewState();
}

class _GamePanelViewState extends State<GamePanelView> {
  late DatabaseReference _gameRef;
  late DatabaseReference _userRef;
  StreamSubscription? _subscription;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // গেম স্টেট
  String activeGame = "LUDO";
  bool isSpinning = false;
  bool isFullScreen = false;
  int diceNumber = 1;
  int userBalance = 0; // ইউজারের আসল ডাইমন্ড
  int betAmount = 100; // ডিফল্ট বেট ১০০
  String resultMessage = ""; // Win/Lose টেক্সট

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

  // রিয়েল টাইম ব্যালেন্স আপডেট
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

  // সাউন্ড সিস্টেম
  void _playSound(String soundPath) async {
    await _audioPlayer.play(AssetSource('sounds/$soundPath'));
  }

  // লাকি স্পিন টাইমার
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

  // স্পিন লজিক
  Future<void> _performSpin() async {
    if (isSpinning) return;
    _playSound("spin_start.mp3");
    setState(() {
      isSpinning = true;
      resultMessage = "";
    });

    int winIdx = Random().nextInt(wheelSegments.length);
    var winResult = wheelSegments[winIdx];
    double targetRot = (2 * pi * 5) + (winResult['deg'] * pi / 180);
    setState(() => _rotationAngle += targetRot);

    Future.delayed(const Duration(seconds: 3), () async {
      final myId = FirebaseAuth.instance.currentUser?.uid;
      int totalWin = 0;
      bool won = false;

      // ইউজার একাধিক ঘরে বেট ধরলে চেক করা
      for (var bet in luckyBets) {
        if (bet['id'] == myId && bet['slot'] == winResult['label']) {
          won = true;
          totalWin += (bet['amount'] as int) * (winResult['mult'] as int);
        }
      }

      if (won) {
        _playSound("win_sound.mp3");
        setState(() => resultMessage = "WINNER! 💎$totalWin");
        await _userRef.update({"diamonds": userBalance + totalWin}); // টাকা যোগ
      } else if (luckyBets.any((b) => b['id'] == myId)) {
        _playSound("lose_sound.mp3");
        setState(() => resultMessage = "LOST!");
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
              _buildTopBar(),
              _buildGameSelector(),
              Expanded(child: activeGame == "LUDO" ? _buildLudoView() : _buildLuckyView()),
            ],
          ),
          // ক্লোজ বাটন
          Positioned(
            top: 15, right: 15,
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.white70, size: 30),
              onPressed: () {
                if (activeGame == "LUDO" && players.length > 0) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("গেম শেষ না হওয়া পর্যন্ত বন্ধ করা যাবে না!")));
                   return;
                }
                Navigator.pop(context);
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.diamond, color: Colors.cyanAccent, size: 20),
                const SizedBox(width: 5),
                Text("$userBalance", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          if (activeGame == "LUCKY") _buildBetController(),
        ],
      ),
    );
  }

  Widget _buildBetController() {
    return Row(
      children: [
        IconButton(onPressed: () => setState(() => betAmount = max(100, betAmount - 100)), icon: const Icon(Icons.remove_circle, color: Colors.red)),
        Text("$betAmount", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(onPressed: () => setState(() => betAmount += 100), icon: const Icon(Icons.add_circle, color: Colors.green)),
      ],
    );
  }

  Widget _buildLuckyView() {
    return Column(
      children: [
        if (resultMessage.isNotEmpty)
          Text(resultMessage, style: TextStyle(color: resultMessage.contains("WIN") ? Colors.green : Colors.red, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedRotation(
              turns: _rotationAngle / (2 * pi),
              duration: const Duration(seconds: 3),
              curve: Curves.easeOutCubic,
              child: Image.asset("assets/images/lucky_wheel.png", width: 200),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.red, size: 40),
            CircleAvatar(backgroundColor: Colors.black54, radius: 20, child: Text("$_countdown", style: const TextStyle(color: Colors.white))),
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
            _playSound("bet_click.mp3");
            await _userRef.update({"diamonds": userBalance - betAmount}); // রিয়েল টাইম মাইনাস
            await _gameRef.child("luckyBets").push().set({
              "id": FirebaseAuth.instance.currentUser?.uid,
              "name": FirebaseAuth.instance.currentUser?.displayName,
              "slot": slot,
              "amount": betAmount
            });
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(border: Border.all(color: Colors.cyanAccent), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(slot, style: const TextStyle(color: Colors.white))),
          ),
        );
      },
    );
  }

  Widget _buildLudoView() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => isFullScreen = true),
          child: Container(
            width: isFullScreen ? 350 : 220,
            height: isFullScreen ? 350 : 220,
            decoration: const BoxDecoration(image: DecorationImage(image: AssetImage("assets/images/ludo_preview.png"))),
            child: _buildLudoBoardDesign(),
          ),
        ),
        const SizedBox(height: 20),
        if (widget.isAdmin) _buildDiceButton(),
      ],
    );
  }

  Widget _buildLudoBoardDesign() {
     // ৪ কোণায় প্লেয়ারদের ছবি বসানোর লজিক
     return Stack(
       children: List.generate(players.length, (i) {
         double t = (i == 0 || i == 1) ? 30.0 : 250.0;
         double l = (i == 0 || i == 2) ? 30.0 : 250.0;
         return Positioned(
           top: isFullScreen ? t * 1.5 : t,
           left: isFullScreen ? l * 1.5 : l,
           child: CircleAvatar(backgroundImage: NetworkImage(players[i]['photo'] ?? ""), radius: 25),
         );
       }),
     );
  }

  Widget _buildDiceButton() {
     return InkWell(
       onTap: () {
         _playSound("dice_roll.mp3");
         int nextDice = Random().nextInt(6) + 1;
         _gameRef.update({"diceNumber": nextDice});
       },
       child: Icon(diceIcons[diceNumber - 1], size: 80, color: Colors.white),
     );
  }

  final List<IconData> diceIcons = [Icons.looks_one, Icons.looks_two, Icons.looks_3, Icons.looks_4, Icons.looks_5, Icons.looks_6];

  Widget _buildGameSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ["LUDO", "LUCKY"].map((g) => TextButton(onPressed: () => _gameRef.update({"type": g}), child: Text(g))).toList(),
    );
  }
}
