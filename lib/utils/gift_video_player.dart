import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class GiftVideoPlayer {
  static void show(BuildContext context, String videoUrl) {
    if (videoUrl.isEmpty) return;

    // ১. ভিডিও শুরু হওয়ার আগেই ওয়াকলক এনাবল করা হলো
    WakelockPlus.enable();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      pageBuilder: (context, anim1, anim2) {
        return _VideoPlayerContent(url: videoUrl);
      },
    ).then((_) {
      // 🔑 অত্যন্ত গুরুত্বপূর্ণ ফিক্স: 
      // ডায়ালগটি যখনই পুরোপুরি বন্ধ (pop) হয়ে যাবে, ঠিক সাথে সাথেই মূল স্ক্রিনের ওয়াকলক আবার এনাবল করে দেওয়া হবে!
      WakelockPlus.enable();
      
      // অ্যান্ড্রয়েডের নেটিভ উইন্ডো ফোকাস পুরোপুরি রিকভার করার জন্য মাইক্রোসেকেন্ড ডিলে দিয়ে আরেকবার ফিক্সড করে দেওয়া হলো
      Future.delayed(const Duration(milliseconds: 300), () {
        WakelockPlus.enable();
      });
    });
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
    WakelockPlus.enable();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isReady = true;
          });
          _controller.play();
          _controller.setVolume(1.0);
          WakelockPlus.enable(); // প্লে হওয়ার সময়ও এনাবল রাখা হলো
        }
      });

    // ভিডিও শেষ হলে ডায়ালগ বন্ধ হবে
    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration) {
        if (mounted) {
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    WakelockPlus.enable(); // ডিসপোজের সময়ও সিকিউর করা হলো
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
            : const SizedBox.shrink(),
      ),
    );
  }
}