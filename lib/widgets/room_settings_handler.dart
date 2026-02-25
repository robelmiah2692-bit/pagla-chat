import 'package:flutter/material.dart';

class RoomSettingsHandler {
  static void showSettings({
    required BuildContext context,
    required bool isLocked,
    required Function onToggleLock,
    required Function(int price, String duration) onSetWallpaper,
    required VoidCallback onExit,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Room Settings",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildItem(isLocked ? Icons.lock : Icons.lock_open,
                      isLocked ? "Unlock" : "Lock", Colors.amber, () {
                    Navigator.pop(context);
                    onToggleLock();
                  }),
                  _buildItem(Icons.wallpaper, "Wallpaper", Colors.cyanAccent, () {
                    Navigator.pop(context);
                    _showWallpaperDeals(context, onSetWallpaper);
                  }),
                  _buildItem(Icons.open_in_full, "Minimize", Colors.green, () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }),
                  _buildItem(Icons.logout, "Exit", Colors.redAccent, () {
                    Navigator.pop(context);
                    _showExitDialog(context, onExit);
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildItem(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color)),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  static void _showWallpaperDeals(
      BuildContext context, Function(int, String) onSet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ওয়ালপেপার ডিল"),
        actions: [
          TextButton(
              onPressed: () {
                onSet(20, "২৪ ঘন্টা");
                Navigator.pop(context);
              },
              child: const Text("২০💎")),
          TextButton(
              onPressed: () {
                onSet(600, "১ মাস");
                Navigator.pop(context);
              },
              child: const Text("৬০০💎")),
        ],
      ),
    );
  }

  static void _showExitDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Exit Room?"),
        content: const Text("আপনি কি রুম থেকে বের হতে চান?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("না")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text("হ্যাঁ")),
        ],
      ),
    );
  }
}
