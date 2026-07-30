import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoGiftOverlay extends StatefulWidget {
  final String url;
  final VoidCallback onFinished;

  const VideoGiftOverlay({super.key, required this.url, required this.onFinished});

  @override
  State<VideoGiftOverlay> createState() => _VideoGiftOverlayState();
}

class _VideoGiftOverlayState extends State<VideoGiftOverlay> with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // ১. ক্যাশ ম্যানেজার থেকে দ্রুত ফাইল ফেচ করা (ক্যাশ না থাকলে ডাউনলোড করবে)
      final fileInfo = await DefaultCacheManager().getFileFromCache(widget.url);
      var cachedFile = fileInfo?.file;

      if (cachedFile == null) {
        cachedFile = await DefaultCacheManager().getSingleFile(widget.url);
      }
      
      if (!mounted) return;

      // ২. লোকাল ফাইল থেকে কন্ট্রোলার তৈরি এবং মেমোরি অপ্টিমাইজেশন
      _controller = VideoPlayerController.file(cachedFile)
        ..initialize().then((_) async {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
            _controller?.play();
            _fadeController.forward();
          }
        });

      _controller?.addListener(() {
        if (_controller == null || !_controller!.value.isInitialized) return;

        final duration = _controller!.value.duration;
        final position = _controller!.value.position;

        // ৩. ভিডিও শেষ হওয়ার ঠিক ৩০০ মিলিগ্রাম আগে ফেড আউট শুরু করে থাম্বনেইল আটকে যাওয়া রোধ করা
        if (duration - position <= const Duration(milliseconds: 300)) {
          if (_fadeController.isCompleted) {
            _fadeController.reverse();
          }
        }

        if (position >= duration) {
          widget.onFinished();
        }
      });
    } catch (e) {
     
      widget.onFinished(); // কোনো এরর হলে যেন আটকে না থাকে
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: (_isInitialized && _controller != null && _controller!.value.isInitialized)
              ? FadeTransition(
                  opacity: _fadeAnimation,
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    // চার কোনা বর্ডার বা হার্ড এজ লুক লুকাতে এবং ব্যাকগ্রাউন্ডের সাথে পারফেক্ট মিশে থাকতে BlendMode ব্যবহার করা হয়েছে
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return RadialGradient(
                          center: Alignment.center,
                          radius: 0.85,
                          colors: [Colors.white, Colors.white.withOpacity(0.0)],
                          stops: const [0.75, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                )
              : const SizedBox.shrink(), // লোডিংয়ের সময় কোনো ব্যাকগ্রাউন্ড দেখাবে না
        ),
      ),
    );
  }
}