import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:pagla_chat/SoundManager.dart';

class CrazyFruitGame extends StatefulWidget {
  final int userBalance;
  final Function(int) onUpdateBalance;

  const CrazyFruitGame(
      {super.key, required this.userBalance, required this.onUpdateBalance});

  @override
  State<CrazyFruitGame> createState() => _CrazyFruitGameState();
}

class _CrazyFruitGameState extends State<CrazyFruitGame> {
  final List<String> fruits = ['🍎', '🍊', '🍌', '🍒', '🍇', '🍉', '🍓', '🍍'];
  final Map<String, int> multipliers = {
    '🍎': 3,
    '🍊': 4,
    '🍌': 5,
    '🍒': 6,
    '🍇': 7,
    '🍉': 8,
    '🍓': 9,
    '🍍': 10
  };

  List<int> currentSlots = List.generate(9, (index) => 0);
  int currentBet = 100;
  bool isSpinning = false;

  late int localBalance;
  int spinCount = 0;
  StreamSubscription? _winnersSubscription;
  List<Map<String, dynamic>> topWinners = [];
  bool isSoundOn = true;

  @override
  void initState() {
    super.initState();
    localBalance = widget.userBalance;
    _listenToWinners();
  }

  // 🔴 সঠিক ডকুমেন্টে ডাইমন্ড আপডেট করার ফাংশন (UID অথবা query দিয়ে)
  Future<void> _updateBalanceToFirestore(int newBalance) async {
    try {
      String authUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (authUid.isEmpty) return;

      // প্রথমে চেক করা যাক সরাসরি authUid দিয়ে ডকুমেন্ট আছে কি না, না থাকলে 'uid' ফিল্ড দিয়ে কুয়েরি করা হবে
      var docRef = FirebaseFirestore.instance.collection('users').doc(authUid);
      var docSnap = await docRef.get();

      if (docSnap.exists) {
        await docRef.update({'diamonds': newBalance});
      } else {
        // যদি ডকুমেন্টের আইডি authUid না হয়ে কাস্টম আইডি হয় (যেমন স্ক্রিনশটের 978051)
        var querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: authUid)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          await querySnapshot.docs.first.reference
              .update({'diamonds': newBalance});
        }
      }
    } catch (e) {
      debugPrint("Error updating balance to Firestore: $e");
    }
  }

  Future<void> _listenToWinners() async {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref('games/42635/luckyWinners');

    _winnersSubscription = ref.onValue.listen((DatabaseEvent event) async {
      final data = event.snapshot.value;
      if (data == null || !mounted) return;

      Map<dynamic, dynamic> map = data as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> fetchedWinners = [];

      for (var entry in map.entries) {
        var value = entry.value;
        String uID = value['uID'] ?? '';
        int winAmount = value['amount'] ?? 0;

        String userName = "Player";
        String userPic = "";

        if (uID.isNotEmpty) {
          var userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uID)
              .get();
          if (userDoc.exists && mounted) {
            var userData = userDoc.data()!;
            userName = userData['name'] ?? 'Player';
            userPic = userData['profilepic'] ?? '';
          }
        }

        fetchedWinners.add({
          'name': userName,
          'profilepic': userPic,
          'win': winAmount,
        });
      }

      fetchedWinners.sort((a, b) => b['win'].compareTo(a['win']));

      if (mounted) {
        setState(() {
          topWinners = fetchedWinners.take(3).toList();
        });
      }
    });
  }

  void _spin() async {
    SoundManager.playSound('spin_sound.mp3');

    if (isSpinning || localBalance < currentBet) {
      if (localBalance < currentBet) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Not enough diamonds!")));
      }
      return;
    }

    setState(() {
      isSpinning = true;
      localBalance -= currentBet;
      spinCount++;
    });

    // 🔴 ফায়ারস্টোরে বেটের টাকা কাটার পর আপডেট করা
    await _updateBalanceToFirestore(localBalance);

    bool shouldWin = false;
    bool forceHighMultiplier = false;

    if (spinCount >= 30) {
      forceHighMultiplier = true;
      shouldWin = true;
      spinCount = 0;
    } else {
      int winChance = Random().nextInt(100);
      shouldWin = winChance < 10; // ১০% সাধারণ জেতার চান্স
    }

    Timer timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        currentSlots = List.generate(9, (_) => Random().nextInt(fruits.length));
      });
    });

    await Future.delayed(const Duration(seconds: 3));
    timer.cancel();

    setState(() {
      if (shouldWin) {
        _generateWinSlots(forceHighMultiplier);
      } else {
        currentSlots = List.generate(9, (_) => Random().nextInt(fruits.length));
      }
      isSpinning = false;
      _checkWin();
    });

    widget.onUpdateBalance(localBalance);
  }

  void _generateWinSlots(bool highMultiplier) {
    int winRow = Random().nextInt(3) * 3;
    int fruitIndex;

    if (highMultiplier) {
      List<int> highIndices = [2, 3, 4, 5, 6, 7]; // ৫x থেকে ১০x এর ইনডেক্স
      fruitIndex = highIndices[Random().nextInt(highIndices.length)];
    } else {
      fruitIndex = Random().nextInt(fruits.length);
    }

    currentSlots = List.generate(9, (_) => Random().nextInt(fruits.length));

    currentSlots[winRow] = fruitIndex;
    currentSlots[winRow + 1] = fruitIndex;
    currentSlots[winRow + 2] = fruitIndex;
  }

  void _showWinnersDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Color(0xFF1A0000),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const Text("TOP WINNERS",
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: topWinners.isEmpty
                  ? const Center(
                      child: Text("No winners yet!",
                          style: TextStyle(color: Colors.white54)))
                  : ListView(
                      children: topWinners
                          .map((winner) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(15)),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.white10,
                                      backgroundImage: (winner['profilepic'] !=
                                                  null &&
                                              winner['profilepic']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? NetworkImage(winner['profilepic'])
                                          : null,
                                      child: (winner['profilepic'] == null ||
                                              winner['profilepic']
                                                  .toString()
                                                  .isEmpty)
                                          ? Text(winner['avatar'] ?? '👑',
                                              style:
                                                  const TextStyle(fontSize: 20))
                                          : null,
                                    ),
                                    const SizedBox(width: 15),
                                    Text(winner['name'] ?? 'Player',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 16)),
                                    const Spacer(),
                                    Text("${winner['win']} 💎",
                                        style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkWin() async {
    int totalWin = 0;
    for (int i = 0; i < 9; i += 3) {
      if (currentSlots[i] == currentSlots[i + 1] &&
          currentSlots[i] == currentSlots[i + 2]) {
        String fruit = fruits[currentSlots[i]];
        totalWin += currentBet * (multipliers[fruit] ?? 2);
      }
    }

    if (totalWin > 0) {
      setState(() {
        localBalance += totalWin;
      });
      widget.onUpdateBalance(localBalance);

      // 🔴 উইন হলে ফায়ারস্টোরে ব্যালেন্স আপডেট করা
      await _updateBalanceToFirestore(localBalance);

      _showWinPopup(totalWin);
    }
  }

  void _showWinPopup(int amount) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: Colors.black87,
              title:
                  const Text("WINNER!", style: TextStyle(color: Colors.amber)),
              content: Text("You won $amount Diamonds!",
                  style: const TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Collect"))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              colors: [Color(0xFF2E0202), Color(0xFF100000)]),
        ),
        child: Column(
          children: [
            const SizedBox(height: 50),
            _buildDashboard(),
            const Spacer(),
            _buildSlotMachine(),
            const Spacer(),
            IconButton(
              icon: Icon(isSoundOn ? Icons.volume_up : Icons.volume_off,
                  color: Colors.amber),
              onPressed: () {
                setState(() {
                  isSoundOn = !isSoundOn;
                  SoundManager.toggleMute();
                });
              },
            ),
            IconButton(
              icon:
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
              onPressed: () => _showWinnersDialog(),
            ),
            _buildMultiplierInfo(),
            const SizedBox(height: 20),
            _buildControls(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _glassBox(Text("BAL: $localBalance",
              style: const TextStyle(
                  color: Colors.amber, fontWeight: FontWeight.bold))),
          _glassBox(Text("BET: $currentBet",
              style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildSlotMachine() {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withOpacity(0.3))),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: 9,
        itemBuilder: (context, index) => _glassBox(
            Center(
                child: Text(fruits[currentSlots[index]],
                    style: const TextStyle(fontSize: 40))),
            padding: 5),
      ),
    );
  }

  Widget _buildMultiplierInfo() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fruits.length,
        itemBuilder: (context, i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white10, borderRadius: BorderRadius.circular(10)),
          child: Text("${fruits[i]} ${multipliers[fruits[i]]}x",
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
            onPressed: () =>
                setState(() => currentBet = max(10, currentBet - 50)),
            icon: const Icon(Icons.remove, color: Colors.white)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(30)),
          onPressed: isSpinning ? null : _spin,
          child: const Text("START",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        IconButton(
            onPressed: () => setState(() => currentBet += 50),
            icon: const Icon(Icons.add, color: Colors.white)),
      ],
    );
  }

  Widget _glassBox(Widget child, {double padding = 20}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white.withOpacity(0.2))),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _winnersSubscription
        ?.cancel(); // 🛠️ ব্যাকগ্রাউন্ড লিসেনার বন্ধ করার জন্য এটি যোগ করুন
    super.dispose();
  }
}
