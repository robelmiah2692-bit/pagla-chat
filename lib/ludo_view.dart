import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class LudoView extends StatefulWidget {
  final DatabaseReference gameRef;
  final List<Map<dynamic, dynamic>> players;
  final int diceNumber;
  final bool isAdmin;
  final bool isFullScreen;
  final Function(String) playSound;
  final String currentUserId; // ডায়মন্ড কাটার জন্য ইউজারের আইডি

  const LudoView({
    super.key,
    required this.gameRef,
    required this.players,
    required this.diceNumber,
    required this.isAdmin,
    required this.isFullScreen,
    required this.playSound,
    required this.currentUserId,
  });

  @override
  State<LudoView> createState() => _LudoViewState();
}

class _LudoViewState extends State<LudoView> {
  bool isRolling = false;
  int rollingNumber = 1;
  int sixCounter = 0;
  int entryFee = 100; // ডিফল্ট ডায়মন্ড এন্ট্রি ফি

  @override
  void initState() {
    super.initState();
    // ডাটাবেজ থেকে এন্ট্রি ফি রিয়েল-টাইমে দেখা
    widget.gameRef.child("entryFee").onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          entryFee = int.parse(event.snapshot.value.toString());
        });
      }
    });
  }

  // এডমিন ডায়মন্ড প্লাস/মাইনাস করতে পারবে
  void _updateEntryFee(int amount) {
    if (widget.isAdmin) {
      int newFee = (entryFee + amount).clamp(10, 10000);
      widget.gameRef.update({"entryFee": newFee});
    }
  }

  // ডায়মন্ড কাটার ফাংশন (জয়েন করার সময় কল হবে)
  void _deductDiamondForJoin() async {
    final userRef = FirebaseDatabase.instance.ref("users/${widget.currentUserId}");
    final snapshot = await userRef.child("diamonds").get();
    if (snapshot.exists) {
      int currentBalance = int.parse(snapshot.value.toString());
      if (currentBalance >= entryFee) {
        await userRef.update({"diamonds": currentBalance - entryFee});
        _showFlashMsg("$entryFee ডায়মন্ড কাটা হয়েছে।");
      } else {
        _showFlashMsg("পর্যাপ্ত ডায়মন্ড নেই!");
      }
    }
  }

  // উইনারকে ৮০% ডায়মন্ড দেওয়া
  void _distributeWinnings(String winnerId) {
    int totalPool = entryFee * widget.players.length;
    int winnerAmount = (totalPool * 0.8).toInt();
    FirebaseDatabase.instance.ref("users/$winnerId/diamonds").set(ServerValue.increment(winnerAmount));
  }

  void rollDice() async {
    if (!widget.isAdmin || isRolling) return;
    setState(() => isRolling = true);
    widget.playSound("https://www.soundjay.com/misc/sounds/dice-roll-01.mp3");

    int count = 0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() { rollingNumber = Random().nextInt(6) + 1; });
      count++;
      if (count >= 10) {
        timer.cancel();
        _finalizeDice();
      }
    });
  }

  void _finalizeDice() {
    int finalNumber = rollingNumber;
    setState(() => isRolling = false);

    if (finalNumber == 6) {
      sixCounter++;
      if (sixCounter >= 3) {
        sixCounter = 0;
        _showFlashMsg("৩ বার ৬! চাল বাতিল।");
        _passTurn();
        return;
      }
    } else { sixCounter = 0; }

    widget.gameRef.update({"diceNumber": finalNumber});
  }

  void _passTurn() { /* turnIndex logic */ }

  void _showFlashMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    // বোর্ড সাইজ বড় করা হয়েছে (স্ক্রিনের চওড়া অনুযায়ী)
    double boardSize = MediaQuery.of(context).size.width * 0.95;

    return Column(
      children: [
        // ডায়মন্ড +/- কন্ট্রোলার (শুধুমাত্র জয়েন করার আগে এডমিন দেখবে)
        _buildDiamondControl(),

        const SizedBox(height: 15),

        // লুডু বোর্ড এরিয়া
        Container(
          width: boardSize,
          height: boardSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
            image: const DecorationImage(
              image: AssetImage("assets/images/ludo_preview.png"),
              fit: BoxFit.fill,
            ),
          ),
          child: Stack(
            children: [
              for (int i = 0; i < widget.players.length; i++)
                ..._buildUserTokens(i, widget.players[i]['photo'], boardSize),
            ],
          ),
        ),

        const SizedBox(height: 25),

        // ছক্কা সেকশন (ডিজাইন ও লজিক ঠিক রাখা হয়েছে)
        _buildDiceUI(),

        const SizedBox(height: 20),
        _buildPlayerList(),
      ],
    );
  }

  Widget _buildDiamondControl() {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.diamond, color: Colors.cyanAccent),
              if (widget.isAdmin) IconButton(onPressed: () => _updateEntryFee(-10), icon: const Icon(Icons.remove_circle, color: Colors.redAccent)),
              Text("$entryFee", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              if (widget.isAdmin) IconButton(onPressed: () => _updateEntryFee(10), icon: const Icon(Icons.add_circle, color: Colors.greenAccent)),
            ],
          ),
          Text("Win: ${(entryFee * widget.players.length * 0.8).toInt()}", style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDiceUI() {
    return GestureDetector(
      onTap: rollDice,
      child: Column(
        children: [
          Container(
            height: 90, width: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: _getDiceColor(isRolling ? rollingNumber : widget.diceNumber).withOpacity(0.5), blurRadius: 15)],
            ),
            child: Center(child: _buildDiceDots(isRolling ? rollingNumber : widget.diceNumber)),
          ),
          const SizedBox(height: 10),
          Text(isRolling ? "ROLLING..." : (widget.isAdmin ? "ROLL DICE" : "WAITING..."),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  List<Widget> _buildUserTokens(int pIdx, String? photo, double size) {
    List<Alignment> baseAlignments = [
      const Alignment(-0.76, -0.76), const Alignment(0.76, -0.76),
      const Alignment(-0.76, 0.76), const Alignment(0.76, 0.76),
    ];
    List<Offset> offsets = [
      const Offset(-18, -18), const Offset(18, -18),
      const Offset(-18, 18), const Offset(18, 18),
    ];
    List<Color> pColors = [Colors.red, Colors.green, Colors.blue, Colors.orange];

    return List.generate(4, (i) {
      return Align(
        alignment: baseAlignments[pIdx % 4],
        child: Transform.translate(
          offset: offsets[i],
          child: Container(
            width: 30, height: 30, // গুটি বড় করা হয়েছে
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pColors[pIdx % 4],
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
            ),
            child: ClipOval(child: photo != null ? Image.network(photo, fit: BoxFit.cover) : const Icon(Icons.person, size: 14, color: Colors.white)),
          ),
        ),
      );
    });
  }

  Widget _buildDiceDots(int n) {
    return GridView.count(
      crossAxisCount: 3, padding: const EdgeInsets.all(12),
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      children: List.generate(9, (index) {
        bool showDot = false;
        if (n == 1 && index == 4) showDot = true;
        if (n == 2 && (index == 0 || index == 8)) showDot = true;
        if (n == 3 && (index == 0 || index == 4 || index == 8)) showDot = true;
        if (n == 4 && (index == 0 || index == 2 || index == 6 || index == 8)) showDot = true;
        if (n == 5 && (index == 0 || index == 2 || index == 4 || index == 6 || index == 8)) showDot = true;
        if (n == 6 && (index == 0 || index == 2 || index == 3 || index == 5 || index == 6 || index == 8)) showDot = true;
        return Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: showDot ? Colors.black : Colors.transparent)));
      }),
    );
  }

  Color _getDiceColor(int n) => [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.pink][n - 1];

  Widget _buildPlayerList() {
    return Wrap(
      spacing: 15,
      children: widget.players.map((p) => Column(
        children: [
          CircleAvatar(radius: 22, backgroundImage: NetworkImage(p['photo'] ?? "")),
          const SizedBox(height: 4),
          Text(p['name']?.split(' ')[0] ?? "P", style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      )).toList(),
    );
  }
}
