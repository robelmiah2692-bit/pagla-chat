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
  final String currentUserId;

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
  int entryFee = 100;

  @override
  void initState() {
    super.initState();
    _listenToEntryFee();
  }

  void _listenToEntryFee() {
    widget.gameRef.child("entryFee").onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        setState(() {
          entryFee = int.parse(event.snapshot.value.toString());
        });
      }
    });
  }

  void _updateEntryFee(int amount) {
    if (widget.isAdmin) {
      int newFee = (entryFee + amount).clamp(10, 10000);
      widget.gameRef.update({"entryFee": newFee});
    }
  }

  // গেম শেষ হলে উইনারকে ডায়মন্ড দেওয়ার জন্য এই ফাংশনটি কল করবেন
  void _distributeWinnings(String winnerId) {
    int totalPool = entryFee * widget.players.length;
    int winnerAmount = (totalPool * 0.8).toInt();
    FirebaseDatabase.instance.ref("users/$winnerId/diamonds").set(ServerValue.increment(winnerAmount));
    _showFlashMsg("বিজয়ী 💎$winnerAmount ডায়মন্ড পেয়েছেন!");
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
        // এখানে টার্ন পাস করার লজিক দিতে পারেন
        return;
      }
    } else {
      sixCounter = 0;
    }
    widget.gameRef.update({"diceNumber": finalNumber});
  }

  void _showFlashMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    double boardSize = MediaQuery.of(context).size.width * 0.92;

    return Column(
      children: [
        // ডায়মন্ড এবং উইন প্রাইস ডিসপ্লে
        _buildDiamondControl(),

        const SizedBox(height: 15),

        // লুডু বোর্ড
        Container(
          width: boardSize,
          height: boardSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 15, spreadRadius: 2)],
            image: const DecorationImage(
              image: AssetImage("assets/images/ludo_preview.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              for (int i = 0; i < widget.players.length; i++)
                ..._buildUserTokens(i, widget.players[i]['photo'], boardSize),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // ছক্কা UI
        _buildDiceUI(),

        const SizedBox(height: 20),
        
        // বর্তমান প্লেয়ার লিস্ট
        _buildPlayerList(),
      ],
    );
  }

  Widget _buildDiamondControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.diamond, color: Colors.cyanAccent, size: 28),
              const SizedBox(width: 8),
              if (widget.isAdmin) 
                IconButton(onPressed: () => _updateEntryFee(-10), icon: const Icon(Icons.do_not_disturb_on, color: Colors.redAccent)),
              Text("$entryFee", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              if (widget.isAdmin) 
                IconButton(onPressed: () => _updateEntryFee(10), icon: const Icon(Icons.add_circle, color: Colors.greenAccent)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("WIN PRIZE", style: TextStyle(color: Colors.white54, fontSize: 10)),
              Text("💎 ${(entryFee * widget.players.length * 0.8).toInt()}", 
                style: const TextStyle(color: Colors.yellowAccent, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiceUI() {
    int displayNum = isRolling ? rollingNumber : widget.diceNumber;
    return GestureDetector(
      onTap: rollDice,
      child: Column(
        children: [
          Container(
            height: 85, width: 85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _getDiceColor(displayNum).withOpacity(0.4), 
                  blurRadius: 20, 
                  spreadRadius: 5
                )
              ],
            ),
            child: Center(child: _buildDiceDots(displayNum)),
          ),
          const SizedBox(height: 12),
          Text(
            isRolling ? "ROLLING..." : (widget.isAdmin ? "TAP TO ROLL" : "WAITING FOR TURN"),
            style: TextStyle(
              color: isRolling ? Colors.orangeAccent : Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2
            ),
          ),
        ],
      ),
    );
  }

  // গুটির পজিশন এবং ডিজাইন
  List<Widget> _buildUserTokens(int pIdx, String? photo, double boardSize) {
    // ঘরগুলোর এলাইনমেন্ট (লুডু বোর্ডের হোম বেস অনুযায়ী)
    List<Alignment> baseAlignments = [
      const Alignment(-0.73, -0.73), // Red
      const Alignment(0.73, -0.73),  // Green
      const Alignment(0.73, 0.73),   // Yellow
      const Alignment(-0.73, 0.73),  // Blue
    ];
    
    // ৪টি গুটির আলাদা আলাদা অফসেট
    List<Offset> tokenOffsets = [
      const Offset(-16, -16), const Offset(16, -16),
      const Offset(-16, 16), const Offset(16, 16),
    ];
    
    List<Color> pColors = [Colors.red, Colors.green, Colors.yellow, Colors.blue];

    return List.generate(4, (i) {
      return Align(
        alignment: baseAlignments[pIdx % 4],
        child: Transform.translate(
          offset: tokenOffsets[i],
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pColors[pIdx % 4],
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 2))],
            ),
            child: photo != null 
              ? ClipOval(child: Image.network(photo, fit: BoxFit.cover))
              : const Icon(Icons.person, size: 14, color: Colors.white),
          ),
        ),
      );
    });
  }

  Widget _buildDiceDots(int n) {
    return GridView.count(
      crossAxisCount: 3, padding: const EdgeInsets.all(15),
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      children: List.generate(9, (index) {
        bool showDot = false;
        if (n == 1 && index == 4) showDot = true;
        if (n == 2 && (index == 2 || index == 6)) showDot = true;
        if (n == 3 && (index == 2 || index == 4 || index == 6)) showDot = true;
        if (n == 4 && (index == 0 || index == 2 || index == 6 || index == 8)) showDot = true;
        if (n == 5 && (index == 0 || index == 2 || index == 4 || index == 6 || index == 8)) showDot = true;
        if (n == 6 && (index == 0 || index == 2 || index == 3 || index == 5 || index == 6 || index == 8)) showDot = true;
        return Center(
          child: Container(
            width: 9, height: 9, 
            decoration: BoxDecoration(shape: BoxShape.circle, color: showDot ? Colors.black87 : Colors.transparent)
          )
        );
      }),
    );
  }

  Color _getDiceColor(int n) {
    List<Color> colors = [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.pink];
    return colors[(n - 1) % colors.length];
  }

  Widget _buildPlayerList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: widget.players.map((p) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.cyanAccent, width: 1.5)),
              child: CircleAvatar(radius: 20, backgroundImage: NetworkImage(p['photo'] ?? "")),
            ),
            const SizedBox(height: 5),
            Text(
              p['name']?.split(' ')[0] ?? "Player", 
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)
            ),
          ],
        )).toList(),
      ),
    );
  }
}
