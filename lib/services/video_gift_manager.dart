import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class VideoGiftManager {
  static void playGift(BuildContext context, String videoUrl) {
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
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

      overlayState.insert(overlayEntry);
      controller.play();

      Timer(controller.value.duration, () {
        controller.dispose();
        overlayEntry.remove();
      });
    });
  }
}
