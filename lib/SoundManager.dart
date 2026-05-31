import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();
  static bool isMuted = false;

  static void toggleMute() {
    isMuted = !isMuted;
  }

  static Future<void> playSound(String fileName) async {
    if (isMuted) return;
    await _player.play(AssetSource('sounds/$fileName'));
  }
}