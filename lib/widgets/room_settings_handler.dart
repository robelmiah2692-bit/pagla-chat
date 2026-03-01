import 'package:flutter/material.dart';

class RoomSettingsHandler {
  static void showSettings({
    required BuildContext context,
    required bool isLocked,
    required VoidCallback onToggleLock, // Function এর বদলে VoidCallback ব্যবহার করা ভালো
    required Function(String) onSetWallpaper, // VoiceRoom এ এটি একটি String পাথ নেয়
    required VoidCallback onLeave, // VoiceRoom এ এটি onLeave নামে আছে
    required VoidCallback onMinimize, // এই নতুন প্যারামিটারটি যোগ করা হলো
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
                    // এখানে সরাসরি আপনার গ্যালারি থেকে ইমেজ নেওয়ার ফাংশন কল হবে
                    onSetWallpaper(""); // VoiceRoom এ এটি ইমেজ পিক করে পাথ নেয়
                  }),
                  _buildItem(Icons.open_in_full, "Minimize", Colors.green, () {
                    Navigator.pop(context); // বটম শিট বন্ধ করবে
                    onMinimize(); // VoiceRoom এর মিনিমাইজ ফাংশন কল করবে
                  }),
                  _buildItem(Icons.logout, "Exit", Colors.redAccent, () {
                    Navigator.pop(context);
                    _showExitDialog(context, onLeave);
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

  static void _showExitDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Exit Room?", style: TextStyle(color: Colors.white)),
        content: const Text("আপনি কি রুম থেকে বের হতে চান?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("না")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text("হ্যাঁ", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }
}
