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
  List<Map<dynamic, dynamic>> topWinners = [];

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

  // রিয়েল টাইম উইনার লিস্ট লোড
  void _listenToWinners() {
    widget.gameRef.child("luckyWinners").limitToLast(10).onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map;
        List<Map<dynamic, dynamic>> tempList = [];
        data.forEach((key, value) => tempList.add(value));
        tempList.sort((a, b) => (b['amount'] as int).compareTo(a['amount'] as int));
        setState(() => topWinners = tempList);
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isSpinning) {
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
    
    // স্পিন শুরু সাউন্ড
    widget.playSound("https://www.soundjay.com/misc/sounds/mechanical-clanking-1.mp3");
    
    setState(() { isSpinning = true; winLoseStatus = ""; });

    int winIdx = Random().nextInt(wheelSegments.length);
    var winResult = wheelSegments[winIdx];
    double targetRot = (2 * pi * 8) + ((360 - winResult['deg']) * pi / 180);
    setState(() => _rotationAngle += targetRot);

    Future.delayed(const Duration(seconds: 4), () async {
      final user = FirebaseAuth.instance.currentUser;
      final myId = user?.uid;
      final myName = user?.displayName ?? "User";
      int totalWin = 0;
      bool won = false;

      for (var bet in widget.luckyBets) {
        if (bet['id'] == myId && bet['slot'] == winResult['label']) {
          won = true;
          totalWin += (int.parse(bet['amount'].toString())) * (winResult['mult'] as int);
        }
      }

      if (won) {
        // উইন সাউন্ড
        widget.playSound("https://www.soundjay.com/human/sounds/applause-01.mp3");
        setState(() => winLoseStatus = "🎉 WIN! +💎$totalWin");
        await widget.userRef.update({"diamonds": widget.userBalance + totalWin});
        
        // উইনার লিডবোর্ড আপডেট
        await widget.gameRef.child("luckyWinners").push().set({
          "name": myName,
          "amount": totalWin,
        });
      } else if (widget.luckyBets.any((b) => b['id'] == myId)) {
        // লস সাউন্ড
        widget.playSound("https://www.soundjay.com/buttons/sounds/button-10.mp3");
        setState(() => winLoseStatus = "❌ LOSE!");
      }

      await widget.gameRef.child("luckyBets").remove();
      if (mounted) setState(() => isSpinning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    double wheelSize = MediaQuery.of(context).size.width * 0.7; // স্কিন বড় করা হয়েছে

    return SingleChildScrollView(
      child: Column(
        children: [
          if (winLoseStatus.isNotEmpty)
            Text(winLoseStatus, style: const TextStyle(color: Colors.yellowAccent, fontSize: 22, fontWeight: FontWeight.bold)),
          
          const SizedBox(height: 10),
          
          // হুইল সেকশন
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
                      child: Image.asset("assets/images/lucky_wheel.png", width: wheelSize),
                    ),
                    CircleAvatar(
                      radius: 28, 
                      backgroundColor: Colors.black, 
                      child: Text("$_countdown", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.red, size: 55), 
            ],
          ),

          const SizedBox(height: 20),
          
          // ৬টি টপিক বেইট গ্রিড
          _buildBetGrid(),

          const SizedBox(height: 25),

          // টপ ১০ উইনার লিস্ট
          _buildTopWinners(),
        ],
      ),
    );
  }

  Widget _buildBetGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, 
        childAspectRatio: 1.8, 
        crossAxisSpacing: 10, 
        mainAxisSpacing: 10
      ),
      itemCount: wheelSegments.length,
      itemBuilder: (context, index) {
        String slot = wheelSegments[index]['label'];
        
        // রিয়েল টাইম এই স্লটে কতজন বেইট ধরেছে
        int betCount = widget.luckyBets.where((b) => b['slot'] == slot).length;

        return GestureDetector(
          onTap: () async {
            if (widget.userBalance < widget.betAmount || isSpinning || _countdown < 2) return;
            
            // বেইট সাউন্ড
            widget.playSound("https://www.soundjay.com/buttons/sounds/button-3.mp3");

            // রিয়েল টাইম ডায়মন্ড কাটা
            await widget.userRef.update({"diamonds": widget.userBalance - widget.betAmount});
            
            await widget.gameRef.child("luckyBets").push().set({
              "id": FirebaseAuth.instance.currentUser?.uid,
              "name": FirebaseAuth.instance.currentUser?.displayName ?? "User",
              "slot": slot,
              "amount": widget.betAmount
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white10, 
              border: Border.all(color: wheelSegments[index]['color'], width: 1.5), 
              borderRadius: BorderRadius.circular(12)
            ),
            child: Stack(
              children: [
                Center(
                  child: Text("$slot\n${wheelSegments[index]['mult']}x", 
                    textAlign: TextAlign.center, 
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                // কতজন ইউজার এইটাতে বেইট ধরেছে
                Positioned(
                  top: 4, right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                    child: Text("$betCount", style: const TextStyle(color: Colors.white, fontSize: 9)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopWinners() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          const Text("🏆 TOP 10 WINNERS", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24),
          if (topWinners.isEmpty) const Text("No winners yet", style: TextStyle(color: Colors.white54, fontSize: 12)),
          ...topWinners.map((winner) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(winner['name'] ?? "User", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text("+💎${winner['amount']}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
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
