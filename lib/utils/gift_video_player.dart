import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class GiftVideoPlayer {
  static void show(BuildContext context, String videoUrl) {
    if (videoUrl.isEmpty) return;

    // barrierColor-এ রঙের অপাসিটি শূন্য (transparent) করে দেওয়া হলো
    showGeneralDialog(
      context: context,
      barrierDismissible: false, // ভিডিও শেষ না হওয়া পর্যন্ত বন্ধ হবে না
      barrierColor: Colors.transparent, // কোনো কালো বা অন্ধকার ব্যাকগ্রাউন্ড থাকবে না
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
      backgroundColor: Colors.transparent, // স্ক্যাফোল্ড ব্যাকগ্রাউন্ড সম্পূর্ণ স্বচ্ছ
      body: Center(
        child: _isReady
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const SizedBox.shrink(), // লোডিংয়ের সময় কোনো এক্সট্রা চাকা বা কালার দেখাবে না, একদম সচ্ছ থাকবে
      ),
    );
  }
}