import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
// আপনার মিউজিক পেজের ইমপোর্ট এখানে দিন (যেমন: import '../screens/music_player_page.dart';)

class MusicPlayerWidget extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final bool isRoomMusicPlaying;
  final bool isDragging;
  final VoidCallback onTogglePlay;
  final VoidCallback onClose;

  const MusicPlayerWidget({
    super.key,
    required this.audioPlayer,
    required this.isRoomMusicPlaying,
    required this.isDragging,
    required this.onTogglePlay,
    required this.onClose,
  });

  // --- মিউজিক পিক করার সেই স্পেশাল ফাংশন যা এখন মেইন ফাইল থেকে এখানে চলে আসলো ---
  static Future<void> openMusicPicker({
    required BuildContext context,
    required AudioPlayer audioPlayer,
    required Widget musicPage, // এখানে আপনার MusicPlayerPage() পাঠিয়ে দিবেন
    required Function(String name, List<String> paths) onMusicSelected,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => musicPage),
    );

    if (result != null && result is Map) {
      String songName = result['name'] ?? "Unknown";
      String songPath = result['path'];

      try {
        await audioPlayer.stop(); 
        await audioPlayer.play(DeviceFileSource(songPath)); 
        
        final prefs = await SharedPreferences.getInstance();
        final List<String> songs = prefs.getStringList('my_music') ?? [];
        
        onMusicSelected(songName, songs);
      } catch (e) {
        debugPrint("গান বাজাতে সমস্যা হয়েছে: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withOpacity(isDragging ? 0.5 : 0.9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.greenAccent, width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Icon(Icons.drag_indicator, color: Colors.greenAccent, size: 18),
            GestureDetector(
              onTap: onTogglePlay,
              child: Icon(
                audioPlayer.state == PlayerState.playing
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: Colors.greenAccent,
                size: 32,
              ),
            ),
            GestureDetector(
              onTap: onClose,
              child: const Icon(Icons.cancel, color: Colors.redAccent, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
