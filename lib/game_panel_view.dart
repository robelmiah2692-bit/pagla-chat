import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  StreamSubscription? _subscription;
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? selectedGame; 
  int userBalance = 0;
  int betAmount = 100;
  int diceNumber = 1;
  // ডিফল্টভাবে এটাকে true করে দিচ্ছি যেন গেম ওপেন হলেই ফুল স্ক্রিন হয়
  bool isFullScreen = true; 
  String gameState = "WAITING"; 
  List<Map<dynamic, dynamic>> players = [];
  List<Map<dynamic, dynamic>> luckyBets = [];

  @override
  void initState() {
    super.initState();
    _gameRef = FirebaseDatabase.instance.ref("games/${widget.roomId}");
    _listenToData();
  }

  void _listenToData() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          setState(() {
            userBalance = int.tryParse(snapshot.data()?['diamonds'].toString() ?? "0") ?? 0;
          });
        }
      });
    }

    _subscription = _gameRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null || !mounted) return;
      setState(() {
        gameState = data['gameState'] ?? "WAITING";
        diceNumber = data['diceNumber'] ?? 1;
        if (data['players'] != null) {
          players = (data['players'] as Map).values.map((e) => e as Map).toList();
        }
        if (data['luckyBets'] != null) {
          luckyBets = (data['luckyBets'] as Map).values.map((e) => e as Map).toList();
        }
      });
    });
  }

  void _joinLudo() async {
    if (gameState == "RUNNING") {
      _showError("গেম চলছে! এই রাউন্ড শেষ হওয়া পর্যন্ত অপেক্ষা করুন।");
      return;
    }
    if (players.length >= 4) {
      _showError("রুম ফুল হয়ে গেছে!");
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    bool alreadyJoined = players.any((p) => p['id'] == user?.uid);
    if (!alreadyJoined && user != null) {
      await _gameRef.child("players").child(user.uid).set({
        "id": user.uid,
        "name": user.displayName ?? "Player",
        "photo": user.photoURL ?? "",
      });
    }
  }

  void _startLudo() {
    if (players.length < 2) {
      _showError("কমপক্ষে ২ জন প্লেয়ার লাগবে!");
      return;
    }
    _gameRef.update({"gameState": "RUNNING"});
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  void _playSound(String url) async => await _audioPlayer.play(UrlSource(url));

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    
    // স্ক্রিনের পুরো হাইট নেওয়া হচ্ছে
    double fullHeight = MediaQuery.of(context).size.height;

    return Container(
      // কন্টেইনার সবসময় ফুল স্ক্রিন হাইট নিবে
      height: fullHeight,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea( // ফোনের ওপরের নচ যেন কভার না করে
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 10),
                
                if (selectedGame == "LUDO" && gameState == "WAITING")
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _joinLudo,
                          icon: const Icon(Icons.login),
                          label: const Text("JOIN"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                        ),
                        if (widget.isAdmin) ...[
                          const SizedBox(width: 15),
                          ElevatedButton.icon(
                            onPressed: _startLudo,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text("START"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ]
                      ],
                    ),
                  ),

                Expanded(
                  child: selectedGame == null 
                    ? _buildGameLobby() 
                    : SingleChildScrollView( // যেন স্ক্রিন ছোট হলেও ওভারফ্লো না হয়
                        physics: const BouncingScrollPhysics(),
                        child: (selectedGame == "LUDO" 
                          ? LudoView(
                              gameRef: _gameRef, 
                              players: players, 
                              diceNumber: diceNumber, 
                              isAdmin: widget.isAdmin, 
                              isFullScreen: true, 
                              playSound: _playSound,
                              currentUserId: currentUserId,
                            )
                          : LuckySpinView(
                              gameRef: _gameRef, 
                              userRef: FirebaseDatabase.instance.ref("users/$currentUserId"), 
                              userBalance: userBalance, 
                              betAmount: betAmount, 
                              luckyBets: luckyBets, 
                              playSound: _playSound
                            )
                        ),
                      ),
                ),
              ],
            ),
            
            // ব্যাক বাটন
            if (selectedGame != null)
              Positioned(
                top: 10, left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                  onPressed: () => setState(() => selectedGame = null),
                ),
              ),
            
            // ক্লোজ বাটন
            Positioned(
              top: 10, right: 10,
              child: IconButton(
                icon: const Icon(Icons.cancel, color: Colors.white, size: 28),
                onPressed: () {
                  if (widget.isAdmin || gameState == "WAITING") {
                    Navigator.pop(context);
                  } else {
                    _showError("গেম চলাকালীন রুম থেকে বের হওয়া যাবে না!");
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGameLobby() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("SELECT A GAME", style: TextStyle(color: Colors.white54, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _gameIcon("LUDO", "assets/images/ludo_logo.png", Colors.blueAccent),
              const SizedBox(width: 30),
              _gameIcon("LUCKY", "assets/images/spin_logo.png", Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gameIcon(String name, String asset, Color color) {
    return GestureDetector(
      onTap: () => setState(() => selectedGame = name),
      child: Column(
        children: [
          Container(
            width: 105, height: 105,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: color.withOpacity(0.6), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(asset, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 70, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // ডায়মন্ড মাঝখানে রাখার জন্য
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white10, 
              borderRadius: BorderRadius.circular(25), 
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3))
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond, color: Colors.cyanAccent, size: 22),
                const SizedBox(width: 8),
                Text("$userBalance", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _subscription?.cancel(); _audioPlayer.dispose(); super.dispose(); }
}
