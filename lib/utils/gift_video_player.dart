import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class GiftVideoPlayer {
  static void show(BuildContext context, String videoUrl) async {
    if (videoUrl.isEmpty) return;

    // ১. কন্ট্রোলার সেটআপ
    final VideoPlayerController controller = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      // ২. ভিডিও ইনিশিয়ালাইজেশন
      await controller.initialize();
      await controller.setVolume(1.0); // সাউন্ড ফুল করে দেওয়া

      final OverlayState? overlayState = Overlay.of(context);
      if (overlayState == null) return;

      late OverlayEntry overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (context) => Material(
          color: Colors.black45, // হালকা কালো পর্দা যাতে ভিডিও পরিষ্কার দেখা যায়
          child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.7,
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
      );

      // ৩. স্ক্রিনে দেখানো এবং প্লে করা
      overlayState.insert(overlayEntry);
      await controller.play();

      // ৪. ভিডিও শেষ হওয়ার পর অটো রিমুভ
      controller.addListener(() {
        if (controller.value.position >= controller.value.duration) {
          controller.dispose();
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        }
      });
    } catch (error) {
      print("ভিডিও লোডিং এরর: $error");
    }
  }
}
