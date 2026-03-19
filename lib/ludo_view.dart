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
          entryFee = int.tryParse(event.snapshot.value.toString()) ?? 100;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenHeight = constraints.maxHeight;
        double screenWidth = constraints.maxWidth;
        
        // বোর্ড সাইজ অ্যাডজাস্টমেন্ট: স্ক্রিন ছোট হোক বা বড়, এটি স্ক্রিন উইডথ অনুযায়ী সেট হবে
        double boardSize = screenWidth * 0.95; 
        if (boardSize > screenHeight * 0.5) {
          boardSize = screenHeight * 0.5; // লম্বা ফোনে বোর্ড খুব বেশি বড় হবে না
        }

        return Container(
          width: screenWidth,
          height: screenHeight,
          // প্যাডিং কমিয়ে ফুল স্ক্রিন ফিল আনা হয়েছে
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            children: [
              // ১. ডায়মন্ড কন্ট্রোল
              _buildDiamondControl(),
              
              const Spacer(), // ফ্লেক্সিবল স্পেস

              // ২. লুডু বোর্ড (পুরো ভিউর কেন্দ্রে)
              Container(
                width: boardSize,
                height: boardSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)
                  ],
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

              const Spacer(),

              // ৩. ছক্কা UI
              _buildDiceUI(),

              const Spacer(),

              // ৪. প্লেয়ার লিস্ট
              _buildPlayerList(),
              
              const SizedBox(height: 10),
            ],
          ),
        );
      }
    );
  }

  Widget _buildDiamondControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.diamond, color: Colors.cyanAccent, size: 22),
              const SizedBox(width: 8),
              if (widget.isAdmin) 
                _circleBtn(Icons.remove, () => _updateEntryFee(-100), Colors.redAccent),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text("$entryFee", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              
              if (widget.isAdmin) 
                _circleBtn(Icons.add, () => _updateEntryFee(100), Colors.greenAccent),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("WIN PRIZE", style: TextStyle(color: Colors.white54, fontSize: 10)),
              Text("💎 ${(entryFee * widget.players.length * 0.8).toInt()}", 
                style: const TextStyle(color: Colors.yellowAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.5))),
        child: Icon(icon, size: 16, color: color),
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
            height: 80, width: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: _getDiceColor(displayNum).withOpacity(0.4), blurRadius: 20, spreadRadius: 2)
              ],
            ),
            child: Center(child: _buildDiceDots(displayNum)),
          ),
          const SizedBox(height: 10),
          Text(
            isRolling ? "চাল চালছে..." : (widget.isAdmin ? "ছক্কা টিপুন" : "অপেক্ষা করুন..."),
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
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
    double tokenSize = boardSize * 0.085; 
    double offsetVal = boardSize * 0.048;

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
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
            ),
            child: photo != null && photo.isNotEmpty
              ? ClipOval(child: Image.network(photo, fit: BoxFit.cover))
              : const Icon(Icons.person, size: 14, color: Colors.white),
          ),
        ),
      );
    });
  }

  // বাকি ছোট ফাংশনগুলো (DiceDots, DiceColor, PlayerList) আপনার কোডের মতোই থাকবে।
  // আমি শুধু UI স্ট্রাকচারটা ফুল স্ক্রিন করার জন্য লেআউট ঠিক করেছি।

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
            width: 8, height: 8, 
            decoration: BoxDecoration(shape: BoxShape.circle, color: showDot ? Colors.black : Colors.transparent)
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
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.players.map((p) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              CircleAvatar(
                radius: 20, 
                backgroundColor: Colors.cyanAccent.withOpacity(0.5),
                child: CircleAvatar(radius: 18, backgroundImage: NetworkImage(p['photo'] ?? "")),
              ),
              const SizedBox(height: 4),
              Text(p['name']?.split(' ')[0] ?? "P", 
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}
