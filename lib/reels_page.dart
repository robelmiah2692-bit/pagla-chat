import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'reels_ad_widget.dart'; // 🔥 আলাদা করা অ্যাড ফাইল

class ReelsPage extends StatefulWidget {
  final bool isActive; 

  const ReelsPage({super.key, required this.isActive});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late PageController _pageController;
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier<int>(0);
  bool _isAppInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _currentIndexNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      setState(() {
        _isAppInForeground = false;
      });
    } else if (state == AppLifecycleState.resumed) {
      setState(() {
        _isAppInForeground = true;
      });
    }
  }

  // 🔥 ভিডিও শেষ হলে স্মুথলি পরবর্তী ভিডিওতে স্ক্রল করার মেথড
  void jumpToNextVideo(int totalItems) {
    if (!mounted) return;
    int nextIndex = _currentIndexNotifier.value + 1;
    if (nextIndex >= totalItems) {
      nextIndex = 0; // লিস্ট শেষ হলে আবার প্রথম ভিডিওতে ফিরে আসবে
    }
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPageActive = widget.isActive && _isAppInForeground;

    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('stories')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF2E93)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "কোনো রিলস বা ভিডিও পাওয়া যায়নি!",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          // 🔥 সকল পোস্ট করা ভিডিও ফিল্টার করে লিস্টে আনা
          final videoDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            String videoUrl = data['videoUrl'] ?? '';
            return videoUrl.isNotEmpty;
          }).toList();

          if (videoDocs.isEmpty) {
            return const Center(
              child: Text(
                "এই মুহূর্তে কোনো ভিডিও রিল নেই!",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          // 🔥 মোট আইটেম সংখ্যা হিসাব (প্রতি ৫টি ভিডিওর পর ১টি করে অ্যাড যুক্ত করা)
          int totalItemsCount = videoDocs.length + (videoDocs.length ~/ 5);

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: totalItemsCount,
            onPageChanged: (index) {
              _currentIndexNotifier.value = index; // setState ছাড়াই ইন্ডেক্স আপডেট
            },
            itemBuilder: (context, index) {
              // চেক করা এটি অ্যাড স্লট কিনা
              bool isAdSlot = (index > 0 && (index + 1) % 6 == 0);

              if (isAdSlot) {
                return const ReelsAdWidget();
              }

              // রিয়েল ভিডিও ইনডেক্স হিসাব করা
              int videoIndex = index - (index ~/ 6);
              if (videoIndex >= videoDocs.length) {
                videoIndex = videoDocs.length - 1;
              }

              final doc = videoDocs[videoIndex];
              final data = doc.data() as Map<String, dynamic>;

              final String videoUrl = data['videoUrl'] ?? '';
              final String userName = data['userName'] ?? 'User';
              final String userImage = data['userImage'] ?? '';
              final String caption = data['caption'] ?? '';
              final List likes = data['likes'] ?? [];
              final String docId = doc.id;

              return ValueListenableBuilder<int>(
                valueListenable: _currentIndexNotifier,
                builder: (context, currentIndex, child) {
                  // 🔥 প্রি-লোডিং লজিক: বর্তমান ভিডিও এবং ঠিক তার পরের ভিডিওটি ব্যাকগ্রাউন্ডে প্রি-লোড বা অ্যাক্টিভ রাখা হবে
                  final bool isVideoActive = isPageActive && (currentIndex == index);
                  final bool isPreloadTarget = isPageActive && (index == currentIndex + 1);

                  return ReelVideoPlayerItem(
                    videoUrl: videoUrl,
                    userName: userName,
                    userImage: userImage,
                    caption: caption,
                    likes: likes,
                    docId: docId,
                    isActive: isVideoActive,
                    isPreload: isPreloadTarget,
                    onVideoEnded: () {
                      jumpToNextVideo(totalItemsCount);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// 🔥 গ্লোবাল ভিডিও ক্যাশ ম্যানেজার যাতে একই ভিডিও বারবার রিক্রিয়েট বা রি-লোড না হয়
class VideoCacheManager {
  static final Map<String, VideoPlayerController> _cache = {};

  static VideoPlayerController getController(String url) {
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    } else {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _cache[url] = controller;
      return controller;
    }
  }
}

class ReelVideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  final String userName;
  final String userImage;
  final String caption;
  final List likes;
  final String docId;
  final bool isActive;
  final bool isPreload;
  final VoidCallback onVideoEnded;

  const ReelVideoPlayerItem({
    super.key,
    required this.videoUrl,
    required this.userName,
    required this.userImage,
    required this.caption,
    required this.likes,
    required this.docId,
    required this.isActive,
    required this.isPreload,
    required this.onVideoEnded,
  });

  @override
  State<ReelVideoPlayerItem> createState() => _ReelVideoPlayerItemState();
}

class _ReelVideoPlayerItemState extends State<ReelVideoPlayerItem>
    with AutomaticKeepAliveClientMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = true;
  bool _userPaused = false;
  bool _hasEndedTriggered = false;

  @override
  bool get wantKeepAlive => true; // পেজ সুইচ করলেও উইজেট ও স্টেট মেমোরিতে ধরে রাখবে

  @override
  void initState() {
    super.initState();
    _initVideoController();
  }

  void _initVideoController() {
    // 🔥 ক্যাশড কন্ট্রোলার ব্যবহার করা হচ্ছে যাতে বারবার ফেচ বা লোড না হয়
    _controller = VideoCacheManager.getController(widget.videoUrl);

    if (_controller.value.isInitialized) {
      setState(() {
        _isInitialized = true;
      });
      _applyPlayState();
    } else {
      _controller.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.setLooping(false);
          _controller.addListener(_videoListener);
          _applyPlayState();
        }
      }).catchError((error) {
        debugPrint("Video initialization error: $error");
      });
    }

    // যদি আগে থেকেই লিসาেনার যুক্ত না থাকে তবে যুক্ত করা
    if (!_controller.hasListeners) {
      _controller.addListener(_videoListener);
    }
  }

  void _applyPlayState() {
    if (widget.isActive) {
      _hasEndedTriggered = false;
      if (!_userPaused) {
        _controller.play();
        _isPlaying = true;
      }
    } else if (widget.isPreload) {
      // 🔥 পরবর্তী ভিডিও ব্যাকগ্রাউন্ডে পজ অবস্থায় ইনিশিয়ালাইজ ও প্রস্তুত থাকবে
      _controller.pause();
      _isPlaying = false;
    } else {
      _controller.pause();
      _isPlaying = false;
    }
  }

  void _videoListener() {
    if (!mounted || !_isInitialized || !_controller.value.isInitialized) return;

    final position = _controller.value.position;
    final duration = _controller.value.duration;

    if (duration > Duration.zero &&
        position >= duration &&
        !_hasEndedTriggered &&
        widget.isActive) {
      _hasEndedTriggered = true;
      widget.onVideoEnded();
    }
  }

  @override
  void didUpdateWidget(covariant ReelVideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isInitialized) {
      if (widget.isActive) {
        _hasEndedTriggered = false;
        if (!_userPaused) {
          _controller.play();
          _isPlaying = true;
        }
      } else {
        if (!widget.isPreload) {
          _userPaused = false; // অন্য ভিডিওতে চলে গেলে ইউজারের পজ স্ট্যাটাস রিসেট হবে
        }
        _controller.pause();
        _isPlaying = false;
      }
    }
  }

  @override
  void dispose() {
    // ক্যাশ ম্যানেজারের কারণে এখানে কন্ট্রোলার পুরোপুরি dispose করা হচ্ছে না যাতে মেমোরিতে ভিডিও ক্যাশ থাকে
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
        _userPaused = true;
      } else {
        _controller.play();
        _isPlaying = true;
        _userPaused = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                )
              : Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF2E93)),
                  ),
                ),
          if (_isInitialized && !_isPlaying && widget.isActive)
            const Center(
              child: Icon(
                Icons.play_arrow_rounded,
                size: 80,
                color: Colors.white70,
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: 15,
            right: 15,
            bottom: 30,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey.shade800,
                            backgroundImage: widget.userImage.isNotEmpty
                                ? NetworkImage(widget.userImage)
                                : null,
                            child: widget.userImage.isEmpty
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (widget.caption.isNotEmpty)
                        Text(
                          widget.caption,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFFF2E93),
                        size: 32,
                      ),
                    ),
                    Text(
                      '${widget.likes.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 15),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.mode_comment_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const Text(
                      'Comment',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    const SizedBox(height: 15),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const Text(
                      'Share',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}