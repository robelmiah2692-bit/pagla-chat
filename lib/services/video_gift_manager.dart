import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class VideoGiftManager {
  static void playGift(BuildContext context, String videoUrl) {
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    // ১. গিটহাবের জন্য সরাসরি network ব্যবহার করা ভালো
    VideoPlayerController controller = VideoPlayerController.network(videoUrl);

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

      // ২. স্ক্রিনে ভিডিওটি দেখাও
      overlayState?.insert(overlayEntry);
      controller.play();

      // ৩. ভিডিও শেষ হলে অটোমেটিক বন্ধ হবে
      // আমরা ভিডিওর আসল ডিউরেশন শেষ হওয়া পর্যন্ত অপেক্ষা করবো
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
