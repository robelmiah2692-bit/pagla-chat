// lib/widgets/ludo_row.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pagla_chat/ludo_game/utility.dart';
import 'package:pagla_chat/ludo_game/game_state.dart';
import 'package:pagla_chat/ludo_game/token.dart';
import 'package:pagla_chat/ludo_game/dice_model.dart';

class LudoRow extends StatelessWidget {
  final int row;
  final List<GlobalKey> keyRow;

  LudoRow(this.row, this.keyRow);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(15, (col) {
        return Flexible(
          key: keyRow[col],
          child: AspectRatio(
            aspectRatio: 1 / 1,
            child: Consumer2<GameState, DiceModel>(
              builder: (context, gameState, diceModel, child) {
                var tokensAtThisPos = gameState.gameTokens
                    .where((t) => t.tokenPosition.row == row && t.tokenPosition.column == col)
                    .toList();

                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.grey),
                      right: col == 14 ? BorderSide(color: Colors.grey) : BorderSide.none,
                    ),
                    color: Utility.getColor(row, col),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(child: SizedBox()),
                      tokensAtThisPos.isNotEmpty
                          ? _buildToken(context, tokensAtThisPos.first, gameState, diceModel)
                          : SizedBox(),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildToken(BuildContext context, Token token, GameState gameState, DiceModel diceModel) {
    Color color;
    switch (token.type) {
      case TokenType.green: color = Colors.green; break;
      case TokenType.yellow: color = Colors.yellow; break;
      case TokenType.blue: color = Colors.blue; break;
      case TokenType.red: color = Colors.red; break;
      default: color = Colors.black;
    }

    return GestureDetector(
      onTap: () {
        // ক্লিক করার সাথে সাথে কনসোলে লগ আসবে
        print("--- Click Event ---");
        print("Token Type: ${token.type}");
        print("Current Player Turn: ${gameState.currentPlayer}");
        print("Dice Value: ${diceModel.diceOneCount}");

        if (token.type == gameState.currentPlayer) {
          print("Success: Moving token...");
          gameState.moveToken(token, diceModel.diceOneCount);
        } else {
          print("Error: It's not your turn!");
        }
      },
      child: Center(
        child: Container(
          margin: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: (gameState.currentPlayer == token.type) ? Colors.white : Colors.transparent,
              width: 3,
            ),
          ),
        ),
      ),
    );
  }
}