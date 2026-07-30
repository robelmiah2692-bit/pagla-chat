import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _dicePlayer = AudioPlayer();
  static final AudioPlayer _tokenPlayer = AudioPlayer();

  // সাউন্ড সার্ভিস ইনিশিয়ালাইজ করার সময় লো-ল্যাটেন্সি মোড সেট করা ভালো
  static Future<void> init() async {
    await _dicePlayer.setPlayerMode(PlayerMode.lowLatency);
    await _tokenPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  // ছক্কা বা ডাইস রোলের সাউন্ড বাজানোর ফাংশন
  static Future<void> playDiceSound() async {
    try {
      await _dicePlayer.stop();
      // এখানে সরাসরি ফাইলের নাম দিতে হবে যেহেতু pubspec.yaml এ sounds ফোল্ডার ডিক্লেয়ার করা আছে
      await _dicePlayer.play(AssetSource('sounds/dice_roll.mp3'));
    } catch (e) {
      print("Error playing dice sound: $e");
    }
  }

  // গুটি চালার (Token move) সাউন্ড বাজানোর ফাংশন
  static Future<void> playTokenMoveSound() async {
    try {
      await _tokenPlayer.stop();
      await _tokenPlayer.play(AssetSource('sounds/token_move.mp3'));
    } catch (e) {
      print("Error playing token sound: $e");
    }
  }
}