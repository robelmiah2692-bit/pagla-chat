import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class RomanticVideoGift {
  // ৪৭৭০ ডায়মন্ডের ভিডিও গিফটটি দেখানোর মেইন ফাংশন
  static void show(BuildContext context, String videoUrl) {
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    // ভিডিও কন্ট্রোলার সেটআপ
    VideoPlayerController controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    controller.initialize().then((_) {
      overlayEntry = OverlayEntry(
        builder: (context) => Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // ভিডিওটি মাঝখানে দেখানোর জন্য
              Center(
                child: IgnorePointer(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
              
              // ৪৭৭০ ডায়মন্ডের স্পেশাল টেক্সট এনিমেশন (নিচে)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Colors.orange, Colors.red]),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      "💖 ROMANTIC DRAGON GIFT 💎 4770",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // স্ক্রিনে ভিডিওটি যুক্ত করা
      overlayState.insert(overlayEntry);
      controller.setVolume(1.0); // সাউন্ড ফুল থাকবে
      controller.play();

      // ভিডিও শেষ হলে মেমোরি ক্লিয়ার করা ও স্ক্রিন থেকে সরানো
      Timer(controller.value.duration, () {
        controller.dispose();
        overlayEntry.remove();
      });
    });
  }
}
