import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;

class GiftOverlayHandler extends StatelessWidget {
  final bool isGiftAnimating;
  final String currentGiftImage;
  final bool isFullScreenBinding;
  final String senderName;
  final String receiverName;
  final String senderImage;   // নতুন যোগ করা হয়েছে
  final String receiverImage; // নতুন যোগ করা হয়েছে

  const GiftOverlayHandler({
    super.key,
    required this.isGiftAnimating,
    required this.currentGiftImage,
    required this.isFullScreenBinding,
    required this.senderName,
    required this.receiverName,
    this.senderImage = '',   // ডিফল্ট খালি রাখা হয়েছে
    this.receiverImage = '', // ডিফল্ট খালি রাখা হয়েছে
  });

  @override
  Widget build(BuildContext context) {
    if (!isGiftAnimating || currentGiftImage.isEmpty) return const SizedBox.shrink();

    final double fullHeight = MediaQuery.of(context).size.height;
    final double fullWidth = MediaQuery.of(context).size.width;
    final int animationType = math.Random().nextInt(3); 

    return IgnorePointer(
      ignoring: true,
      child: SizedBox(
        width: fullWidth,
        height: fullHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ১. বিজলি চমকানো এবং ধামাকা ইফেক্ট (Thunder & Flash)
            _buildThunderStrikeEffect(),

            // ২. ফুল স্ক্রিন গিফট এবং নাম/ছবি
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1400),
              curve: Curves.fastOutSlowIn,
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return _applyRandomAnimation(animationType, value, fullWidth, fullHeight, child!);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // মেইন গিফট যা চারপাশ থেকে মিশে যাবে
                  _buildFullScreenSoftGift(context),
                  
                  // নাম এবং প্রোফাইল ছবি
                  Positioned(
                    bottom: 120, 
                    child: _buildNameBadgeWithImages(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // বিজলি চমকানোর মতো ধামাকা ইফেক্ট
  Widget _buildThunderStrikeEffect() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        // বিজলির মতো কাঁপানো এবং ফ্ল্যাশ তৈরি করা
        double flash = math.sin(value * math.pi * 5).abs(); 
        return Opacity(
          opacity: (flash * (1.0 - value)).clamp(0.0, 1.0),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.8),
                  Colors.blueAccent.withOpacity(0.3),
                  Colors.transparent
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullScreenSoftGift(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) {
        return RadialGradient(
          center: Alignment.center,
          radius: 0.65,
          colors: [Colors.black, Colors.black.withOpacity(0.8), Colors.transparent],
          stops: const [0.0, 0.88, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: CachedNetworkImage(
          imageUrl: currentGiftImage,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          placeholder: (context, url) => const SizedBox.shrink(),
          errorWidget: (context, url, error) => const Icon(Icons.thunderstorm, size: 100, color: Colors.yellow),
        ),
      ),
    );
  }

  Widget _buildNameBadgeWithImages() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)
        ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUserAvatar(senderImage),
          const SizedBox(width: 8),
          Text(
            senderName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.bolt, color: Colors.yellowAccent, size: 24), // বিজলি আইকন
          ),
          Text(
            receiverName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 8),
          _buildUserAvatar(receiverImage),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(String imageUrl) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: imageUrl.isNotEmpty 
          ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
          : Container(color: Colors.grey, child: const Icon(Icons.person, size: 20, color: Colors.white)),
      ),
    );
  }

  Widget _applyRandomAnimation(int type, double value, double width, double height, Widget child) {
    if (type == 0) {
      return Transform.translate(
        offset: Offset(0, (1.0 - value) * 400),
        child: Opacity(opacity: value, child: child),
      );
    } else if (type == 1) {
      return Transform.scale(
        scale: 0.3 + (value * 0.7),
        child: Opacity(opacity: value, child: child),
      );
    } else {
      return Transform.rotate(
        angle: (1.0 - value) * 0.4,
        child: Transform.scale(scale: value, child: child),
      );
    }
  }
}