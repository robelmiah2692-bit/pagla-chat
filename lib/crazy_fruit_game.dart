import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // লোকাল ব্যালেন্স ভেরিয়েবল যা লাইভ আপডেট হবে
  late int localBalance;
  int spinCount = 0; // মোট কতবার স্পিন করেছে
  int targetWinCount = 3; // গেমটি কখন জেতাবে তার টার্গেট
  // ফায়ারবেস থেকে রিয়েল ডাটা আসার লিস্ট
  List<Map<String, dynamic>> topWinners = [];
  bool isSoundOn = true;
  @override
  void initState() {
    super.initState();
    localBalance = widget.userBalance;
    _listenToWinners();
  }

  // এটি অবশ্যই ইমপোর্ট করতে হবে

  Future<void> _listenToWinners() async {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref('games/42635/luckyWinners');

    ref.onValue.listen((DatabaseEvent event) async {
      final data = event.snapshot.value;
      if (data == null) return;

      Map<dynamic, dynamic> map = data as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> fetchedWinners = [];

      for (var entry in map.entries) {
        var value = entry.value;
        // ডাটাবেজ থেকে সরাসরি আইডি পাওয়ার চেষ্টা করছি (যদি থাকে)
        String uID = value['uID'] ?? '';
        int winAmount = value['amount'] ?? 0;

        // Firestore থেকে নাম ও ছবি আনছি
        String userName = "Player";
        String userPic = "";

        if (uID.isNotEmpty) {
          var userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uID)
              .get();
          if (userDoc.exists) {
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

      setState(() {
        topWinners = fetchedWinners.take(3).toList();
      });
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
      spinCount++; // স্পিন কাউন্ট বাড়ানো হচ্ছে
    });

    // ডাইনামিক লজিক: প্রতি ১০ স্পিন অন্তর টার্গেট উইন রেট পাল্টে যাবে
    if (spinCount % 10 == 0) {
      targetWinCount = [2, 3, 2, 4][Random().nextInt(4)];
    }

    Timer timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        currentSlots = List.generate(9, (_) => Random().nextInt(fruits.length));
      });
    });

    await Future.delayed(const Duration(seconds: 3));
    timer.cancel();

    setState(() {
      // চেক করা হচ্ছে এটা কি জেতার পালা কি না
      if (spinCount % (5 + Random().nextInt(6)) < targetWinCount) {
        _generateWinSlots();
      } else {
        currentSlots = List.generate(9, (_) => Random().nextInt(fruits.length));
      }
      isSpinning = false;
      _checkWin();
    });

    widget.onUpdateBalance(localBalance);
  }

  void _showWinnersDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // এটি দিলে লিস্ট অনেক বড় হলেও সমস্যা করবে না
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height:
            MediaQuery.of(context).size.height * 0.5, // স্ক্রিনের অর্ধেক উচ্চতা
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
                                    // এখানে ছবি অথবা ডিফল্ট অবতার চেক করছি
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

  void _generateWinSlots() {
    int winRow = Random().nextInt(3) * 3;
    int fruitIndex = Random().nextInt(fruits.length);
    currentSlots = List.generate(9, (_) => Random().nextInt(fruits.length));

    // কনফার্ম উইন লাইন তৈরি করা
    currentSlots[winRow] = fruitIndex;
    currentSlots[winRow + 1] = fruitIndex;
    currentSlots[winRow + 2] = fruitIndex;
  }

  void _checkWin() {
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
            // এখানে লোকাল ব্যালেন্স ব্যবহার করা হয়েছে
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
              onPressed: () =>
                  _showWinnersDialog(), // ক্লিক করলে উইনার লিস্ট দেখাবে
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

  // বাকি উইজেটগুলো আগের মতোই থাকবে...
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
}
