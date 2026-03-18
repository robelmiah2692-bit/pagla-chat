import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GamePanelView extends StatefulWidget {
  final String roomId;
  const GamePanelView({super.key, required this.roomId});

  @override
  State<GamePanelView> createState() => _GamePanelViewState();
}

class _GamePanelViewState extends State<GamePanelView> {
  late DatabaseReference _gameRef;
  StreamSubscription? _subscription;

  // গেম স্টেট
  String activeGame = "LUDO"; 
  bool isSpinning = false;
  int diceNumber = 1;
  int turnIndex = 0;
  List<Map<dynamic, dynamic>> players = [];
  List<Map<dynamic, dynamic>> luckyBets = [];
  List<Map<dynamic, dynamic>> topWinners = [];
  
  // টাইমার ও এনিমেশন লজিক
  Timer? _spinTimer;
  int _countdown = 15;
  double _rotationAngle = 0;

  // আপনার ডিজাইনের ৬টি ঘর এবং তাদের গুণিতক
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
    _gameRef = FirebaseDatabase.instance.ref("games/${widget.roomId}");
    _listenToData();
    _startLuckyTimer();
  }

  void _listenToData() {
    _subscription = _gameRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;
      if (mounted) {
        setState(() {
          activeGame = data['type'] ?? "LUDO";
          turnIndex = data['turnIndex'] ?? 0;
          diceNumber = data['diceNumber'] ?? 1;
          
          if (data['players'] != null) {
            players = (data['players'] as Map).values.map((e) => e as Map).toList();
          }
          if (data['luckyBets'] != null) {
            luckyBets = (data['luckyBets'] as Map).values.map((e) => e as Map).toList();
          }
          if (data['winners'] != null) {
            topWinners = (data['winners'] as Map).values.map((e) => e as Map).toList();
            topWinners.sort((a, b) => (b['amount'] as int).compareTo(a['amount'] as int));
          }
        });
      }
    });
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
    setState(() => isSpinning = true);

    // রেন্ডম উইনার ঘর সিলেক্ট
    int randomIndex = Random().nextInt(wheelSegments.length);
    var winResult = wheelSegments[randomIndex];

    // রোটেশন ক্যালকুলেশন (৫ বার ঘুরে নির্দিষ্ট ডিগ্রিতে থামবে)
    double targetRotation = (2 * pi * 5) + (winResult['deg'] * pi / 180);
    setState(() => _rotationAngle += targetRotation);

    Future.delayed(const Duration(seconds: 3), () async {
      // উইনার লজিক: যাদের বেট মিলেছে তাদের ডাইমন্ড দেওয়া
      for (var bet in luckyBets) {
        if (bet['slot'] == winResult['label']) {
          int winAmount = (bet['amount'] as int) * (winResult['mult'] as int);
          _updateUserBalance(bet['id'], winAmount);
          _addToWinnerList(bet['name'], bet['photo'], winAmount);
        }
      }
      
      await _gameRef.child("luckyBets").remove(); 
      setState(() => isSpinning = false);
    });
  }

  Future<void> _placeLuckyBet(String slot, int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // জয়েন করার সাথে সাথে ডাইমন্ড কেটে নেওয়ার লজিক এখানে কল হবে
    // _deductDiamonds(user.uid, amount);

    await _gameRef.child("luckyBets").child(user.uid).set({
      "id": user.uid,
      "name": user.displayName,
      "photo": user.photoURL,
      "slot": slot,
      "amount": amount,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 550,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          _buildGameSelector(),
          Expanded(
            child: activeGame == "LUDO" ? _buildLudoView() : _buildLuckyView(),
          ),
        ],
      ),
    );
  }

  Widget _buildGameSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ["LUDO", "LUCKY"].map((game) {
          bool isSelected = activeGame == game;
          return GestureDetector(
            onTap: () => _gameRef.update({"type": game}),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.cyanAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(game, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLuckyView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTopWinnersRow(),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.topCenter,
            children: [
              // আপনার ডিজাইন করা হুইল
              AnimatedRotation(
                turns: _rotationAngle / (2 * pi),
                duration: const Duration(seconds: 3),
                curve: Curves.easeOutCubic,
                child: Image.asset("assets/images/lucky_wheel.png", width: 220),
              ),
              // পিন বা নিডল
              const Icon(Icons.location_on, color: Colors.redAccent, size: 40),
              // মাঝখানে টাইমার
              Positioned(
                top: 90,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: Text("$_countdown", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBettingGrid(),
        ],
      ),
    );
  }

  Widget _buildBettingGrid() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.2, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: wheelSegments.length,
        itemBuilder: (context, index) {
          var segment = wheelSegments[index];
          int totalBets = luckyBets.where((b) => b['slot'] == segment['label']).length;
          return GestureDetector(
            onTap: () => _placeLuckyBet(segment['label'], 100),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blueGrey.shade900, Colors.black]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${segment['label']} (${segment['mult']}x)", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("Users: $totalBets", style: const TextStyle(color: Colors.white60, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopWinnersRow() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: topWinners.length,
        itemBuilder: (context, index) {
          var winner = topWinners[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                CircleAvatar(radius: 20, backgroundImage: NetworkImage(winner['photo'] ?? "")),
                Text("💎 ${winner['amount']}", style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- লুডু ভিউ (আগের লজিক ঠিক রেখে) ---
  Widget _buildLudoView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("LUDO MULTIPLAYER", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            // লুডু রোল ডাইস লজিক
          },
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Icon(diceIcons[diceNumber-1], size: 50, color: Colors.black),
          ),
        ),
      ],
    );
  }

  final List<IconData> diceIcons = [Icons.looks_one, Icons.looks_two, Icons.looks_3, Icons.looks_4, Icons.looks_5, Icons.looks_6];

  void _updateUserBalance(String uid, int amount) {
    // এখানে উইনারের একাউন্টে ডাইমন্ড যোগ করার API কল করবেন
  }

  void _addToWinnerList(String name, String photo, int amount) {
    _gameRef.child("winners").push().set({
      "name": name, "photo": photo, "amount": amount, "time": ServerValue.timestamp,
    });
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
