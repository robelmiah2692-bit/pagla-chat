import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LuckySpinView extends StatefulWidget {
  final DatabaseReference gameRef;
  final DatabaseReference userRef; // এটি সরাসরি ইউজারের ডায়মন্ড পাথ হওয়া উচিত
  final int userBalance;
  final int betAmount;
  final List<Map<dynamic, dynamic>> luckyBets;
  final Function(String) playSound;

  const LuckySpinView({
    super.key,
    required this.gameRef,
    required this.userRef,
    required this.userBalance,
    required this.betAmount,
    required this.luckyBets,
    required this.playSound,
  });

  @override
  State<LuckySpinView> createState() => _LuckySpinViewState();
}

class _LuckySpinViewState extends State<LuckySpinView> {
  double _rotationAngle = 0;
  int _countdown = 15;
  bool isSpinning = false;
  String winLoseStatus = "";
  Timer? _timer;
  List<Map<dynamic, dynamic>> topWinnersList = [];

  final List<Map<String, dynamic>> wheelSegments = [
    {"label": "777", "mult": 25, "deg": 0, "color": Colors.amber},
    {"label": "Grapes", "mult": 2, "deg": 300, "color": Colors.purple},
    {"label": "Apple", "mult": 3, "deg": 240, "color": Colors.red},
    {"label": "Plum", "mult": 4, "deg": 180, "color": Colors.indigo},
    {"label": "Strawberry", "mult": 5, "deg": 120, "color": Colors.pink},
    {"label": "Watermelon", "mult": 1, "deg": 60, "color": Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _listenToWinners();
  }

  // রিয়েল টাইম উইনার লিস্ট লিসেনার (ফিক্সড)
  void _listenToWinners() {
    widget.gameRef.child("luckyWinners").onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        List<Map<dynamic, dynamic>> tempList = [];
        data.forEach((key, value) {
          tempList.add(Map<dynamic, dynamic>.from(value));
        });
        // লেটেস্ট উইনার আগে দেখাবে
        tempList.sort((a, b) => (b['time'] ?? 0).compareTo(a['time'] ?? 0));
        setState(() {
          topWinnersList = tempList.take(10).toList();
        });
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isSpinning && mounted) {
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
    
    widget.playSound("https://www.soundjay.com/misc/sounds/mechanical-clanking-1.mp3");
    setState(() { isSpinning = true; winLoseStatus = ""; });

    int winIdx = Random().nextInt(wheelSegments.length);
    var winResult = wheelSegments[winIdx];
    
    double targetRot = (2 * pi * 8) + ((360 - winResult['deg']) * pi / 180);
    setState(() => _rotationAngle += targetRot);

    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final myId = FirebaseAuth.instance.currentUser?.uid;
    final myName = FirebaseAuth.instance.currentUser?.displayName ?? "User";
    int totalWin = 0;
    bool hasWon = false;

    // বেইট চেক
    for (var bet in widget.luckyBets) {
      if (bet['id'] == myId && bet['slot'] == winResult['label']) {
        hasWon = true;
        int amt = int.tryParse(bet['amount'].toString()) ?? 0;
        totalWin += amt * (winResult['mult'] as int);
      }
    }

    if (hasWon) {
      widget.playSound("https://www.soundjay.com/human/sounds/applause-01.mp3");
      setState(() => winLoseStatus = "🎉 WIN! +💎$totalWin");
      
      // রিয়েল টাইম ডায়মন্ড যোগ (Realtime DB increment)
      await widget.userRef.child("diamonds").set(ServerValue.increment(totalWin));
      
      // উইনার লিস্টে নাম সেভ
      await widget.gameRef.child("luckyWinners").push().set({
        "name": myName,
        "amount": totalWin,
        "time": ServerValue.timestamp,
      });
    } else if (widget.luckyBets.any((b) => b['id'] == myId)) {
      widget.playSound("https://www.soundjay.com/buttons/sounds/button-10.mp3");
      setState(() => winLoseStatus = "❌ LOSE!");
    }

    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted) {
        await widget.gameRef.child("luckyBets").remove();
        setState(() => isSpinning = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(winLoseStatus.isEmpty ? "Spinning in: $_countdown" : winLoseStatus,
            style: const TextStyle(color: Colors.yellowAccent, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        
        // হুইল ডিজাইন
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 25),
              child: AnimatedRotation(
                turns: _rotationAngle / (2 * pi),
                duration: const Duration(seconds: 4),
                curve: Curves.easeOutCubic,
                child: Image.asset("assets/images/lucky_wheel.png", width: 230),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.red, size: 60), 
          ],
        ),

        const SizedBox(height: 20),
        _buildBetGrid(),
        const SizedBox(height: 20),
        _buildTopWinners(),
      ],
    );
  }

  Widget _buildBetGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 1.8, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: wheelSegments.length,
      itemBuilder: (context, index) {
        String slot = wheelSegments[index]['label'];
        int myBetOnThis = 0;
        for (var b in widget.luckyBets) {
          if (b['id'] == FirebaseAuth.instance.currentUser?.uid && b['slot'] == slot) {
            myBetOnThis += int.tryParse(b['amount'].toString()) ?? 0;
          }
        }

        return GestureDetector(
          onTap: () async {
            if (widget.userBalance < widget.betAmount || isSpinning || _countdown < 2) return;
            widget.playSound("https://www.soundjay.com/buttons/sounds/button-3.mp3");

            // ১. রিয়েল টাইম ডায়মন্ড কাটা (সবচেয়ে গুরুত্বপূর্ণ)
            await widget.userRef.child("diamonds").set(ServerValue.increment(-widget.betAmount));

            // ২. বেইট পুশ করা
            await widget.gameRef.child("luckyBets").push().set({
              "id": FirebaseAuth.instance.currentUser?.uid,
              "slot": slot,
              "amount": widget.betAmount,
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: myBetOnThis > 0 ? Colors.blue.withOpacity(0.2) : Colors.white10,
              border: Border.all(color: wheelSegments[index]['color']),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(slot, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("${wheelSegments[index]['mult']}x", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                if (myBetOnThis > 0)
                  Text("💎$myBetOnThis", style: const TextStyle(color: Colors.cyanAccent, fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopWinners() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          const Text("🏆 TOP 10 WINNERS", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white12),
          if (topWinnersList.isEmpty) const Text("No winners yet", style: TextStyle(color: Colors.white30, fontSize: 12)),
          ...topWinnersList.map((w) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(w['name'] ?? "User", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text("+💎${w['amount']}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
