import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LuckySpinView extends StatefulWidget {
  final DatabaseReference gameRef;
  final DatabaseReference userRef;
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

  final List<Map<String, dynamic>> wheelSegments = [
    {"label": "777", "mult": 25, "deg": 0},
    {"label": "Grapes", "mult": 2, "deg": 300},
    {"label": "Apple", "mult": 3, "deg": 240},
    {"label": "Plum", "mult": 4, "deg": 180},
    {"label": "Strawberry", "mult": 5, "deg": 120},
    {"label": "Watermelon", "mult": 1, "deg": 60},
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isSpinning) {
        if (_countdown > 0) setState(() => _countdown--);
        else { _performSpin(); setState(() => _countdown = 15); }
      }
    });
  }

  Future<void> _performSpin() async {
    if (isSpinning) return;
    widget.playSound("https://www.soundjay.com/misc/sounds/bell-ringing-01.mp3");
    setState(() { isSpinning = true; winLoseStatus = ""; });

    int winIdx = Random().nextInt(wheelSegments.length);
    var winResult = wheelSegments[winIdx];
    double targetRot = (2 * pi * 8) + ((360 - winResult['deg']) * pi / 180);
    setState(() => _rotationAngle += targetRot);

    Future.delayed(const Duration(seconds: 4), () async {
      final myId = FirebaseAuth.instance.currentUser?.uid;
      int totalWin = 0;
      bool won = false;

      for (var bet in widget.luckyBets) {
        if (bet['id'] == myId && bet['slot'] == winResult['label']) {
          won = true;
          totalWin += (int.parse(bet['amount'].toString())) * (winResult['mult'] as int);
        }
      }

      if (won) {
        widget.playSound("https://www.soundjay.com/human/sounds/applause-01.mp3");
        setState(() => winLoseStatus = "🎉 WIN! +💎$totalWin");
        await widget.userRef.update({"diamonds": widget.userBalance + totalWin});
      } else if (widget.luckyBets.any((b) => b['id'] == myId)) {
        widget.playSound("https://www.soundjay.com/buttons/sounds/button-10.mp3");
        setState(() => winLoseStatus = "❌ LOSE!");
      }

      await widget.gameRef.child("luckyBets").remove();
      if(mounted) setState(() => isSpinning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (winLoseStatus.isNotEmpty)
          Text(winLoseStatus, style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 25),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedRotation(
                    turns: _rotationAngle / (2 * pi),
                    duration: const Duration(seconds: 4),
                    curve: Curves.easeOutCubic,
                    child: Image.asset("assets/images/lucky_wheel.png", width: 180),
                  ),
                  CircleAvatar(radius: 20, backgroundColor: Colors.black, child: Text("$_countdown", style: const TextStyle(color: Colors.white))),
                ],
              ),
            ),
            const Icon(Icons.location_on, color: Colors.red, size: 45), 
          ],
        ),
        const SizedBox(height: 15),
        _buildBetGrid(),
      ],
    );
  }

  Widget _buildBetGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.3, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: wheelSegments.length,
      itemBuilder: (context, index) {
        String slot = wheelSegments[index]['label'];
        return GestureDetector(
          onTap: () async {
            if (widget.userBalance < widget.betAmount || isSpinning) return;
            await widget.userRef.update({"diamonds": widget.userBalance - widget.betAmount});
            await widget.gameRef.child("luckyBets").push().set({
              "id": FirebaseAuth.instance.currentUser?.uid,
              "slot": slot,
              "amount": widget.betAmount
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

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
}
