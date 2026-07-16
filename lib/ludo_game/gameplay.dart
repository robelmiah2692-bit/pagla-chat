import 'package:flutter/material.dart';
import 'package:pagla_chat/ludo_game/token.dart';
import './board.dart';
import './tokenp.dart';
import 'package:pagla_chat/ludo_game/game_state.dart';

class GamePlay extends StatefulWidget {
  final GlobalKey keyBar;
  final GameState gameState;
  final List<Map<String, dynamic>> players; // প্লেয়ার লিস্ট রিসিভ করার জন্য

  GamePlay(this.keyBar, this.gameState, {required this.players});

  @override
  _GamePlayState createState() => _GamePlayState();
}

class _GamePlayState extends State<GamePlay> {
  bool boardBuild = false;
  final List<List<GlobalKey>> keyRefrences = _getGlobalKeys();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          boardBuild = true;
        });
      }
    });
  }

  static List<List<GlobalKey>> _getGlobalKeys() {
    List<List<GlobalKey>> keysMain = [];
    for (int i = 0; i < 15; i++) {
      List<GlobalKey> keys = [];
      for (int j = 0; j < 15; j++) {
        keys.add(GlobalKey());
      }
      keysMain.add(keys);
    }
    return keysMain;
  }

  List<double> _getPosition(int row, int column) {
    if (widget.keyBar.currentContext == null) return [0, 0, 0, 0];
    
    final RenderBox renderBoxBar = widget.keyBar.currentContext!.findRenderObject() as RenderBox;
    final sizeBar = renderBoxBar.size;
    
    final cellBoxKey = keyRefrences[row][column];
    if (cellBoxKey.currentContext == null) return [0, 0, 0, 0];
    
    final RenderBox renderBoxCell = cellBoxKey.currentContext!.findRenderObject() as RenderBox;
    final positionCell = renderBoxCell.localToGlobal(Offset.zero);
    
    return [
      positionCell.dx + 1,
      (positionCell.dy - sizeBar.height + 1),
      renderBoxCell.size.width - 2,
      renderBoxCell.size.height - 2
    ];
  }

  List<Widget> _buildPlayerInfo() {
    // এখানে গেমের ভেতরে প্লেয়ারদের ডাটা দেখানোর লজিক
    return widget.players.map((player) {
      return Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(player['avatar'] ?? ''),
              radius: 15,
            ),
            Text(player['name'] ?? '', style: TextStyle(fontSize: 8, color: Colors.white)),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Board(keyRefrences,players: widget.players,),
        ...widget.gameState.gameTokens.map((token) => Tokenp(
          token: token,
          dimentions: _getPosition(token.tokenPosition.row, token.tokenPosition.column),
        )),
        // প্লেয়ারদের ডাটা গেমের ওপর দেখানোর জন্য:
        Positioned(
          top: 50,
          left: 10,
          child: Row(children: _buildPlayerInfo()),
        ),
      ],
    );
  }
}