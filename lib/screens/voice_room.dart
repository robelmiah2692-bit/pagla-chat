import 'dart:ui';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

// Firebase & Agora
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

// Third Party Packages
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:image_picker/image_picker.dart';

// Your Project Files (Paths simplified, ensure they match your project)
import 'package:pagla_chat/widgets/user_profile_dialog.dart';
import 'package:pagla_chat/room_follower_sheet.dart';
import '../services/gift_transaction_helper.dart';
import 'package:pagla_chat/inbox_page.dart';
import 'package:pagla_chat/widgets/voice_ripple.dart';
import '../services/room_service.dart';
import 'package:pagla_chat/room_sync_service.dart';
import 'package:pagla_chat/services/database_service.dart';
import 'package:pagla_chat/services/soulmate_animation_service.dart';
import 'package:pagla_chat/services/agora_status_checker.dart';
import 'package:pagla_chat/services/seat_sync_service.dart';
import 'package:pagla_chat/widgets/live_viewers_list.dart';
import '../pk_battle_view.dart';
import '../pk_winner_dialog.dart';
import '../game_panel_view.dart';
import '../vs_pk_manager.dart';
import '../floating_room_tools.dart';
import '../gift_rank_dialog.dart';
import '../top_room_leaderboard.dart';
import '../personal_pk_view.dart';
import '../vs_pk_view.dart';
import '../live_notification_service.dart';
import 'package:pagla_chat/services/agora_manager.dart';
import '../widgets/emoji_handler.dart';
import '../widgets/gift_overlay_handler.dart';
import '../widgets/gift_system.dart';
import '../widgets/music_player_widget.dart';
import '../widgets/room_settings_handler.dart';

class VoiceRoom extends StatefulWidget {
  final String roomId;
  final String ownerId;

  const VoiceRoom({
    super.key,
    required this.roomId,
    this.ownerId = "",
  });

  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  // Services
  final RoomService _roomService = RoomService();
  final RoomSyncService _syncService = RoomSyncService();
  final DatabaseService _dbService = DatabaseService();
  final AgoraManager _agoraManager = AgoraManager();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _messageController = TextEditingController();

  // Room States
  bool isRoomMuted = false;
  bool isCalculatorActive = false;
  String activityTheme = "";
  Map<String, dynamic> roomData = {};
  Map<String, int> roomScores = {};
  Map<int, String> activeEmojis = {};
  List<Offset> seatPositions = List.generate(15, (index) => Offset.zero);
  List<GlobalKey> seatKeys = List.generate(15, (index) => GlobalKey());

  // User & Owner Info
  bool isGiftCounting = false;
  String uID = "";
  String ownerName = "";
  String userProfilePic = "";
  String ownerPic = "";
  String myFixeduID = "";
  String ownerAuthId = "";
  String ownerId = "";
  List<dynamic> adminList = [];
  String userRole = "Guest";
  String myPersonalAvatar = "";
  bool isOwner = false;
  String displayUserID = "Hridoy";
  String roomName = "পাগলা চ্যাট রুম";
  int followerCount = 0;
  String roomProfileImage = '';
  bool isFollowing = false;
  int activeEmojiSeatIndex = -1;
  bool isRoomLocked = false;
  String roomWallpaperPath = '';

  // PK Battle Info
  int blueTeamPoints = 0;
  int redTeamPoints = 0;
  bool isPKActive = false;
  late VSPKManager pkManager;
  int pkSeconds = 300;
  int currentGiftCount = 0;

  // Music Feature
  bool isMusicBarVisible = false;
  bool isFloatingPlayerVisible = false;
  String currentPlayingMusicName = "";
  List<Map<String, dynamic>> userAddedMusicList = [];
  bool isMusicLoading = false;
  String currentMusicUrl = "";
  Offset playerPosition = const Offset(150, 400);
  bool isRoomMusicPlaying = false;

  // Realtime States
  Map<String, dynamic> currentUserData = {};
  int currentSeatIndex = -1;
  bool isMicOn = false;
  List<Map<String, String>> chatMessages = [];
  bool isGiftAnimating = false;
  String currentGiftImage = "";
  late List<Map<String, dynamic>> seats;

  // Timer & Gift Logic
  bool isCountingGifts = false;
  int remainingSeconds = 900;
  Timer? giftTimer;
  String targetType = "";
  String currentSenderName = "";
  String currentReceiverName = "";

  StreamSubscription? _seatSubscription;
  StreamSubscription? _emojiSubscription;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // স্ক্রিন যাতে অফ না হয়

    // ১. ১৫টি সিটের ইনিশিয়ালাইজেশন
    seats = List.generate(15, (index) => {
      "isOccupied": false,
      "userName": "",
      "userImage": "",
      "isVip": index < 5,
      "status": "empty",
      "giftCount": 0,
      "isMicOn": false,
      "isTalking": false,
      "userId": "",
      "uID": "",
      "agorauID": "",
    });

    // ২. রিয়েলটাইম সিট লিসেনার
    _seatSubscription = FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/seats')
        .onValue.listen((event) {
      if (!mounted) return;
      final dynamic data = event.snapshot.value;

      setState(() {
        for (var seat in seats) {
          seat["isOccupied"] = false;
          seat["userName"] = "";
          seat["userImage"] = "";
          seat["uID"] = "";
          seat["userId"] = "";
        }

        if (data != null) {
          Map<dynamic, dynamic> dataMap = (data is Map) ? data : (data as List).asMap();
          dataMap.forEach((key, value) {
            int? index = int.tryParse(key.toString());
            if (index != null && index < seats.length) {
              seats[index]["isOccupied"] = value["isOccupied"] ?? false;
              seats[index]["userName"] = value["name"] ?? value["userName"] ?? "";
              seats[index]["userImage"] = value["profilePic"] ?? value["userImage"] ?? "";
              seats[index]["isMicOn"] = value["isMicOn"] ?? false;
              seats[index]["userId"] = value["authUID"] ?? value["userId"] ?? "";
              seats[index]["uID"] = value["uID"] ?? "";
              seats[index]["agorauID"] = value["agorauID"]?.toString() ?? "";
            }
          });
        }
      });
    });

    // ৩. এগোরা লজিক
    Future.microtask(() async {
      try {
        await _agoraManager.initAgora();
        final String authUID = FirebaseAuth.instance.currentUser?.uid ?? "";
        await _agoraManager.joinAsListener(widget.roomId, authUID);
        
        _addUserToViewers();

        final engine = _agoraManager.engine;
        if (engine != null) {
          await engine.enableAudioVolumeIndication(interval: 500, smooth: 3, reportVad: true);
          engine.registerEventHandler(
            RtcEngineEventHandler(
              onUserJoined: (connection, remoteuID, elapsed) {
                if (mounted) _addUserToViewers();
              },
              onAudioVolumeIndication: (connection, speakers, totalVolume, speakerNumber) {
                if (!mounted) return;
                bool hasChanged = false;
                List<String> currentTalkinguIDs = speakers
                    .where((s) => (s.volume ?? 0) > 10)
                    .map((s) => s.uid == 0 ? authUID : s.uid.toString())
                    .toList();

                for (var seat in seats) {
                  bool isUserTalkingNow = currentTalkinguIDs.contains(seat["userId"]) ||
                      currentTalkinguIDs.contains(seat["agorauID"]);
                  if (seat["isTalking"] != isUserTalkingNow) {
                    seat["isTalking"] = isUserTalkingNow;
                    hasChanged = true;
                  }
                }
                if (hasChanged) setState(() {});
              },
            ),
          );
        }
      } catch (e) {
        debugPrint("Agora Error: $e");
      }
    });

    _loadRoomAndUserData();
  }

  // ৪. ইমোজি লিসেনার
  void _initEmojiListener() {
    _emojiSubscription?.cancel();
    _emojiSubscription = FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/seats')
        .onChildChanged.listen((event) {
      if (!mounted) return;
      final dynamic value = event.snapshot.value;
      final int index = int.tryParse(event.snapshot.key ?? "") ?? -1;

      if (index != -1 && value is Map && value["currentEmoji"] != null) {
        setState(() => activeEmojis[index] = value["currentEmoji"]);
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => activeEmojis.remove(index));
        });
      }
    });
  }

  // ৫. রুম এবং ইউজার ডাটা লোড
  Future<void> _loadRoomAndUserData() async {
    try {
      final roomDoc = await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).get();
      if (roomDoc.exists && mounted) {
        final rData = roomDoc.data();
        setState(() {
          roomName = rData?['roomName'] ?? 'Love Line';
          roomProfileImage = rData?['roomImage'] ?? '';
          ownerId = rData?['ownerId']?.toString() ?? rData?['uID']?.toString() ?? "";
          ownerName = rData?['ownerName'] ?? 'Hridoy';
          ownerPic = rData?['ownerPic'] ?? "";
          ownerAuthId = rData?['ownerAuthId'] ?? "";
          isOwner = (ownerAuthId == FirebaseAuth.instance.currentUser?.uid);
        });
        _initEmojiListener();
        _addUserToViewers();
      }
    } catch (e) {
      debugPrint("Room Load Error: $e");
    }
  }


  // গিফট কাউন্টিং শুরু
  void _startGiftCounting(int minutes, String theme) {
    if (isGiftCounting) return;
    setState(() {
      isGiftCounting = true;
      activityTheme = theme;
      remainingSeconds = minutes * 60;
    });

    giftTimer?.cancel();
    giftTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        if (mounted) setState(() => remainingSeconds--);
      } else {
        timer.cancel();
        if (mounted) setState(() => isGiftCounting = false);
        _showWinnerPopup();
      }
    });
  }

  void _showWinnerPopup() {
    List<Map<String, dynamic>> seatData = List.from(seats);
    seatData.sort((a, b) => (b['giftCount'] ?? 0).compareTo(a['giftCount'] ?? 0));

    List<Map<String, dynamic>> topWinners = [];
    for (var s in seatData) {
      if (s != null && (s['giftCount'] ?? 0) > 0 && (s['isOccupied'] ?? false)) {
        topWinners.add({
          "name": s['userName'] ?? "User",
          "avatar": s['userImage'] ?? "",
          "gifts": s['giftCount']
        });
      }
      if (topWinners.length == 2) break;
    }

    if (topWinners.isNotEmpty) {
      showDialog(context: context, builder: (context) => GiftRankDialog(winners: topWinners));
    }
  }

  void sitOnSeat(int index) async {
    if (currentSeatIndex == index) {
      _showLeaveConfirmation(index);
      return;
    }
    if (seats[index]["isOccupied"] == true || isRoomLocked) return;

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (userSnap.docs.isNotEmpty) {
        final userData = userSnap.docs.first.data();
        await _agoraManager.becomeBroadcaster();
        final int myAgorauID = _agoraManager.localuID ?? 0;

        if (currentSeatIndex != -1) {
          await FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$currentSeatIndex').remove();
        }

        final seatRef = FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$index');
        await seatRef.set({
          'name': userData['name'] ?? "Hridoy",
          'profilePic': userData['profilePic'] ?? "",
          'uID': userData['uID'] ?? "",
          'authUID': currentUser.uid,
          'isOccupied': true,
          'isMicOn': true,
          'agorauID': myAgorauID,
          'status': 'occupied',
          'at': ServerValue.timestamp,
        });

        await seatRef.onDisconnect().remove();

        if (mounted) {
          setState(() {
            currentSeatIndex = index;
            isMicOn = true;
          });
          Future.delayed(const Duration(milliseconds: 300), () {
            updateSeatPosition(index, seatKeys[index]);
          });
        }
      }
    } catch (e) {
      debugPrint("Sit Error: $e");
    }
  }

  void _showLeaveConfirmation(int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Leave Seat", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure?", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("No")),
          TextButton(
              onPressed: () async {
                await _agoraManager.becomeListener();
                await FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$index').remove();
                if (mounted) {
                  setState(() {
                    currentSeatIndex = -1;
                    isMicOn = false;
                  });
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("Yes", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  void updateSeatPosition(int index, GlobalKey key) {
    try {
      final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        double centerX = position.dx + (size.width / 2);
        double centerY = position.dy + (size.height / 2);

        final RenderBox? roomBox = context.findRenderObject() as RenderBox?;
        if (roomBox != null) {
          setState(() {
            seatPositions[index] = roomBox.globalToLocal(Offset(centerX, centerY));
          });
        }
      }
    } catch (e) {
      debugPrint("Position Update Error: $e");
    }
  }

  void _endPKBattle() {
    if (!mounted) return;
    String winner = blueTeamPoints > redTeamPoints ? "BLUE" : "RED";
    showDialog(
      context: context,
      builder: (context) => PKWinnerDialog(
          winnerTeam: winner, bluePoints: blueTeamPoints, redPoints: redTeamPoints),
    );
    setState(() => isPKActive = false);
  }

@override
  Widget build(BuildContext context) {
    // কিবোর্ডের উচ্চতা মাপার জন্য
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1222),
      // কিবোর্ড আসার সময় রুম হ্যাং হওয়া কমাতে এটি true করা হয়েছে
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.roomId)
              .snapshots(),
          builder: (context, snapshot) {
            String? wallpaperUrl;
            Map<String, dynamic> roomData = {};

            if (snapshot.hasData && snapshot.data!.exists) {
              roomData = snapshot.data!.data() as Map<String, dynamic>;
              wallpaperUrl = roomData['currentWallpaper'];

              // গিফট অ্যানিমেশনের লজিক - লুপ বন্ধ করার জন্য কন্ডিশনাল হ্যান্ডলিং
              var lastGift = roomData['last_gift'];
              if (lastGift != null) {
                int giftTime = lastGift['timestamp'] ?? 0;
                int now = DateTime.now().millisecondsSinceEpoch;
                
                // যদি ৫ সেকেন্ডের মধ্যে নতুন গিফট আসে এবং বর্তমানে কোনো অ্যানিমেশন না চলে
                if (now - giftTime < 5000 && mounted && !isGiftAnimating) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        currentGiftImage = lastGift['image'] ?? '';
                        currentSenderName = lastGift['senderName'] ?? 'Someone';
                        targetType = lastGift['target'] ?? '';
                        currentGiftCount = lastGift['count'] ?? 1;
                        isGiftAnimating = true;
                      });
                      
                      // ৫ সেকেন্ড পর অ্যানিমেশন স্টেট বন্ধ করা
                      Timer(const Duration(seconds: 5), () {
                        if (mounted) {
                          setState(() {
                            isGiftAnimating = false;
                          });
                        }
                      });
                    }
                  });
                }
              }
            }

            return Stack(
              children: [
                // ১. ওয়ালপেপার (সবার নিচে) - RepaintBoundary ল্যাগ কমাবে
                Positioned.fill(
                  child: RepaintBoundary(
                    child: (wallpaperUrl != null && wallpaperUrl.isNotEmpty)
                        ? Image.network(
                            wallpaperUrl,
                            fit: BoxFit.cover,
                            color: Colors.black.withOpacity(0.2),
                            colorBlendMode: BlendMode.darken,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: const Color(0xFF0B1222)),
                          )
                        : Container(color: const Color(0xFF0B1222)),
                  ),
                ),

                // ২. মেইন UI (TopBar, Seats, Messages)
                SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildTopNavBar(),
                      if (isPKActive)
                        PKBattleView(
                          bluePoints: blueTeamPoints,
                          redPoints: redTeamPoints,
                          pkSeconds: pkSeconds,
                          pkManager: pkManager,
                        ),
                      _buildViewerArea(),

                      // সিট এরিয়া - ল্যাগ কমাতে RepaintBoundary ব্যবহার করা হয়েছে
                      Expanded(
                        child: RepaintBoundary(child: _buildSeatGridArea()),
                      ),

                      // মেসেজ এরিয়া
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 10, right: 90),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('rooms')
                                .doc(widget.roomId)
                                .collection('messages')
                                .orderBy('timestamp', descending: true)
                                .limit(25)
                                .snapshots(),
                            builder: (context, msgSnapshot) {
                              if (!msgSnapshot.hasData) return const SizedBox();
                              var docs = msgSnapshot.data!.docs;
                              return ListView.builder(
                                reverse: true,
                                padding: EdgeInsets.zero,
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  var mData = docs[index].data()
                                      as Map<String, dynamic>;
                                  String uName = mData['name'] ??
                                      mData['userName'] ??
                                      "User";
                                  String uImage = mData['profilePic'] ??
                                      mData['userImage'] ??
                                      "";
                                  String messageText = mData['message'] ??
                                      mData['text'] ??
                                      "";
                                  String uID = (mData['uID'] ??
                                          mData['senderId'] ??
                                          uName)
                                      .toString();

                                  return Align(
                                    alignment: Alignment.bottomLeft,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _messageController.text = "@$uID ";
                                          _messageController.selection =
                                              TextSelection.fromPosition(
                                            TextPosition(
                                                offset: _messageController
                                                    .text.length),
                                          );
                                        });
                                      },
                                      child: _buildMessageRow({
                                        'name': uName,
                                        'profilePic': uImage,
                                        'text': messageText,
                                      }),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      _buildBottomActionArea(),
                    ],
                  ),
                ),

                // ৩. মেইল বাটন ও ইনবক্স
                Positioned(
                  bottom: 110,
                  right: 15,
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(25)),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: const InboxPage(),
                          ),
                        ),
                      );
                    },
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .where('receiverId',
                              isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                          .where('isSeen', isEqualTo: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        int unreadCount =
                            (snapshot.hasData) ? snapshot.data!.docs.length : 0;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white24, width: 1),
                              ),
                              child: const Icon(Icons.mail,
                                  color: Colors.white, size: 24),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                      color: Colors.red, shape: BoxShape.circle),
                                  constraints: const BoxConstraints(
                                      minWidth: 16, minHeight: 16),
                                  child: Text('$unreadCount',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // ৪. মিউজিক প্লেয়ার
                if (isFloatingPlayerVisible)
                  Positioned(
                    left: playerPosition.dx,
                    top: playerPosition.dy,
                    child: Draggable(
                      feedback: _buildFloatingPlayer(isDragging: true),
                      childWhenDragging: Container(),
                      onDragEnd: (details) {
                        setState(() {
                          playerPosition = details.offset;
                        });
                      },
                      child: _buildFloatingPlayer(isDragging: false),
                    ),
                  ),

                // ৫. টুলস এবং ক্যালকুলেটর
                FloatingRoomTools(
                  onGiftCountStart: (minutes, theme) {
                    _startGiftCounting(minutes, theme);
                  },
                  seats: seats,
                ),
                if (isCalculatorActive)
                  Positioned(
                    right: 10,
                    top: 250,
                    child: GiftCalculatorRanking(roomData: roomData),
                  ),

                // ৬. গিফট এবং ইমোজি অ্যানিমেশন (সবার ওপরে)
                IgnorePointer(
                  child: GiftOverlayHandler(
                    isGiftAnimating: isGiftAnimating,
                    currentGiftImage: currentGiftImage,
                    isFullScreenBinding: isGiftAnimating,
                    senderName: currentSenderName,
                    receiverName: targetType,
                  ),
                ),
                ..._buildFloatingEmojiAnimations(),
              ],
            );
          },
        ),
      ),
    );
  }

  // ইমোজি মেথড (সিট পজিশন অনুযায়ী)
  List<Widget> _buildFloatingEmojiAnimations() {
    return activeEmojis.entries.map((entry) {
      int seatIndex = entry.key;
      String lottieUrl = entry.value;

      // পজিশন সেফটি চেক
      if (seatIndex < 0 || seatIndex >= seatPositions.length) {
        return const SizedBox();
      }

      // সিটের লোকেশন বের করা
      double leftPos = seatPositions[seatIndex].dx;
      double topPos = seatPositions[seatIndex].dy;

      // যদি পজিশন 0,0 হয় (মানে ডাটা এখনো আসেনি), তবে এটি রেন্ডার করবে না
      if (leftPos == 0 && topPos == 0) return const SizedBox();

      return Positioned(
        // সিটের পজিশন অনুযায়ী অ্যাডজাস্টমেন্ট
        left: leftPos - 15,
        top: topPos - 50, // সিটের ঠিক উপরে ভাসানোর জন্য -৫০ দিলাম
        child: IgnorePointer(
          child: SizedBox(
            width: 80,
            height: 80,
            child: Lottie.network(
              lottieUrl,
              repeat: false,
              // নেটওয়ার্ক এরর হ্যান্ডলিং
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
        ),
      );
    }).toList();
  }

// এই উইজেটটি আপনার আইকন বাটন তৈরি করবে
Widget buildCircularIcon(IconData icon, Color color, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(30),
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.black26, // ব্যাকগ্রাউন্ড একটু ডার্ক রাখলে আইকন ফুটে উঠবে
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Icon(icon, color: color, size: 22),
    ),
  );
}
 
 @override
 void dispose() {
   // ১. ভিউয়ার লিস্ট থেকে ব্যবহারকারীকে সরিয়ে ফেলা
   _removeUserFromViewers(); 

   // ২. স্ট্রীম এবং লুপ বন্ধ করা (সবচেয়ে জরুরি)
   _seatSubscription?.cancel();
   _emojiSubscription?.cancel();
   giftTimer?.cancel();

   // ৩. সিটে বসে থাকলে সেটি অটোমেটিক খালি করে দেওয়া
   if (currentSeatIndex != -1) {
     _roomService.updateSeatData(
       roomId: widget.roomId, 
       seatIndex: currentSeatIndex, 
       uName: "", 
       uImage: "", 
       isOccupied: false
     );
     
     // Firestore ডাটা আপডেট
     FirebaseFirestore.instance
         .collection('rooms')
         .doc(widget.roomId)
         .collection('seats')
         .doc(currentSeatIndex.toString())
         .update({
           'isOccupied': false,
           'userName': '',
           'userImage': '',
           'status': 'empty',
           'isMicOn': false,
         });
     
     // Realtime Database ক্লিনআপ
     FirebaseDatabase.instance
         .ref('rooms/${widget.roomId}/seats/$currentSeatIndex')
         .remove();
   }

   // ৪. কন্ট্রোলার এবং পিকে ম্যানেজার বন্ধ করা
   if (isPKActive) pkManager.stopPK(); 
   _audioPlayer.dispose();
   _messageController.dispose();
   
   // ৫. এগোরা ইঞ্জিন রিলিজ করা (Resource cleanup)
   try {
     _agoraManager.engine?.leaveChannel();
     _agoraManager.engine?.release();
   } catch (e) {
     debugPrint("Agora Dispose Error: $e");
   }

   super.dispose();
 }
  
Widget _buildTopNavBar() {
  final String myAuthId = FirebaseAuth.instance.currentUser?.uid ?? "";

  // ১. ওনার শনাক্তকরণের শক্তিশালী লজিক
  bool isOwner = false;
  if (myAuthId.isNotEmpty && ownerAuthId.toString() == myAuthId) {
    isOwner = true;
  } else if (myFixeduID.isNotEmpty &&
      (myFixeduID.toString() == ownerId.toString() ||
          myFixeduID.toString() == uID.toString())) {
    isOwner = true;
  }

  // ২. অ্যাডমিন চেক
  bool isAdmin = adminList.contains(myAuthId) || adminList.contains(myFixeduID);

  // পারমিশন স্ট্যাটাস
  bool hasPermission = isOwner || isAdmin;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              // 🖼️ রুমের প্রোফাইল পিকচার এডিট
              GestureDetector(
                onTap: () async {
                  if (!hasPermission) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Only Owner & Admin can change room picture"),
                        backgroundColor: Colors.redAccent));
                    return;
                  }

                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery, imageQuality: 50);

                  if (image != null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Uploading room profile..."),
                        backgroundColor: Colors.blueAccent));

                    try {
                      String fileName = 'room_profiles/${widget.roomId}.jpg';
                      Reference storageRef =
                          FirebaseStorage.instance.ref().child(fileName);
                      UploadTask uploadTask = storageRef.putFile(File(image.path));
                      TaskSnapshot snapshot = await uploadTask;
                      String downloadUrl = await snapshot.ref.getDownloadURL();

                      setState(() {
                        roomProfileImage = downloadUrl;
                      });

                      _roomService.updateRoomFullData(
                        roomId: widget.roomId,
                        roomName: roomName,
                        roomImage: downloadUrl,
                        isLocked: isRoomLocked,
                        wallpaper: roomWallpaperPath,
                        followers: followerCount,
                        totalDiamonds: 0,
                        uID: ownerId,
                        ownerName: ownerName,
                      );
                    } catch (e) {
                      debugPrint("Upload Error: $e");
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white12,
                    backgroundImage: roomProfileImage.isNotEmpty
                        ? NetworkImage(roomProfileImage)
                        : null,
                    child: roomProfileImage.isEmpty
                        ? const Icon(Icons.camera_alt, size: 18, color: Colors.white70)
                        : null,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // 🖋️ রুমের নাম, আইডি এবং ফলোয়ার
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (!hasPermission) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text("Only Owner & Admin can change room name"),
                              backgroundColor: Colors.redAccent));
                          return;
                        }

                        showDialog(
                          context: context,
                          builder: (context) {
                            TextEditingController nameEditController =
                                TextEditingController(text: roomName);
                            return AlertDialog(
                              backgroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              title: const Text("Edit Room Name", style: TextStyle(color: Colors.white)),
                              content: TextField(
                                controller: nameEditController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: "Enter new room name",
                                  hintStyle: TextStyle(color: Colors.white54),
                                  enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.amber)),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    String newName = nameEditController.text.trim();
                                    if (newName.isNotEmpty) {
                                      setState(() => roomName = newName);
                                      _roomService.updateRoomFullData(
                                        roomId: widget.roomId,
                                        roomName: newName,
                                        roomImage: roomProfileImage,
                                        isLocked: isRoomLocked,
                                        wallpaper: roomWallpaperPath,
                                        followers: followerCount,
                                        totalDiamonds: 0,
                                        uID: ownerId,
                                        ownerName: ownerName,
                                      );
                                    }
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Save", style: TextStyle(color: Colors.amber)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text(
                        roomName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          "ID: ${widget.roomId}",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.6), fontSize: 10),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 1,
                          height: 8,
                          color: Colors.white24,
                        ),
                        const Icon(Icons.favorite, size: 10, color: Colors.pinkAccent),
                        const SizedBox(width: 3),
                        Text(
                          "$followerCount Followers",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.6), fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ১. ফলোয়ার বাটন
              IconButton(
                icon: Icon(
                    isFollowing ? Icons.check_circle : Icons.person_add_alt_1,
                    color: isFollowing ? Colors.greenAccent : Colors.blueAccent,
                    size: 20),
                onPressed: () async {
                  if (uID.isEmpty) return;

                  var roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
                  var roomDoc = await roomRef.get();
                  if (!roomDoc.exists) return;
                  var data = roomDoc.data();

                  String owneruIDFromDb = data?['uID'] ?? data?['ownerId'] ?? "";
                  String currentOwnerName = data?['ownerName'] ?? "Unknown";

                  if (uID == owneruIDFromDb) return;

                  if (isFollowing) {
                    await roomRef.update({
                      'followers': FieldValue.arrayRemove([uID]),
                      'followerCount': FieldValue.increment(-1),
                    });
                    setState(() {
                      isFollowing = false;
                      followerCount--;
                    });
                  } else {
                    await roomRef.update({
                      'followers': FieldValue.arrayUnion([uID]),
                      'followerCount': FieldValue.increment(1),
                    });
                    setState(() {
                      isFollowing = true;
                      followerCount++;
                    });
                  }

                  _roomService.updateRoomFullData(
                    roomId: widget.roomId,
                    roomName: roomName,
                    roomImage: roomProfileImage,
                    isLocked: isRoomLocked,
                    wallpaper: roomWallpaperPath,
                    followers: followerCount,
                    totalDiamonds: 0,
                    uID: owneruIDFromDb,
                    ownerName: currentOwnerName,
                  );
                },
              ),

              // ২. ইউজার লিস্ট বাটন
              IconButton(
                icon: const Icon(Icons.group, color: Colors.white70, size: 20),
                onPressed: () async {
                  var roomDoc = await FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(widget.roomId)
                      .get();

                  if (!roomDoc.exists) return;

                  var data = roomDoc.data();
                  String owneruIDFromDb = data?['uID'] ?? data?['ownerId'] ?? "";

                  if (!context.mounted) return;

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => RoomFollowerSheet(
                      roomId: widget.roomId,
                      ownerId: owneruIDFromDb,
                    ),
                  );
                },
              ),

              // ৩. সেটিংস বাটন
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70, size: 20),
                onPressed: _showSettings,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
 // --- ১. মেইন সিট গ্রিড এরিয়া (সংশোধিত) ---
  Widget _buildSeatGridArea() {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats').onValue,
      builder: (context, snapshot) {
        Map<dynamic, dynamic> dbSeats = {};
        
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final dynamic value = snapshot.data!.snapshot.value;
          if (value is Map) {
            dbSeats = value;
          } else if (value is List) {
            dbSeats = value.asMap(); 
          }
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 5,
          ),
          itemCount: 15,
          itemBuilder: (context, index) {
            var seatData = dbSeats[index.toString()] ?? dbSeats[index];
            bool isOccupied = seatData != null ? (seatData['isOccupied'] == true) : false;
            
            // আপনার আগের সব ডাটা এক্সট্রাকশন ঠিক রাখা হয়েছে
            String uName = isOccupied ? (seatData['name']?.toString() ?? seatData['userName']?.toString() ?? "User") : ""; 
            String uImage = isOccupied ? (seatData['profilePic']?.toString() ?? seatData['userImage']?.toString() ?? "") : ""; 
            String uIDShow = isOccupied ? (seatData['uID']?.toString() ?? "") : ""; 
            bool isTalking = isOccupied ? (seatData['isTalking'] == true) : false;
            bool isMicOn = isOccupied ? (seatData['isMicOn'] == true) : false;
            bool isVipSeat = index < 5; 

            // ✅ হ্যাং হওয়া বন্ধ করার ফিক্স: পজিশন একবার থাকলে আর আপডেট হবে না
            if (isOccupied) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && seatKeys[index].currentContext != null) {
                  // seatPositions ম্যাপে ডাটা না থাকলেই শুধু আপডেট করবে
                  if (seatPositions[index] == null) {
                    updateSeatPosition(index, seatKeys[index]);
                  }
                }
              });
            }

            return GestureDetector(
              key: seatKeys[index],
              onTap: () {
                bool isOwner = (FirebaseAuth.instance.currentUser?.uid == ownerAuthId);
                if (!isOwner && isVipSeat && (userRole != "VIP")) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(
                       content: Text("This is a VIP King Seat! Upgrade to VIP to sit here."),
                       backgroundColor: Colors.amber,
                       behavior: SnackBarBehavior.floating,
                     )
                   );
                   return;
                }
                sitOnSeat(index);
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  VoiceRipple( 
                    isTalking: isTalking, 
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isVipSeat 
                                  ? Colors.amber 
                                  : (isOccupied ? Colors.cyanAccent : Colors.white10), 
                              width: 1.8,
                            ),
                            boxShadow: isVipSeat ? [
                              BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)
                            ] : [],
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: isVipSeat ? Colors.amber.withOpacity(0.1) : Colors.black45,
                            backgroundImage: (isOccupied && uImage.isNotEmpty) 
                                ? NetworkImage(uImage) 
                                : null,
                            child: (isOccupied) 
                                ? (uImage.isEmpty ? const Icon(Icons.person, color: Colors.white24, size: 25) : null) 
                                : Icon(isVipSeat ? Icons.workspace_premium : Icons.chair_rounded, 
                                    color: isVipSeat ? Colors.amber.withOpacity(0.6) : Colors.white12, 
                                    size: 22),
                          ),
                        ),
                        if (isOccupied)
                          Positioned(
                            bottom: 2, right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7), 
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24, width: 0.5)
                              ),
                              child: Icon(
                                isMicOn ? Icons.mic : Icons.mic_off, 
                                color: isMicOn ? Colors.greenAccent : Colors.redAccent, 
                                size: 11
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isOccupied ? uName : (isVipSeat ? "King ${index + 1}" : "${index + 1}"),
                    style: TextStyle(
                      fontSize: 10, 
                      color: isOccupied ? Colors.white : (isVipSeat ? Colors.amber : Colors.white38), 
                      fontWeight: isOccupied || isVipSeat ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isOccupied && uIDShow.isNotEmpty)
                    Text(
                      "ID: $uIDShow",
                      style: const TextStyle(fontSize: 8, color: Colors.white54, letterSpacing: 0.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  // ১. অ্যাকশন বার (অন্য সকল ফিচার ঠিক রেখে আপডেট করা)
Widget _buildBottomActionArea() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: Row(
      children: [
        // ১. ইমোজি বাটন 😄 (আপনার অরিজিনাল ৩ ও ৪ সেকেন্ডের টাইমার লজিক সহ)
        buildCircularIcon(Icons.emoji_emotions_outlined, Colors.orangeAccent, () async {
  // ১. সরাসরি লম্বা Auth UID না নিয়ে, আপনার ডাটাবেসের শর্ট uID টা খুঁজে বের করা
  // আপনি চাইলে গ্লোবাল কোনো ভ্যারিয়েবল থেকেও এটা নিতে পারেন যা লগইনের সময় সেভ করেছিলেন
  final String authId = FirebaseAuth.instance.currentUser?.uid ?? "";
  
  // সিটে বসা ইউজারকে খোঁজার জন্য সঠিক আইডি বের করা
  // যদি আপনার কাছে অলরেডি 'myShortId' থাকে তবে সরাসরি সেটা ব্যবহার করতে পারেন
  var userSnap = await FirebaseFirestore.instance
      .collection('users')
      .where('authUID', isEqualTo: authId)
      .limit(1)
      .get();

  if (userSnap.docs.isEmpty) return;
  
  String myActualId = userSnap.docs.first.id; // এটা হবে '৯৭৮০৫১'

  // ২. এখন সিটে চেক করুন এই আইডি দিয়ে
  int mySeatIndex = seats.indexWhere((s) => s != null && 
      (s['uID'].toString() == myActualId || s['userId'].toString() == myActualId || s['uid'].toString() == myActualId));

  if (mySeatIndex != -1) {
    EmojiHandler.showPicker(
      context: context, 
      seatIndex: mySeatIndex, 
      onEmojiSelected: (index, url) {
        if (index != -1 && url != null) {
          // ৩. লোকাল স্টেট আপডেট
          setState(() {
            seats[index]['showEmoji'] = true;
            seats[index]['currentEmoji'] = url;
          });

          // ৪. রিয়েলটাইম ডাটাবেস আপডেট
          DatabaseReference seatRef = FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$index');
          
          seatRef.update({
            'currentEmoji': url,
            'showEmoji': true,
            'emojiTime': ServerValue.timestamp,
          });

          // ৩ সেকেন্ড পর লোকাল স্ক্রিন থেকে মুছে ফেলা
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() { seats[index]['showEmoji'] = false; });
          });

          // ৪ সেকেন্ড পর ডাটাবেস থেকে শো অপশন বন্ধ করা
          Future.delayed(const Duration(seconds: 4), () {
            seatRef.update({ 'showEmoji': false });
          });
        }
      }
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Take seat first")));
  }
}),

        const SizedBox(width: 8),

        // ২. আপনার চাওয়া নতুন ফিচার: সরাসরি মেসেজ ইনপুট এরিয়া বদলে শুধু ✉️ বাটন
        _buildCircularIcon(Icons.mail_outline, Colors.white70, () {
          // বাটনে ক্লিক করলে ইনপুট বক্সটি নিচ থেকে পপ-আপ হবে
          _showChatInputBottomSheet(); 
        }),

        const SizedBox(width: 8),

        // ৩. রুম মোড বাটন 🏩 (অরিজিনাল ফিচার)
        _buildCircularIcon(Icons.hotel, Colors.purpleAccent, () {
          // আপনার রুম মোড পরিবর্তনের লজিক এখানে
        }),

        const SizedBox(width: 4),

        // ৪. রুম সাউন্ড বাটন
        GestureDetector(
          onTap: () {
            setState(() {
              isRoomMuted = !isRoomMuted;
              _agoraManager.muteAllRemoteAudio(isRoomMuted);
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
            child: Icon(
              isRoomMuted ? Icons.volume_off : Icons.volume_up,
              color: isRoomMuted ? Colors.redAccent : Colors.greenAccent,
              size: 20,
            ),
          ),
        ),

        const SizedBox(width: 4),

        // ৫. মাইক কন্ট্রোল বাটন
        IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          icon: Icon(
            isMicOn ? Icons.mic : Icons.mic_off,
            color: isMicOn ? Colors.greenAccent : Colors.redAccent,
            size: 22,
          ),
          onPressed: () async {
            if (currentSeatIndex == -1) return;
            try { HapticFeedback.lightImpact(); } catch (_) {}
            bool newMicState = !isMicOn;
            try {
              if (_agoraManager.engine != null) { await _agoraManager.toggleMic(!newMicState); }
              FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$currentSeatIndex').update({'isMicOn': newMicState});
              if (mounted) {
                setState(() {
                  isMicOn = newMicState;
                  if (!newMicState && currentSeatIndex >= 0 && currentSeatIndex < seats.length) {
                    seats[currentSeatIndex]["isTalking"] = false;
                  }
                });
              }
            } catch (e) { debugPrint("Mic Toggle Error: $e"); }
          },
        ),

        // ৬. মিউজিক বাটন
        IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          icon: Icon(Icons.music_note, color: isFloatingPlayerVisible ? Colors.blueAccent : Colors.white70, size: 22),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => MusicPlayerWidget(
                onMusicSelect: (path) async {
                  setState(() { currentMusicUrl = path; isFloatingPlayerVisible = true; isRoomMusicPlaying = true; });
                  try {
                    await _agoraManager.engine.stopAudioMixing();
                    await _agoraManager.engine.startAudioMixing(filePath: path, loopback: false, cycle: 1);
                    await _agoraManager.engine.adjustAudioMixingVolume(100);
                  } catch (e) { debugPrint("Music Error: $e"); }
                },
                onVolumeChange: (volume) => _agoraManager.engine.adjustAudioMixingVolume(volume.toInt()),
              ),
            );
          },
        ),

        // ৭. এনিমেটেড গিফট বাটন 🎁 (নড়াচড়া করার ফিচার সহ)
        _buildAnimatedGiftButton(),

        // ৮. গেম বাটন 🎮
        IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          icon: const Icon(Icons.videogame_asset, color: Colors.orange, size: 22),
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: false,
            backgroundColor: Colors.transparent,
            builder: (c) => SizedBox(
              height: MediaQuery.of(context).size.height,
              child: GamePanelView(roomId: widget.roomId),
            ),
          ),
        ),
      ],
    ),
  );
}

// ২. আপনার মেসেজ ইনপুট এরিয়া ফিক্স (ব্র্যাকেট এবং লজিক সব ঠিক করা হয়েছে)
void _showChatInputBottomSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Say something...",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.pinkAccent),
              onPressed: () async {
                String msgText = _messageController.text.trim();
                if (msgText.isEmpty) return;

                // ১. লম্বা Auth UID নেওয়া হলো
                final String authUID = FirebaseAuth.instance.currentUser?.uid ?? "";
                
                // ২. সঠিক রাস্তায় ডাটা খোঁজা (authUID ফিল্ড ব্যবহার করে)
                var userQuery = await FirebaseFirestore.instance
                    .collection('users')
                    .where('authUID', isEqualTo: authUID)
                    .limit(1)
                    .get();

                String finalName = "User";
                String finalImage = "";
                String finalSenderId = authUID; // ডিফল্ট

                if (userQuery.docs.isNotEmpty) {
                  var uData = userQuery.docs.first.data();
                  // আপনার ডাটাবেস অনুযায়ী সঠিক ফিল্ড ম্যাপ করা
                  finalName = uData['name'] ?? "User";
                  finalImage = uData['profilePic'] ?? ""; 
                  finalSenderId = userQuery.docs.first.id; // এটা হবে শর্ট আইডি (৯৭৮০৫১)
                }

                // ৩. মেসেজ পাঠানোর লজিক
                await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(widget.roomId)
                    .collection('messages')
                    .add({
                  'userName': finalName,
                  'profilePic': finalImage,
                  'text': msgText,
                  'senderId': finalSenderId, // শর্ট আইডিটি সেভ হবে
                  'timestamp': FieldValue.serverTimestamp(),
                });
                
                _messageController.clear();
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildMessageRow(Map<String, dynamic> msg) {
  // আপনার দেওয়া ফিল্ড নেম অনুযায়ী ডাটা নেওয়া
  String senderName = msg['name'] ?? "User";
  String senderImage = msg['profilePic'] ?? "";
  
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🖼️ প্রোফাইল পিকচার (গ্যালারি থেকে সেভ করা ছবি এখানে দেখাবে)
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.white10,
          backgroundImage: senderImage.isNotEmpty ? NetworkImage(senderImage) : null,
          child: senderImage.isEmpty 
              ? const Icon(Icons.person, size: 16, color: Colors.white24) 
              : null,
        ),
        const SizedBox(width: 6),

        // ✉️ গ্লাস মেসেজ ফ্রেম
        Flexible(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senderName, // শুধু name দেখাচ্ছে
                      style: const TextStyle(
                        color: Colors.amber, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 10
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      msg['text'] ?? "",
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}  
// ৩. গিফট বাটনের এনিমেশন লজিক (অপরিবর্তিত)
Widget _buildAnimatedGiftButton() {
  return TweenAnimationBuilder(
    tween: Tween<double>(begin: 1.0, end: 1.2),
    duration: const Duration(milliseconds: 800),
    curve: Curves.easeInOut,
    builder: (context, double scale, child) {
      return Transform.scale(scale: scale, child: child);
    },
    child: IconButton(
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      icon: const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 22),
      onPressed: () async {
        // ১. লম্বা Auth UID নেওয়া হলো
        final String authUID = FirebaseAuth.instance.currentUser?.uid ?? "";

        // ২. সরাসরি .doc(uid) না করে .where('authUID') দিয়ে সঠিক ইউজার খোঁজা
        var userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('authUID', isEqualTo: authUID)
            .limit(1)
            .get();

        int currentBalance = 0;
        String senderName = "User";
        String senderActualId = authUID; // ডিফল্ট

        if (userQuery.docs.isNotEmpty) {
          final data = userQuery.docs.first.data();
          currentBalance = data['diamonds'] ?? 0;
          senderName = data['name'] ?? data['userName'] ?? "User";
          senderActualId = userQuery.docs.first.id; // আপনার শর্ট আইডি (৯৭৮০৫১)
        }

        if (!mounted) return;

        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => GiftBottomSheet(
            diamondBalance: currentBalance,
            currentSeats: List.from(seats),
            onGiftSend: (gift, count, target) async {
              setState(() {
                currentGiftImage = gift['icon'];
                isGiftAnimating = true;
                targetType = target;
                currentSenderName = senderName;
                currentReceiverName = target;
              });

              try {
                // ৩. গিফট অ্যানিমেশন সেভ (রুম কালেকশনে)
                await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(widget.roomId)
                    .collection('gift_animations')
                    .add({
                  'giftIcon': gift['icon'],
                  'senderName': senderName,
                  'receiverName': target,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                bool isFree = gift['isFree'] ?? false;
                int unitPrice = gift['price'] ?? 0;
                int totalAmount = unitPrice * count;

                // ৪. টার্গেট ইউজার (রিসিভার) এর আইডি খুঁজে বের করা
                var targetSeat = seats.firstWhere(
                  (s) => s != null && (s['userName'] == target || s['name'] == target),
                  orElse: () => <String, dynamic>{},
                );

                String receiverId = "";
                if (targetSeat.isNotEmpty) {
                  receiverId = (targetSeat['uID'] ?? targetSeat['uid'] ?? "").toString();
                }

                if (receiverId.isNotEmpty) {
                  // ৫. গিফট ট্রানজেকশন হেল্পার (এখানেও শর্ট আইডি পাঠানো হচ্ছে)
                  await GiftTransactionHelper.processGiftTransaction(
                    senderId: senderActualId, // ৯৭৮০৫১
                    receiverId: receiverId,   // টার্গেট ইউজার আইডি
                    roomId: widget.roomId,
                    totalPrice: totalAmount,
                    isFree: isFree,
                    giftName: gift['name'] ?? "Gift",
                  );

                  if (isGiftCounting) {
                    await FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(widget.roomId)
                        .collection('gift_counts')
                        .add({
                      'senderName': senderName,
                      'receiverName': target,
                      'points': totalAmount,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                  }
                }
              } catch (e) {
                debugPrint("Transaction Error: $e");
              }

              Timer(const Duration(seconds: 5), () {
                if (mounted) setState(() { isGiftAnimating = false; });
              });
            },
          ),
        );
      },
    ),
  );
}
// হেল্পার বাটন ফাংশন
Widget _buildCircularIcon(IconData icon, Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(icon, color: color, size: 22),
    ),
  );
}
  
  Widget _buildViewerArea() { 
    return Container(
      height: 50, 
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups, color: Colors.white54, size: 18),
          const SizedBox(width: 8),
          const Text(
            "Viewers:", 
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LiveViewersList(roomId: widget.roomId), 
          ),
        ],
      ),
    ); 
  }

  Widget buildMessageRow(Map<String, String> msg) { 
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), 
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "${msg['userName'] ?? 'User'}: ", 
              style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            TextSpan(
              text: "${msg['text'] ?? ''}", 
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    ); 
  }

 void _showSettings() {
    RoomSettingsHandler.showSettings(
      context: context,
      roomId: widget.roomId, // বিল্ড এরর ফিক্সের জন্য এটি দরকার
      isLocked: isRoomLocked,
      onToggleLock: () async {
        setState(() => isRoomLocked = !isRoomLocked);
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .update({'isLocked': isRoomLocked});
      },
      onSetWallpaper: (path) async {
        if (path.isEmpty) return;
        try {
          setState(() => roomWallpaperPath = path);

          // ১. পুরাতন ওয়ালপেপার ডিলিট করার লজিক
          final roomDoc = await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).get();
          if (roomDoc.exists) {
            String? oldUrl = roomDoc.data()?['roomWallpaper'];
            // যদি আগে থেকেই কোনো ওয়ালপেপার থাকে এবং সেটি যদি ফায়ারবেস স্টোরেজের হয়
            if (oldUrl != null && oldUrl.isNotEmpty && oldUrl.contains('firebase')) {
              try {
                await FirebaseStorage.instance.refFromURL(oldUrl).delete();
                debugPrint("🗑️ পুরাতন ওয়ালপেপার ডিলিট হয়েছে");
              } catch (e) {
                debugPrint("Old wallpaper delete error: $e");
              }
            }
          }

          // ২. নতুন ফাইল আপলোড লজিক
          String fileName = 'wallpapers/${widget.roomId}.jpg'; // ফাইলনেম ফিক্সড রাখলে রিপ্লেস হতে সুবিধা হয়
          var storageRef = FirebaseStorage.instance.ref().child(fileName);

          final XFile imageFile = XFile(path);
          final bytes = await imageFile.readAsBytes();
          
          UploadTask uploadTask = storageRef.putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );

          var snapshot = await uploadTask;
          String downloadUrl = await snapshot.ref.getDownloadURL();

          // ৩. ডাটাবেস আপডেট
          await FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.roomId)
              .update({
                'roomWallpaper': downloadUrl,
                'wallpaper': downloadUrl
              });

          setState(() {
            roomWallpaperPath = downloadUrl;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Wallpaper updated and old one deleted!")),
            );
          }
        } catch (e) {
          debugPrint("Wallpaper Error: $e");
        }
      },
      onMinimize: () => Navigator.pop(context),
      onClearChat: () async {
        try {
          final chatDocs = await FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.roomId)
              .collection('messages') 
              .get();

          for (var ds in chatDocs.docs) {
            await ds.reference.delete();
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Chat cleared successfully!")),
            );
          }
        } catch (e) {
          debugPrint("Error clearing chat: $e");
        }
      },
      onLeave: () {
        _agoraManager.engine.leaveChannel();
        Navigator.pop(context);
      },
    );
  }
  
  Widget _buildFloatingPlayer({required bool isDragging}) {
  return Material(
    color: Colors.transparent,
    child: Stack(
      alignment: Alignment.center,
      children: [
        // মূল প্লেয়ার বডি
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.cyanAccent, width: 2.5),
            boxShadow: [
              if (!isDragging) 
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.4), 
                  blurRadius: 15,
                )
            ],
          ),
          child: Center(
            child: IconButton(
              icon: Icon(
                isRoomMusicPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: Colors.white,
                size: 45,
              ),
              onPressed: () async {
                try {
                  if (isRoomMusicPlaying) {
                    // ✅ আগোরার মিউজিক পজ করা (সবার জন্য থামবে)
                    await _agoraManager.engine.pauseAudioMixing();
                  } else {
                    // ✅ আগোরার মিউজিক রিজুম করা (সবার জন্য চলবে)
                    await _agoraManager.engine.resumeAudioMixing();
                  }
                  
                  setState(() {
                    isRoomMusicPlaying = !isRoomMusicPlaying;
                  });
                } catch (e) {
                  debugPrint("Play/Pause Error: $e");
                }
              },
            ),
          ),
        ),
        
        // ক্রস বাটন (প্লেয়ার বন্ধ করা)
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              try {
                // ✅ আগোরার মিউজিক পুরোপুরি স্টপ করা
                await _agoraManager.engine.stopAudioMixing();
              } catch (e) {
                debugPrint("Stop Error: $e");
              }
              
              setState(() {
                isFloatingPlayerVisible = false;
                isRoomMusicPlaying = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    ),
  );
}

  void _addUserToViewers() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    
    // চেক করা হচ্ছে ইউজার অলরেডি ভিউয়ার লিস্টে আছে কি না (কাউন্ট ঠিক রাখার জন্য)
    final viewerDoc = await roomRef.collection('viewers').doc(user.uid).get();
    bool isAlreadyViewer = viewerDoc.exists;

    // ১. ইউজার প্রোফাইল ডাটা সংগ্রহ (users কালেকশন থেকে)
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    
    if (userDoc.exists) {
      final userData = userDoc.data();
      final String myName = userData?['name'] ?? userData?['userName'] ?? 'Guest';
      final String myImage = userData?['profilePic'] ?? userData?['userImage'] ?? '';
      final String mySixDigitId = userData?['uID'] ?? user.uid;

      // ২. ভিউয়ার লিস্টে ইউজারকে এড করা (merge: true ব্যবহার করা হয়েছে যাতে ছবি না হারায়)
      await roomRef.collection('viewers').doc(user.uid).set({
        'uID': mySixDigitId,
        'name': myName,
        'userName': myName,
        'profilePic': myImage,
        'userImage': myImage,
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ৩. ভিউয়ার কাউন্ট আপডেট (যদি সে আগে থেকে লিস্টে না থাকে তবেই ১ বাড়বে)
      if (!isAlreadyViewer) {
        await roomRef.update({
          'viewerCount': FieldValue.increment(1)
        });
      }
    }
  } catch (e) {
    debugPrint("Viewer Add Error: $e");
  }
}

void _removeUserFromViewers() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    
    // ইউজার যদি লিস্টে থাকে তবেই ডিলিট এবং কাউন্ট কমানো হবে
    final viewerDoc = await roomRef.collection('viewers').doc(user.uid).get();
    
    if (viewerDoc.exists) {
      // ১. ভিউয়ার লিস্ট থেকে ইউজারকে মুছে ফেলা
      await roomRef.collection('viewers').doc(user.uid).delete();

      // ২. ভিউয়ার কাউন্ট ১ কমানো
      await roomRef.update({
        'viewerCount': FieldValue.increment(-1)
      });
    }
  } catch (e) {
    debugPrint("Viewer Remove Error: $e");
  }
}
}

class GiftCalculatorRanking extends StatelessWidget {
  final Map<String, dynamic> roomData;
  const GiftCalculatorRanking({super.key, required this.roomData});

  @override
  Widget build(BuildContext context) {
    // ডাটা থেকে ক্যালকুলেটর স্কোর এবং থিম বের করা
    Map<String, dynamic> scores = roomData['calcScores'] ?? {};
    String theme = roomData['theme'] ?? "GIFT COUNT";
    
    // স্কোর অনুযায়ী সর্টিং (বেশি থেকে কম)
    var sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6), // গ্লাস ইফেক্ট
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(theme, style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, thickness: 1),
          if (sortedEntries.isEmpty)
            const Text("No gifts yet", style: TextStyle(color: Colors.white54, fontSize: 10)),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedEntries.length > 5 ? 5 : sortedEntries.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text("${index + 1}", style: const TextStyle(color: Colors.amber, fontSize: 11)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(sortedEntries[index].key, style: const TextStyle(color: Colors.white, fontSize: 11), overflow: TextOverflow.ellipsis)),
                    Text("${sortedEntries[index].value} 💎", style: const TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
