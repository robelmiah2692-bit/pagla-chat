import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class VideoGiftManager {
  static void playGift(BuildContext context, String videoUrl) {
    if (videoUrl.isEmpty) return;

    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    // networkUrl এবং Uri.parse ব্যবহার করা হয়েছে
    VideoPlayerController controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    controller.initialize().then((_) {
      overlayEntry = OverlayEntry(
        builder: (context) => Material(
          color: Colors.transparent,
          child: Center(
            child: IgnorePointer(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
      );

      overlayState.insert(overlayEntry);
      controller.play();

      Future.delayed(controller.value.duration, () {
        if (overlayEntry.mounted) {
          controller.dispose();
          overlayEntry.remove();
        }
      });
    }).catchError((error) {
      debugPrint("Video Error: $error");
    });
  }
}
