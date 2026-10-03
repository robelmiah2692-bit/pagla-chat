import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pagla_chat/reels_interstitial_ad_manager.dart';
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

  List<QueryDocumentSnapshot> _shuffledVideoDocs = [];
  bool _isInitialized = false;

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

  void jumpToNextVideo(int totalItems) {
    if (!mounted) return;
    int nextIndex = _currentIndexNotifier.value + 1;
    if (nextIndex >= totalItems) {
      nextIndex = 0;
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
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_isInitialized) {
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

          if (!_isInitialized || _shuffledVideoDocs.isEmpty) {
            final videoDocs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              String videoUrl = data['videoUrl'] ?? '';
              return videoUrl.isNotEmpty;
            }).toList();

            videoDocs.shuffle();
            _shuffledVideoDocs = videoDocs;
            _isInitialized = true;

            // 🔥 প্রথম ভিডিওটি লোড হওয়ার সাথে সাথেই পরবর্তী ভিডিওটি ব্যাকগ্রাউন্ডে প্রিলোড শুরু করবে
            if (_shuffledVideoDocs.length > 1) {
              final nextData = _shuffledVideoDocs[1].data() as Map<String, dynamic>;
              String nextUrl = nextData['videoUrl'] ?? '';
              if (nextUrl.isNotEmpty) {
                VideoCacheManager.preloadVideo(nextUrl);
              }
            }
          }

          if (_shuffledVideoDocs.isEmpty) {
            return const Center(
              child: Text(
                "এই মুহূর্তে কোনো ভিডিও রিল নেই!",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          int totalItemsCount =
              _shuffledVideoDocs.length + (_shuffledVideoDocs.length ~/ 3);

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: totalItemsCount,
            onPageChanged: (index) {
              _currentIndexNotifier.value = index;

              if ((index + 1) % 4 == 0) {
                ReelsInterstitialAdManager.showAd();
              }

              // 🔥 ইউজার যখনই পরবর্তী ভিডিওতে যাবে, তার পরের ভিডিওটি ব্যাকগ্রাউন্ডে প্রিলোড হবে
              int currentVideoIndex = index - (index ~/ 4);
              int nextVideoIndex = currentVideoIndex + 1;
              if (nextVideoIndex < _shuffledVideoDocs.length) {
                final nextData = _shuffledVideoDocs[nextVideoIndex].data() as Map<String, dynamic>;
                String nextUrl = nextData['videoUrl'] ?? '';
                if (nextUrl.isNotEmpty) {
                  VideoCacheManager.preloadVideo(nextUrl);
                }
              }
            },
            itemBuilder: (context, index) {
              bool isAdSlot = (index > 0 && (index + 1) % 4 == 0);

              if (isAdSlot) {
                return const ReelsAdWidget();
              }

              int videoIndex = index - (index ~/ 4);
              if (videoIndex >= _shuffledVideoDocs.length) {
                videoIndex = _shuffledVideoDocs.length - 1;
              }

              final doc = _shuffledVideoDocs[videoIndex];
              final data = doc.data() as Map<String, dynamic>;

              final String videoUrl = data['videoUrl'] ?? '';
              final String userName = data['userName'] ?? 'User';
              final String userImage = data['userImage'] ?? '';
              final String caption = data['caption'] ?? '';
              final List likes = data['likes'] ?? [];
              final String docId = doc.id;
              final String userId = data['userId'] ?? data['uid'] ?? '';

              return ValueListenableBuilder<int>(
                valueListenable: _currentIndexNotifier,
                builder: (context, currentIndex, child) {
                  final bool isVideoActive =
                      isPageActive && (currentIndex == index);
                  final bool isPreloadTarget =
                      isPageActive && (index == currentIndex + 1);

                  return ReelVideoPlayerItem(
                    videoUrl: videoUrl,
                    userName: userName,
                    userImage: userImage,
                    caption: caption,
                    likes: likes,
                    docId: docId,
                    userId: userId,
                    postId: docId,
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

class VideoCacheManager {
  static final Map<String, VideoPlayerController> _cache = {};

  static VideoPlayerController getController(String url) {
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    } else {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        formatHint: VideoFormat.other,
      );
      _cache[url] = controller;
      return controller;
    }
  }

  // 🔥 ব্যাকগ্রাউন্ডে সাইলেন্টলি ভিডিও ইনিশিয়ালাইজ ও প্রিলোড করার মেথড
  static void preloadVideo(String url) {
    if (!_cache.containsKey(url) && url.isNotEmpty) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        formatHint: VideoFormat.other,
      );
      controller.initialize().then((_) {
        _cache[url] = controller;
      }).catchError((e) {
        debugPrint("Preload error: $e");
      });
    }
  }

  static void disposeControllers(List<String> activeUrls) {
    _cache.keys.toList().forEach((url) {
      if (!activeUrls.contains(url)) {
        _cache[url]?.dispose();
        _cache.remove(url);
      }
    });
  }
}

class ReelVideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  final String userName;
  final String userImage;
  final String caption;
  final List likes;
  final String docId;
  final String userId;
  final String postId;
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
    required this.userId,
    required this.postId,
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
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initVideoController();
  }

  void _initVideoController() {
    _controller = VideoCacheManager.getController(widget.videoUrl);

    if (_controller.value.isInitialized) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (!_controller.hasListeners) {
          _controller.addListener(_videoListener);
        }
        _applyPlayState();
      }
    } else {
      _controller.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.setLooping(false);
          if (!_controller.hasListeners) {
            _controller.addListener(_videoListener);
          }
          _applyPlayState();
        }
      }).catchError((error) {
        debugPrint("Video initialization error: $error");
      });
    }

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
          _userPaused = false;
        }
        _controller.pause();
        _isPlaying = false;
      }
    }
  }

  @override
  void dispose() {
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

  void _toggleLike(String pId, String postOwnerId, List currentLikes) async {
    DocumentReference ref =
        FirebaseFirestore.instance.collection('stories').doc(pId);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    bool isLiking = !currentLikes.contains(currentUser.uid);

    if (!isLiking) {
      ref.update({
        'likes': FieldValue.arrayRemove([currentUser.uid])
      });
    } else {
      ref.update({
        'likes': FieldValue.arrayUnion([currentUser.uid])
      });

      try {
        final senderQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: currentUser.email)
            .get();

        String sName = "Someone";
        String sPic = "";

        if (senderQuery.docs.isNotEmpty) {
          var sData = senderQuery.docs.first.data();
          sName = sData['name'] ?? "Someone";
          sPic = sData['profilePic'] ?? sData['userImage'] ?? "";
        }

        String targetAuthUID = postOwnerId;

        // যদি postOwnerId ফায়ারবেস Auth UID না হয়ে কাস্টম userId হয় (যেমন সংখ্যা বা ছোট স্ট্রিং)
        if (postOwnerId.length < 20) {
          final ownerQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('uID', isEqualTo: postOwnerId)
              .get();

          if (ownerQuery.docs.isNotEmpty) {
            targetAuthUID =
                ownerQuery.docs.first.data()['authUID'] ?? postOwnerId;
          }
        }

        // ইমেজ বাদ দিয়ে শুধু ভিডিও বা ইউজার প্রফাইল পিকচার ব্যবহার করা হয়েছে
        String pImage = (widget.userImage ?? '').toString();

        if (targetAuthUID.isNotEmpty && targetAuthUID != currentUser.uid) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'receiverId': targetAuthUID,
            'senderId': currentUser.uid,
            'senderName': sName,
            'senderPic': sPic,
            'type': 'like',
            'commentText': '',
            'postImage': pImage,
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        print("Error sending like notification: $e");
      }
    }
  }

  void _showCommentSheet(BuildContext context, String pId, String postOwnerId) {
    final TextEditingController _commentController = TextEditingController();

    ValueNotifier<Map<String, String>?> replyingToNotifier =
        ValueNotifier<Map<String, String>?>(null);

    const Color premiumGold = Color(0xFFFFD700);
    const Color cyanOwner = Color(0xFF00FBFF);
    final Color glassBg = const Color(0xFF1E2A47).withOpacity(0.4);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 12,
                right: 12),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1a0b36).withOpacity(0.92),
                        const Color(0xFF0d1b3a).withOpacity(0.92),
                        const Color(0xFF050b18).withOpacity(0.95),
                      ],
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border.all(
                      color: cyanOwner.withOpacity(0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3b0764).withOpacity(0.4),
                        blurRadius: 25,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Container(
                          width: 36,
                          height: 3.5,
                          decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(10))),
                      const SizedBox(height: 10),
                      const Text("COMMENTS",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 1.5)),
                      const Divider(color: Colors.white10, height: 20),
                      SizedBox(
                        height: 250,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('stories')
                              .doc(pId)
                              .collection('comments')
                              .orderBy('timestamp', descending: false)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: cyanOwner, strokeWidth: 2));
                            }
                            if (snapshot.data!.docs.isEmpty) {
                              return const Center(
                                  child: Text("No comments yet. Be the first!",
                                      style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 13)));
                            }
                            return ListView.builder(
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                var doc = snapshot.data!.docs[index];
                                Map<String, dynamic> cData =
                                    doc.data() as Map<String, dynamic>;

                                String commentId = doc.id;
                                String senderName = cData['userName'] ?? "User";
                                String commentText = cData['text'] ?? "";
                                String? replyToName = cData['replyToName'];
                                String? replyToText = cData['replyToText'];

                                return InkWell(
                                  onTap: () {
                                    replyingToNotifier.value = {
                                      'id': commentId,
                                      'name': senderName,
                                      'text': commentText,
                                    };
                                    setState(() {});
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.03),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.grey[900],
                                          backgroundImage:
                                              CachedNetworkImageProvider(cData[
                                                              'userImage'] !=
                                                          null &&
                                                      cData['userImage'] != ""
                                                  ? cData['userImage']
                                                  : "https://www.w3schools.com/howto/img_avatar.png"),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(senderName,
                                                  style: const TextStyle(
                                                      color: cyanOwner,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              const SizedBox(height: 2),
                                              if (replyToName != null &&
                                                  replyToText != null)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 4),
                                                  padding:
                                                      const EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                      color: cyanOwner
                                                          .withOpacity(0.08),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      border: const Border(
                                                        left: BorderSide(
                                                            color: cyanOwner,
                                                            width: 2),
                                                      )),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          "Replying to $replyToName",
                                                          style: const TextStyle(
                                                              color: cyanOwner,
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                      Text(replyToText,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: const TextStyle(
                                                              color: Colors
                                                                  .white60,
                                                              fontSize: 10)),
                                                    ],
                                                  ),
                                                ),
                                              Text(commentText,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.reply,
                                            color: Colors.white24, size: 14),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      ValueListenableBuilder<Map<String, String>?>(
                        valueListenable: replyingToNotifier,
                        builder: (context, replyingTo, child) {
                          if (replyingTo == null)
                            return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: glassBg,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: cyanOwner.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.reply,
                                    color: cyanOwner, size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Replying to ${replyingTo['name']}",
                                    style: const TextStyle(
                                        color: cyanOwner,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    replyingToNotifier.value = null;
                                    setState(() {});
                                  },
                                  child: const Icon(Icons.close,
                                      color: Colors.white54, size: 14),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.06),
                                  hintText: replyingToNotifier.value != null
                                      ? "Write a reply..."
                                      : "Add a comment...",
                                  hintStyle: const TextStyle(
                                      color: Colors.white38, fontSize: 12),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(22),
                                      borderSide: BorderSide(
                                        color: premiumGold.withOpacity(0.2),
                                        width: 0.8,
                                      )),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(22),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 0.8,
                                      )),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(22),
                                      borderSide: const BorderSide(
                                        color: cyanOwner,
                                        width: 1,
                                      )),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [
                                  cyanOwner,
                                  cyanOwner.withOpacity(0.6)
                                ]),
                                boxShadow: [
                                  BoxShadow(
                                    color: cyanOwner.withOpacity(0.3),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.send_rounded,
                                    color: Colors.black, size: 18),
                                onPressed: () {
                                  if (_commentController.text.trim().isEmpty)
                                    return;

                                  Map<String, String>? currentReply =
                                      replyingToNotifier.value;
                                  _submitCommentWithReply(
                                    pId,
                                    _commentController.text.trim(),
                                    _commentController,
                                    postOwnerId,
                                    currentReply,
                                  );

                                  replyingToNotifier.value = null;
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _submitCommentWithReply(
      String pId,
      String text,
      TextEditingController controller,
      String postOwnerId,
      Map<String, String>? replyInfo) async {
    if (text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();

      String name = "User";
      String image = "";

      if (userQuery.docs.isNotEmpty) {
        var userData = userQuery.docs.first.data();
        name = userData['name'] ?? "User";
        image = userData['profilePic'] ?? userData['userImage'] ?? "";
      }

      await FirebaseFirestore.instance
          .collection('stories')
          .doc(pId)
          .collection('comments')
          .add({
        'uid': user.uid,
        'userName': name,
        'userImage': image,
        'text': text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'replyToId': replyInfo != null ? replyInfo['id'] : null,
        'replyToName': replyInfo != null ? replyInfo['name'] : null,
        'replyToText': replyInfo != null ? replyInfo['text'] : null,
      });

      if (postOwnerId.isNotEmpty && postOwnerId != user.uid) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'receiverId': postOwnerId,
          'senderId': user.uid,
          'senderName': name,
          'senderPic': image,
          'type': 'comment',
          'commentText': text.trim(),
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      controller.clear();
    } catch (e) {}
  }

 @override
  Widget build(BuildContext context) {
    super.build(context);
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bool isLiked = widget.likes.contains(currentUserId);

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
                      // 🔥 ঠিক এই জায়গাতে পুরনো কোডগুলো মুছে ReelUserInfo বসানো হলো
                      ReelUserInfo(
                        userId: widget.userId,
                        fallbackName: widget.userName,
                        fallbackImage: widget.userImage,
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
                      onPressed: () => _toggleLike(
                          widget.postId, widget.userId, widget.likes),
                      icon: Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isLiked ? const Color(0xFFFF2E93) : Colors.white,
                        size: 32,
                      ),
                    ),
                    Text(
                      '${widget.likes.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 15),
                    IconButton(
                      onPressed: () => _showCommentSheet(
                          context, widget.postId, widget.userId),
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
// 🔥 ইউজার ইনফো রিয়েল-টাইম দেখানোর জন্য একটি ছোট স্টেটলেস উইজেট
class ReelUserInfo extends StatelessWidget {
  final String userId;
  final String fallbackName;
  final String fallbackImage;

  const ReelUserInfo({
    super.key,
    required this.userId,
    required this.fallbackName,
    required this.fallbackImage,
  });

  @override
  Widget build(BuildContext context) {
    // যদি userId না থাকে, তবে পোস্টের পুরনো ডাটা ফলব্যাক হিসেবে দেখাবে
    if (userId.isEmpty) {
      return Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade800,
            backgroundImage: fallbackImage.isNotEmpty
                ? CachedNetworkImageProvider(fallbackImage)
                : null,
            child: fallbackImage.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Text(
            fallbackName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        String displayName = fallbackName;
        String displayImage = fallbackImage;

        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>?;
          if (userData != null) {
            displayName = userData['name'] ?? userData['userName'] ?? fallbackName;
            displayImage = userData['profilePic'] ?? userData['userImage'] ?? fallbackImage;
          }
        }

        return Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade800,
              backgroundImage: displayImage.isNotEmpty
                  ? CachedNetworkImageProvider(displayImage)
                  : null,
              child: displayImage.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        );
      },
    );
  }
}