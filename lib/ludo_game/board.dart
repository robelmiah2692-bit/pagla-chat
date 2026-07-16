import 'package:flutter/material.dart';
import 'package:pagla_chat/ludo_game/player_container.dart';
import './ludo_row.dart';
import 'package:pagla_chat/ludo_game/token.dart';

class Board extends StatelessWidget {
  final List<List<GlobalKey>> keyRefrences;
  final List<Map<String, dynamic>> players;

  Board(this.keyRefrences, {required this.players});

Map<String, dynamic> getPlayerByType(TokenType type) {
  // TokenType.green কে "green" এ রূপান্তর করছে
  String typeStr = type.toString().split('.').last.toLowerCase(); 
  
  for (var p in players) {
    // এখানে কালার চেক হবে
    String playerColor = (p['color'] ?? "").toString().toLowerCase().trim();
    
    // কনসোলে চেক করুন কি আসছে
    debugPrint("Looking for: $typeStr, Found in map: $playerColor");
    
    if (playerColor == typeStr) {
      return p;
    }
  }
  return {"name": "", "avatar": ""};
}
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 380,
        height: 380,
        child: Stack(
          children: [
            Card(
              elevation: 10,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/Ludo_board.png"),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(15, (i) => LudoRow(i, keyRefrences[i])),
                ),
              ),
            ),
            Positioned(
              top: 5,
              left: 5,
              child: PlayerContainer(
                type: TokenType.green,
                playerName: getPlayerByType(TokenType.green)["name"],
                avatar: getPlayerByType(TokenType.green)["avatar"],
              ),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: PlayerContainer(
                type: TokenType.yellow,
                playerName: getPlayerByType(TokenType.yellow)["name"],
                avatar: getPlayerByType(TokenType.yellow)["avatar"],
              ),
            ),
            Positioned(
              bottom: 5,
              left: 5,
              child: PlayerContainer(
                type: TokenType.red,
                playerName: getPlayerByType(TokenType.red)["name"],
                avatar: getPlayerByType(TokenType.red)["avatar"],
              ),
            ),
            Positioned(
              bottom: 5,
              right: 5,
              child: PlayerContainer(
                type: TokenType.blue,
                playerName: getPlayerByType(TokenType.blue)["name"],
                avatar: getPlayerByType(TokenType.blue)["avatar"],
              ),
            ),
          ],
        ),
      ),
    );
  }
}