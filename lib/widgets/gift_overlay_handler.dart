import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // ইমেজ ল্যাগ কমানোর জন্য

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
    // গিফট এনিমেটিং না হলে বা ইমেজ খালি হলে কিছুই দেখাবে না
    if (!isGiftAnimating || currentGiftImage.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: true,
      child: Stack( // স্ট্যাক ব্যবহার করা হয়েছে যেন পুরো স্ক্রিন কভার করে
        children: [
          Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut, // এনিমেশনটি একটু বাউন্সি হবে, দেখতে ভালো লাগবে
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // যতটুকু দরকার ততটুকু জায়গা নেবে
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ইমেজ লোডিং অপ্টিমাইজেশন
                        CachedNetworkImage(
                          imageUrl: currentGiftImage,
                          height: isFullScreenBinding ? 320 : 180,
                          width: isFullScreenBinding ? 320 : 180,
                          fit: BoxFit.contain,
                          // ইমেজ লোড হওয়ার সময় একটি ছোট ইন্ডিকেটর বা কিছুই দেখাবে না
                          placeholder: (context, url) => const SizedBox.shrink(),
                          errorWidget: (context, url, error) => 
                              const Icon(Icons.card_giftcard, size: 80, color: Colors.pink),
                        ),
                        const SizedBox(height: 15),
                        
                        // দাতা ও গ্রহীতার নামের ডিজাইন
                        _buildNameBadge(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // নামের ব্যাজটি আলাদা মেথডে নিয়ে আসা হয়েছে কোড পরিষ্কার রাখতে
  Widget _buildNameBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pinkAccent.withOpacity(0.9), 
            Colors.purpleAccent.withOpacity(0.9)
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              senderName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.card_giftcard, color: Colors.white, size: 18),
          ),
          Flexible(
            child: Text(
              receiverName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}