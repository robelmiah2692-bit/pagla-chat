import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:pagla_chat/main.dart';

class DonggiBabaGameWidget extends StatefulWidget {
  final String roomId;

  const DonggiBabaGameWidget({Key? key, required this.roomId})
      : super(key: key);

  @override
  _DonggiBabaGameWidgetState createState() => _DonggiBabaGameWidgetState();
}

class _DonggiBabaGameWidgetState extends State<DonggiBabaGameWidget>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AudioPlayer _spinAudioPlayer = AudioPlayer();
  final AudioPlayer _bettingAudioPlayer =
      AudioPlayer(); // ১৫ সেকেন্ড বেটিং সময়ের জন্য আলাদা অডিও প্লেয়ার

  // বেট অপশন এবং মাল্টিপ্লায়ার
  final List<Map<String, dynamic>> betOptions = [
    {'id': 'chicken', 'name': 'Chicken', 'multiplier': 45, 'icon': '🍗'},
    {'id': 'octopus', 'name': 'Octopus', 'multiplier': 25, 'icon': '🐙'},
    {'id': 'shrimp', 'name': 'Shrimp', 'multiplier': 15, 'icon': '🦐'},
    {'id': 'fish', 'name': 'Fish', 'multiplier': 10, 'icon': '🐟'},
    {'id': 'watermelon', 'name': 'Watermelon', 'multiplier': 5, 'icon': '🍉'},
    {'id': 'cabbage', 'name': 'Cabbage', 'multiplier': 5, 'icon': '🥬'},
    {'id': 'carrot', 'name': 'Carrot', 'multiplier': 5, 'icon': '🥕'},
    {'id': 'mushroom', 'name': 'Mushroom', 'multiplier': 5, 'icon': '🍄'},
  ];

  int selectedChip = 1000;
  final List<int> chipValues = [1000, 5000, 10000, 50000];

  late AnimationController _wheelController;
  bool isSpinning = false;
  int userDiamonds = 0;
  bool isSoundOn = true;
  int countdownTimer = 15;
  String lastResultIcon = '🍉';
  List<String> recentResults = ['🥬', '🥕', '🍉', '🐟', '🥕', '🥬', '🐟', '🍉'];

  Timer? _resetTimer;
  Timer? _countdownTimerInstance;
  Map<String, int> myCurrentBets = {};

  // নতুন অ্যানিমেশন ও ইফেক্ট ভেরিয়েবল
  int? scanningIndex;
  String? winningOptionId;
  bool isFlashing = false;

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _fetchUserData();
    _startCountdown();
    _startResultResetTimer();
    _listenMyBets();
  }

  // ৫ মিনিট পর পর রিসেট করার টাইমার
  void _startResultResetTimer() {
    _resetTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        setState(() {
          recentResults.clear();
        });
      }
    });
  }

  // ইউজারের নিজস্ব বেট ট্র্যাক করার জন্য ফায়ারস্টোর লিসেনার
  void _listenMyBets() {
    if (AppData.myID.isEmpty) return;
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('game_bets')
        .doc(AppData.myID)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        var data = snapshot.data() as Map<String, dynamic>?;
        if (data != null) {
          setState(() {
            myCurrentBets = data.map((key, value) => MapEntry(key,
                value is int ? value : int.tryParse(value.toString()) ?? 0));
          });
        }
      } else {
        if (mounted) {
          setState(() {
            myCurrentBets = {};
          });
        }
      }
    });
  }

  // টাইমার এবং গেম লজিক লুপ
  void _startCountdown() {
    _countdownTimerInstance?.cancel();

    // ১৫ সেকেন্ড বেটিং শুরু হওয়ার সময় সাউন্ড প্লে করা (যদি সাউন্ড অন থাকে)
    if (isSoundOn) {
      _playBettingMusic();
    }

    _countdownTimerInstance =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (countdownTimer > 0) {
          countdownTimer--;
        } else {
          timer.cancel();
          // বেটিং সময় শেষ, তাই বেটিং মিউজিক বন্ধ করা হচ্ছে
          _bettingAudioPlayer.stop();
          _executeGameSequence();
        }
      });
    });
  }

  // ১৫ সেকেন্ডের বেটিং মিউজিক প্লে করার মেথড
  Future<void> _playBettingMusic() async {
    try {
      // এখানে আপনার ১৫ সেকেন্ডের বেটিং মিউজিকের গিটার বা ব্যাকগ্রাউন্ড লিংক দিন
      final String bettingSoundUrl =
          'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/dongi3.mp3';

      await _bettingAudioPlayer.setReleaseMode(ReleaseMode.loop);
      await _bettingAudioPlayer.play(UrlSource(bettingSoundUrl));
    } catch (e) {
      print("Error playing betting sound from GitHub: $e");
    }
  }

  // গেম সিকোয়েন্স: স্লো ইফেক্ট -> উইনিং লাইট ইফেক্ট -> পেমেন্ট ও নতুন রাউন্ড
  Future<void> _executeGameSequence() async {
    // এখানে স্পিন শুরু হওয়ার সাউন্ড প্লে হবে এবং লুপ মোড অন থাকবে (যদি সাউন্ড অন থাকে)
    if (isSoundOn) {
      try {
        final String spinSoundUrl =
            'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/dongi2.mp3';

        await _spinAudioPlayer.setReleaseMode(ReleaseMode.loop);
        await _spinAudioPlayer.play(UrlSource(spinSoundUrl));
      } catch (e) {
        print("Error playing spin sound from GitHub: $e");
      }
    }

    setState(() {
      isSpinning = true;
      winningOptionId = null;
    });

    _wheelController.forward(from: 0.0);

    // ১. ১৫ সেকেন্ড পরে আইকনগুলোর ওপর একটি একটি করে স্লো ইফেক্ট (স্ক্যানিং)
    int totalIcons = betOptions.length;
    int loops = 2; // দুই চক্কর ঘুরবে
    int currentIndex = 0;

    for (int i = 0; i < (totalIcons * loops); i++) {
      if (!mounted) return;
      setState(() {
        scanningIndex = currentIndex % totalIcons;
      });
      await Future.delayed(
          const Duration(milliseconds: 200)); // স্লো ইফেক্ট স্পিড
      currentIndex++;
    }

    // ২. রেন্ডম উইনিং লজিক নির্ধারণ
    final random = Random();
    int chance = random.nextInt(100);
    String winnerId;

    if (chance < 3) {
      winnerId = 'chicken';
    } else if (chance < 8) {
      winnerId = 'octopus';
    } else if (chance < 18) {
      winnerId = 'shrimp';
    } else if (chance < 33) {
      winnerId = 'fish';
    } else {
      List<String> lowTier = ['watermelon', 'cabbage', 'carrot', 'mushroom'];
      winnerId = lowTier[random.nextInt(lowTier.length)];
    }

    scanningIndex = null;
    winningOptionId = winnerId;

    // ৩. যেই আইকন উইন হয় তার ওপর লাইট ইফেক্ট ২/৩ বার ফ্ল্যাশ করানো
    for (int f = 0; f < 3; f++) {
      if (!mounted) return;
      setState(() {
        isFlashing = true;
      });
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        isFlashing = false;
      });
      await Future.delayed(const Duration(milliseconds: 300));
    }

    var winningOption =
        betOptions.firstWhere((element) => element['id'] == winnerId);

    // স্পিন শেষ হওয়ার সাথে সাথে স্পিন সাউন্ড বন্ধ করে দেওয়া হচ্ছে
    await _spinAudioPlayer.stop();

    setState(() {
      isSpinning = false;
      lastResultIcon = winningOption['icon'];
      recentResults.add(lastResultIcon);
      if (recentResults.length > 12) recentResults.removeAt(0);
    });

    // ৪. চেক করা ইউজার এই অপশনে বেট ধরেছিল কিনা এবং উইনিং ডাইমন্ড যোগ করা
    int userBetOnWinner = myCurrentBets[winnerId] ?? 0;
    if (userBetOnWinner > 0) {
      int winAmount = userBetOnWinner * (winningOption['multiplier'] as int);
      await _awardUserWinnings(winAmount);
      _showWinPopup(
          winningOption['name'], winningOption['multiplier'], winAmount);
    }

    // ৫. পুরনো বেট রিসেট করে নতুন রাউন্ড ও ১৫ সেকেন্ড টাইম চালু করা
    await _clearUserBets();
    setState(() {
      countdownTimer = 15;
      winningOptionId = null;
    });
    _startCountdown();
  }

  // উইনিং অ্যামাউন্ট ইউজারের অ্যাকাউন্টে যোগ করা
  Future<void> _awardUserWinnings(int winAmount) async {
    if (AppData.myID.isEmpty) return;
    try {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(AppData.myID);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) return;
        int currentDiamonds = userSnapshot.get('diamonds') ?? 0;
        transaction.update(userRef, {'diamonds': currentDiamonds + winAmount});
      });
      _fetchUserData();
    } catch (e) {
      debugPrint("Award error: $e");
    }
  }

  // রাউন্ড শেষে বেট ডাটা মুছে ফেলা
  Future<void> _clearUserBets() async {
    if (AppData.myID.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('game_bets')
          .doc(AppData.myID)
          .delete();
    } catch (e) {
      debugPrint("Clear bet error: $e");
    }
  }

  void _showWinPopup(String name, int multiplier, int winAmount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A103C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.amberAccent, width: 2),
        ),
        title: const Text("🎉 Wow! You Won!",
            style: TextStyle(
                color: Colors.amberAccent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Winner Icon: $name(x$multiplier)",
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 10),
            Text("You have received a reward: 💎 $winAmount",
                style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK",
                style: TextStyle(
                    color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchUserData() async {
    if (AppData.myID.isNotEmpty) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(AppData.myID)
          .get();
      if (userDoc.exists && mounted) {
        setState(() {
          userDiamonds = userDoc.data()?['diamonds'] ?? 0;
        });
      }
    }
  }

  void placeBet(String optionId) async {
    if (AppData.myID.isEmpty || isSpinning) return;

    if (userDiamonds < selectedChip) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not enough diamonds!")),
      );
      return;
    }

    // ১. ইনস্ট্যান্ট লোকাল আপডেট (Optimistic Update) যাতে ক্লিক করার সাথেই স্ক্রিনে দেখায়
    setState(() {
      userDiamonds -= selectedChip;
      myCurrentBets[optionId] = (myCurrentBets[optionId] ?? 0) + selectedChip;
    });

    try {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(AppData.myID);
      DocumentReference betRef = FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('game_bets')
          .doc(AppData.myID);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        DocumentSnapshot betSnapshot = await transaction.get(betRef);

        if (!userSnapshot.exists) return;
        int currentDiamonds = userSnapshot.get('diamonds') ?? 0;
        if (currentDiamonds < selectedChip) throw "Not enough diamonds";

        int existingBetForOption = 0;
        Map<String, dynamic> existingBets = {};

        if (betSnapshot.exists) {
          existingBets = Map<String, dynamic>.from(betSnapshot.data() as Map);
          existingBetForOption = existingBets[optionId] ?? 0;
        }

        existingBets[optionId] = existingBetForOption + selectedChip;

        transaction
            .update(userRef, {'diamonds': currentDiamonds - selectedChip});
        transaction.set(betRef, existingBets);
      });
    } catch (e) {
      debugPrint("Bet error: $e");
      // কোনো কারণে ফায়ারস্টোরে ফেইল করলে সঠিক ডাটা সিঙ্ক করার জন্য রিলোড করা যেতে পারে
      _fetchUserData();
    }
  }

  @override
  void dispose() {
    _spinAudioPlayer.dispose();
    _bettingAudioPlayer.dispose(); // অডিও প্লেয়ার ডিসপোজ করা হলো
    _wheelController.dispose();
    _resetTimer?.cancel();
    _countdownTimerInstance?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // ব্যাকগ্রাউন্ডে লটি অ্যানিমেশন வால்பேப்பர்
        Positioned.fill(
          child: Lottie.network(
            'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/animated_background.json',
            fit: BoxFit.cover,
          ),
        ),

        // মূল গেম কন্টেইনার
        Container(
          height: size.height * 0.58,
          decoration: BoxDecoration(
            color: const Color(0xFF1A103C).withOpacity(0.85),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border:
                const Border(top: BorderSide(color: Colors.amber, width: 2.5)),
          ),
          child: Column(
            children: [
              // টপ বার: নাম, সাউন্ড বাটন ও ডায়মন্ড
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "👑 Dongi Baba",
                          style: TextStyle(
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isSoundOn = !isSoundOn;
                              if (!isSoundOn) {
                                _bettingAudioPlayer.stop();
                                _spinAudioPlayer.stop();
                              }
                            });
                          },
                          child: Icon(
                            isSoundOn ? Icons.volume_up : Icons.volume_off,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.cyanAccent),
                          ),
                          child: Row(
                            children: [
                              const Text("💎 ", style: TextStyle(fontSize: 12)),
                              Text(
                                "$userDiamonds",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // হুইল ও চারপাশের বড় আইকনসমূহ
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RotationTransition(
                      turns:
                          Tween(begin: 0.0, end: 3.0).animate(CurvedAnimation(
                        parent: _wheelController,
                        curve: Curves.easeInOut,
                      )),
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber, width: 5),
                          gradient: const LinearGradient(
                            colors: [Colors.orange, Colors.deepOrangeAccent],
                          ),
                        ),
                      ),
                    ),

                    // সেন্টারে লটি অ্যানিমেশন ও টাইমার
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amberAccent,
                        boxShadow: [
                          BoxShadow(color: Colors.black54, blurRadius: 6)
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 50,
                              height: 50,
                              child: Lottie.network(
                                'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/Cute_Tiger.json',
                                fit: BoxFit.contain,
                                repeat: true,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Text("🦁",
                                      style: TextStyle(fontSize: 20));
                                },
                              ),
                            ),
                            Text(
                              isSpinning && countdownTimer == 0
                                  ? "Spinning"
                                  : "$countdownTimer s",
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // চারপাশের ৮টি অপশন আইকন
                    ...List.generate(betOptions.length, (index) {
                      final angle = (index * 2 * pi) / betOptions.length;
                      const radius = 95.0;
                      final x = radius * cos(angle);
                      final y = radius * sin(angle);

                      final option = betOptions[index];
                      int myBetOnThis = myCurrentBets[option['id']] ?? 0;
                      bool hasMyBet = myBetOnThis > 0;
                      bool isScanning = scanningIndex == index;
                      bool isWinningItem =
                          winningOptionId == option['id'] && isFlashing;

                      return Transform.translate(
                        offset: Offset(x, y),
                        child: GestureDetector(
                          onTap: () => placeBet(option['id']),
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isWinningItem
                                      ? Colors.amber
                                      : (isScanning
                                          ? Colors.orangeAccent
                                          : (hasMyBet
                                              ? const Color(0xFF512E94)
                                              : const Color(0xFF2A1B5E))),
                                  border: Border.all(
                                    color: isWinningItem
                                        ? Colors.white
                                        : (isScanning
                                            ? Colors.yellow
                                            : (hasMyBet
                                                ? Colors.cyanAccent
                                                : Colors.amber)),
                                    width: isWinningItem || isScanning
                                        ? 4
                                        : (hasMyBet ? 3 : 2),
                                  ),
                                  boxShadow: [
                                    if (isWinningItem || isScanning)
                                      const BoxShadow(
                                          color: Colors.amberAccent,
                                          blurRadius: 15,
                                          spreadRadius: 4)
                                    else if (hasMyBet)
                                      const BoxShadow(
                                          color: Colors.cyanAccent,
                                          blurRadius: 10,
                                          spreadRadius: 2)
                                    else
                                      const BoxShadow(
                                          color: Colors.black45, blurRadius: 4),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(option['icon'],
                                        style: const TextStyle(fontSize: 20)),
                                    Text(
                                      "x${option['multiplier']}",
                                      style: const TextStyle(
                                          color: Colors.amberAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              if (hasMyBet)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.cyanAccent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.black, width: 1),
                                    ),
                                    child: Text(
                                      myBetOnThis >= 1000
                                          ? "${myBetOnThis ~/ 1000}K"
                                          : "$myBetOnThis",
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // লাস্ট রেজাল্ট বার
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text("Result: ",
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    Expanded(
                      child: SizedBox(
                        height: 24,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: recentResults
                              .map((icon) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    child: CircleAvatar(
                                      radius: 11,
                                      backgroundColor:
                                          Colors.amber.withOpacity(0.2),
                                      child: Text(icon,
                                          style: const TextStyle(fontSize: 12)),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // বেটিং চিপস সিলেকশন
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: chipValues.map((chip) {
                    bool isSelected = selectedChip == chip;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedChip = chip;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.amber : Colors.white12,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 1.5),
                          boxShadow: isSelected
                              ? [
                                  const BoxShadow(
                                      color: Colors.amberAccent, blurRadius: 6)
                                ]
                              : [],
                        ),
                        child: Text(
                          chip >= 1000 ? "${chip ~/ 1000}K" : "$chip",
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
