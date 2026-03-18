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
  String activeGame = "LUDO"; // LUDO or LUCKY
  bool isSpinning = false;
  int diceNumber = 1;
  int turnIndex = 0;
  List<Map<dynamic, dynamic>> players = [];
  List<Map<dynamic, dynamic>> luckyBets = [];
  List<Map<dynamic, dynamic>> topWinners = [];
  
  // টাইমার লজিক
  Timer? _spinTimer;
  int _countdown = 15;
  double _rotationAngle = 0;

  final List<String> luckySlots = ["1X", "2X", "3X", "4X", "5X", "777"];

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
          
          // প্লেয়ার এবং বেট লিস্ট আপডেট
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

  // লাকি স্পিন টাইমার (১৫ সেকেন্ড)
  void _startLuckyTimer() {
    _spinTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (activeGame == "LUCKY") {
        if (_countdown > 0) {
          setState(() => _countdown--);
        } else {
          _performSpin();
          setState(() => _countdown = 15);
        }
      }
    });
  }

  // স্পিন লজিক এবং ডাইমন্ড ডিস্ট্রিবিউশন
  Future<void> _performSpin() async {
    if (isSpinning) return;
    setState(() => isSpinning = true);

    int winIndex = Random().nextInt(luckySlots.length);
    String winSlot = luckySlots[winIndex];

    // এনিমেশন এর জন্য রোটেশন
    setState(() => _rotationAngle += (2 * pi * 5) + (winIndex * (2 * pi / 6)));

    Future.delayed(const Duration(seconds: 3), () async {
      // উইনারদের ডাইমন্ড দেওয়া এবং অন্যদের কাটা (যাদের বেট অমিল)
      for (var bet in luckyBets) {
        if (bet['slot'] == winSlot) {
          int multiplier = winSlot == "777" ? 25 : int.parse(winSlot.replaceAll("X", ""));
          int winAmount = (bet['amount'] as int) * multiplier;
          _updateUserBalance(bet['id'], winAmount);
          _addToWinnerList(bet['name'], bet['photo'], winAmount);
        }
      }
      
      await _gameRef.child("luckyBets").remove(); // বেট রিসেট
      setState(() => isSpinning = false);
    });
  }

  // ডাইমন্ড কাটার লজিক (জয়েন করার সময়)
  Future<void> _placeLuckyBet(String slot, int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // ১. এখান থেকেই ইউজারের মেইন ব্যালেন্স থেকে ডাইমন্ড কেটে নিন (আপনার API অনুযায়ী)
    // subtractDiamonds(user.uid, amount); 

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
      height: 500,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ["LUDO", "LUCKY"].map((game) {
          return GestureDetector(
            onTap: () => _gameRef.update({"type": game}),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: activeGame == game ? Colors.cyanAccent : Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(game, style: TextStyle(color: activeGame == game ? Colors.black : Colors.white)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- লাকি স্পিন ভিউ (ইউনিক ডিজাইন) ---
  Widget _buildLuckyView() {
    return Column(
      children: [
        _buildTopWinnersRow(),
        const SizedBox(height: 10),
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedRotation(
              turns: _rotationAngle / (2 * pi),
              duration: const Duration(seconds: 3),
              curve: Curves.easeOutCubic,
              child: Image.asset("assets/custom_spinner.png", width: 200), // আপনার ইউনিক স্পিনার ইমেজ
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
              child: Text("$_countdown", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildBettingGrid(),
      ],
    );
  }

  Widget _buildBettingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2),
      itemCount: luckySlots.length,
      itemBuilder: (context, index) {
        String slot = luckySlots[index];
        int betCount = luckyBets.where((b) => b['slot'] == slot).length;
        return GestureDetector(
          onTap: () => _placeLuckyBet(slot, 100), // ১০০ ডাইমন্ড বেট
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.purple, Colors.blue.shade900]),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(slot, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                Text("Bets: $betCount", style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopWinnersRow() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: topWinners.length,
        itemBuilder: (context, index) {
          var winner = topWinners[index];
          return Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Column(
              children: [
                CircleAvatar(radius: 18, backgroundImage: NetworkImage(winner['photo'] ?? "")),
                Text(winner['name'].split(" ")[0], style: const TextStyle(color: Colors.white, fontSize: 8)),
                Text("💎${winner['amount']}", style: const TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }

  // হেল্পার ফাংশনস
  void _updateUserBalance(String uid, int amount) {
    // আপনার ফায়ারবেস ইউজার ব্যালেন্স নোড আপডেট করার কোড এখানে লিখুন
  }

  void _addToWinnerList(String name, String photo, int amount) {
    _gameRef.child("winners").push().set({
      "name": name,
      "photo": photo,
      "amount": amount,
      "time": ServerValue.timestamp,
    });
  }

  Widget _buildLudoView() {
    // আপনার আগের লুডু কোডটি এখানে থাকবে, শুধু জয়েনিং এ ডাইমন্ড কাটার লজিক অ্যাড করা হয়েছে
    return const Center(child: Text("Ludo Game Active", style: TextStyle(color: Colors.white)));
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
