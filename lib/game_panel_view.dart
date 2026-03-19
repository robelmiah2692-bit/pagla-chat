import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'ludo_view.dart';
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
  late DatabaseReference _userRef;
  StreamSubscription? _subscription;
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? selectedGame; // শুরুতে কোনো গেম সিলেক্ট থাকবে না (মেনু দেখাবে)
  int userBalance = 0;
  int betAmount = 100;
  int diceNumber = 1;
  bool isFullScreen = false;
  List<Map<dynamic, dynamic>> players = [];
  List<Map<dynamic, dynamic>> luckyBets = [];

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _gameRef = FirebaseDatabase.instance.ref("games/${widget.roomId}");
    _userRef = FirebaseDatabase.instance.ref("users/$uid");
    _listenToData();
  }

  void _listenToData() {
    _userRef.child("diamonds").onValue.listen((e) {
      if(mounted) setState(() => userBalance = int.tryParse(e.snapshot.value.toString()) ?? 0);
    });
    _subscription = _gameRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null || !mounted) return;
      setState(() {
        diceNumber = data['diceNumber'] ?? 1;
        if (data['players'] != null) players = (data['players'] as Map).values.map((e) => e as Map).toList();
        if (data['luckyBets'] != null) luckyBets = (data['luckyBets'] as Map).values.map((e) => e as Map).toList();
      });
    });
  }

  void _playSound(String url) async => await _audioPlayer.play(UrlSource(url));

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: isFullScreen ? MediaQuery.of(context).size.height : 600,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 10),
              Expanded(
                child: selectedGame == null 
                  ? _buildGameLobby() // গেম সিলেক্ট না করলে মেনু দেখাবে
                  : (selectedGame == "LUDO" 
                      ? LudoView(gameRef: _gameRef, players: players, diceNumber: diceNumber, isAdmin: widget.isAdmin, isFullScreen: isFullScreen, playSound: _playSound)
                      : LuckySpinView(gameRef: _gameRef, userRef: _userRef, userBalance: userBalance, betAmount: betAmount, luckyBets: luckyBets, playSound: _playSound)
                    ),
              ),
            ],
          ),
          // ব্যাক বাটন (গেম থেকে মেনুতে ফেরার জন্য)
          if (selectedGame != null)
            Positioned(
              top: 15, left: 15,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 25),
                onPressed: () => setState(() => selectedGame = null),
              ),
            ),
          Positioned(
            top: 15, right: 15,
            child: IconButton(
              icon: Icon(isFullScreen ? Icons.close_fullscreen : Icons.cancel, color: Colors.white, size: 30),
              onPressed: () => isFullScreen ? setState(() => isFullScreen = false) : Navigator.pop(context),
            ),
          )
        ],
      ),
    );
  }

  // গেম লবি (আইকন মেনু)
  Widget _buildGameLobby() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("SELECT A GAME", style: TextStyle(color: Colors.white54, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _gameIcon("LUDO", "assets/images/ludo_logo.png", Colors.blueAccent),
            const SizedBox(width: 30),
            _gameIcon("LUCKY", "assets/images/spin_logo.png", Colors.orangeAccent),
          ],
        ),
      ],
    );
  }

  Widget _gameIcon(String name, String asset, Color color) {
    return GestureDetector(
      onTap: () => setState(() => selectedGame = name),
      child: Column(
        children: [
          Container(
            width: 100, height: 100,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
            child: Image.asset(asset), // আপনার লোগো এখানে বসবে
          ),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 70, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40), // ব্যাক বাটনের জন্য জায়গা খালি রাখা
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.cyanAccent.withOpacity(0.3))),
            child: Row(
              children: [
                const Icon(Icons.diamond, color: Colors.cyanAccent, size: 20),
                const SizedBox(width: 8),
                Text("$userBalance", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (selectedGame == "LUCKY") 
            Row(children: [
              IconButton(onPressed: () => setState(() => betAmount = max(100, betAmount - 100)), icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent)),
              Text("$betAmount", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => setState(() => betAmount += 100), icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent)),
            ]),
        ],
      ),
    );
  }

  @override
  void dispose() { _subscription?.cancel(); _audioPlayer.dispose(); super.dispose(); }
}
