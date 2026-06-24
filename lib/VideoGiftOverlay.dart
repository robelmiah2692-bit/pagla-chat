import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'; // ১. প্যাকেজ ইমপোর্ট

class VideoGiftOverlay extends StatefulWidget {
  final String url;
  final VoidCallback onFinished;

  const VideoGiftOverlay({super.key, required this.url, required this.onFinished});

  @override
  State<VideoGiftOverlay> createState() => _VideoGiftOverlayState();
}

class _VideoGiftOverlayState extends State<VideoGiftOverlay> {
  late VideoPlayerController _controller;
  bool _isInitialized = false; // কন্ট্রোলার ইনিশিয়ালাইজ হয়েছে কি না তা বোঝার জন্য

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // ক্যাশ ম্যানেজার থেকে ফাইলটি সংগ্রহ করুন (ডাউনলোড অথবা লোকাল স্টোরেজ থেকে)
      final file = await DefaultCacheManager().getSingleFile(widget.url);
      
      if (!mounted) return;

      // লোকাল ফাইল থেকে কন্ট্রোলার তৈরি
      _controller = VideoPlayerController.file(file)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _controller.play();
            });
          }
        });

      _controller.addListener(() {
        if (_controller.value.position >= _controller.value.duration) {
          widget.onFinished();
        }
      });
    } catch (e) {
      print("DEBUG: Video caching or loading error: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // মেমোরি থেকে কন্ট্রোলার রিলিজ করা
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26, // ভিডিওর পেছনে হালকা কালো আভা
      child: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}