import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RoomSettingsHandler {
  static void showSettings({
    required BuildContext context,
    required bool isLocked,
    required VoidCallback onToggleLock,
    required Function(String) onSetWallpaper, 
    required VoidCallback onLeave, 
    required VoidCallback onMinimize, 
    required VoidCallback onClearChat, // 🔥 চ্যাট ক্লিনের জন্য নতুন রিকোয়ার্ড প্যারামিটার
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
                  // ১. রুম লক/আনলক
                  _buildItem(isLocked ? Icons.lock : Icons.lock_open,
                      isLocked ? "Unlock" : "Lock", Colors.amber, () {
                    Navigator.pop(context);
                    onToggleLock();
                  }),
                  
                  // ২. ওয়ালপেপার পরিবর্তন
                  _buildItem(Icons.wallpaper, "Wallpaper", Colors.cyanAccent, () async {
                    Navigator.pop(context);
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      onSetWallpaper(image.path);
                    }
                  }),

                  // ৩. চ্যাট ক্লিন (হারানো ফিচারটি এখানে যোগ করা হলো)
                  _buildItem(Icons.delete_sweep, "Clean Chat", Colors.orangeAccent, () {
                    Navigator.pop(context);
                    onClearChat(); // মেইন ফাইল থেকে চ্যাট মুছার ফাংশন কল হবে
                  }),

                  // ৪. মিনিমাইজ
                  _buildItem(Icons.open_in_full, "Minimize", Colors.green, () {
                    Navigator.pop(context); 
                    onMinimize(); 
                  }),
                  
                  // ৫. এক্সিট (রুম থেকে বিদায়)
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
