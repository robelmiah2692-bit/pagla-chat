import 'package:flutter/material.dart';
import 'package:pagla_chat/ludo_game/player_container.dart';
import './ludo_row.dart';
import 'package:pagla_chat/ludo_game/token.dart';

class Board extends StatelessWidget {
  final List<List<GlobalKey>> keyRefrences;
  final List<Map<String, dynamic>> players;
  final String roomId;
  final String ownerId;
  final List<String> adminList;
  final String currentUserId;
  final VoidCallback onCloseBoard;

  const Board({
    Key? key,
    required this.keyRefrences,
    required this.players,
    required this.roomId,
    required this.ownerId,
    required this.adminList,
    required this.currentUserId,
    required this.onCloseBoard,
  }) : super(key: key);

  Map<String, dynamic> getPlayerByType(TokenType type) {
    String typeStr = type.toString().split('.').last.toLowerCase(); 
    
    for (var p in players) {
      String playerColor = (p['color'] ?? "").toString().toLowerCase().trim();
      if (playerColor == typeStr) {
        return p;
      }
    }
    return {"name": "", "avatar": ""};
  }

  bool isPlayerColorActive(TokenType type) {
    String typeStr = type.toString().split('.').last.toLowerCase();
    return players.any((p) => (p['color'] ?? "").toString().toLowerCase().trim() == typeStr);
  }

  @override
  Widget build(BuildContext context) {
    // ডেটা সঠিক আসছে কিনা তা দেখার জন্য কনসোলে প্রিন্ট হবে
    debugPrint("Board Check -> Current User ID: '$currentUserId'");
    debugPrint("Board Check -> Owner ID: '$ownerId'");
    debugPrint("Board Check -> Admin List: $adminList");

    String cleanCurrentUserId = currentUserId.toString().trim();
    String cleanOwnerId = ownerId.toString().trim();
    
    List<String> cleanAdminList = adminList.map((e) => e.toString().trim()).toList();

    bool isOwner = cleanOwnerId.isNotEmpty && cleanOwnerId == cleanCurrentUserId;
    bool isAdmin = cleanAdminList.contains(cleanCurrentUserId);
    
    bool isAdminOrOwner = isOwner || isAdmin;

    debugPrint("Is Owner: $isOwner, Is Admin: $isAdmin, Final Result: $isAdminOrOwner");

    return Center(
      child: Container(
        width: 400,
        height: 400,
        child: Stack(
          clipBehavior: Clip.none, // বাটনটি যেন কোনো কারণে কেটে না যায়
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
            
            if (isPlayerColorActive(TokenType.green))
              Positioned(
                top: 5,
                left: 5,
                child: PlayerContainer(
                  type: TokenType.green,
                  playerName: getPlayerByType(TokenType.green)["name"],
                  avatar: getPlayerByType(TokenType.green)["avatar"],
                  roomId: roomId,
                ),
              ),

            if (isPlayerColorActive(TokenType.yellow))
              Positioned(
                top: 5,
                right: 5,
                child: PlayerContainer(
                  type: TokenType.yellow,
                  playerName: getPlayerByType(TokenType.yellow)["name"],
                  avatar: getPlayerByType(TokenType.yellow)["avatar"],
                  roomId: roomId,
                ),
              ),

            if (isPlayerColorActive(TokenType.red))
              Positioned(
                bottom: 5,
                left: 5,
                child: PlayerContainer(
                  type: TokenType.red,
                  playerName: getPlayerByType(TokenType.red)["name"],
                  avatar: getPlayerByType(TokenType.red)["avatar"],
                  roomId: roomId,
                ),
              ),

            if (isPlayerColorActive(TokenType.blue))
              Positioned(
                bottom: 5,
                right: 5,
                child: PlayerContainer(
                  type: TokenType.blue,
                  playerName: getPlayerByType(TokenType.blue)["name"],
                  avatar: getPlayerByType(TokenType.blue)["avatar"],
                  roomId: roomId,
                ),
              ),

            if (isAdminOrOwner)
              Positioned(
                top: -15,
                right: -15,
                child: GestureDetector(
                  onTap: onCloseBoard,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}