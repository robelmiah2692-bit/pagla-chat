import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'; // ক্যাশ করার জন্য
import 'dart:async';

class EntryEffectHandler extends StatefulWidget {
  final String userName;
  final String? userImage;
  final String? activeFrameUrl;
  final String effectUrl;
  final VoidCallback onFinished;

  const EntryEffectHandler({
    super.key,
    required this.userName,
    required this.userImage,
    this.activeFrameUrl,
    required this.effectUrl,
    required this.onFinished,
  });

  @override
  State<EntryEffectHandler> createState() => _EntryEffectHandlerState();
}

class _EntryEffectHandlerState extends State<EntryEffectHandler> {
  @override
  void initState() {
    super.initState();
    
    // ভিডিও হলে প্লেয়ারের নিজস্ব ফেড আউট ও টাইমিং কাজ করবে, অন্যথায় ৬ সেকেন্ড পর অটো বন্ধ হবে
    bool isVideo = widget.effectUrl.toLowerCase().contains('.mp4') || 
                   widget.effectUrl.toLowerCase().contains('.webm') || 
                   widget.effectUrl.toLowerCase().contains('.mov');

    if (!isVideo) {
      Timer(const Duration(seconds: 6), () {
        if (mounted) widget.onFinished();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.effectUrl.isEmpty) {
      widget.onFinished();
      return const SizedBox.shrink();
    }

    bool isVideo = widget.effectUrl.toLowerCase().contains('.mp4') || 
                   widget.effectUrl.toLowerCase().contains('.webm') || 
                   widget.effectUrl.toLowerCase().contains('.mov');

    // 🔥 যদি এটি ভিডিও এন্ট্রি হয়, তবে ShaderMask এবং FadeTransition সহ ভিডিও প্লে হবে
    if (isVideo) {
      return _VideoEntryPlayerWrapper(
        videoUrl: widget.effectUrl,
        onFinished: widget.onFinished,
      );
    }

    // অন্যথায় আগের লটি বা ব্যানার এন্ট্রি দেখাবে
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ১. মূল এন্ট্রি এনিমেশন (Lottie)
            Lottie.network(
              widget.effectUrl,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),

            // ২. রয়াল ব্যানার ডিজাইন
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.9),
                      Colors.purple.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.yellowAccent.withOpacity(0.5), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2)
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 22,
                            backgroundImage: (widget.userImage != null && widget.userImage!.isNotEmpty)
                                ? NetworkImage(widget.userImage!)
                                : null,
                            child: (widget.userImage == null || widget.userImage!.isEmpty)
                                ? const Icon(Icons.person)
                                : null,
                          ),
                        ),
                        if (widget.activeFrameUrl != null && widget.activeFrameUrl!.isNotEmpty)
                          Positioned(
                            width: 80,
                            height: 80,
                            child: widget.activeFrameUrl!.contains('.json')
                                ? Lottie.network(widget.activeFrameUrl!, fit: BoxFit.contain)
                                : Image.network(widget.activeFrameUrl!, fit: BoxFit.contain),
                          ),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              color: Colors.yellowAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              shadows: [Shadow(color: Colors.black, blurRadius: 5)],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            "is coming...",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔥 ভিডিও এন্ট্রি প্লেয়ার যাতে কর্নার ব্লার এবং শেষ ২ সেকেন্ডে আস্তে আস্তে মুছে যায়
class _VideoEntryPlayerWrapper extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onFinished;

  const _VideoEntryPlayerWrapper({required this.videoUrl, required this.onFinished});

  @override
  State<_VideoEntryPlayerWrapper> createState() => _VideoEntryPlayerWrapperState();
}

class _VideoEntryPlayerWrapperState extends State<_VideoEntryPlayerWrapper> with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // ভিডিওর শেষ ২ সেকেন্ডে আস্তে আস্তে মুছার জন্য ফেড কন্ট্রোলার
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // ১. ক্যাশ ম্যানেজার থেকে দ্রুত ফাইল ফেচ করা
      final fileInfo = await DefaultCacheManager().getFileFromCache(widget.videoUrl);
      var cachedFile = fileInfo?.file;

      if (cachedFile == null) {
        cachedFile = await DefaultCacheManager().getSingleFile(widget.videoUrl);
      }
      
      if (!mounted) return;

      // ২. লোকাল ক্যাশ ফাইল থেকে কন্ট্রোলার তৈরি
      _controller = VideoPlayerController.file(cachedFile)
        ..initialize().then((_) async {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
            _controller?.play();
            _controller?.setVolume(1.0);
            _fadeController.value = 1.0; // শুরুতে ফুল ভিজিবল থাকবে
          }
        });

      _controller?.addListener(() {
        if (_controller == null || !_controller!.value.isInitialized) return;

        final duration = _controller!.value.duration;
        final position = _controller!.value.position;

        // ৩. ভিডিও শেষ হওয়ার ঠিক ২ সেকেন্ড আগে থেকে ফেড আউট (আস্তে আস্তে মুছে যাওয়া) শুরু হবে
        if (duration - position <= const Duration(seconds: 2)) {
          if (!_fadeController.isAnimating && _fadeController.value > 0.0) {
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
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: (_isInitialized && _controller != null && _controller!.value.isInitialized)
                ? FadeTransition(
                    opacity: _fadeAnimation,
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      // চার কোনা বর্ডার বা হার্ড এজ লুক লুকাতে ShaderMask ব্যবহার করা হয়েছে
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
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}