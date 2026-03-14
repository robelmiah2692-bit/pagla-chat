import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class GiftVideoPlayer {
  static void show(BuildContext context, String videoUrl) {
    if (videoUrl.isEmpty) return;

    // আমরা একটি ডায়ালগ ব্যবহার করবো যাতে ভিডিওটা স্ক্রিনের সামনে আসে
    showGeneralDialog(
      context: context,
      barrierDismissible: false, // ভিডিও শেষ না হওয়া পর্যন্ত বন্ধ হবে না
      barrierColor: Colors.black.withOpacity(0.8), // ব্যাকগ্রাউন্ড অন্ধকার হবে
      pageBuilder: (context, anim1, anim2) {
        return _VideoPlayerContent(url: videoUrl);
      },
    );
  }
}

class _VideoPlayerContent extends StatefulWidget {
  final String url;
  const _VideoPlayerContent({required this.url});

  @override
  State<_VideoPlayerContent> createState() => _VideoPlayerContentState();
}

class _VideoPlayerContentState extends State<_VideoPlayerContent> {
  late VideoPlayerController _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    // networkUrl ব্যবহার করা হচ্ছে
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {
          _isReady = true;
        });
        _controller.play(); // অটো প্লে শুরু হবে
        _controller.setVolume(1.0);
      });

    // ভিডিও শেষ হলে ডায়ালগটি অটো বন্ধ করে দেবে
    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration) {
        if (mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: _isReady
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(color: Colors.pinkAccent), // ভিডিও লোড হওয়ার সময় গোল চাকা ঘুরবে
      ),
    );
  }
}
