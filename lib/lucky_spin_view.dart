import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomWheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> segments;
  final List<String> userBetSlots;

  CustomWheelPainter(this.segments, this.userBetSlots);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final List<String> icons = ["7️⃣7️⃣7️⃣", "🍇", "🍎", "🍑", "🍓", "🍉"];
    double sweepAngle = 2 * pi / segments.length;

    // ঘড়ির কাঁটার বিপরীতে (Counter-clockwise) সাজানো যাতে টপ পয়েন্টারের সাথে নিখুঁত মিলে যায়
    for (int i = 0; i < segments.length; i++) {
      paint.color = segments[i]['color'];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        (i * sweepAngle) - (pi / 2) - (sweepAngle / 2),
        sweepAngle,
        true,
        paint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
            text: icons[i], style: TextStyle(fontSize: (i == 0) ? 28 : 40)),
        textDirection: TextDirection.ltr,
      )..layout();

      final angle = (i * sweepAngle) - (pi / 2);
      final offset = Offset(
        center.dx + (radius * 0.55) * cos(angle) - textPainter.width / 2,
        center.dy + (radius * 0.55) * sin(angle) - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);

      String slotLabel = segments[i]['label'];
      if (userBetSlots.contains(slotLabel)) {
        final multPainter = TextPainter(
          text: TextSpan(
              text: "${segments[i]['mult']}x",
              style: const TextStyle(
                  fontSize: 16,
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

class _LuckySpinViewState extends State<LuckySpinView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentAngle = 0;

  int _countdown = 15;
  bool isSpinning = false;
  String winLoseStatus = "";
  StreamSubscription? _winnersSubscription;
  Timer? _timer;
  List<Map<dynamic, dynamic>> topWinnersList = [];
  Map<String, int> betMultipliers = {};
  List<String> userBetSlots = [];

  final List<Map<String, dynamic>> wheelSegments = [
    {"label": "777", "mult": 25, "color": Colors.amber},
    {"label": "Grapes", "mult": 2, "color": Colors.purple},
    {"label": "Apple", "mult": 3, "color": Colors.red},
    {"label": "Plum", "mult": 4, "color": Colors.indigo},
    {"label": "Strawberry", "mult": 5, "color": Colors.pink},
    {"label": "Watermelon", "mult": 1, "color": Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);

    _startTimer();
    _listenToWinners();
  }

  void _listenToWinners() {
    _winnersSubscription =
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
      if (query.docs.isEmpty) {
        query = await collection.where('uID', isEqualTo: user.uid).limit(1).get();
      }
      if (query.docs.isEmpty && user.email != null) {
        query = await collection
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();
      }

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

    widget.playSound(
        "https://github.com/robelmiah2692-bit/vip-badges/raw/refs/heads/main/officialall/spin_sound.mp3.mp3");

    final random = Random();

    // বেট অ্যানালাইসিস এবং হাউস প্রটেকশন লজিক
    Map<String, int> slotTotalBets = {};
    for (var segment in wheelSegments) {
      slotTotalBets[segment['label']] = 0;
    }

    for (var bet in widget.luckyBets) {
      String slot = bet['slot'] ?? '';
      int amount = bet['amount'] ?? 0;
      if (slotTotalBets.containsKey(slot)) {
        slotTotalBets[slot] = slotTotalBets[slot]! + amount;
      }
    }

    String? highestBetSlot;
    int maxBetAmount = -1;
    slotTotalBets.forEach((slot, totalAmount) {
      if (totalAmount > maxBetAmount) {
        maxBetAmount = totalAmount;
        highestBetSlot = slot;
      }
    });

    List<int> safeIndices = [];
    for (int i = 0; i < wheelSegments.length; i++) {
      if (wheelSegments[i]['label'] != highestBetSlot) {
        safeIndices.add(i);
      }
    }

    if (safeIndices.isEmpty) {
      safeIndices = List.generate(wheelSegments.length, (i) => i);
    }

    int winIdx;
    bool allow777 = random.nextInt(100) < 5;
    List<int> preferredIndices = safeIndices.where((i) {
      if (wheelSegments[i]['label'] == "777" && !allow777) return false;
      return true;
    }).toList();

    if (preferredIndices.isNotEmpty) {
      winIdx = preferredIndices[random.nextInt(preferredIndices.length)];
    } else {
      winIdx = safeIndices[random.nextInt(safeIndices.length)];
    }

    String winningSlotLabel = wheelSegments[winIdx]['label'];
    debugPrint("DEBUG: Winning Slot -> $winningSlotLabel (Index: $winIdx)");

    // নিখুঁত অ্যাঙ্গেল ক্যালকুলেশন
    double totalSlices = wheelSegments.length.toDouble();
    double degreesPerSlice = 360 / totalSlices;

    // কাঙ্ক্ষিত ইনডেক্সটি পয়েন্টারের নিচে ফিক্সড করার ম্যাথমেটিক্যাল হিসাব
    double targetAngle = 360 - (winIdx * degreesPerSlice);
    double fullRotations = 360 * 8; // ৮ বার ফুল রোটেট করবে
    double finalTargetAngle = _currentAngle + fullRotations + (targetAngle - (_currentAngle % 360));

    _animation = Tween<double>(begin: _currentAngle, end: finalTargetAngle)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.reset();
    await _controller.forward();
    _currentAngle = finalTargetAngle;

    if (!mounted) return;

    final currentuID = FirebaseAuth.instance.currentUser?.uid;
    bool userWon = widget.luckyBets
        .any((b) => b['id'] == currentuID && b['slot'] == winningSlotLabel);

    if (userWon) {
      int multiplier =
          int.tryParse(wheelSegments[winIdx]['mult'].toString()) ?? 0;
      int totalWin = widget.betAmount * multiplier;

      widget.playSound(
          "https://github.com/robelmiah2692-bit/vip-badges/raw/refs/heads/main/officialall/winlucy.mp3");
      setState(() => winLoseStatus = "🎉 WIN! +💎$totalWin");
      await _updateUserDiamonds(totalWin);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await widget.gameRef.child("luckyWinners").push().set({
          "name": user.displayName ?? "User",
          "amount": totalWin,
          "time": ServerValue.timestamp,
        });
      }
    } else {
      widget.playSound(
          "https://github.com/robelmiah2692-bit/vip-badges/raw/refs/heads/main/officialall/lose.mp3");
      setState(() => winLoseStatus = "❌ LOSE!");
    }

    await Future.delayed(const Duration(seconds: 2));
    await widget.gameRef.child("luckyBets").remove();

    setState(() {
      _countdown = 15;
      winLoseStatus = "";
      isSpinning = false;
      userBetSlots.clear();
      betMultipliers.clear();
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
            Stack(
              alignment: Alignment.topCenter,
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: (_animation.value * pi / 180),
                      child: child,
                    );
                  },
                  child: Container(
                    width: constraints.maxWidth * 0.65,
                    height: constraints.maxWidth * 0.65,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: CustomPaint(
                      painter: CustomWheelPainter(wheelSegments, userBetSlots),
                    ),
                  ),
                ),
                const Positioned(
                    top: -2,
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

        bool isSelected = widget.luckyBets
            .any((b) => b['id'] == currentuID && b['slot'] == slot);

        return GestureDetector(
          onTap: () async {
            if (currentuID == null ||
                widget.userBalance < widget.betAmount ||
                isSpinning ||
                _countdown < 2) return;

            setState(() {
              betMultipliers[slot] = mult;
              if (!userBetSlots.contains(slot)) {
                userBetSlots.add(slot);
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
    _winnersSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }
}