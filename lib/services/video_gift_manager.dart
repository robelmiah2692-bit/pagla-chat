import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class VideoGiftManager {
  static void playGift(BuildContext context, String videoUrl) {
    if (videoUrl.isEmpty) return;

    // ১. নাল চেকসহ ওভারলে স্টেট নেওয়া
    final OverlayState? overlayState = Overlay.of(context);
    if (overlayState == null) return;

    late OverlayEntry overlayEntry;
    
    // ২. networkUrl ব্যবহার করা (Uri.parse সহ)
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

      // ৩. এখানে কম্পাইলারকে নিশ্চিত করা হচ্ছে overlayState নাল না
      overlayState.insert(overlayEntry);
      controller.play();

      Future.delayed(controller.value.duration, () {
        if (overlayEntry.mounted) {
          controller.dispose();
          overlayEntry.remove();
        }
      });
    }).catchError((error) {
      debugPrint("ভিডিও লোড হতে সমস্যা: $error");
    });
  }
}
