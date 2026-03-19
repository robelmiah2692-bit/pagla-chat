import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class LudoView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    double boardSize = isFullScreen ? 350 : 280;

    return Column(
      children: [
        // লুডু বোর্ড এরিয়া
        Container(
          width: boardSize,
          height: boardSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
            image: const DecorationImage(
              image: AssetImage("assets/images/ludo_preview.png"), // আপনার বোর্ডের ছবি
              fit: BoxFit.fill,
            ),
          ),
          child: Stack(
            children: [
              // ৪ জন প্লেয়ারের গুটিগুলো তাদের ঘরে বসানো
              for (int i = 0; i < players.length; i++) 
                ..._buildProfessionalTokens(i, players[i]['photo'], boardSize),
            ],
          ),
        ),
        
        const SizedBox(height: 25),

        // ছক্কা (Dice) সেকশন - আপনার দেওয়া ডিজাইন অনুযায়ী
        GestureDetector(
          onTap: () {
            if (isAdmin) {
              playSound("https://www.soundjay.com/misc/sounds/dice-roll-01.mp3");
              gameRef.update({"diceNumber": Random().nextInt(6) + 1});
            }
          },
          child: Column(
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: _getDiceColor(diceNumber).withOpacity(0.5), blurRadius: 15, spreadRadius: 2)
                  ],
                ),
                child: Center(
                  // এখানে আপনার দেওয়া ছক্কার ছবি বা আইকন বসবে
                  child: Icon(_getDiceIcon(diceNumber), size: 60, color: _getDiceColor(diceNumber)),
                ),
              ),
              const SizedBox(height: 8),
              Text(isAdmin ? "ROLL DICE" : "WAITING...", 
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildPlayerList(),
      ],
    );
  }

  // গুটিগুলোকে বোর্ডের চার রঙের বক্সে সঠিক পজিশনে বসানোর লজিক
  List<Widget> _buildProfessionalTokens(int pIdx, String? photo, double size) {
    // লাল, সবুজ, নীল, হলুদ ঘরের পজিশন (বোর্ডের ডিজাইন অনুযায়ী)
    List<Alignment> baseAlignments = [
      Alignment(-0.72, -0.72), // Red (Top Left)
      Alignment(0.72, -0.72),  // Green (Top Right)
      Alignment(-0.72, 0.72),  // Blue (Bottom Left)
      Alignment(0.72, 0.72),   // Yellow (Bottom Right)
    ];

    // ঘরের ভেতরে ৪টি গুটির আলাদা পজিশন
    List<Offset> offsets = [
      const Offset(-15, -15),
      const Offset(15, -15),
      const Offset(-15, 15),
      const Offset(15, 15),
    ];

    return List.generate(4, (i) {
      return Align(
        alignment: baseAlignments[pIdx % 4],
        child: Transform.translate(
          offset: offsets[i],
          child: Container(
            width: isFullScreen ? 28 : 22,
            height: isFullScreen ? 28 : 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
            ),
            child: ClipOval(
              child: photo != null 
                ? Image.network(photo, fit: BoxFit.cover) 
                : Container(color: _getDiceColor(pIdx + 1), child: const Icon(Icons.person, size: 12, color: Colors.white)),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPlayerList() {
    return Wrap(
      spacing: 20,
      children: players.map((p) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.cyanAccent, width: 1.5)),
            child: CircleAvatar(radius: 22, backgroundImage: NetworkImage(p['photo'] ?? "")),
          ),
          const SizedBox(height: 4),
          Text(p['name']?.split(' ')[0] ?? "Player", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      )).toList(),
    );
  }

  IconData _getDiceIcon(int n) => [
    Icons.looks_one, Icons.looks_two, Icons.looks_3, 
    Icons.looks_4, Icons.looks_5, Icons.looks_6
  ][n - 1];

  Color _getDiceColor(int n) {
    List<Color> colors = [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.pink];
    return colors[n - 1];
  }
}
