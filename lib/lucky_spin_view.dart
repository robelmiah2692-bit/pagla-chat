import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomWheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> segments;
  final List<int> userBetIndices; // ইনডেক্স নম্বর দিয়ে ট্র্যাক করব

  CustomWheelPainter(this.segments, this.userBetIndices);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final List<String> icons = ["7️⃣7️⃣7️⃣", "🍇", "🍎", "🍑", "🍓", "🍉"];

    for (int i = 0; i < segments.length; i++) {
      paint.color = segments[i]['color'];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          i * (pi / 3), pi / 3, true, paint);

      final textPainter = TextPainter(
        text: TextSpan(
            text: icons[i], style: TextStyle(fontSize: (i == 0) ? 30 : 45)),
        textDirection: TextDirection.ltr,
      )..layout();

      final angle = i * (pi / 3) + (pi / 6);
      final offset = Offset(
        center.dx + (radius * 0.50) * cos(angle) - textPainter.width / 2,
        center.dy + (radius * 0.50) * sin(angle) - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);

      // মাল্টিপ্লায়ার দেখার লজিক: ইনডেক্স চেক করে
      if (userBetIndices.contains(i)) {
        final multPainter = TextPainter(
          text: TextSpan(
              text: "${segments[i]['mult']}x",
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        )..layout();

        final multOffset = Offset(
          center.dx + (radius * 0.25) * cos(angle) - multPainter.width / 2,
          center.dy + (radius * 0.25) * sin(angle) - multPainter.height / 2,
        );
        multPainter.paint(canvas, multOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomWheelPainter oldDelegate) => true;
}

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
  Map<String, int> betMultipliers =
      {}; // এটি ট্র্যাক করবে কোন স্লটে কত মাল্টিপ্লায়ার ইউজার ধরেছে
  // আগেরটি মুছে এটি দিন:
  List<int> userBetIndices = [];

  // [আপনার দেওয়া মূল লিস্ট, এখানে হাত দেওয়া হয়নি]
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

  Future<void> _updateUserDiamonds(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final collection = FirebaseFirestore.instance.collection('users');
      QuerySnapshot? query =
          await collection.where('authUID', isEqualTo: user.uid).limit(1).get();
      if (query.docs.isEmpty)
        query =
            await collection.where('uID', isEqualTo: user.uid).limit(1).get();
      if (query.docs.isEmpty && user.email != null)
        query = await collection
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

      if (query.docs.isNotEmpty) {
        await collection
            .doc(query.docs.first.id)
            .update({'diamonds': FieldValue.increment(amount)});
      } else {
        await collection
            .doc(user.uid)
            .update({'diamonds': FieldValue.increment(amount)});
      }
    } catch (e) {
      debugPrint("Diamond Update Error: $e");
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (!isSpinning) {
          if (_countdown > 0) {
            setState(() => _countdown--);
            
          } else {
            
            _performSpin();
          }
        }
      }
    });
  }

Future<void> _performSpin() async {
  if (isSpinning) return;

  setState(() {
    isSpinning = true;
    winLoseStatus = "Spinning...";
  });

  widget.playSound("https://github.com/robelmiah2692-bit/vip-badges/raw/refs/heads/main/officialall/spin_sound.mp3.mp3");

  // ১. টার্গেট ইনডেক্স নির্ধারণ
  int winIdx;
  if (userBetIndices.isNotEmpty) {
    winIdx = userBetIndices.first; // ইউজারের প্রথম বেট করা আইকন
  } else {
    winIdx = Random().nextInt(wheelSegments.length);
  }
  debugPrint("DEBUG: টার্গেট ইনডেক্স: $winIdx");

  // ২. অ্যাঙ্গেল ক্যালকুলেশন (সবচেয়ে গুরুত্বপূর্ণ অংশ)
  // প্রতিটা সেগমেন্ট ৬০ ডিগ্রি। 
  double slice = 360 / wheelSegments.length;
  
  // ক্যালকুলেশন: চাকার বর্তমান পজিশন থেকে টার্গেট ইনডেক্সে নিয়ে যাওয়া
  // (winIdx * slice) আমাদের টার্গেট অ্যাঙ্গেল। 
  // +30 বা +90 যোগ করে অ্যারোর সাথে সিঙ্ক করুন।
  double targetAngle = (winIdx * slice) + 30; // এখানে +30 বা +90 বসিয়ে মিলান
  double targetRot = _rotationAngle + (360 * 5) + (360 - (targetAngle % 360));
  
  setState(() => _rotationAngle = targetRot);

  await Future.delayed(const Duration(seconds: 4));
  if (!mounted) return;

  // ৩. রেজাল্ট লজিক
  if (userBetIndices.contains(winIdx)) {
    int multiplier = int.tryParse(wheelSegments[winIdx]['mult'].toString()) ?? 0;
    int totalWin = widget.betAmount * multiplier;
    
    widget.playSound("https://github.com/robelmiah2692-bit/vip-badges/raw/refs/heads/main/officialall/winlucy.mp3");
    setState(() => winLoseStatus = "🎉 WIN! +💎$totalWin");
    await _updateUserDiamonds(totalWin);
  } else {
    widget.playSound("https://github.com/robelmiah2692-bit/vip-badges/raw/refs/heads/main/officialall/lose.mp3");
    setState(() => winLoseStatus = "❌ LOSE!");
  }

  await Future.delayed(const Duration(seconds: 2));
  await widget.gameRef.child("luckyBets").remove();
  
  setState(() {
    _countdown = 15;
    winLoseStatus = "";
    isSpinning = false;
    userBetIndices.clear();
  });
}
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                winLoseStatus.isEmpty
                    ? "Spinning in: $_countdown"
                    : winLoseStatus,
                style: const TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),

            // [চাকার নতুন ডিজাইন লজিক]
            Stack(
              alignment: Alignment.topCenter,
              children: [
                AnimatedRotation(
                  turns: _rotationAngle / (2 * pi),
                  duration: const Duration(seconds: 4),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    width: constraints.maxWidth * 0.65,
                    height: constraints.maxWidth * 0.65,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: CustomPaint(
                      painter:
                          CustomWheelPainter(wheelSegments, userBetIndices),
                    ),
                  ),
                ),
                const Positioned(
                    top: 0,
                    child: Icon(Icons.arrow_drop_down,
                        color: Colors.red, size: 55)),
              ],
            ),
            const SizedBox(height: 20),
            _buildBetGrid(constraints.maxWidth),
            const SizedBox(height: 20),
            _buildTopWinners(),
            const SizedBox(height: 30),
          ],
        ),
      );
    });
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
          mainAxisSpacing: 10),
      itemBuilder: (context, index) {
        String slot = wheelSegments[index]['label'];
        int mult = wheelSegments[index]['mult'] as int;

        // ইউজার কি এই স্লটে বেট ধরেছে?
        bool isSelected = widget.luckyBets
            .any((b) => b['id'] == currentuID && b['slot'] == slot);

        return GestureDetector(
          onTap: () async {
            if (currentuID == null ||
                widget.userBalance < widget.betAmount ||
                isSpinning ||
                _countdown < 2) return;

            setState(() {
              betMultipliers[slot] = mult; // মাল্টিপ্লায়ার সেট হলো
              if (!userBetIndices.contains(index)) {
                userBetIndices.add(index); // এখানে ইনডেক্স সেভ করছেন
              }
            });

            widget.playSound(
                "https://www.soundjay.com/buttons/sounds/button-3.mp3");
            await _updateUserDiamonds(-widget.betAmount);
            await widget.gameRef.child("luckyBets").push().set({
              "id": currentuID,
              "slot": slot,
              "amount": widget.betAmount,
              "time": ServerValue.timestamp,
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.white.withOpacity(0.05),
              border: Border.all(
                  color: wheelSegments[index]['color'].withOpacity(0.6),
                  width: 1.5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(slot,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    Text("${mult}x",
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10)),
                  ],
                ),
                // [নতুন ফিচার: ক্লিক করলে উপরে মাল্টিপ্লায়ার দেখাবে]
                if (isSelected && betMultipliers.containsKey(slot))
                  Positioned(
                    top: 2,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(5)),
                      child: Text("${betMultipliers[slot]}x",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
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
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Text("TOP 10 WINNERS",
              style: TextStyle(
                  color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
          ...topWinnersList.map((w) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(w['name'] ?? "User",
                        style: const TextStyle(color: Colors.white70)),
                    Text("+💎${w['amount']}",
                        style: const TextStyle(color: Colors.greenAccent)),
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
