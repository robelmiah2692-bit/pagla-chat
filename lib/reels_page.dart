import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pagla_chat/profile_page.dart';
import 'package:pagla_chat/reels_interstitial_ad_manager.dart';
import 'package:pagla_chat/services/follow_service.dart';
import 'package:pagla_chat/widgets/video_post_widget.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
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

  final ValueNotifier<bool> _isFollowingTabNotifier =
      ValueNotifier<bool>(false);
  String _myResolvedUid = '';
  Set<String> _followingIds = {};
  StreamSubscription<QuerySnapshot>? _followingSub;

  List<QueryDocumentSnapshot> _shuffledVideoDocs = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    _syncWakelock();
    _initFollowingListener();
  }

  @override
  void didUpdateWidget(covariant ReelsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncWakelock();
    }
  }

  void _syncWakelock() {
    final bool shouldKeepAwake = widget.isActive && _isAppInForeground;
    if (shouldKeepAwake) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable(); // 🔒 পেজ বন্ধ হলে স্ক্রিন লক স্বাভাবিক করে দেওয়া
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _currentIndexNotifier.dispose();
    _followingSub?.cancel();
    _isFollowingTabNotifier.dispose();
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
      _syncWakelock();
    } else if (state == AppLifecycleState.resumed) {
      setState(() {
        _isAppInForeground = true;
      });
      _syncWakelock();
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

  Future<void> _initFollowingListener() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    String myUid = currentUser.uid;
    try {
      final byAuth = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
      if (byAuth.docs.isNotEmpty) {
        myUid = byAuth.docs.first.data()['uID']?.toString().trim().isNotEmpty ==
                true
            ? byAuth.docs.first.data()['uID'].toString().trim()
            : byAuth.docs.first.id;
      }
    } catch (e) {
      debugPrint("Following myUid resolve error: $e");
    }

    if (!mounted) return;
    setState(() {
      _myResolvedUid = myUid;
    });

    _followingSub?.cancel();
    _followingSub = FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('followingList')
        .snapshots()
        .listen((snap) async {
      final Set<String> ids = {};
      for (final doc in snap.docs) {
        final String id = doc.id.trim();
        if (id.isEmpty) continue;
        ids.add(id);

        // যদি ওই ইউজারের ডকুমেন্টে authUID বা uID আলাদা থাকে, সেটাও লিস্টে যুক্ত করা
        try {
          final targetDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(id)
              .get();
          if (targetDoc.exists) {
            final data = targetDoc.data();
            final String? uIdField = data?['uID']?.toString().trim();
            final String? authUidField = data?['authUID']?.toString().trim();
            if (uIdField != null && uIdField.isNotEmpty) ids.add(uIdField);
            if (authUidField != null && authUidField.isNotEmpty) {
              ids.add(authUidField);
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _followingIds = ids;
        });
      }
    });
  }

  void _switchFeedTab(bool followingMode) {
    if (_isFollowingTabNotifier.value == followingMode) return;
    _isFollowingTabNotifier.value = followingMode;
    _currentIndexNotifier.value = 0;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
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

            // 🔥 প্রথম ভিডিওটি লোড হওয়ার সাথে সাথেই পরবর্তী ভিডিওটি ব্যাকগ্রাউন্ডে প্রিলোড শুরু করবে
            if (_shuffledVideoDocs.length > 1) {
              final nextData =
                  _shuffledVideoDocs[1].data() as Map<String, dynamic>;
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

          // 🔥 ঠিক এই জায়গায় Following / For You ট্যাব অনুযায়ী ফিল্টার ও PageView বসানো হলো
          return ValueListenableBuilder<bool>(
            valueListenable: _isFollowingTabNotifier,
            builder: (context, isFollowingTab, _) {
              final List<QueryDocumentSnapshot> activeVideoDocs = isFollowingTab
                  ? _shuffledVideoDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final String postUserId =
                          (data['userId'] ?? '').toString().trim();
                      final String postUid =
                          (data['uid'] ?? '').toString().trim();
                      return (postUserId.isNotEmpty &&
                              _followingIds.contains(postUserId)) ||
                          (postUid.isNotEmpty &&
                              _followingIds.contains(postUid));
                    }).toList()
                  : _shuffledVideoDocs;

              if (isFollowingTab && activeVideoDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "আপনি যাদের ফলো করেছেন তাদের কোনো ভিডিও নেই!",
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _switchFeedTab(false),
                        child: const Text(
                          "Back to For You",
                          style: TextStyle(color: Color(0xFF00FBFF)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              int totalItemsCount =
                  activeVideoDocs.length + (activeVideoDocs.length ~/ 3);

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
                  if (nextVideoIndex < activeVideoDocs.length) {
                    final nextData = activeVideoDocs[nextVideoIndex].data()
                        as Map<String, dynamic>;
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
                  if (videoIndex >= activeVideoDocs.length) {
                    videoIndex = activeVideoDocs.length - 1;
                  }

                  final doc = activeVideoDocs[videoIndex];
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
                        isFollowingTab: isFollowingTab,
                        onTabChanged: _switchFeedTab,
                        onVideoEnded: () {
                          jumpToNextVideo(totalItemsCount);
                        },
                      );
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
  final bool isFollowingTab; // ✅ যুক্ত করা হলো
  final ValueChanged<bool> onTabChanged; // ✅ যুক্ত করা হলো
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
    this.isFollowingTab = false, // ✅ যুক্ত করা হলো
    required this.onTabChanged, // ✅ যুক্ত করা হলো
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

  bool _isMuted = false; // সাউন্ড চালু (`false`) নাকি বন্ধ (`true`)

  void _applyVolumeState() {
    if (_isInitialized && _controller.value.isInitialized) {
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _applyVolumeState();
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

  void _showReelVideoPostModal() {
    final TextEditingController captionController = TextEditingController();
    XFile? pickedVideo;
    Uint8List? pickedWebBytes;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141026),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // হেডার বার
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Post a Video Reel",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 6),

                  // শুধু ভিডিও সিলেক্ট করার উইজেট (VIP ফ্রি করা হয়েছে)
                  VideoPostWidget(
                    isVip: true,
                    onVideoSelected: (videoFile, webBytes) {
                      setModalState(() {
                        pickedVideo = videoFile;
                        pickedWebBytes = webBytes;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // ক্যাপশন ইনপুট
                  TextField(
                    controller: captionController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Write a caption for your reel...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // পোস্ট সাবমিট বাটন
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: (isUploading || pickedVideo == null)
                          ? null
                          : () async {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null || pickedVideo == null) return;

                              setModalState(() => isUploading = true);

                              try {
                                // ১. Firebase Storage-এ ভিডিও আপলোড করে Download URL নেওয়া
                                final String fileExt =
                                    pickedVideo!.name.contains('.')
                                        ? pickedVideo!.name.split('.').last
                                        : 'mp4';
                                final String fileName =
                                    'reel_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

                                final Reference storageRef = FirebaseStorage
                                    .instance
                                    .ref()
                                    .child('reel_videos')
                                    .child(fileName);

                                UploadTask uploadTask;
                                if (kIsWeb) {
                                  final Uint8List bytes = pickedWebBytes ??
                                      await pickedVideo!.readAsBytes();
                                  uploadTask = storageRef.putData(
                                    bytes,
                                    SettableMetadata(
                                        contentType: 'video/$fileExt'),
                                  );
                                } else {
                                  uploadTask = storageRef.putFile(
                                    io.File(pickedVideo!.path),
                                    SettableMetadata(
                                        contentType: 'video/$fileExt'),
                                  );
                                }

                                final TaskSnapshot snapshot = await uploadTask;
                                final String uploadedVideoUrl =
                                    await snapshot.ref.getDownloadURL();

                                // ২. ইউজারের নাম ও ছবি বের করা
                                String uName = user.displayName ?? "User";
                                String uPic = user.photoURL ?? "";
                                String uIdCustom = user.uid;

                                final userDocQuery = await FirebaseFirestore
                                    .instance
                                    .collection('users')
                                    .where('authUID', isEqualTo: user.uid)
                                    .limit(1)
                                    .get();

                                if (userDocQuery.docs.isNotEmpty) {
                                  final uData = userDocQuery.docs.first.data();
                                  uName = uData['name'] ??
                                      uData['userName'] ??
                                      uName;
                                  uPic = uData['profilePic'] ??
                                      uData['userImage'] ??
                                      uPic;
                                  uIdCustom =
                                      uData['uID']?.toString() ?? user.uid;
                                }

                                // ৩. stories কালেকশনে শুধু ভিডিও রিল হিসেবে সেভ করা
                                await FirebaseFirestore.instance
                                    .collection('stories')
                                    .add({
                                  'videoUrl': uploadedVideoUrl,
                                  'userName': uName,
                                  'userImage': uPic,
                                  'caption': captionController.text.trim(),
                                  'userId': uIdCustom,
                                  'uid': user.uid,
                                  'likes': [],
                                  'type': 'reel_video',
                                  'timestamp': FieldValue.serverTimestamp(),
                                });

                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "✅ Video reel posted successfully!"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                debugPrint("Reel post error: $e");
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error posting reel: $e"),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              } finally {
                                if (context.mounted) {
                                  setModalState(() => isUploading = false);
                                }
                              }
                            },
                      child: isUploading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.2,
                              ),
                            )
                          : const Text(
                              "Publish Reel",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  // আপনার _ReelVideoPlayerItemState ক্লাসে SingleTickerProviderStateMixin যুক্ত করুন:
// class _ReelVideoPlayerItemState extends State<ReelVideoPlayerItem>
//     with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // =====================================================================
          // 🎯 [১] মেইন ভিডিও প্লেয়ার ও লোডিং স্টেট (পুরাতন লজিক অক্ষত)
          // =====================================================================
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

          // =====================================================================
          // 🎯 [২] ভিডিও পজ অবস্থায় মাঝখানের প্লে আইকন (পুরাতন লজিক অক্ষত)
          // =====================================================================
          if (_isInitialized && !_isPlaying && widget.isActive)
            const Center(
              child: Icon(
                Icons.play_arrow_rounded,
                size: 80,
                color: Colors.white70,
              ),
            ),

          // =====================================================================
          // 🎯 [৩] ওপর ও নিচের ডার্ক গ্রেডিয়েন্ট (আইকন ও লেখা স্পষ্ট রাখার জন্য)
          // =====================================================================
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                      Colors.black.withOpacity(0.82),
                    ],
                    stops: const [0.0, 0.42, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // =====================================================================
          // 🎯 [৪] উপরের অংশ (TOP BAR): রিফ্রেশ, Following/For You, +Post, সাউন্ড
          // 👉 নিচের নেভিগেশন বাদে ভিডিওর ওপরের অংশের নতুন ডিজাইন লেয়ার
          // =====================================================================
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 14,
            right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ---------------------------------------------------------
                    // 🔘 নতুন UI: বাম পাশের LIVE বাটন ডিজাইন
                    // 👉 ক্লিক করলে এখন "Coming Soon" দেখাবে; পরে ভিডিও লাইভ যুক্ত করবেন
                    // ---------------------------------------------------------
                    GestureDetector(
                      onTap: () {
                        // TODO: পরে এখানে ভিডিও লাইভ স্ক্রিন/লজিক যুক্ত করুন
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '🎥 Video Live feature is Coming Soon!',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Color(0xFF1E1438),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF2E93),
                              Color(0xFFFF1744),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2E93).withOpacity(0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ---------------------------------------------------------
                    // 🔘 রিয়েল ফাংশন: মাঝখানের "Following" ও "For You" ট্যাব
                    // 👉 Following: ফলো করা ইউজারদের ভিডিও | For You: সব ভিডিও
                    // ---------------------------------------------------------
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.28),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => widget.onTabChanged(true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.isFollowingTab
                                    ? Colors.white.withOpacity(0.18)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Following',
                                style: TextStyle(
                                  color: widget.isFollowingTab
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.75),
                                  fontSize: 14,
                                  fontWeight: widget.isFollowingTab
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => widget.onTabChanged(false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: !widget.isFollowingTab
                                    ? Colors.white.withOpacity(0.18)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'For You',
                                style: TextStyle(
                                  color: !widget.isFollowingTab
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.75),
                                  fontSize: 14,
                                  fontWeight: !widget.isFollowingTab
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ---------------------------------------------------------
                    // 🔘 রিয়েল ফাংশন: ডান পাশের সবুজ "+ Post" পিল বাটন
                    // 👉 শুধু ভিডিও রিলস পোস্ট করার মোডাল ওপেন করবে
                    // ---------------------------------------------------------
                    GestureDetector(
                      onTap: _showReelVideoPostModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DB954),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 16),
                            SizedBox(width: 3),
                            Text(
                              'Post',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ---------------------------------------------------------
                // 🔘 রিয়েল ফাংশন: "+ Post" এর নিচে সাউন্ড/ভলিউম বাটন
                // 👉 চালু থাকলে মিক্স কালার ডিজাইন, বন্ধ হলে লাল ক্রস বাটন
                // ---------------------------------------------------------
                GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _isMuted
                          ? LinearGradient(
                              colors: [
                                Colors.redAccent.withOpacity(0.9),
                                const Color(0xFF990011).withOpacity(0.9),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [
                                Color(0xFF00FBFF), // ইলেকট্রিক সায়ান
                                Color(0xFFFF2E93), // ভাইব্রেন্ট পিংক-ভায়োলেট
                                Color(0xFFFFD700), // গোল্ডেন অ্যাকসেন্ট
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: _isMuted
                              ? Colors.redAccent.withOpacity(0.45)
                              : const Color(0xFF00FBFF).withOpacity(0.35),
                          blurRadius: 8,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isMuted
                            ? const Color(0xFF2A080C).withOpacity(0.92)
                            : const Color(0xFF141026).withOpacity(0.88),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            _isMuted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            color: _isMuted
                                ? const Color(0xFFFF4D4D)
                                : Colors.white,
                            size: 19,
                          ),
                          if (_isMuted)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF2B2B),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 8,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // =====================================================================
          // 🎯 [৫] নিচের অংশ: বামে শুধু নাম/ক্যাপশন/সাউন্ড এবং ডানে অ্যাকশন বাটনগুলো
          // =====================================================================
          Positioned(
            left: 14,
            right: 12,
            bottom: 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // -----------------------------------------------------------
                // 📌 বাম-নিচের অংশ: শুধু ইউজারের নাম + Caption + মিউজিক লাইন
                // (ছবি বাদ দেওয়া হয়েছে, হ্যাশট্যাগ ছাড়া, পুরাতন লজিক অক্ষত)
                // -----------------------------------------------------------
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ ইউজারের নাম (ছবি ছাড়া, রিয়েল-টাইম/ফলব্যাক নাম অক্ষত)
                        ReelUserInfo(
                          userId: widget.userId,
                          fallbackName: widget.userName,
                          fallbackImage: widget.userImage,
                          showAvatar: false,
                        ),
                        const SizedBox(height: 8),

                        // ✅ পুরাতন ক্যাপশন (অপরিবর্তিত, হ্যাশট্যাগ ছাড়া)
                        if (widget.caption.isNotEmpty)
                          Text(
                            widget.caption,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              height: 1.35,
                              shadows: [
                                Shadow(color: Colors.black87, blurRadius: 4),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                        const SizedBox(height: 8),

                        // 🔘 নতুন UI: নিচের মিউজিক / অরিজিনাল সাউন্ড লাইন
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.music_note_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Original Sound - ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            10.0, // 👈 শুধু "Original Sound - " লেখার সাইজ এখান থেকে কমান
                                        fontWeight: FontWeight.w400,
                                        shadows: [
                                          Shadow(
                                              color: Colors.black87,
                                              blurRadius: 4),
                                        ],
                                      ),
                                    ),
                                    TextSpan(
                                      text: widget.userName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            10.0, // 👈 ইউজারের নামের সাইজ আগের মতোই থাকবে
                                        fontWeight: FontWeight.w500,
                                        shadows: [
                                          Shadow(
                                              color: Colors.black87,
                                              blurRadius: 4),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // -----------------------------------------------------------
                // 📌 ডানপাশের ভার্টিক্যাল অ্যাকশন বার:
                // রিয়েল-টাইম প্রোফাইল+ফলো, লাইক, কমেন্ট, সেভ, শেয়ার, More, ঘূর্ণায়মান মিউজিক ডিস্ক
                // -----------------------------------------------------------
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔘 নতুন UI: ডানপাশে রিয়েল-টাইম প্রোফাইল ছবি ও নিচে "+" ফলো ব্যাজ
                    // 👉 পরে এখানে প্রোফাইল ওপেন বা ফলো করার রিয়েল লজিক বসাতে পারবেন
                    GestureDetector(
                      onTap: () {
                        // TODO: প্রোফাইল বা ফলো অ্যাকশন এখানে যুক্ত করুন
                      },
                      child: ReelPlusAvatar(
                        userId: widget.userId,
                        fallbackImage: widget.userImage,
                      ),
                    ),

                    const SizedBox(height: 5),

                    // ✅ পুরাতন লাইক বাটন ও লাইভ কাউন্ট (StreamBuilder + _toggleLike অক্ষত)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('stories')
                          .doc(widget.postId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        List liveLikes = widget.likes;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final docData =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          if (docData != null && docData['likes'] is List) {
                            liveLikes = docData['likes'];
                          }
                        }

                        final String currentUserId =
                            FirebaseAuth.instance.currentUser?.uid ?? '';
                        final bool isLiked = currentUserId.isNotEmpty &&
                            liveLikes.contains(currentUserId);

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _toggleLike(
                                  widget.postId, widget.userId, liveLikes),
                              icon: Icon(
                                isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isLiked
                                    ? const Color(0xFFFF2E93)
                                    : Colors.white,
                                size: 32,
                                shadows: const [
                                  Shadow(color: Colors.black54, blurRadius: 6),
                                ],
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${liveLikes.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 4),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 5),

                    // ✅ পুরাতন কমেন্ট বাটন (_showCommentSheet অক্ষত) + রিয়েল-টাইম কমেন্ট সংখ্যা
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showCommentSheet(
                          context, widget.postId, widget.userId),
                      icon: const Icon(
                        Icons.mode_comment_rounded,
                        color: Colors.white,
                        size: 30,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(height: 1),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('stories')
                          .doc(widget.postId.isNotEmpty
                              ? widget.postId
                              : widget.docId)
                          .collection('comments')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final int count =
                            snapshot.hasData ? snapshot.data!.docs.length : 0;
                        final String countText = count >= 1000
                            ? '${(count / 1000).toStringAsFixed(1)}K'
                            : count.toString();

                        return Text(
                          countText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 5),

                    // 🔘 নতুন UI: Save (বুকমার্ক) বাটন
                    // 👉 পরে এখানে পোস্ট সেভ/বুকমার্ক করার রিয়েল লজিক বসাতে পারবেন
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        // TODO: Save বাটনের রিয়েল ফাংশন এখানে যুক্ত করুন
                      },
                      icon: const Icon(
                        Icons.bookmark_border_rounded,
                        color: Colors.white,
                        size: 30,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),

                    // ✅ পুরাতন শেয়ার বাটন (অক্ষত)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {},
                      icon: const Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                        size: 30,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),

                    // 🔘 নতুন UI: More ("...") বাটন
                    // 👉 পরে এখানে রিপোর্ট/ডিলিট/অপশন মেনুর রিয়েল লজিক বসাতে পারবেন
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        // TODO: More বাটনের রিয়েল ফাংশন এখানে যুক্ত করুন
                      },
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.white,
                        size: 26,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),

                    // ---------------------------------------------------------
                    // 🔘 নতুন UI: থ্রি ডট ("...") এর নিচে ঘূর্ণায়মান মিউজিক ডিস্ক অ্যানিমেশন
                    // 👉 ভিডিও চললে ডিস্ক ঘুরবে, পজ হলে থেমে যাবে
                    // ---------------------------------------------------------
                    SpinningMusicDisc(
                      isSpinning:
                          _isInitialized && _isPlaying && widget.isActive,
                      userId: widget.userId,
                      fallbackImage: widget.userImage,
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

// 🔥 + বাটনসহ ডানপাশের প্রোফাইল পিকে রিয়েল-টাইম ছবি + প্রোফাইল ওপেন + ফলো/আনফলো লজিক
class ReelPlusAvatar extends StatefulWidget {
  final String userId;
  final String fallbackImage;

  const ReelPlusAvatar({
    super.key,
    required this.userId,
    required this.fallbackImage,
  });

  @override
  State<ReelPlusAvatar> createState() => _ReelPlusAvatarState();
}

class _ReelPlusAvatarState extends State<ReelPlusAvatar> {
  final FollowService _followService = FollowService();
  String _myResolvedUid = '';
  String _targetResolvedUid = '';
  bool _isFollowBusy = false;
  bool _isOpeningProfile = false;

  @override
  void initState() {
    super.initState();
    _resolveUids();
  }

  @override
  void didUpdateWidget(covariant ReelPlusAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _targetResolvedUid = '';
      _resolveUids();
    }
  }

  // authUID বা ছোট uID যাই হোক, users কালেকশন থেকে সঠিক uID বের করার হেল্পার
  Future<String> _resolveUserDocId(String rawId) async {
    if (rawId.trim().isEmpty) return '';
    final cleanId = rawId.trim();

    try {
      // ১. সরাসরি doc(cleanId) আছে কি না দেখা
      final directDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cleanId)
          .get();
      if (directDoc.exists) {
        return directDoc.data()?['uID']?.toString() ?? directDoc.id;
      }

      // ২. authUID দিয়ে users কালেকশন থেকে uID বের করা (পুরাতন লজিক অনুযায়ী)
      final byAuthQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: cleanId)
          .limit(1)
          .get();
      if (byAuthQuery.docs.isNotEmpty) {
        final doc = byAuthQuery.docs.first;
        return doc.data()['uID']?.toString() ?? doc.id;
      }

      // ৩. uID ফিল্ড দিয়ে সরাসরি ম্যাচ করা
      final byUidQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('uID', isEqualTo: cleanId)
          .limit(1)
          .get();
      if (byUidQuery.docs.isNotEmpty) {
        final doc = byUidQuery.docs.first;
        return doc.data()['uID']?.toString() ?? doc.id;
      }
    } catch (e) {
      debugPrint("❌ uID resolve করতে সমস্যা হয়েছে: $e");
    }

    return cleanId;
  }

  Future<void> _resolveUids() async {
    final currentAuthUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final resolvedMyUid = currentAuthUid.isNotEmpty
        ? await _resolveUserDocId(currentAuthUid)
        : '';
    final resolvedTargetUid = await _resolveUserDocId(widget.userId);

    if (!mounted) return;
    setState(() {
      _myResolvedUid = resolvedMyUid;
      _targetResolvedUid = resolvedTargetUid;
    });
  }

  // প্রোফাইল পিকে ক্লিক করলে ProfilePage-এ যাওয়ার পুরাতন লজিক
  Future<void> _openTargetProfile() async {
    if (_isOpeningProfile || widget.userId.isEmpty) return;
    setState(() => _isOpeningProfile = true);

    String finalIdToPass =
        _targetResolvedUid.isNotEmpty ? _targetResolvedUid : widget.userId;

    try {
      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: widget.userId)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        finalIdToPass = userQuery.docs.first.data()['uID']?.toString() ??
            userQuery.docs.first.id;
      } else {
        finalIdToPass = await _resolveUserDocId(widget.userId);
      }
    } catch (e) {
      debugPrint("❌ Users কালেকশন থেকে uID লোড করতে ব্যর্থ: $e");
    } finally {
      if (mounted) {
        setState(() => _isOpeningProfile = false);
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: finalIdToPass),
      ),
    );
  }

  // + অথবা টিকমার্ক বাটনে ক্লিক করলে ফলো/আনফলো টগল লজিক
  Future<void> _handleToggleFollow() async {
    if (_isFollowBusy) return;

    final String myUid = _myResolvedUid.isNotEmpty
        ? _myResolvedUid
        : await _resolveUserDocId(FirebaseAuth.instance.currentUser?.uid ?? '');
    final String targetUid = _targetResolvedUid.isNotEmpty
        ? _targetResolvedUid
        : await _resolveUserDocId(widget.userId);

    if (myUid.isEmpty || targetUid.isEmpty || myUid == targetUid) return;

    setState(() => _isFollowBusy = true);
    try {
      await _followService.toggleFollowUser(targetUid, myUid);
      if (mounted &&
          (_myResolvedUid != myUid || _targetResolvedUid != targetUid)) {
        setState(() {
          _myResolvedUid = myUid;
          _targetResolvedUid = targetUid;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isFollowBusy = false);
      }
    }
  }

  Widget _buildFollowBadge({
    required bool isFollowing,
    required bool showBadge,
  }) {
    if (!showBadge) return const SizedBox.shrink();

    return Positioned(
      bottom: 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleToggleFollow,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            // ফলো করা থাকলে সবুজ/রয়্যাল টিক ব্যাজ, না থাকলে আগের পিংক "+" ব্যাজ
            color:
                isFollowing ? const Color(0xFF1DB954) : const Color(0xFFFF2E93),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.2),
          ),
          child: _isFollowBusy
              ? const Padding(
                  padding: EdgeInsets.all(3.5),
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  isFollowing ? Icons.check : Icons.add,
                  color: Colors.white,
                  size: 12,
                ),
        ),
      ),
    );
  }

  Widget _buildAvatarBody({
    required String imageUrl,
    required bool isFollowing,
    required bool showBadge,
  }) {
    return SizedBox(
      width: 46,
      height: 54,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // প্রোফাইল ছবিতে ক্লিক করলে তার প্রোফাইলে যাবে
          GestureDetector(
            onTap: _openTargetProfile,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: ClipOval(
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.person, color: Colors.white),
                      )
                    : const Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),

          // নিচের "+" বা টিকমার্ক ফলো/আনফলো বাটন
          _buildFollowBadge(
            isFollowing: isFollowing,
            showBadge: showBadge,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String activeTargetUid =
        _targetResolvedUid.isNotEmpty ? _targetResolvedUid : widget.userId;

    if (widget.userId.isEmpty) {
      return _buildAvatarBody(
        imageUrl: widget.fallbackImage,
        isFollowing: false,
        showBadge: false,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(activeTargetUid)
          .snapshots(),
      builder: (context, userSnapshot) {
        String displayImage = widget.fallbackImage;
        String effectiveTargetUid = activeTargetUid;

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final rawData = userSnapshot.data!.data();
          if (rawData is Map<String, dynamic>) {
            displayImage = (rawData['profilePic'] ??
                    rawData['userImage'] ??
                    widget.fallbackImage)
                .toString();
            effectiveTargetUid =
                rawData['uID']?.toString().trim().isNotEmpty == true
                    ? rawData['uID'].toString().trim()
                    : userSnapshot.data!.id;
          } else {
            effectiveTargetUid = userSnapshot.data!.id;
          }
        }

        final bool canShowFollowBadge = _myResolvedUid.isNotEmpty &&
            effectiveTargetUid.isNotEmpty &&
            _myResolvedUid != effectiveTargetUid;

        if (!canShowFollowBadge) {
          return _buildAvatarBody(
            imageUrl: displayImage,
            isFollowing: false,
            showBadge: false,
          );
        }

        // followingList ডকুমেন্টের রিয়েল-টাইম স্ট্রিম: ফলো থাকলে টিকমার্ক স্থায়ী থাকবে যতক্ষণ না আনফলো করা হয়
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(_myResolvedUid)
              .collection('followingList')
              .doc(effectiveTargetUid)
              .snapshots(),
          builder: (context, followSnapshot) {
            final bool isFollowing = followSnapshot.hasData &&
                (followSnapshot.data?.exists ?? false);

            return _buildAvatarBody(
              imageUrl: displayImage,
              isFollowing: isFollowing,
              showBadge: true,
            );
          },
        );
      },
    );
  }
}

// 🔥 থ্রি ডট ("...") এর নিচে পুরাতন দিনের মিউজিক প্লেয়ারের মতো ঘূর্ণায়মান আইকন/ডিস্ক
class SpinningMusicDisc extends StatefulWidget {
  final bool isSpinning;
  final String userId;
  final String fallbackImage;

  const SpinningMusicDisc({
    super.key,
    required this.isSpinning,
    required this.userId,
    required this.fallbackImage,
  });

  @override
  State<SpinningMusicDisc> createState() => _SpinningMusicDiscState();
}

class _SpinningMusicDiscState extends State<SpinningMusicDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    if (widget.isSpinning) {
      _spinController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SpinningMusicDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !_spinController.isAnimating) {
      _spinController.repeat();
    } else if (!widget.isSpinning && _spinController.isAnimating) {
      _spinController.stop();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Widget _buildDiscVisual(String imageUrl) {
    return RotationTransition(
      turns: _spinController,
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF2B2B2B), Color(0xFF101010)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white24, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 6,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade900,
            image: imageUrl.isNotEmpty
                ? DecorationImage(
                    image: CachedNetworkImageProvider(imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageUrl.isEmpty
              ? const Icon(
                  Icons.music_note_rounded,
                  color: Colors.white,
                  size: 16,
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId.isEmpty) {
      return _buildDiscVisual(widget.fallbackImage);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        String displayImage = widget.fallbackImage;
        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>?;
          if (userData != null) {
            displayImage = userData['profilePic'] ??
                userData['userImage'] ??
                widget.fallbackImage;
          }
        }
        return _buildDiscVisual(displayImage);
      },
    );
  }
}

// 🔥 ইউজার ইনফো রিয়েল-টাইম দেখানোর উইজেট (showAvatar: false দিলে শুধু নাম দেখাবে)
class ReelUserInfo extends StatelessWidget {
  final String userId;
  final String fallbackName;
  final String fallbackImage;
  final bool showAvatar;

  const ReelUserInfo({
    super.key,
    required this.userId,
    required this.fallbackName,
    required this.fallbackImage,
    this.showAvatar = true,
  });

  Widget _buildNameRow(String displayName, String displayImage) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showAvatar) ...[
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
        ],
        Flexible(
          child: Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              shadows: [
                Shadow(color: Colors.black87, blurRadius: 4),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return _buildNameRow(fallbackName, fallbackImage);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        String displayName = fallbackName;
        String displayImage = fallbackImage;

        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>?;
          if (userData != null) {
            displayName =
                userData['name'] ?? userData['userName'] ?? fallbackName;
            displayImage = userData['profilePic'] ??
                userData['userImage'] ??
                fallbackImage;
          }
        }

        return _buildNameRow(displayName, displayImage);
      },
    );
  }
}
