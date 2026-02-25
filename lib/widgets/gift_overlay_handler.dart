import 'package:flutter/material.dart';

class GiftOverlayHandler extends StatelessWidget {
  final bool isGiftAnimating;
  final String currentGiftImage;
  final bool isFullScreenBinding;
  final String senderName;
  final String receiverName;

  const GiftOverlayHandler({
    super.key,
    required this.isGiftAnimating,
    required this.currentGiftImage,
    required this.isFullScreenBinding,
    required this.senderName,
    required this.receiverName,
  });

  @override
  Widget build(BuildContext context) {
    if (!isGiftAnimating) return const SizedBox();

    return Center(
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 800),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // দামী গিফট বড়, কম দামী ছোট (আপনার আগের লজিক)
                  Image.network(
                    currentGiftImage,
                    height: isFullScreenBinding ? 380 : 180,
                    errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.card_giftcard, size: 100, color: Colors.pink),
                  ),
                  const SizedBox(height: 10),
                  // গিফট দাতা ও গ্রহীতার নাম
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$senderName 🎁 $receiverName",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
