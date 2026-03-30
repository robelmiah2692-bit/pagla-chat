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
      if (event.snapshot.value == null || !mounted) return;
      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        gameState = data['gameState'] ?? "WAITING";
        diceNumber = data['diceNumber'] ?? 1;
        if (data['players'] != null) {
          players = (data['players'] as Map).values.map((e) => Map<dynamic, dynamic>.from(e)).toList();
        } else {
          players = [];
        }
        if (data['luckyBets'] != null) {
          luckyBets = (data['luckyBets'] as Map).values.map((e) => Map<dynamic, dynamic>.from(e)).toList();
        } else {
          luckyBets = [];
        }
      });
    });
  }

  // লুডু জয়েন করার সময় ডায়মন্ড কাটার লজিক এখানে ঠিক করা হয়েছে
  void _joinLudo() async {
    if (gameState == "RUNNING") {
      _showError("গেম চলছে! এই রাউন্ড শেষ হওয়া পর্যন্ত অপেক্ষা করুন।");
      return;
    }
    if (players.length >= 4) {
      _showError("রুম ফুল হয়ে গেছে!");
      return;
    }
    
    if (userBalance < betAmount) {
      _showError("আপনার পর্যাপ্ত ডায়মন্ড নেই!");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool alreadyJoined = players.any((p) => p['id'] == user.uid);
    if (!alreadyJoined) {
      try {
        // ১. Firestore থেকে ডায়মন্ড কাটা
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'diamonds': FieldValue.increment(-betAmount)
        });

        // ২. Realtime Database-এ প্লেয়ার লিস্টে যোগ করা
        await _gameRef.child("players").child(user.uid).set({
          "id": user.uid,
          "name": user.displayName ?? "Player",
          "photo": user.photoURL ?? "",
          "bet": betAmount,
        });
        
        _playSound("https://www.soundjay.com/buttons/sounds/button-3.mp3");
      } catch (e) {
        _showError("জয়েন করতে সমস্যা হয়েছে। আবার চেষ্টা করুন।");
      }
    } else {
      _showError("আপনি ইতিমধ্যে জয়েন করেছেন।");
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
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: Color(0xFF0F0F1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 50), 
                
                _buildGameHeader(), 

                if (selectedGame == "LUDO" && gameState == "WAITING")
                  _buildLudoActionButtons(),

                Expanded(
                  child: selectedGame == null 
                    ? _buildGameLobby() 
                    : (selectedGame == "LUDO" 
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
                            // এখানে userRef হিসেবে সঠিক Realtime Database পাথ অথবা logic হ্যান্ডেল করতে হবে
                            userRef: FirebaseDatabase.instance.ref("users/$currentUserId"), 
                            userBalance: userBalance, 
                            betAmount: betAmount, 
                            luckyBets: luckyBets, 
                            playSound: _playSound,
                          )
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
                Text("$userBalance", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          if (selectedGame != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => betAmount = max(100, betAmount - 100)),
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 26),
                  ),
                  Text("$betAmount", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => setState(() => betAmount += 100),
                    icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent, size: 26),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 50), 
        ],
      ),
    );
  }

  Widget _buildLudoActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _joinLudo,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            child: const Text("JOIN GAME", style: TextStyle(color: Colors.white)),
          ),
          if (widget.isAdmin) ...[
            const SizedBox(width: 15),
            ElevatedButton(
              onPressed: _startLudo,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: const Text("START GAME", style: TextStyle(color: Colors.white)),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildFloatingNavButtons() {
    return Stack(
      children: [
        if (selectedGame != null)
          Positioned(
            top: 45, left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
              onPressed: () => setState(() => selectedGame = null),
            ),
          ),
        Positioned(
          top: 45, right: 10,
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
            onPressed: () {
              if (widget.isAdmin || gameState == "WAITING") {
                Navigator.pop(context);
              } else {
                _showError("গেম চলাকালীন রুম থেকে বের হওয়া যাবে না!");
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGameLobby() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("SELECT A GAME", style: TextStyle(color: Colors.white54, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _gameIcon("LUDO", "assets/images/ludo_logo.png", Colors.blueAccent),
            const SizedBox(width: 40),
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
            width: 105, height: 105,
            decoration: BoxDecoration(
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

  @override
  void dispose() { _subscription?.cancel(); _audioPlayer.dispose(); super.dispose(); }
}
