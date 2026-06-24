import 'package:flutter/material.dart';

class EmojiHandler {
  // আপনার সেই ইমোজি লটি লিংকের ম্যাপ
  static final Map<String, String> emojiLottieLinks = {
    "😘":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/kiss.json",
    "🥰":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/hartface.json",
    "😭":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/craing.json",
    "😡":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/rage.json",
    "👏":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/clap.json",
    "🥱":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/sleep.json",
    "🤔":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/thingking.json",
    "😏":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/smirk.json",
    "🤫":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/stopmouth.json",
    "🫣":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/pecking.json",
    "🤭":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/lojja.json",
    "😋":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/yum.json",
    "🤪":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/jannyface.json",
    "🤮":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/vome.json",
    "🤯":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/mainbloing.json",
    "🙄":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/rolingice.json",
    "👍":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/right.json",
    "👉":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/pointright.json",
    "💃":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/dance.json",
    "🐯":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/taiger.json",
    "🥳":
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/emoji/party.json",
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
