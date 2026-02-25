import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

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
            // ১. ড্র্যাগ করার আইকন
            const Icon(Icons.drag_indicator, color: Colors.greenAccent, size: 18),

            // ২. Play/Pause বাটন
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

            // ৩. বন্ধ করার বাটন (Cancel)
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
