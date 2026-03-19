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
    return Column(
      children: [
        Container(
          width: isFullScreen ? 350 : 250,
          height: isFullScreen ? 350 : 250,
          decoration: const BoxDecoration(image: DecorationImage(image: AssetImage("assets/images/ludo_preview.png"))),
          child: Stack(
            children: [
              for (int i = 0; i < players.length; i++) ..._buildTokens(i, players[i]['photo'], isFullScreen),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (isAdmin)
          GestureDetector(
            onTap: () {
              playSound("https://www.soundjay.com/misc/sounds/dice-roll-01.mp3");
              gameRef.update({"diceNumber": Random().nextInt(6) + 1});
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 10)]),
              child: Icon(_getDiceIcon(diceNumber), size: 55, color: Colors.black),
            ),
          ),
        const SizedBox(height: 15),
        _buildPlayerList(),
      ],
    );
  }

  List<Widget> _buildTokens(int pIdx, String? photo, bool full) {
    List<Alignment> aligns = [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight];
    return List.generate(4, (i) => Align(
      alignment: aligns[pIdx % 4],
      child: Padding(
        padding: EdgeInsets.all(full ? 45 : 30),
        child: CircleAvatar(radius: full ? 12 : 9, backgroundColor: Colors.white, child: CircleAvatar(radius: full ? 10 : 7, backgroundImage: NetworkImage(photo ?? ""))),
      ),
    ));
  }

  Widget _buildPlayerList() {
    return Wrap(
      spacing: 15,
      children: players.map((p) => Column(
        children: [
          CircleAvatar(radius: 20, backgroundImage: NetworkImage(p['photo'] ?? "")),
          Text(p['name']?.split(' ')[0] ?? "", style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      )).toList(),
    );
  }

  IconData _getDiceIcon(int n) => [Icons.looks_one, Icons.looks_two, Icons.looks_3, Icons.looks_4, Icons.looks_5, Icons.looks_6][n - 1];
}
