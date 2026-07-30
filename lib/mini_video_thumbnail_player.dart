import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// গ্লোবাল স্টোরেজ যাতে অ্যাপে একবার লোড হওয়ার পর বারবার লোড না করে
class GlobalVideoThumbnailCache {
  static final Map<String, VideoPlayerController> controllers = {};
  static final Set<String> loadingUrls = {};
}

class MiniVideoThumbnailPlayer extends StatefulWidget {
  final String videoUrl;
  const MiniVideoThumbnailPlayer({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _MiniVideoThumbnailPlayerState createState() => _MiniVideoThumbnailPlayerState();
}

class _MiniVideoThumbnailPlayerState extends State<MiniVideoThumbnailPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadStaticThumbnail();
  }

  Future<void> _loadStaticThumbnail() async {
    try {
      // ১. যদি আগেই গ্লোবাল ক্যাশে এই কন্ট্রোলার থেকে থাকে, তবে নতুন করে লোড করার দরকার নেই
      if (GlobalVideoThumbnailCache.controllers.containsKey(widget.videoUrl)) {
        if (mounted) {
          setState(() {
            _controller = GlobalVideoThumbnailCache.controllers[widget.videoUrl];
            _isInitialized = true;
          });
        }
        return;
      }

      // ২. ফাইল ক্যাশ থেকে বা নেট থেকে একবারই আনা হবে
      final fileInfo = await DefaultCacheManager().getFileFromCache(widget.videoUrl);
      var cachedFile = fileInfo?.file;

      if (cachedFile == null) {
        cachedFile = await DefaultCacheManager().getSingleFile(widget.videoUrl);
      }

      if (!mounted) return;

      // ৩. নতুন কন্ট্রোলার তৈরি করে ইনিশিয়ালাইজ করা
      final newController = VideoPlayerController.file(cachedFile);
      
      await newController.initialize();

      if (!mounted) return;

      // ৪. গ্লোবাল ক্যাশে সেভ করে রাখা যাতে বারবার বক্সে ঢুকলেও লোড না হয়
      GlobalVideoThumbnailCache.controllers[widget.videoUrl] = newController;

      setState(() {
        _controller = newController;
        _isInitialized = true;
      });
    } catch (e) {
      print("DEBUG: Thumbnail load error: $e");
    }
  }

  @override
  void dispose() {
    // এখানে কন্ট্রোলার ডিসপোজ করা হবে না, যাতে গ্লোবাল ক্যাশ মেমোরিতে স্থায়ীভাবে থাকে
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: SizedBox(
          width: 20, 
          height: 20, 
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24)
        ),
      );
    }
    
    // ভিডিও প্লে হবে না, একদম স্থির থাম্বনেইলের মতো শো করবে
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}