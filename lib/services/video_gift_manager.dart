import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class VideoGiftManager {
  static void playGift(BuildContext context, String videoUrl) {
    // ১. এখানে OverlayState? এর বদলে নাল হবে না এমনভাবে ডিফাইন করা ভালো
    final OverlayState overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    // ভিডিও ইউআরএল চেক
    if (videoUrl.isEmpty) return;

    VideoPlayerController controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    controller.initialize().then((_) {
      overlayEntry = OverlayEntry(
        builder: (context) => Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: IgnorePointer(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
      );

      // ২. এখানে পরিবর্তন: প্রশ্নবোধক চিহ্ন (?) সরিয়ে দেওয়া হয়েছে
      overlayState.insert(overlayEntry); 
      controller.play();

      // ৩. ভিডিও শেষ হলে রিমুভ করা
      Future.delayed(controller.value.duration, () {
        if (overlayEntry.mounted) {
          controller.dispose();
          overlayEntry.remove();
        }
      });
    }).catchError((error) {
      print("ভিডিও লোড হতে সমস্যা: $error");
    });
  }
}
