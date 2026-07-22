import 'package:flutter/material.dart';
import 'package:pagla_chat/ludo_game/token.dart';
import 'package:provider/provider.dart';
import 'package:pagla_chat/ludo_game/dice_model.dart';
import 'package:pagla_chat/ludo_game/game_state.dart'; // গেমস্টেট ইমপোর্ট করুন

class Dice extends StatelessWidget {
  // আপনার ইউজার টাইপ (উদাহরণস্বরূপ)
  final TokenType myType; 

  Dice({required this.myType});

  void updateDices(DiceModel dice, GameState gameState) {
    // সিকিউরিটি চেক: শুধু বর্তমান প্লেয়ারই ডাইস রোল করতে পারবে
    if (gameState.currentPlayer != myType) {
      debugPrint("এটি আপনার চাল নয়!");
      return;
    }

    // ডাইস রোলিং লজিক
    for (int i = 0; i < 6; i++) {
      Future.delayed(Duration(milliseconds: 100 + i * 100), () {
        dice.generateDiceOne();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> _diceOneImages = [
      "assets/1.png", "assets/2.png", "assets/3.png", 
      "assets/4.png", "assets/5.png", "assets/6.png",
    ];

    // প্রয়োজনীয় মডেলগুলো কল করলাম
    final dice = Provider.of<DiceModel>(context);
    final gameState = Provider.of<GameState>(context);
    final c = dice.diceOneCount;

    var img = Image.asset(
      _diceOneImages[c - 1],
      gaplessPlayback: true,
      fit: BoxFit.fill,
    );

    return Card(
      elevation: 10,
      child: Container(
        height: 40,
        width: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: GestureDetector(
                    // ক্লিক করার সময় চেক হবে প্লেয়ার ঠিক কি না
                    onTap: () => updateDices(dice, gameState),
                    child: img,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}