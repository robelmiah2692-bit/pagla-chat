import 'package:flutter/material.dart';
import 'ludo_lobby_popup.dart';

class LudoHelper {
  static void showLudoLobby(
      BuildContext context, List<dynamic> seats, bool isAdmin) {
    // সিট থেকে ফিল্টার করা ইউজার
    List<Map<String, dynamic>> activePlayers = seats
        .where((s) => s["isOccupied"] == true)
        .map((s) => {
              "name": s["userName"].toString(),
              "avatar": s["userImage"].toString()
            })
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: LudoLobbyPopup(
          joinedUsers: activePlayers,
          isAdmin: isAdmin,
          betAmount: 2,
          onJoin: () => print("Join Ludo"),
          onStart: () => print("Start Ludo"),
          onClose: () => Navigator.pop(context), // ক্লোজ করার জন্য
          onUpdateBet: (newBet) =>
              print("New Bet: $newBet"), // নতুন বেট হ্যান্ডল
        ),
      ),
    );
  }
}
