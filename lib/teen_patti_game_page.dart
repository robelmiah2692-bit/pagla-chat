import 'dart:async';
import 'dart:math'; // রেন্ডম ও গণনার জন্য
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart'; // সাউন্ড বাজানোর জন্য

class TeenPattiGamePage extends StatefulWidget {
  final String roomId;
  final String currentUserId;

  const TeenPattiGamePage({
    Key? key,
    required this.roomId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<TeenPattiGamePage> createState() => _TeenPattiGamePageState();
}

class _TeenPattiGamePageState extends State<TeenPattiGamePage>
    with TickerProviderStateMixin {
  int roundNumber = 2214;
  int remainingTime = 15;
  String gameStage = "Guessing Stage";
  Timer? _gameTimer;

  int userDiamonds = 0;
  StreamSubscription? _userStream;

  int selectedChip = 2;
  final List<int> chipValues = [5, 2, 10, 100, 1000, 2000];

  // সাউন্ড অন/অফ স্টেট
  bool isSoundOn = true;
  late AudioPlayer _audioPlayer;

  // উইনিং স্লটের লাইটিং ও অ্যানিমেশনের জন্য কন্ট্রোলার
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // আগের রাউন্ডের বেট সেভ রাখার জন্য (Repeat বাটনের জন্য)
  Map<int, int> lastRoundBets = {0: 0, 1: 0, 2: 0};

  List<Map<String, dynamic>> pots = [
    {
      "potTotal": 240,
      "userBet": 0,
      "cards": [
        {"val": "?", "suit": "", "isFaceUp": false},
        {"val": "?", "suit": "", "isFaceUp": false},
        {"val": "?", "suit": "", "isFaceUp": false},
      ],
      "result": "",
      "isWinner": false,
    },
    {
      "potTotal": 51400,
      "userBet": 0,
      "cards": [
        {"val": "?", "suit": "", "isFaceUp": false},
        {"val": "?", "suit": "", "isFaceUp": false},
        {"val": "?", "suit": "", "isFaceUp": false},
      ],
      "result": "",
      "isWinner": false,
    },
    {
      "potTotal": 2048,
      "userBet": 0,
      "cards": [
        {"val": "?", "suit": "", "isFaceUp": false},
        {"val": "?", "suit": "", "isFaceUp": false},
        {"val": "?", "suit": "", "isFaceUp": false},
      ],
      "result": "",
      "isWinner": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    // লাইটিং ও গ্লো অ্যানিমেশন সেটআপ
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 2.0, end: 6.0).animate(_glowController);

    _fetchUserDiamonds();
    _startCountdown();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _userStream?.cancel();
    _glowController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // 🔊 রিয়েল সাউন্ড প্লে করার ফাংশন
  void _playSound(String soundFileName) async {
    if (!isSoundOn) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/$soundFileName.mp3'));
    } catch (e) {
      debugPrint("সাউন্ড প্লে করতে সমস্যা: $e");
    }
  }

  // ফায়ারবেস থেকে সঠিক uid দিয়ে ইউজারের ডাইমন্ড ফেচ করার লজিক
  void _fetchUserDiamonds() async {
    String authUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    String targetDocId = widget.currentUserId;

    if (authUid.isNotEmpty) {
      try {
        var querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: authUid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          targetDocId = querySnapshot.docs.first.id;
        }
      } catch (e) {
        debugPrint("ডকুমেন্ট আইডি খুঁজতে সমস্যা: $e");
      }
    }

    if (targetDocId.isNotEmpty) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(targetDocId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          var data = snapshot.data();
          setState(() {
            var rawDiamonds = data?['diamonds'] ?? 0;
            userDiamonds = rawDiamonds is int
                ? rawDiamonds
                : int.tryParse(rawDiamonds.toString()) ?? 0;
          });
        }
      });
    }
  }

  void _startCountdown() {
    remainingTime = 15;
    gameStage = "Guessing Stage";

    // নতুন রাউন্ড শুরু হলে উইনার রিসেট করা
    for (var pot in pots) {
      pot["isWinner"] = false;
      pot["result"] = "";
    }

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (remainingTime > 0) {
          remainingTime--;
        } else {
          _timerEnded();
        }
      });
    });
  }

  // 🧠 আপনার চাহিদা অনুযায়ী কড়া ও নিখুঁত হাউস প্রোটেকশন এবং জিরো/লো বেট উইনিং লজিক
  void _timerEnded() {
    _gameTimer?.cancel();
    _playSound('win'); // 🎵 উইনিং সাউন্ড বাজবে

    final random = Random();
    int winningIndex = 0;

    // ১. শূন্য বেট বা কম বেট থাকা স্লটগুলোকে ফিল্টার করা
    List<int> zeroBetIndices = [];
    List<int> lowBetIndices = [];
    
    int minBet = 999999999;
    int maxBet = -1;
    int highestBetIndex = 0;

    for (int i = 0; i < pots.length; i++) {
      int currentBet = pots[i]["userBet"] ?? 0; // অথবা potTotal ব্যবহার করতে পারেন, এখানে userBet দিয়ে লজিক মেইনটেইন করা হলো
      int totalPot = pots[i]["potTotal"] ?? 0;

      if (currentBet == 0 || totalPot == 0) {
        zeroBetIndices.add(i);
      }

      if (totalPot < minBet) {
        minBet = totalPot;
      }

      if (totalPot > maxBet) {
        maxBet = totalPot;
        highestBetIndex = i;
      }
    }

    // কম বেটের স্লটগুলো বের করা
    for (int i = 0; i < pots.length; i++) {
      if ((pots[i]["potTotal"] ?? 0) == minBet) {
        lowBetIndices.add(i);
      }
    }

    // ২. উইনিং সিলেকশন রুলস প্রয়োগ
    int chance = random.nextInt(100); // ১০০ এর মধ্যে হিসাব

    if (zeroBetIndices.isNotEmpty && chance < 85) {
      // শূন্য (0) বেট বা স্লট থাকলে সেটিকে বেশি প্রাধান্য দেওয়া হবে (প্রায় ৮৫% ক্ষেত্রে)
      winningIndex = zeroBetIndices[random.nextInt(zeroBetIndices.length)];
    } else if (chance == 99 && highestBetIndex >= 0) {
      // সর্বোচ্চ বেট থাকা স্লটটি শতকরার নিয়মে মাত্র ১ বার (১% চান্স) উইন করবে হাউস প্রটেকশনের জন্য
      winningIndex = highestBetIndex;
    } else {
      // বাকি ক্ষেত্রে সবচেয়ে কম বেট বা সেফ স্লট উইন করবে
      if (lowBetIndices.isNotEmpty) {
        winningIndex = lowBetIndices[random.nextInt(lowBetIndices.length)];
      } else {
        winningIndex = random.nextInt(pots.length);
      }
    }

    // কার্ডের বিভিন্ন কম্বিনেশন লিস্ট
    List<Map<String, dynamic>> possibleResults = [
      {"cards": [{"val": "A", "suit": "♠", "isFaceUp": true}, {"val": "5", "suit": "♥", "isFaceUp": true}, {"val": "4", "suit": "♦", "isFaceUp": true}], "result": "Flush"},
      {"cards": [{"val": "K", "suit": "♣", "isFaceUp": true}, {"val": "10", "suit": "♥", "isFaceUp": true}, {"val": "6", "suit": "♠", "isFaceUp": true}], "result": "High card"},
      {"cards": [{"val": "J", "suit": "♦", "isFaceUp": true}, {"val": "9", "suit": "♣", "isFaceUp": true}, {"val": "2", "suit": "♥", "isFaceUp": true}], "result": "High card"},
    ];

    setState(() {
      gameStage = "Stop Guessing";

      for (int i = 0; i < pots.length; i++) {
        bool isWin = (i == winningIndex);
        pots[i]["isWinner"] = isWin;
        pots[i]["cards"] = possibleResults[i]["cards"];
        pots[i]["result"] = possibleResults[i]["result"];

        // 💰 ইউজার যদি উইনিং স্লটে বেট করে থাকে, তবে তার পুরস্কার যোগ করা
        if (isWin && pots[i]["userBet"] > 0) {
          int winnings = pots[i]["userBet"] * 2; // বেটের দ্বিগুণ ডায়মন্ড রিটার্ন
          userDiamonds += winnings;
        }
      }
    });

    // ডাটাবেজে আপডেট করে দেওয়া যাতে জেতার ডায়মন্ড জমা হয়
    _updateFirebaseDiamonds();

    for (int i = 0; i < pots.length; i++) {
      lastRoundBets[i] = pots[i]["userBet"];
    }

    Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        roundNumber++;
        for (var pot in pots) {
          pot["cards"] = [
            {"val": "?", "suit": "", "isFaceUp": false},
            {"val": "?", "suit": "", "isFaceUp": false},
            {"val": "?", "suit": "", "isFaceUp": false},
          ];
          pot["result"] = "";
          pot["userBet"] = 0;
          pot["isWinner"] = false;
        }
      });
      _startCountdown();
    });
  }

  // বেট প্লেস করার ফাংশন
  void _placeBet(int potIndex, int amount) async {
    if (gameStage != "Guessing Stage") return;
    _playSound('chip'); // 🎵 চিপস রাখার সাউন্ড বাজবে

    if (userDiamonds < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("পর্যাপ্ত ডাইমন্ড নেই!"),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      pots[potIndex]["userBet"] += amount;
      pots[potIndex]["potTotal"] += amount;
      userDiamonds -= amount;
    });

    _updateFirebaseDiamonds();
  }

  // Repeat বাটন প্রেস করলে আগের রাউন্ডের বেট আবার বসে যাবে
  void _repeatLastBet() {
    if (gameStage != "Guessing Stage") return;
    _playSound('chip'); 

    int totalRepeatAmount = 0;
    lastRoundBets.forEach((key, value) {
      totalRepeatAmount += value;
    });

    if (totalRepeatAmount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("পূর্ববর্তী কোনো বেট নেই!"),
            backgroundColor: Colors.orange),
      );
      return;
    }

    if (userDiamonds < totalRepeatAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("রিপিট করার জন্য পর্যাপ্ত ডাইমন্ড নেই!"),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      lastRoundBets.forEach((potIndex, amount) {
        if (amount > 0) {
          pots[potIndex]["userBet"] += amount;
          pots[potIndex]["potTotal"] += amount;
          userDiamonds -= amount;
        }
      });
    });

    _updateFirebaseDiamonds();
  }

  void _updateFirebaseDiamonds() async {
    String authUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    String targetDocId = widget.currentUserId;

    if (authUid.isNotEmpty) {
      try {
        var querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: authUid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          targetDocId = querySnapshot.docs.first.id;
        }
      } catch (e) {
        debugPrint("আপডেটের জন্য ডকুমেন্ট আইডি খুঁজতে সমস্যা: $e");
      }
    }

    if (targetDocId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetDocId)
            .update({
          'diamonds': userDiamonds,
        });
      } catch (e) {
        debugPrint("ডাইমন্ড আপডেট করতে সমস্যা: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1b4d3e),
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: Text("Teen Patti - Room: ${widget.roomId} (NO.$roundNumber)"),
        centerTitle: true,
        actions: [
          // 🔊 সাউন্ড অন/অফ করার বাটন
          IconButton(
            icon: Icon(
              isSoundOn ? Icons.volume_up : Icons.volume_off,
              color: isSoundOn ? Colors.greenAccent : Colors.redAccent,
            ),
            onPressed: () {
              setState(() {
                isSoundOn = !isSoundOn;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.amber, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.diamond,
                        color: Colors.cyanAccent, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      "$userDiamonds",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 🖼️ ফুল স্ক্রিন ব্যাকগ্রাউন্ড ইমেজ
          Positioned.fill(
            child: Image.asset(
              'assets/images/dealer_bg.webp',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                color: Colors.transparent,
                child: Container(
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      gameStage == "Guessing Stage"
                          ? "$gameStage ($remainingTime s)"
                          : gameStage,
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ৩টি কার্ড পট (Betting Pots) - অ্যানিমেটেড লাইটিং ও উইনিং ইফেক্ট সহ
              SizedBox(
                height: 200,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (index) {
                      bool isWinner = pots[index]["isWinner"] ?? false;

                      return AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          return GestureDetector(
                            onTap: () => _placeBet(index, selectedChip),
                            child: Container(
                              width: 118,
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                              decoration: BoxDecoration(
                                color: isWinner
                                    ? Colors.amber.shade900.withOpacity(0.95)
                                    : Colors.brown.shade800.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                                // 🌟 উইনিং স্লটের চারিপাশে অ্যানিমেটেড লাইটিং/বর্ডার ইফেক্ট
                                border: Border.all(
                                  color: isWinner ? Colors.greenAccent : Colors.amber,
                                  width: isWinner ? _glowAnimation.value : 1.5,
                                ),
                                boxShadow: isWinner
                                    ? [
                                        BoxShadow(
                                          color: Colors.greenAccent,
                                          blurRadius: 12 + _glowAnimation.value * 2,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 👑 উইনার ব্যাজ
                                  if (isWinner)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        "👑 WINNER",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  Text("POT: ${pots[index]["potTotal"]}",
                                      style: const TextStyle(
                                          color: Colors.amber,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text("You: ${pots[index]["userBet"]}",
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 10)),
                                  const SizedBox(height: 6),
                                  
                                  // 🃏 প্লেইং কার্ড ডিজাইন
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: (pots[index]["cards"] as List)
                                        .map<Widget>((cardMap) {
                                      bool isFaceUp = cardMap["isFaceUp"];
                                      String val = cardMap["val"];
                                      String suit = cardMap["suit"];
                                      bool isRed = suit == "♥" || suit == "♦";

                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 1.5),
                                        width: 28,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: isFaceUp
                                              ? Colors.white
                                              : Colors.red.shade900,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                              color: Colors.black54, width: 0.8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 2,
                                              offset: const Offset(1, 1),
                                            ),
                                          ],
                                        ),
                                        child: isFaceUp
                                            ? Stack(
                                                children: [
                                                  Positioned(
                                                    top: 1,
                                                    left: 2,
                                                    child: Text(
                                                      val,
                                                      style: TextStyle(
                                                        color: isRed
                                                            ? Colors.red
                                                            : Colors.black,
                                                        fontSize: 8,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  Center(
                                                    child: Text(
                                                      suit,
                                                      style: TextStyle(
                                                        color: isRed
                                                            ? Colors.red
                                                            : Colors.black,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Center(
                                                child: Container(
                                                  width: 20,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.white24),
                                                    borderRadius:
                                                        BorderRadius.circular(2),
                                                  ),
                                                  child: const Center(
                                                    child: Text(
                                                      "TP",
                                                      style: TextStyle(
                                                        color: Colors.white38,
                                                        fontSize: 8,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    pots[index]["result"].isEmpty
                                        ? "Tap to Bet"
                                        : pots[index]["result"],
                                    style: TextStyle(
                                      color: pots[index]["result"].isEmpty
                                          ? Colors.white54
                                          : (isWinner ? Colors.greenAccent : Colors.white70),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // নিচের চিপস ও বেটিং কন্ট্রোল প্যানেল
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                color: Colors.black87,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: chipValues.map((chip) {
                        bool isSelected = selectedChip == chip;
                        return GestureDetector(
                          onTap: () => setState(() => selectedChip = chip),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isSelected ? Colors.amber : Colors.blueGrey,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                "$chip",
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Repeat বাটন
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                      onPressed: _repeatLastBet,
                      child: const Text("Repeat",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}