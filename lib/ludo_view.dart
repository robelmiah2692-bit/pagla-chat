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

  void _distributeWinnings(String winnerId) {
    int totalPool = entryFee * widget.players.length;
    int winnerAmount = (totalPool * 0.8).toInt();
    FirebaseDatabase.instance.ref("users/$winnerId/diamonds").set(ServerValue.increment(winnerAmount));
    _showFlashMsg("বিজয়ী 💎$winnerAmount ডায়মন্ড পেয়েছেন!");
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
    // স্ক্রিনের হাইট এবং উইডথ চেক করা
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenHeight = constraints.maxHeight;
        double screenWidth = constraints.maxWidth;
        // বোর্ড সাইজ স্ক্রিনের উইডথ এর ৯০% এর বেশি হবে না
        double boardSize = screenWidth * 0.92;
        if (boardSize > screenHeight * 0.45) {
          boardSize = screenHeight * 0.45; // লম্বা স্ক্রিনে বোর্ড ছোট রাখা যেন বাকি অংশ দেখা যায়
        }

        return Container(
          height: screenHeight,
          width: screenWidth,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // সমান দূরত্বে আইটেম রাখা
            children: [
              // ১. ডায়মন্ড কন্ট্রোল (টপ সেকশন)
              _buildDiamondControl(),

              // ২. লুডু বোর্ড সেকশন (মাঝের সেকশন)
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

              // ৩. ছক্কা UI সেকশন
              _buildDiceUI(),

              // ৪. বর্তমান প্লেয়ার লিস্ট (বটম সেকশন)
              _buildPlayerList(),
            ],
          ),
        );
      }
    );
  }

  Widget _buildDiamondControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.diamond, color: Colors.cyanAccent, size: 24),
              const SizedBox(width: 5),
              if (widget.isAdmin) 
                IconButton(onPressed: () => _updateEntryFee(-10), icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20)),
              Text("$entryFee", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              if (widget.isAdmin) 
                IconButton(onPressed: () => _updateEntryFee(10), icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent, size: 20)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("WIN PRIZE", style: TextStyle(color: Colors.white54, fontSize: 9)),
              Text("💎 ${(entryFee * widget.players.length * 0.8).toInt()}", 
                style: const TextStyle(color: Colors.yellowAccent, fontSize: 16, fontWeight: FontWeight.bold)),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 70, width: 70, // সাইজ সামান্য কমানো হয়েছে ফিট করার জন্য
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: _getDiceColor(displayNum).withOpacity(0.3), blurRadius: 15, spreadRadius: 2)
              ],
            ),
            child: Center(child: _buildDiceDots(displayNum)),
          ),
          const SizedBox(height: 8),
          Text(
            isRolling ? "ROLLING..." : (widget.isAdmin ? "TAP TO ROLL" : "WAITING..."),
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUserTokens(int pIdx, String? photo, double boardSize) {
    List<Alignment> baseAlignments = [
      const Alignment(-0.73, -0.73), const Alignment(0.73, -0.73),
      const Alignment(0.73, 0.73), const Alignment(-0.73, 0.73),
    ];
    // বোর্ড সাইজ অনুযায়ী টোকেন সাইজ এবং অফসেট অ্যাডজাস্ট করা হয়েছে
    double tokenSize = boardSize * 0.08; 
    double offsetVal = boardSize * 0.045;

    List<Offset> tokenOffsets = [
      Offset(-offsetVal, -offsetVal), Offset(offsetVal, -offsetVal),
      Offset(-offsetVal, offsetVal), Offset(offsetVal, offsetVal),
    ];
    
    List<Color> pColors = [Colors.red, Colors.green, Colors.yellow, Colors.blue];

    return List.generate(4, (i) {
      return Align(
        alignment: baseAlignments[pIdx % 4],
        child: Transform.translate(
          offset: tokenOffsets[i],
          child: Container(
            width: tokenSize, height: tokenSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pColors[pIdx % 4],
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 3)],
            ),
            child: photo != null && photo.isNotEmpty
              ? ClipOval(child: Image.network(photo, fit: BoxFit.cover))
              : const Icon(Icons.person, size: 12, color: Colors.white),
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
        if (n == 2 && (index == 2 || index == 6)) showDot = true;
        if (n == 3 && (index == 2 || index == 4 || index == 6)) showDot = true;
        if (n == 4 && (index == 0 || index == 2 || index == 6 || index == 8)) showDot = true;
        if (n == 5 && (index == 0 || index == 2 || index == 4 || index == 6 || index == 8)) showDot = true;
        if (n == 6 && (index == 0 || index == 2 || index == 3 || index == 5 || index == 6 || index == 8)) showDot = true;
        return Center(
          child: Container(
            width: 7, height: 7, 
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
    return Container(
      constraints: const BoxConstraints(maxHeight: 80),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.players.map((p) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 18, 
                  backgroundColor: Colors.cyanAccent,
                  child: CircleAvatar(radius: 16, backgroundImage: NetworkImage(p['photo'] ?? "")),
                ),
                const SizedBox(height: 4),
                Text(p['name']?.split(' ')[0] ?? "Player", 
                  style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
}
