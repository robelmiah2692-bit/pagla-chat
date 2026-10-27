import 'package:flutter/material.dart';

class EmojiHandler {
  // 📂 লোকাল অ্যাসেট পাথ ম্যাপ
  static final Map<String, String> emojiLottiePaths = {
    "😘>": "assets/emoji/kiss1.json",
    "😘": "assets/emoji/kiss.json",
    "🥰": "assets/emoji/hartface.json",
    "😭": "assets/emoji/craing.json",
    "😡": "assets/emoji/rage.json",
    "👏": "assets/emoji/clap.json",
    "🤡": "assets/emoji/clown.json",
    "😤": "assets/emoji/Triumph.json",
    "🥱": "assets/emoji/sleep.json",
    "🤔": "assets/emoji/thingking.json",
    "😏": "assets/emoji/smirk.json",
    "🤫": "assets/emoji/stopmouth.json",
    "🤣": "assets/emoji/ROFL.json",
    "💑": "assets/emoji/Happy.json",
    "🫣": "assets/emoji/pecking.json",
    "🤭": "assets/emoji/lojja.json",
    "😋": "assets/emoji/yum.json",
    "🤪": "assets/emoji/jannyface.json",
    "🤮": "assets/emoji/vome.json",
    "🤯": "assets/emoji/mainbloing.json",
    "🙄": "assets/emoji/rolingice.json",
    "👍": "assets/emoji/right.json",
    "👉": "assets/emoji/pointright.json",
    "💃": "assets/emoji/dance.json",
    "🐯": "assets/emoji/taiger.json",
    "🥳": "assets/emoji/party.json",
    "👹": "assets/emoji/AngryDarkDevil.json",
    "☹": "assets/emoji/bigfrown.json",
    "🦦": "assets/emoji/CatCryingemoji.json",
    "🤤": "assets/emoji/drool.json",
    "🤗": "assets/emoji/Emoji1.json",
    "😂": "assets/emoji/emojiTest.json",
    "🧐": "assets/emoji/WinkingFaceby.json",
    "🦚": "assets/emoji/peacock.json",
    "😁": "assets/emoji/Rolling.json",
    "🐍": "assets/emoji/Snake.json",
    "🐊": "assets/emoji/trex.json",
  };

  // বটম শিট দেখানোর ফাংশন
  static void showPicker({
    required BuildContext context,
    required int seatIndex,
    required Function(int index, String assetPath) onEmojiSelected,
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
          children: emojiLottiePaths.keys.map((emojiIcon) {
            // 🔄 শুধু কিস ইমোজি (😘) পিকারের মধ্যেও উল্টো বা ফ্লিপ দেখাবে
            bool isKiss = emojiIcon == "😘";

            return IconButton(
              onPressed: () {
                // মেইন ফাইলে লোকাল অ্যাসেট পাথ পাঠিয়ে দেওয়া হচ্ছে
                onEmojiSelected(seatIndex, emojiLottiePaths[emojiIcon]!);
                Navigator.pop(context);
              },
              icon: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scale(isKiss ? -1.0 : 1.0, 1.0),
                child: Text(emojiIcon, style: const TextStyle(fontSize: 30)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}