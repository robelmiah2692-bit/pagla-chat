import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LevelImageConfig {
  // 🌟 এক্টিভ লেভেলের জন্য ৫টি বেস লিংক (১ থেকে ৫০ লেভেল)
  static String getActiveLevelImage(int level) {
    if (level <= 10) {
      return 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/activelavel/Lva.webp';
    } else if (level <= 20) {
      return 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/activelavel/Lva1.webp';
    } else if (level <= 30) {
      return 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/activelavel/Lva2.webp';
    } else if (level <= 40) {
      return 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/activelavel/Lva3.webp';
    } else {
      return 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/activelavel/Lva4.webp';
    }
  }

  // 🎁 গিফট লেভেলের জন্য ৫টি আলাদা বেস লিংক (১ থেকে ৫০ লেভেল)
  static String getGiftLevelImage(int level) {
    if (level <= 10) {
      return 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/giftlavel/gi.webp';
    } else if (level <= 20) {
      return 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/giftlavel/gi1.webp';
    } else if (level <= 30) {
      return 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/giftlavel/gi2.webp';
    } else if (level <= 40) {
      return 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/giftlavel/gi3.webp';
    } else {
      return 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/giftlavel/gi4.webp';
    }
  }
}

// 🖼️ ইমেজের উপর ডায়নামিক লেভেল নম্বর ও "Lv." বসানোর উইজেট
class DynamicLevelBadgeView extends StatelessWidget {
  final int level;
  final bool isGift;

  const DynamicLevelBadgeView({
    Key? key,
    required this.level,
    required this.isGift,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String imageUrl = isGift
        ? LevelImageConfig.getGiftLevelImage(level)
        : LevelImageConfig.getActiveLevelImage(level);

    return SizedBox(
      width: 85, // লম্বা ডিজাইনের জন্য উইথ একটু বাড়িয়ে দেওয়া হলো
      height: 45, // উচ্চতা পারফেক্ট রাখার জন্য কমানো হলো
      child: Stack(
        alignment: Alignment.center,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            width: 85,
            height: 45,
            fit: BoxFit.fill, // ডিজাইন যেন পুরো বক্সে সুন্দরভাবে ফিট হয়
            errorWidget: (context, error, stackTrace) => Icon(
              isGift ? Icons.card_giftcard : Icons.shield,
              size: 24,
              color: isGift ? Colors.purpleAccent : Colors.blueGrey,
            ),
          ),
          Positioned(
            right: 14, // ডানপাশের কালো জায়গার ভেতরে টেক্সট বসানোর জন্য
            top: 17,
            child: Text(
              'Lv.$level', // লেভেলের আগে Lv. যুক্ত করা হলো
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}