import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class GiftVideoPlayer {
  static void show(BuildContext context, String videoUrl) {
    // ১. ভিডিও কন্ট্রোলার সেটআপ
    final VideoPlayerController controller = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    late OverlayEntry overlayEntry;

    controller.initialize().then((_) {
      overlayEntry = OverlayEntry(
        builder: (context) => Material(
          color: Colors.transparent,
          child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.6,
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(overlayEntry);
      controller.play();

      // ভিডিও শেষ হলে রিমুভ হবে
      controller.addListener(() {
        if (controller.value.position >= controller.value.duration) {
          controller.dispose();
          overlayEntry.remove();
        }
      });
    }).catchError((error) {
      print("Error loading video: $error");
    });
  }
}
