import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  List<Map<dynamic, dynamic>> topWinnersList = [];

 final List<Map<String, dynamic>> wheelSegments = [
  {"label": "777", "mult": 25, "deg": 0, "color": Colors.amber},
  {"label": "Grapes", "mult": 2, "deg": 60, "color": Colors.purple},
  {"label": "Apple", "mult": 3, "deg": 120, "color": Colors.red},
  {"label": "Plum", "mult": 4, "deg": 180, "color": Colors.indigo},
  {"label": "Strawberry", "mult": 5, "deg": 240, "color": Colors.pink},
  {"label": "Watermelon", "mult": 1, "deg": 300, "color": Colors.green},
];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _listenToWinners();
  }

  void _listenToWinners() {
    widget.gameRef.child("luckyWinners").onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        List<Map<dynamic, dynamic>> tempList = [];
        data.forEach((key, value) {
          tempList.add(Map<dynamic, dynamic>.from(value));
        });
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

  // --- আপডেট করা ডায়মন্ড লজিক (Search by email, authUID, uID) ---
  Future<void> _updateUserDiamonds(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final collection = FirebaseFirestore.instance.collection('users');
      QuerySnapshot? query;

      // ১. authUID দিয়ে খোঁজা
      query = await collection.where('authUID', isEqualTo: user.uid).limit(1).get();

      // ২. না পাওয়া গেলে uID দিয়ে খোঁজা
      if (query.docs.isEmpty) {
        query = await collection.where('uID', isEqualTo: user.uid).limit(1).get();
      }

      // ৩. তাও না পাওয়া গেলে email দিয়ে খোঁজা
      if (query.docs.isEmpty && user.email != null) {
        query = await collection.where('email', isEqualTo: user.email).limit(1).get();
      }

      // যদি ডকুমেন্ট পাওয়া যায়, তবে আপডেট করা
      if (query.docs.isNotEmpty) {
        await collection.doc(query.docs.first.id).update({
          'diamonds': FieldValue.increment(amount)
        });
      } else {
        // যদি ওপরের কোনো ফিল্ড না থাকে, সরাসরি doc ID হিসেবে চেক করা (Fallback)
        await collection.doc(user.uid).update({
          'diamonds': FieldValue.increment(amount)
        });
      }
    } catch (e) {
      debugPrint("Diamond Update Error: $e");
    }
  }

  Future<void> _performSpin() async {
    if (isSpinning) return;
    
    widget.playSound("https://www.soundjay.com/misc/sounds/mechanical-clanking-1.mp3");
    setState(() { 
      isSpinning = true; 
      winLoseStatus = ""; 
    });

    // ১. আগে থেকে উইনার ইনডেক্স সিলেক্ট করা
    int winIdx = Random().nextInt(wheelSegments.length);
    var winResult = wheelSegments[winIdx];
    
    // ২. ছবির সাথে মিলানোর ক্যালকুলেশন (আপনার ছবি অনুযায়ী ৭৭৭ থেকে শুরু)
    // চাকাটি ৮ বার পূর্ণ ঘুরবে, তারপর নির্ধারিত ডিগ্রিতে থামবে
    // (360 - deg) লজিকটি ব্যবহার করা হয়েছে যাতে কাঁটাটি সঠিক ছবির ওপর থাকে
    double targetAngle = (360 - winResult['deg']).toDouble();
    double targetRot = (2 * pi * 8) + (targetAngle * pi / 180);
    
    setState(() => _rotationAngle += targetRot);

    // ৪ সেকেন্ড এনিমেশন টাইম
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final myId = FirebaseAuth.instance.currentUser?.uid;
    final myName = FirebaseAuth.instance.currentUser?.displayName ?? "User";
    
    if (myId == null) return;

    int totalWin = 0;
    bool hasWon = false;
    bool hasParticipated = false;

    // ৩. চেক করা ইউজার বেট ধরেছে কি না এবং জিতেছে কি না
    for (var bet in widget.luckyBets) {
      if (bet['id'] == myId) {
        hasParticipated = true;
        if (bet['slot'] == winResult['label']) {
          hasWon = true;
          int amt = int.tryParse(bet['amount'].toString()) ?? 0;
          totalWin += amt * (winResult['mult'] as int);
        }
      }
    }

    // ৪. ফলাফল অনুযায়ী ডায়মন্ড আপডেট
    if (hasWon && totalWin > 0) {
      widget.playSound("https://www.soundjay.com/human/sounds/applause-01.mp3");
      setState(() => winLoseStatus = "🎉 WIN! +💎$totalWin");
      
      // ডায়মন্ড যোগ করা (email, authUID, uID স্মার্ট সার্চের মাধ্যমে)
      await _updateUserDiamonds(totalWin);
      
      // উইনার লিস্টে নাম যোগ করা
      await widget.gameRef.child("luckyWinners").push().set({
        "name": myName,
        "amount": totalWin,
        "time": ServerValue.timestamp,
      });
    } else if (hasParticipated) {
      widget.playSound("https://www.soundjay.com/buttons/sounds/button-10.mp3");
      setState(() => winLoseStatus = "❌ LOSE!");
    }

    // ৫. ক্লিনিং লজিক (গেম শেষে বেট রিমুভ করা)
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted) {
        await widget.gameRef.child("luckyBets").remove();
        setState(() => isSpinning = false);
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Container(
            width: constraints.maxWidth,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    winLoseStatus.isEmpty ? "Spinning in: $_countdown" : winLoseStatus,
                    style: const TextStyle(color: Colors.yellowAccent, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.orangeAccent.withOpacity(0.1), blurRadius: 30, spreadRadius: 5)
                        ]
                      ),
                      child: AnimatedRotation(
                        turns: _rotationAngle / (2 * pi),
                        duration: const Duration(seconds: 4),
                        curve: Curves.easeOutCubic,
                        child: Image.asset("assets/images/lucky_wheel.png", width: constraints.maxWidth * 0.65),
                      ),
                    ),
                    const Positioned(
                      top: 0,
                      child: Icon(Icons.arrow_drop_down, color: Colors.red, size: 55),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                _buildBetGrid(constraints.maxWidth),
                const SizedBox(height: 20),
                _buildTopWinners(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildBetGrid(double width) {
    final currentuID = FirebaseAuth.instance.currentUser?.uid;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: wheelSegments.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, 
        childAspectRatio: 1.6, 
        crossAxisSpacing: 10, 
        mainAxisSpacing: 10
      ),
      itemBuilder: (context, index) {
        String slot = wheelSegments[index]['label'];
        int myBetOnThis = 0;

        for (var b in widget.luckyBets) {
          if (b['id'] == currentuID && b['slot'] == slot) {
            myBetOnThis += int.tryParse(b['amount'].toString()) ?? 0;
          }
        }

        return GestureDetector(
          onTap: () async {
            if (currentuID == null || widget.userBalance < widget.betAmount || isSpinning || _countdown < 2) return;
            
            widget.playSound("https://www.soundjay.com/buttons/sounds/button-3.mp3");
            
            // ডায়মন্ড বিয়োগ করা
            await _updateUserDiamonds(-widget.betAmount);
            
            // Realtime Database-এ বেট জমা দেওয়া
            await widget.gameRef.child("luckyBets").push().set({
              "id": currentuID,
              "slot": slot,
              "amount": widget.betAmount,
              "time": ServerValue.timestamp,
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: myBetOnThis > 0 ? Colors.blue.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              border: Border.all(color: wheelSegments[index]['color'].withOpacity(0.6), width: 1.5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(slot, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text("${wheelSegments[index]['mult']}x", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                if (myBetOnThis > 0)
                  Text("💎$myBetOnThis", style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopWinners() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: Colors.orangeAccent, size: 18),
              SizedBox(width: 8),
              Text("TOP 10 WINNERS", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          if (topWinnersList.isEmpty) 
            const Text("No winners yet", style: TextStyle(color: Colors.white24, fontSize: 12)),
          ...topWinnersList.map((w) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(w['name'] ?? "User", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text("+💎${w['amount']}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
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