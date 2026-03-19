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

  const LudoView({
    super.key,
    required this.gameRef,
    required this.players,
    required this.diceNumber,
    required this.isAdmin,
    required this.isFullScreen,
    required this.playSound,
  });

  @override
  State<LudoView> createState() => _LudoViewState();
}

class _LudoViewState extends State<LudoView> {
  bool isRolling = false;
  int rollingNumber = 1;
  int sixCounter = 0; // পরপর কয়বার ৬ উঠলো তা মাপার জন্য

  // ছক্কা রোল করার ফাংশন
  void rollDice() async {
    if (!widget.isAdmin || isRolling) return;

    setState(() => isRolling = true);
    widget.playSound("https://www.soundjay.com/misc/sounds/dice-roll-01.mp3");

    // ১ সেকেন্ডের অ্যানিমেশন (নম্বর ঘুরবে)
    int count = 0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        rollingNumber = Random().nextInt(6) + 1;
      });
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

    // লজিক ১: ৩ বার ৬ উঠলে ফেইল
    if (finalNumber == 6) {
      sixCounter++;
      if (sixCounter >= 3) {
        sixCounter = 0;
        _showFlashMsg("৩ বার ৬! চাল বাতিল।");
        _passTurn(); // পরবর্তী প্লেয়ারের কাছে চাল চলে যাবে
        return;
      }
    } else {
      sixCounter = 0; // ৬ না উঠলে কাউন্টার রিসেট
    }

    // ডাটাবেজ আপডেট
    widget.gameRef.update({"diceNumber": finalNumber});

    // লজিক ২: ৬ উঠলে বোনাস চাল (এটি ডাটাবেজ ট্র্যাকার দিয়ে নিয়ন্ত্রণ হবে)
    if (finalNumber != 6) {
      // যদি ৬ না উঠে তবে নির্দিষ্ট সময় পর চাল অন্য প্লেয়ারে যাবে (লজিক অনুযায়ী)
    }
  }

  void _passTurn() {
     // ডাটাবেজে turnIndex আপডেট করার কোড এখানে বসবে
  }

  void _showFlashMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    double boardSize = widget.isFullScreen ? 350 : 280;

    return Column(
      children: [
        // লুডু বোর্ড এরিয়া
        Container(
          width: boardSize,
          height: boardSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
            image: const DecorationImage(
              image: AssetImage("assets/images/ludo_preview.png"),
              fit: BoxFit.fill,
            ),
          ),
          child: Stack(
            children: [
              // ১৬টি গুটি (৪ জন ইউজারের ৪টি করে)
              for (int i = 0; i < widget.players.length; i++)
                ..._buildUserTokens(i, widget.players[i]['photo'], boardSize),
            ],
          ),
        ),

        const SizedBox(height: 25),

        // ছক্কা সেকশন
        GestureDetector(
          onTap: rollDice,
          child: Column(
            children: [
              Container(
                height: 85,
                width: 85,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: _getDiceColor(isRolling ? rollingNumber : widget.diceNumber).withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2
                    )
                  ],
                ),
                child: Center(
                  // ছক্কার ডট ডিজাইন (SVG স্টাইল)
                  child: _buildDiceDots(isRolling ? rollingNumber : widget.diceNumber),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isRolling ? "ROLLING..." : (widget.isAdmin ? "TAP TO ROLL" : "WAITING..."),
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildPlayerList(),
      ],
    );
  }

  // ১৬টি গুটি তৈরির লজিক (৪ রঙে আলাদা করা)
  List<Widget> _buildUserTokens(int pIdx, String? photo, double size) {
    List<Alignment> baseAlignments = [
      const Alignment(-0.75, -0.75), // Red
      const Alignment(0.75, -0.75),  // Green
      const Alignment(-0.75, 0.75),  // Blue
      const Alignment(0.75, 0.75),   // Yellow
    ];

    List<Offset> offsets = [
      const Offset(-16, -16), const Offset(16, -16),
      const Offset(-16, 16), const Offset(16, 16),
    ];

    List<Color> pColors = [Colors.red, Colors.green, Colors.blue, Colors.orange];

    return List.generate(4, (i) {
      return Align(
        alignment: baseAlignments[pIdx % 4],
        child: Transform.translate(
          offset: offsets[i],
          child: GestureDetector(
            onTap: () => _onTokenTap(pIdx, i), // গুটি চালার লজিক
            child: Container(
              width: widget.isFullScreen ? 28 : 22,
              height: widget.isFullScreen ? 28 : 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pColors[pIdx % 4],
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
              ),
              child: ClipOval(
                child: photo != null 
                  ? Image.network(photo, fit: BoxFit.cover) 
                  : const Icon(Icons.person, size: 10, color: Colors.white),
              ),
            ),
          ),
        ),
      );
    });
  }

  // গুটি চালার (Move & Cut) লজিক
  void _onTokenTap(int pIdx, int tIdx) {
    // ১. চেক করবে এটি কি ইউজারের নিজের গুটি?
    // ২. ৬ উঠলে গুটি ঘর থেকে বের হবে (পজিশন ১ এ যাবে)।
    // ৩. অন্য গুটির ওপর পড়লে সেটা 'কাটা' যাবে (পজিশন ০ হবে)।
    // ৪. জেতার ঘরে পৌঁছালে পয়েন্ট যোগ হবে।
    print("Player $pIdx tapped token $tIdx");
  }

  // ছক্কার ডট ডিজাইন
  Widget _buildDiceDots(int n) {
    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(9, (index) {
        bool showDot = false;
        if (n == 1 && index == 4) showDot = true;
        if (n == 2 && (index == 0 || index == 8)) showDot = true;
        if (n == 3 && (index == 0 || index == 4 || index == 8)) showDot = true;
        if (n == 4 && (index == 0 || index == 2 || index == 6 || index == 8)) showDot = true;
        if (n == 5 && (index == 0 || index == 2 || index == 4 || index == 6 || index == 8)) showDot = true;
        if (n == 6 && (index == 0 || index == 2 || index == 3 || index == 5 || index == 6 || index == 8)) showDot = true;

        return Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: showDot ? Colors.black : Colors.transparent,
            ),
          ),
        );
      }),
    );
  }

  Color _getDiceColor(int n) {
    List<Color> colors = [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.pink];
    return colors[n - 1];
  }

  Widget _buildPlayerList() {
    return Wrap(
      spacing: 15,
      children: widget.players.map((p) => Column(
        children: [
          CircleAvatar(radius: 20, backgroundImage: NetworkImage(p['photo'] ?? "")),
          const SizedBox(height: 4),
          Text(p['name']?.split(' ')[0] ?? "Player", style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      )).toList(),
    );
  }
}
