import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pagla_chat/ludo_game/sound_service.dart';
import 'package:pagla_chat/ludo_game/token.dart';
import 'package:provider/provider.dart';
import 'package:pagla_chat/ludo_game/dice_model.dart';
import 'package:pagla_chat/ludo_game/game_state.dart';
import 'package:firebase_database/firebase_database.dart';

class Dice extends StatelessWidget {
  final TokenType myType; 
  final String roomId; // রুম আইডি রিসিভ করার জন্য

  Dice({required this.myType, required this.roomId});

  void updateDices(DiceModel dice, GameState gameState, bool hasRolled) {
    // সিকিউরিটি চেক: শুধু বর্তমান প্লেয়ারই ডাইস রোল করতে পারবে
    if (gameState.currentPlayer != myType) {
      debugPrint("এটি আপনার চাল নয়!");
      return;
    }

    // যদি ইতিমধ্যে একবার ডাইস রোল করা হয়ে থাকে এবং ৬ না উঠে থাকে, তবে আর রোল করতে পারবে না
    if (hasRolled) {
      debugPrint("আপনি ইতিমধ্যে একবার ডাইস রোল করেছেন! এখন গুটি চালুন।");
      return;
    }

     SoundService.playDiceSound();

    // ডাইস রোলিং অ্যানিমেশন ও ফায়ারবেসে লাইভ আপডেট লজিক
    for (int i = 0; i < 6; i++) {
      Future.delayed(Duration(milliseconds: 100 + i * 100), () {
        dice.generateDiceOne();
        
        int rolledValue = dice.diceOneCount;

        // ডাইসের ঘুরার প্রতিটা ধাপ এবং hasRolled স্ট্যাটাস ফায়ারবেসে পাঠিয়ে দেওয়া হচ্ছে
        FirebaseDatabase.instance.ref("ludo_rooms/$roomId/dice_state").set({
          "diceValue": rolledValue,
          "roller": myType.toString(),
          "hasRolled": true, // একবার ঘোরানোর পর এটি true হয়ে যাবে যাতে পুনরায় ক্লিক করা না যায়
          "timestamp": ServerValue.timestamp,
        });

        // অ্যানিমেশন শেষ হওয়ার পর (শেষ লুপে) লুডুর নিয়ম চেক করা
        if (i == 5) {
          gameState.handleDiceResult(rolledValue);
          
          // যদি ৬ না ওঠে, তবে ফায়ারবেসে hasRolled স্ট্যাটাসটি পাকাপাকিভাবে true সেভ রাখা যাতে আর না ঘুরে
          // আর যদি ৬ ওঠে, তবে ফায়ারবেসের hasRolled আবার false করে দেওয়া যাতে আবার রোল করা যায়
          if (rolledValue == 6) {
            FirebaseDatabase.instance.ref("ludo_rooms/$roomId/dice_state").update({
              "hasRolled": false,
            });
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> _diceOneImages = [
      "assets/1.png", "assets/2.png", "assets/3.png", 
      "assets/4.png", "assets/5.png", "assets/6.png",
    ];

    final dice = Provider.of<DiceModel>(context);
    final gameState = Provider.of<GameState>(context);

    // ফায়ারবেস থেকে রিয়েল-টাইমে ডাইসের ডাটা শোনার জন্য StreamBuilder ব্যবহার করা হলো
    DatabaseReference diceRef = FirebaseDatabase.instance.ref("ludo_rooms/$roomId/dice_state");

    return StreamBuilder(
      stream: diceRef.onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        int currentDiceValue = dice.diceOneCount; // ডিফল্ট লোকাল ভ্যালু
        bool hasRolled = false;

        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          currentDiceValue = data["diceValue"] ?? 1;
          hasRolled = data["hasRolled"] ?? false;

          // ফায়ারবেসে সেভ থাকা roller যদি বর্তমান গেমের currentPlayer-এর সাথে না মিলে, 
          // অথবা গেমের currentPlayer যদি পরিবর্তিত হয়ে থাকে, তবে স্বয়ংক্রিয়ভাবে hasRolled ফল্স হয়ে যাবে
          String roller = data["roller"] ?? "";
          if (roller != gameState.currentPlayer.toString()) {
            hasRolled = false;
          }
        }

        var img = Image.asset(
          _diceOneImages[(currentDiceValue >= 1 && currentDiceValue <= 6) ? currentDiceValue - 1 : 0],
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
                        onTap: () => updateDices(dice, gameState, hasRolled),
                        child: img,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}