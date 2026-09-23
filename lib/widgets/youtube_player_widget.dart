import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YouTubePlayerManager {
  String? currentVideoUrl;
  bool isVideoPlaying = false;
  YoutubePlayerController? _youtubeController;
  WebViewController? _browserWebViewController;
  bool _isSyncingFromFirebase = false;

  void dispose() {
    currentVideoUrl = null;
    isVideoPlaying = false;
    _youtubeController?.close();
    _youtubeController = null;
    _browserWebViewController = null;
  }

  // সঠিক ইউটিউব আইডি এক্সট্রাক্ট করার ফাংশন
  String? _extractYouTubeVideoId(String url) {
    try {
      Uri uri = Uri.parse(url.trim());
      if (uri.host.contains('youtube.com')) {
        if (uri.pathSegments.contains('shorts')) {
          return uri.pathSegments.last;
        }
        return uri.queryParameters['v'];
      } else if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }
    } catch (e) {
      debugPrint("Error parsing YouTube ID: $e");
    }
    return null;
  }

  // ১. মূল ইউটিউব প্লেয়ার ইনিশিয়ালাইজ করা
  void initializeYouTubePlayer(
    String videoUrl, 
    double startSeconds, 
    bool shouldPlay, 
    Function setStateCallback, 
    String roomId
  ) {
    if (videoUrl.isEmpty) return;
    
    String? ytId = _extractYouTubeVideoId(videoUrl);
    if (ytId == null || ytId.isEmpty) return;

    // যদি একই ভিডিও অলরেডি রানিং থাকে, নতুন করে কন্ট্রোলার রিসেট করার দরকার নেই
    if (currentVideoUrl == videoUrl && _youtubeController != null) {
      if (shouldPlay) {
        _youtubeController?.playVideo();
      } else {
        _youtubeController?.pauseVideo();
      }
      return;
    }

    currentVideoUrl = videoUrl;

    if (_youtubeController != null) {
      _youtubeController?.loadVideoById(
        videoId: ytId,
        startSeconds: startSeconds,
      );
      if (!shouldPlay) {
        _youtubeController?.pauseVideo();
      } else {
        _youtubeController?.playVideo();
      }
    } else {
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: ytId,
        autoPlay: shouldPlay,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: false,
          strictRelatedVideos: true,
          playsInline: true,
          showVideoAnnotations: false,
          enableCaption: false,
          loop: false,
          color: 'dark',
        ),
      );

      if (startSeconds > 0) {
        _youtubeController?.seekTo(seconds: startSeconds);
      }

      // প্লেয়ার ইভেন্ট লিসেনার (অপ্রয়োজনীয় ফ্রিকোয়েন্সি কমানো হয়েছে)
      _youtubeController?.listen((event) {
        if (_isSyncingFromFirebase) return;

        if (event.playerState == PlayerState.playing || event.playerState == PlayerState.paused) {
          bool playing = (event.playerState == PlayerState.playing);
          _youtubeController?.currentTime.then((position) {
            // শুধুমাত্র স্টেট পরিবর্তনের সময় ফায়ারবেসে ডাটা আপডেট হবে, বারবার নয়
            FirebaseDatabase.instance.ref('rooms/$roomId/youtube').update({
              'isPlaying': playing,
              'position': position,
            });
          });
        }
      });
    }

    setStateCallback(() {
      isVideoPlaying = shouldPlay;
    });
  }

  // ২. অ্যাপের ভেতর ইউটিউব ব্রাউজ করার বটম শিট
  void showYouTubeSearchModal(BuildContext context, Function(String) onVideoSelected) {
    String selectedCapturedUrl = "";

    _browserWebViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36");

    if (_browserWebViewController!.platform is AndroidWebViewController) {
      (_browserWebViewController!.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _browserWebViewController!.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.contains('/watch?v=') || request.url.contains('/shorts/') || request.url.contains('youtu.be/')) {
            selectedCapturedUrl = request.url;
          }
          return NavigationDecision.navigate;
        },
        onUrlChange: (UrlChange change) {
          if (change.url != null && (change.url!.contains('/watch?v=') || change.url!.contains('/shorts/') || change.url!.contains('youtu.be/'))) {
            selectedCapturedUrl = change.url!;
          }
        },
      ),
    );

    _browserWebViewController!.loadRequest(Uri.parse("https://m.youtube.com"));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Watch video together",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: WebViewWidget(controller: _browserWebViewController!),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey[900],
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () async {
                        String? currentUrl;
                        try {
                          currentUrl = await _browserWebViewController?.runJavaScriptReturningResult('window.location.href;') as String?;
                          if (currentUrl != null) {
                            currentUrl = currentUrl.replaceAll('"', '');
                          }
                        } catch (e) {
                          debugPrint("JS Error: $e");
                        }

                        currentUrl ??= await _browserWebViewController?.currentUrl();
                        String finalUrl = selectedCapturedUrl;
                        
                        if (currentUrl != null && (currentUrl.contains('watch?v=') || currentUrl.contains('youtu.be') || currentUrl.contains('shorts'))) {
                          finalUrl = currentUrl;
                        }
                        
                        if (finalUrl.isNotEmpty && (finalUrl.contains('watch?v=') || finalUrl.contains('youtu.be') || finalUrl.contains('shorts'))) {
                          Navigator.pop(context);
                          onVideoSelected(finalUrl);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please open a specific video on YouTube first!")),
                          );
                        }
                      },
                      child: const Text(
                        "Play this video",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ৩. রুমের ইউআই প্লেয়ার উইজেট (অপ্টিমাইজড ও ফ্রিজ মুক্ত)
  Widget buildYouTubePlayerWidgetWithStream(
    BuildContext context, 
    Function setStateCallback, 
    Stream<DatabaseEvent> roomVideoStateStream, 
    String roomId,
    Function(String videoUrl) onVideoStateChangedFromStream
  ) {
    return StreamBuilder<DatabaseEvent>(
      stream: roomVideoStateStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
          try {
            var rawData = snapshot.data!.snapshot.value;
            String remoteVideoUrl = '';
            double remotePosition = 0.0;
            bool remoteIsPlaying = true;

            if (rawData is Map) {
              var youtubeMap = rawData['youtube'];
              if (youtubeMap is Map) {
                remoteVideoUrl = youtubeMap['videoUrl'] ?? '';
                remotePosition = (youtubeMap['position'] ?? 0).toDouble();
                remoteIsPlaying = youtubeMap['isPlaying'] ?? true;
              } else if (rawData['videoUrl'] != null) {
                remoteVideoUrl = rawData['videoUrl'];
              }
            }

            if (remoteVideoUrl.isNotEmpty) {
              if (remoteVideoUrl != currentVideoUrl || _youtubeController == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  initializeYouTubePlayer(remoteVideoUrl, remotePosition, remoteIsPlaying, setStateCallback, roomId);
                });
              } else {
                // অতিরিক্ত লুপ এড়াতে সিঙ্ক লজিক সিকিউর করা হয়েছে
                _isSyncingFromFirebase = true;
                _youtubeController?.currentTime.then((localPos) {
                  // ব্যবধান ৪ সেকেন্ডের বেশি হলে তবেই সিক করবে, ছোটখাটো পার্থক্যে ভিডিও আটকে রাখবে না
                  if ((localPos - remotePosition).abs() > 4.0) {
                    _youtubeController?.seekTo(seconds: remotePosition);
                  }
                  
                  if (remoteIsPlaying) {
                    _youtubeController?.playVideo();
                  } else {
                    _youtubeController?.pauseVideo();
                  }

                  Future.delayed(const Duration(milliseconds: 800), () {
                    _isSyncingFromFirebase = false;
                  });
                });
                
                if (isVideoPlaying != remoteIsPlaying) {
                  setStateCallback(() {
                    isVideoPlaying = remoteIsPlaying;
                  });
                }
              }
            }
          } catch (e) {
            debugPrint("Stream Error: $e");
          }
        }

        return Container(
          height: 170.0,
          width: double.infinity,
          color: Colors.black,
          child: Stack(
            children: [
              Center(
                child: (isVideoPlaying || _youtubeController != null) && currentVideoUrl != null && currentVideoUrl!.isNotEmpty
                    ? SizedBox(
                        width: double.infinity,
                        height: 170.0,
                        child: YoutubePlayer(
                          controller: _youtubeController!,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_circle_fill, size: 45, color: Colors.white),
                          const SizedBox(height: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              showYouTubeSearchModal(context, (selectedUrl) {
                                onVideoStateChangedFromStream(selectedUrl);
                                FirebaseDatabase.instance.ref('rooms/$roomId/youtube').set({
                                  'videoUrl': selectedUrl,
                                  'position': 0.0,
                                  'isPlaying': true,
                                });
                                initializeYouTubePlayer(selectedUrl, 0.0, true, setStateCallback, roomId);
                              });
                            },
                            child: const Text("Select the video", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}