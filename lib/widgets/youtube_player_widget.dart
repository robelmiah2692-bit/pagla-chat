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
  bool _isSyncingFromFirebase = false; // ইনফাইনাইট লুপ বা ওভারল্যাপ এড়ানোর জন্য

  void dispose() {
    print("DEBUG_PLAYER: dispose() called. Resetting player state.");
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
      print("Error parsing YouTube ID: $e");
    }
    return null;
  }

  // ১. মূল ইউটিউব প্লেয়ার ইনিশিয়ালাইজ করা (সময় এবং প্লে/পোজ স্টেট সহ)
  void initializeYouTubePlayer(
    String videoUrl, 
    double startSeconds, 
    bool shouldPlay, 
    Function setStateCallback, 
    String roomId
  ) {
    print("DEBUG_PLAYER: initializePlayer started with URL -> $videoUrl at $startSeconds sec, play: $shouldPlay");
    
    if (videoUrl.isNotEmpty) {
      String? ytId = _extractYouTubeVideoId(videoUrl);

      if (ytId != null && ytId.isNotEmpty) {
        currentVideoUrl = videoUrl;

        if (_youtubeController != null) {
          print("DEBUG_PLAYER: Loading new video into existing controller -> $ytId");
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
          print("DEBUG_PLAYER: Creating new YoutubePlayerController for -> $ytId");
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

          // যদি জিরো থেকে বেশি সেকেন্ডে শুরু করতে হয়
          if (startSeconds > 0) {
            _youtubeController?.seekTo(seconds: startSeconds);
          }

          // প্লেয়ারের নিজস্ব প্লে/পোজ বা সিক (Seek) ইভেন্ট ট্র্যাক করার জন্য লিসেনার
          _youtubeController?.listen((event) {
            if (_isSyncingFromFirebase) return; // যদি ফায়ারবেস থেকে আপডেট আসে, তবে ডাটাবেজে আবার পাঠাবো না

            // ইন্টারনেট বা বাফারিং সমস্যা কেটে যাওয়ার পর প্লে স্টেট রিকভার করার জন্য মনিটর করা
            if (event.playerState == PlayerState.playing) {
              bool playing = true;
              _youtubeController?.currentTime.then((position) {
                FirebaseDatabase.instance.ref('rooms/$roomId/youtube').update({
                  'isPlaying': playing,
                  'position': position,
                });
              });
            } else if (event.playerState == PlayerState.paused) {
              bool playing = false;
              _youtubeController?.currentTime.then((position) {
                FirebaseDatabase.instance.ref('rooms/$roomId/youtube').update({
                  'isPlaying': playing,
                  'position': position,
                });
              });
            }
          });
        }

        // UI রি-রেন্ডার করার জন্য স্টেট আপডেট নিশ্চিত করা হলো
        setStateCallback(() {
          isVideoPlaying = shouldPlay;
        });
      }
    }
  }

  // ২. অ্যাপের ভেতর ইউটিউব ব্রাউজ করে লিংক অটো তোলার জন্য বটম শিট
  void showYouTubeSearchModal(BuildContext context, Function(String) onVideoSelected) {
    print("DEBUG_MODAL: Opening YouTube Browse Modal...");
    
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
          print("DEBUG_NAV: Navigating to -> ${request.url}");
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
                          print("DEBUG_JS_ERROR: $e");
                        }

                        currentUrl ??= await _browserWebViewController?.currentUrl();
                        String finalUrl = selectedCapturedUrl;
                        
                        if (currentUrl != null && (currentUrl.contains('watch?v=') || currentUrl.contains('youtu.be') || currentUrl.contains('shorts'))) {
                          finalUrl = currentUrl;
                        }

                        print("DEBUG_BROWSER: Final Selected URL -> $finalUrl");
                        
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

  // ৩. রুমের ইউআই প্লেয়ার উইজেট (টাইম সিঙ্ক এবং পজ/প্লে হ্যান্ডলিং সহ)
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
              // যদি নতুন ভিডিও হয় অথবা প্রথমবার লোড হয়
              if (remoteVideoUrl != currentVideoUrl || _youtubeController == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  initializeYouTubePlayer(remoteVideoUrl, remotePosition, remoteIsPlaying, setStateCallback, roomId);
                });
              } else {
                // একই ভিডিও চলছে কিন্তু নেট ঠিক হওয়ার পর বা অন্য কারও অ্যাকশনের পর সিঙ্ক করার জন্য
                _isSyncingFromFirebase = true;
                _youtubeController?.currentTime.then((localPos) {
                  // যদি পজিশনের ব্যবধান ২ সেকেন্ডের বেশি হয় অথবা ইন্টারনেট রিডায়রেক্টে আটকে থাকে তবে সিঙ্ক ফোর্স করা হবে
                  if ((localPos - remotePosition).abs() > 2.0) {
                    _youtubeController?.seekTo(seconds: remotePosition);
                  }
                  if (remoteIsPlaying) {
                    _youtubeController?.playVideo();
                  } else {
                    _youtubeController?.pauseVideo();
                  }
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _isSyncingFromFirebase = false;
                  });
                });
                
                // প্লে স্টেট সিঙ্ক নিশ্চিত করতে
                if (isVideoPlaying != remoteIsPlaying) {
                  setStateCallback(() {
                    isVideoPlaying = remoteIsPlaying;
                  });
                }
              }
            }
          } catch (e) {
            print("DEBUG_STREAM_ERROR: $e");
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
                                // নতুন ভিডিও শুরু হলে পজিশন ০ এবং isPlaying true থাকবে
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