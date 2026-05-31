import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pagla_chat/crazy_fruit_game.dart';
import 'lucky_spin_view.dart';

class GamePanelView extends StatefulWidget {
  final String roomId;
  final bool isAdmin;
  const GamePanelView({super.key, required this.roomId, this.isAdmin = false});

  @override
  State<GamePanelView> createState() => _GamePanelViewState();
}

class _GamePanelViewState extends State<GamePanelView> {
  late DatabaseReference _gameRef;
  StreamSubscription? _subscription;
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? selectedGame;
  int userBalance = 0;
  int betAmount = 100;
  String gameState = "WAITING";
  List<Map<dynamic, dynamic>> luckyBets = [];

  @override
  void initState() {
    super.initState();
    _gameRef = FirebaseDatabase.instance.ref("games/${widget.roomId}");
    _listenToData();
  }

  // --- ১. ইউজার ডাটা এবং ডাইমন্ড খোঁজার লজিক ---
  void _listenToData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // ইমেইল বা authUID দিয়ে ইউজার খোঁজা
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: user.uid)
          .limit(1)
          .get();

      // যদি authUID দিয়ে না পায়, তবে ইমেইল দিয়ে খুঁজবে
      if (userQuery.docs.isEmpty && user.email != null) {
        userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();
      }

      if (userQuery.docs.isNotEmpty) {
        final docId = userQuery.docs.first.id;
        FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists && mounted) {
            setState(() {
              // ডাইমন্ড দেখাচ্ছে না সমস্যা সমাধানের জন্য ডাটা টাইপ চেক করা হয়েছে
              var data = snapshot.data();
              userBalance =
                  int.tryParse(data?['diamonds']?.toString() ?? "0") ?? 0;
            });
          }
        });
      }
    }

    _subscription = _gameRef.onValue.listen((event) {
      if (event.snapshot.value == null || !mounted) return;
      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        gameState = data['gameState'] ?? "WAITING";
        if (data['luckyBets'] != null) {
          luckyBets = (data['luckyBets'] as Map)
              .values
              .map((e) => Map<dynamic, dynamic>.from(e))
              .toList();
        } else {
          luckyBets = [];
        }
      });
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  void _playSound(String url) async => await _audioPlayer.play(UrlSource(url));

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        // আপনার দেওয়া ছবির কালার প্যালেট অনুযায়ী গোল্ডেন-রেড গ্রেডিয়েন্ট
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(
                  0xFF8B0000), // গাঢ় লাল (Dark Red - ছবির ব্যাকগ্রাউন্ডের মতো)
              Color(0xFFD4AF37), // উজ্জ্বল সোনালি (Gold - বর্ডারের মতো)
              Color(0xFF1A0A0A), // একদম নিচে গাঢ় কালো-লাল ফিনিশ
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 50),
                _buildGameHeader(),
                Expanded(
                  child: selectedGame == null
                      ? _buildGameLobby()
                      : LuckySpinView(
                          gameRef: _gameRef,
                          userRef: FirebaseDatabase.instance
                              .ref("users/$currentUserId"),
                          userBalance: userBalance,
                          betAmount: betAmount,
                          luckyBets: luckyBets,
                          playSound: _playSound,
                        ),
                ),
              ],
            ),
            _buildFloatingNavButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond, color: Colors.cyanAccent, size: 20),
                const SizedBox(width: 5),
                Text("$userBalance",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (selectedGame != null) _buildBetControls(),
          const SizedBox(width: 50),
        ],
      ),
    );
  }

  Widget _buildBetControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () =>
                setState(() => betAmount = max(100, betAmount - 100)),
            icon: const Icon(Icons.remove_circle_outline,
                color: Colors.redAccent, size: 26),
          ),
          Text("$betAmount",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: () => setState(() => betAmount += 100),
            icon: const Icon(Icons.add_circle_outline,
                color: Colors.greenAccent, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavButtons() {
    return Stack(
      children: [
        if (selectedGame != null)
          Positioned(
            top: 45,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 24),
              onPressed: () => setState(() => selectedGame = null),
            ),
          ),
        Positioned(
          top: 45,
          right: 10,
          child: IconButton(
            icon:
                const Icon(Icons.close_rounded, color: Colors.white, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

 // --- ২. গেম লবি আপডেট (সংশোধিত) ---
Widget _buildGameLobby() {
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    child: Column(
      children: [
        const Text("SELECT A GAME",
            style: TextStyle(
                color: Colors.white54,
                letterSpacing: 2,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: [
            // LUCKY গেমটি আগের মতোই
            _gameIcon("LUCKY", "assets/images/spin_logo.png", Colors.orangeAccent, false),
            // নতুন CRAZY FRUIT গেম (কোনো url নেই)
            _gameIcon("CRAZY FRUIT", "assets/images/crazyfrut.png", Colors.yellow, false),
            _gameIcon("FRUIT", "assets/images/coming_soon.png", Colors.grey, true),
            _gameIcon("TEEN PATTI", "assets/images/coming_soon.png", Colors.grey, true),
            _gameIcon("RACING", "assets/images/coming_soon.png", Colors.grey, true),
            _gameIcon("BATTLE", "assets/images/coming_soon.png", Colors.grey, true),
          ],
        ),
      ],
    ),
  );
}

// --- সংশোধিত গেম আইকন ফাংশন ---
Widget _gameIcon(String name, String asset, Color color, bool isComingSoon) {
  return GestureDetector(
    onTap: () {
      if (isComingSoon) {
        _showError("Coming Soon! Stay tuned.");
      } else if (name == "CRAZY FRUIT") {
        // এখানে আপনার নেটিভ ফ্লাটার গেমের ক্লাসটি বসবে
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CrazyFruitGame(
              userBalance: userBalance,
              onUpdateBalance: (newBalance) {
                // ফায়ারবেস আপডেট লজিক
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .update({'diamonds': newBalance.toString()});
              },
            ),
          ),
        );
      } else if (name == "LUCKY") {
        // আপনার আগের "LUCKY" গেমের নেভিগেশন লজিক (এটি মুছে গিয়েছিল)
        setState(() => selectedGame = name);
      
      } else {
        // অন্যান্য গেমের জন্য
        setState(() => selectedGame = name);
      }
    },
    child: Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
              color: isComingSoon ? Colors.black38 : Colors.transparent,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(asset, fit: BoxFit.cover),
                  if (isComingSoon)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Text("Coming\nSoon",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(name,
            style: TextStyle(
                color: isComingSoon ? Colors.white38 : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
  @override
  void dispose() {
    _subscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
