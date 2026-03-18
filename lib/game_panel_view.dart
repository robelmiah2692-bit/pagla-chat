import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GamePanelView extends StatefulWidget {
  final String roomId; // আপনার ভয়েস রুমের আইডি এখানে পাস করবেন
  const GamePanelView({super.key, required this.roomId});

  @override
  State<GamePanelView> createState() => _GamePanelViewState();
}

class _GamePanelViewState extends State<GamePanelView> {
  // ফায়ারবেস রেফারেন্স
  late DatabaseReference _gameRef;
  StreamSubscription? _subscription;

  // গেম স্টেট ভেরিয়েবল
  int diamondBet = 100;
  bool isGameStarted = false;
  List<Map<dynamic, dynamic>> players = [];
  int turnIndex = 0;
  int diceNumber = 1;
  bool isRolling = false;
  
  // অটো চালের টাইমার
  Timer? _autoTimer;
  int _secondsLeft = 4;

  @override
  void initState() {
    super.initState();
    // রুম আইডি অনুযায়ী পাথ সেটআপ
    _gameRef = FirebaseDatabase.instance.ref("ludo_games/${widget.roomId}");
    _listenToGame();
  }

  // ফায়ারবেস থেকে লাইভ আপডেট শোনা
  void _listenToGame() {
    _subscription = _gameRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      if (mounted) {
        setState(() {
          isGameStarted = data['isStarted'] ?? false;
          turnIndex = data['turnIndex'] ?? 0;
          diceNumber = data['diceNumber'] ?? 1;
          diamondBet = data['bet'] ?? 100;

          if (data['players'] != null) {
            Map pMap = data['players'];
            players = pMap.values.map((e) => e as Map).toList();
            // জয়েনিং টাইম অনুযায়ী সর্ট করা যাতে সবার স্ক্রিনে প্লেয়ার পজিশন এক থাকে
            players.sort((a, b) => (a['joinedAt'] ?? 0).compareTo(b['joinedAt'] ?? 0));
          }
        });

        // যদি গেম চলে এবং আপনার চাল হয়, তবে টাইমার শুরু হবে
        if (isGameStarted) {
          _startTimer();
        }
      }
    });
  }

  void _startTimer() {
    _autoTimer?.cancel();
    _secondsLeft = 4;
    
    // চেক করা হচ্ছে এটা কি বর্তমান ইউজারের চাল কি না
    final myId = FirebaseAuth.instance.currentUser?.uid;
    if (players.isNotEmpty && players[turnIndex]['id'] == myId) {
      _autoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsLeft > 0) {
          setState(() => _secondsLeft--);
        } else {
          timer.cancel();
          _rollDice(); // ৪ সেকেন্ড শেষ হলে অটোমেটিক চাল
        }
      });
    }
  }

  // জয়েন করার ফাংশন
  Future<void> _joinGame() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || players.length >= 4) return;

    // অলরেডি জয়েন করা আছে কি না চেক
    if (players.any((p) => p['id'] == user.uid)) return;

    await _gameRef.child("players").child(user.uid).set({
      "id": user.uid,
      "name": user.displayName ?? "User ${players.length + 1}",
      "photo": user.photoURL ?? "",
      "joinedAt": ServerValue.timestamp,
    });
  }

  // ডাইস রোল করা
  Future<void> _rollDice() async {
    if (isRolling) return;
    _autoTimer?.cancel();
    setState(() => isRolling = true);

    int result = Random().nextInt(6) + 1;

    // গেমের রেজাল্ট আপডেট (এখানে লজিক: ৬ পেলে উইন)
    if (result == 6) {
      await _handleWin();
    } else {
      await _gameRef.update({
        "diceNumber": result,
        "turnIndex": (turnIndex + 1) % players.length,
      });
    }
    setState(() => isRolling = false);
  }

  Future<void> _handleWin() async {
    int totalPot = diamondBet * players.length;
    int winnerShare = (totalPot * 0.8).toInt(); // ৮০% উইনার পাবে

    // এখানে আপনার ডায়মন্ড ট্রানজ্যাকশন লজিক কল করবেন
    
    await _gameRef.update({
      "isStarted": false,
      "lastWinner": players[turnIndex]['name'],
    });

    _showResult(players[turnIndex]['name'], winnerShare);
    // গেম ডেটা রিসেট
    Future.delayed(const Duration(seconds: 3), () => _gameRef.remove());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: isGameStarted ? _buildGameUI() : _buildLobbyUI(),
    );
  }

  // গেম বোর্ড ডিজাইন
  Widget _buildGameUI() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("💎 Pot: ${diamondBet * players.length}", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              child: Text("Auto: $_secondsLeft", style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ৪ কোণার ৪ প্লেয়ার (ছবি সহ)
              for (int i = 0; i < players.length; i++) _buildPlayerSpot(i),
              
              // মাঝখানে ডাইস
              GestureDetector(
                onTap: () {
                  final myId = FirebaseAuth.instance.currentUser?.uid;
                  if (players[turnIndex]['id'] == myId) _rollDice();
                },
                child: _buildDice(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerSpot(int i) {
    final alignments = [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight];
    bool isMyTurn = turnIndex == i;
    
    return Align(
      alignment: alignments[i],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isMyTurn ? Colors.cyanAccent : Colors.transparent, width: 3),
              boxShadow: isMyTurn ? [BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 10)] : [],
            ),
            child: CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(players[i]['photo'] ?? ""),
              child: players[i]['photo'] == "" ? const Icon(Icons.person) : null,
            ),
          ),
          const SizedBox(height: 5),
          Text(players[i]['name'], style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildDice() {
    return Container(
      width: 70, height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 15)],
      ),
      child: Icon(_getDiceIcon(diceNumber), size: 45, color: Colors.black87),
    );
  }

  // লবি ডিজাইন (জয়েন এবং স্টার্ট)
  Widget _buildLobbyUI() {
    return Column(
      children: [
        const Text("LUDO MATCH", style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        Wrap(
          spacing: 20,
          children: List.generate(4, (index) => _buildLobbySlot(index)),
        ),
        const Spacer(),
        _betControl(),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
          onPressed: players.length == 4 ? () => _gameRef.update({"isStarted": true}) : _joinGame,
          child: Text(players.length == 4 ? "START GAME" : "JOIN GAME (${players.length}/4)"),
        ),
      ],
    );
  }

  Widget _buildLobbySlot(int index) {
    bool occupied = index < players.length;
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white12,
          backgroundImage: occupied ? NetworkImage(players[index]['photo'] ?? "") : null,
          child: !occupied ? const Icon(Icons.add, color: Colors.white24) : null,
        ),
        const SizedBox(height: 5),
        Text(occupied ? players[index]['name'] : "Waiting...", style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _betControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => _gameRef.update({"bet": diamondBet - 50})),
        Text("💎 $diamondBet", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => _gameRef.update({"bet": diamondBet + 50})),
      ],
    );
  }

  IconData _getDiceIcon(int n) => [Icons.looks_one, Icons.looks_two, Icons.looks_3, Icons.looks_4, Icons.looks_5, Icons.looks_6][n-1];

  void _showResult(String name, int amount) {
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text("Winner!", style: TextStyle(color: Colors.cyanAccent)),
      content: Text("$name জিতেছেন 💎 $amount ডায়মন্ড!"),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
    ));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _autoTimer?.cancel();
    super.dispose();
  }
}
