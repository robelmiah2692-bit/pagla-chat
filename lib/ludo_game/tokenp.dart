import 'package:flutter/material.dart';
import 'package:pagla_chat/ludo_game/dice_model.dart';
import 'package:pagla_chat/ludo_game/game_state.dart';
import 'package:pagla_chat/ludo_game/token.dart';
import 'package:provider/provider.dart';

class Tokenp extends StatelessWidget {
  final Token token;
  final List<double> dimentions;
  final Function(Token)? callBack; // নাল সেফটির জন্য ? যোগ করা হয়েছে

  // কনস্ট্রাক্টরে key যোগ করা হয়েছে
  Tokenp({Key? key, required this.token, required this.dimentions, this.callBack}) : super(key: key);

  Color _getcolor() {
    switch (this.token.type) {
      case TokenType.green:
        return Colors.green;
      case TokenType.yellow:
        return Colors.yellow[900] ?? Colors.yellow; // ?? ডিফল্ট কালার সেট করা হয়েছে
      case TokenType.blue:
        return Colors.blue[600] ?? Colors.blue; // ?? ডিফল্ট কালার সেট করা হয়েছে
      case TokenType.red:
        return Colors.red;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final dice = Provider.of<DiceModel>(context);
    
    return AnimatedPositioned(
      duration: Duration(milliseconds: 100),
      left: dimentions[0],
      top: dimentions[1],
      width: dimentions[2],
      height: dimentions[3],
      child: GestureDetector(
        onTap: () {
          gameState.moveToken(token, dice.diceOne);
        },
        child: Card(
          elevation: 5,
          shape: CircleBorder(), // কার্ডকে গোলাকার করার জন্য
          child: Container(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getcolor(),
                boxShadow: [
                  BoxShadow(
                    color: _getcolor().withOpacity(0.5), // শ্যাডোর জন্য অপাসিটি যোগ করা হয়েছে
                    blurRadius: 5.0,
                    spreadRadius: 1.0,
                  )
                ]),
          ),
        ),
      ),
    );
  }
}