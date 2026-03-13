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
    if (!isGiftAnimating || currentGiftImage.isEmpty) return const SizedBox.shrink();

    return IgnorePointer( // গিফট চলাকালীন যেন নিচের বাটনে ভুল টাচ না লাগে
      ignoring: true,
      child: Center(
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
                    // দামী গিফট ৩৪০ সাইজ, সাধারণ গিফট ১৮০
                    Image.network(
                      currentGiftImage,
                      height: isFullScreenBinding ? 340 : 180,
                      width: isFullScreenBinding ? 340 : 180,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.card_giftcard, size: 100, color: Colors.pink),
                    ),
                    const SizedBox(height: 15),
                    
                    // গিফট দাতা ও গ্রহীতার নাম
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.pinkAccent, Colors.purpleAccent],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Text(
                        "$senderName 🎁 $receiverName",
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
