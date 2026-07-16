import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pagla_chat/ludo_game/dice.dart';
import 'package:provider/provider.dart';
import 'package:pagla_chat/ludo_game/game_state.dart';
import 'package:pagla_chat/ludo_game/token.dart';

class PlayerContainer extends StatelessWidget {
  final TokenType type;
  final String playerName;
  final String avatar;

  PlayerContainer(
      {required this.type, required this.playerName, required this.avatar});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, gameState, _) {
      bool isMyTurn = gameState.currentPlayer == type;

      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                  color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: avatar.isNotEmpty
                      ? NetworkImage(avatar)
                      : null, // নেটওয়ার্ক ইমেজ থেকে ডাটা আসবে
                  child: avatar.isEmpty
                      ? Icon(Icons.person, size: 20, color: Colors.white)
                      : null,
                ),
                SizedBox(height: 4),
                Text(
                  playerName.isNotEmpty ? playerName : "Empty",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                ),
                if (isMyTurn)
                  Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: Dice(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}