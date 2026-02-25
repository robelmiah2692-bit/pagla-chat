import 'package:flutter/material.dart';

class EmojiHandler {
  // আপনার সেই ইমোজি লটি লিংকের ম্যাপ
  static final Map<String, String> emojiLottieLinks = {
    "😘": "https://fonts.gstatic.com/s/e/notoemoji/latest/1f618/lottie.json",
    "🥰": "https://fonts.gstatic.com/s/e/notoemoji/latest/1f970/lottie.json",
    "😭": "https://fonts.gstatic.com/s/e/notoemoji/latest/1f62d/lottie.json",
    "😡": "https://fonts.gstatic.com/s/e/notoemoji/latest/1f621/lottie.json",
    "👏": "https://fonts.gstatic.com/s/e/notoemoji/latest/1f44f/lottie.json",
    "🥱": "https://fonts.gstatic.com/s/e/notoemoji/latest/1f971/lottie.json",
    "🤔": "https://fonts.gstatic.com/s/e/notoemoji/latest/1f914/lottie.json",
    "😏": "https://fonts.gstatic.com/s/e/notoemoji/latest/1f60f/lottie.json",
    "🤫": "https://fonts.gstatic.com/s/e/notoemoji/latest/1f92b/lottie.json",
    "🫣": "https://fonts.gstatic.com/s/e/notoemoji/latest/1fae3/lottie.json",
    "🤭": "https://fonts.gstatic.com/s/e/notoemoji/latest/1f92d/lottie.json",
  };

  // বটম শিট দেখানোর ফাংশন
  static void showPicker({
    required BuildContext context,
    required int seatIndex,
    required Function(int index, String url) onEmojiSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(15),
        height: 250,
        child: GridView.count(
          crossAxisCount: 5,
          children: emojiLottieLinks.keys.map((emojiIcon) {
            return IconButton(
              onPressed: () {
                // মেইন ফাইলে ডাটা পাঠিয়ে দেওয়া হচ্ছে
                onEmojiSelected(seatIndex, emojiLottieLinks[emojiIcon]!);
                Navigator.pop(context);
              },
              icon: Text(emojiIcon, style: const TextStyle(fontSize: 30)),
            );
          }).toList(),
        ),
      ),
    );
  }
}
