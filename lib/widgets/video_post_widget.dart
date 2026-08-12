import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io' as io;

const Color cyanOwner = Color(0xFF00FBFF);

// ==========================================
// ১. ভিডিও পোস্ট বা সিলেক্ট করার উইজেট (পিক আপ সেকশন)
// ==========================================
class VideoPostWidget extends StatefulWidget {
  final Function(XFile? videoFile, Uint8List? webVideoBytes) onVideoSelected;
  final bool isVip;

  const VideoPostWidget({
    super.key,
    required this.onVideoSelected,
    required this.isVip,
  });

  @override
  State<VideoPostWidget> createState() => _VideoPostWidgetState();
}

class _VideoPostWidgetState extends State<VideoPostWidget> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedVideo;
  Uint8List? _webVideoBytes;

  Future<void> _pickVideo(StateSetter setModalState) async {
    if (!widget.isVip) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔒 Video posting is locked! Only VIP users can post videos."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );

      if (video != null) {
        if (!kIsWeb) {
          final io.File file = io.File(video.path);
          final controller = VideoPlayerController.file(file);
          await controller.initialize();
          
          if (controller.value.duration > const Duration(seconds: 30)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("⚠️ Video must be 30 seconds or less! Please trim your video."),
                  backgroundColor: Colors.orangeAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            controller.dispose();
            return;
          }
          controller.dispose();
        }

        Uint8List? bytes;
        if (kIsWeb) {
          bytes = await video.readAsBytes();
        }

        setState(() {
          _selectedVideo = video;
          _webVideoBytes = bytes;
        });

        widget.onVideoSelected(_selectedVideo, _webVideoBytes);
        setModalState(() {});
      }
    } catch (e) {
      debugPrint("Error picking video: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_selectedVideo != null)
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                  color: Colors.black26,
                ),
                child: const Center(
                  child: Icon(Icons.play_circle_fill, color: Colors.cyanAccent, size: 50),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedVideo = null;
                      _webVideoBytes = null;
                    });
                    widget.onVideoSelected(null, null);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              )
            ],
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isVip ? Icons.videocam : Icons.lock,
              color: widget.isVip ? Colors.cyanAccent : Colors.redAccent,
            ),
          ),
          title: Row(
            children: [
              const Text("Add video (Max 30s)",
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              if (!widget.isVip) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: const Text("VIP LOCKED",
                      style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ]
            ],
          ),
          onTap: () => _pickVideo((fn) => setState(fn)),
        ),
      ],
    );
  }
}

// ==========================================
// ২. ফিডে ইমেজ এবং ভিডিও রেন্ডার করার মূল উইজেট
// ==========================================
class PostCardItemView extends StatelessWidget {
  final Map<String, dynamic> data;

  const PostCardItemView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- যদি ইমেজ থাকে ---
        if (data['storyImage'] != null && data['storyImage'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 200, maxHeight: 500),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.03)),
                child: CachedNetworkImage(
                  imageUrl: data['storyImage'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: cyanOwner, strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 150,
                    color: Colors.white10,
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 40),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // --- যদি ভিডিও থাকে (videoUrl অথবা storyVideo ফিল্ড চেক করা) ---
        if ((data['videoUrl'] != null && data['videoUrl'].toString().isNotEmpty) ||
            (data['storyVideo'] != null && data['storyVideo'].toString().isNotEmpty))
          FeedVideoPlayer(videoUrl: data['videoUrl'] ?? data['storyVideo']),
      ],
    );
  }
}

// ==========================================
// ৩. ফিডের ভেতরে ভিডিও প্লে করার প্লেয়ার উইজেট ( ক্যাশ ও লুপসহ )
// ==========================================
class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const FeedVideoPlayer({super.key, required this.videoUrl});

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // ক্যাশ থেকে ভিডিও লোড করার জন্য standard networkUrl ব্যবহার করা হয়েছে যা অটো ক্যাশ মেইনটেইন করে
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          
          // ভিডিও শেষ হলে শুরুতে চলে যাওয়ার জন্য লিসেনার যুক্ত করা হলো
          _controller.addListener(_videoListener);
        }
      });
  }

  void _videoListener() {
    if (!mounted) return;
    // ভিডিও শেষ হয়ে গেলে (position == duration) আবার শুরুতে নিয়ে যাবে এবং পজ করে দেবে বা প্লে বাটনে আনবে
    if (_controller.value.position >= _controller.value.duration) {
      setState(() {
        _isPlaying = false;
        _controller.seekTo(Duration.zero);
        _controller.pause();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const CircularProgressIndicator(color: cyanOwner, strokeWidth: 2),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 200, maxHeight: 500),
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isPlaying = !_isPlaying;
                    if (_isPlaying) {
                      // যদি ভিডিও একদম শেষে থাকে আর প্লে চাপলে শুরুতে এসে প্লে হবে
                      if (_controller.value.position >= _controller.value.duration) {
                        _controller.seekTo(Duration.zero);
                      }
                      _controller.play();
                    } else {
                      _controller.pause();
                    }
                  });
                },
                child: Container(
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: AnimatedOpacity(
                    opacity: _isPlaying ? 0.0 : 1.0, // প্লে হলে আইকন হাইড হবে, পজ হলে শো করবে
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: cyanOwner,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}