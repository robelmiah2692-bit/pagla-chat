import 'dart:ui';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
// Firebase & Agora
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

// Third Party Packages
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import 'package:pagla_chat/room_list_page.dart' show RoomListPage;
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
  Offset bannerPosition = Offset(20, 120); // শুরুতে ব্যানারটি কোথায় থাকবে
  // Room States
  bool isRoomMuted = false;
  bool isCalculatorActive = false;
  String activityTheme = "";
  Map<String, dynamic> roomData = {};
  Map<String, int> roomScores = {};
  Map<int, String> activeEmojis = {};
  List<Offset> seatPositions = List.generate(15, (index) => Offset.zero);
  List<GlobalKey> seatKeys = List.generate(15, (index) => GlobalKey());

  String currentReceiverImage = "";
  String currentSenderImage = "";
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
  bool _isMeTalkingNow = false; // এটি লাল দাগ দূর করবে
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
    WakelockPlus.enable(); // স্ক্রিন যাতে অফ না হয়

    // ফলো স্ট্যাটাস চেক ফাংশন কল
    _checkIfFollowing();
    _fetchRoomData();
    _initEmojiListener();
    _addUserToViewers();

    // ১. ১৫টি সিটের ইনিশিয়ালাইজেশন
    seats = List.generate(
        15,
        (index) => {
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
        .onValue
        .listen((event) {
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
          Map<dynamic, dynamic> dataMap =
              (data is Map) ? data : (data as List).asMap();
          dataMap.forEach((key, value) {
            int? index = int.tryParse(key.toString());
            if (index != null && index < seats.length) {
              seats[index]["isOccupied"] = value["isOccupied"] ?? false;
              seats[index]["userName"] =
                  value["name"] ?? value["userName"] ?? "";
              seats[index]["userImage"] =
                  value["profilePic"] ?? value["userImage"] ?? "";
              seats[index]["isMicOn"] = value["isMicOn"] ?? false;
              seats[index]["userId"] =
                  value["authUID"] ?? value["userId"] ?? "";
              seats[index]["uID"] = value["uID"] ?? "";
              seats[index]["agorauID"] = value["agorauID"]?.toString() ?? "";
            }
          });
        }
      });
    });

    // ৩. এগোরা লজিক (সংশোধিত)
    // ৩. এগোরা লজিক (সংশোধিত - নাচানাচি বন্ধ করার জন্য)
    Future.microtask(() async {
      try {
        await _agoraManager.initAgora();
        final String authUID = FirebaseAuth.instance.currentUser?.uid ?? "";

        await _agoraManager.joinAsListener(widget.roomId, authUID);

        if (mounted) {
          _addUserToViewers();
        }

        final engine = _agoraManager.engine;
        if (engine != null) {
          await engine.enableAudioVolumeIndication(
              interval: 250, smooth: 3, reportVad: true);

          engine.registerEventHandler(
            RtcEngineEventHandler(
              onUserJoined: (connection, remoteuID, elapsed) {
                debugPrint("Remote user joined: $remoteuID");
              },
              onAudioVolumeIndication:
                  (connection, speakers, totalVolume, speakerNumber) {
                if (!mounted) return;

                bool isMeTalking = false;
                for (var speaker in speakers) {
                  // ভলিউম থ্রেশহোল্ড ১০ এর বদলে ১৫-২০ রাখা ভালো যাতে নয়েজে রি-বিল্ড না হয়
                  if (speaker.uid == 0 && (speaker.volume ?? 0) > 15) {
                    isMeTalking = true;
                    break;
                  }
                }

                // মূল সমাধান: অবস্থা পরিবর্তন (True/False) না হলে ফাংশন কল হবে না
                if (_isMeTalkingNow != isMeTalking) {
                  _isMeTalkingNow = isMeTalking;
                  _updateTalkingStatus(
                      isMeTalking); // এখন এটি কেবল একবারই কল হবে
                }
              },
            ),
          );
        }
      } catch (e) {
        debugPrint("Agora Error: $e");
      }
    });
  }

  // এই ফাংশনটি initState এর ক্লোজিং ব্র্যাকেটের নিচে বসাবেন
  Future<void> _checkIfFollowing() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // ইউজারের ডাটা পাথ অনুযায়ী uID খুঁজে বের করা
      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        String myuID = userQuery.docs.first.id; // আপনার ৬-ডিজিটের আইডি

        var roomDoc = await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .get();

        if (roomDoc.exists && mounted) {
          var data = roomDoc.data();
          List followersList = data?['followers'] ?? [];
          int countFromDb = data?['followerCount'] ?? 0;

          setState(() {
            // যদি লিস্টে আপনার আইডি থাকে তবে isFollowing true হবে
            isFollowing = followersList.contains(myuID);
            followerCount = countFromDb;
          });
        }
      }
    } catch (e) {
      print("Follow check error: $e");
    }
  }

  void _fetchRoomData() {
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        final rData = doc.data() as Map<String, dynamic>;

        // ১. ডাটাবেসের ডাটা এবং লোকাল ডাটা তুলনা করা
        // যদি ডাটা না বদলায়, তবে setState হবে না, ফলে কাঁপাকাঁপি বন্ধ হবে
        bool hasChanged = roomName != (rData['roomName'] ?? 'Love Line') ||
            roomProfileImage != (rData['roomImage'] ?? '') ||
            followerCount != (rData['followerCount'] ?? 0) ||
            ownerAuthId != (rData['ownerAuthId'] ?? "");

        if (hasChanged) {
          setState(() {
            roomData = rData;

            // ২. এডমিন লিস্ট লোড
            adminList = rData['admins'] ?? [];

            // ৩. রুমের সাধারণ তথ্য
            roomName = rData['roomName'] ?? 'Love Line';
            roomProfileImage = rData['roomImage'] ?? '';

            // ৪. ওনারের তথ্য
            ownerId =
                rData['ownerId']?.toString() ?? rData['uID']?.toString() ?? "";
            ownerName = rData['ownerName'] ?? 'Hridoy';
            ownerPic = rData['ownerPic'] ?? "";
            ownerAuthId = rData['ownerAuthId'] ?? "";

            // ৫. ওনার চেক (FirebaseAuth ID দিয়ে)
            isOwner = (ownerAuthId == FirebaseAuth.instance.currentUser?.uid);

            // ৬. ফলোয়ার সংখ্যা
            followerCount = rData['followerCount'] ?? 0;
          });
        }
      }
    });
  }

  void _initEmojiListener() {
    _emojiSubscription?.cancel();
    _emojiSubscription = FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/seats')
        .onChildChanged // এখানে onValue এর বদলে onChildChanged ঠিক আছে, তবে ডাটা পাঠানোর স্টাইল বদলাতে হবে
        .listen((event) {
      if (!mounted) return;

      final dynamic value = event.snapshot.value;
      final int index = int.tryParse(event.snapshot.key ?? "") ?? -1;

      // এখানে value["emojiTime"] থাকাটা বাধ্যতামূলক যাতে প্রতিবার ডাটা "Change" হয়
      if (index != -1 && value is Map && value["currentEmoji"] != null) {
        final int serverTime = value["emojiTime"] ?? 0;
        final int currentTime = DateTime.now().millisecondsSinceEpoch;

        // টাইম চেক (৫ সেকেন্ডের বেশি পুরনো হলে ইগনোর)
        if ((currentTime - serverTime).abs() > 5000) return;

        // --- সুপার ফাস্ট করার ট্রিক ---
        // যদি ওই সিটে আগে থেকেই ইমোজি থাকে, তবে সেটা সরিয়ে নতুনটা সাথে সাথে বসান
        if (activeEmojis.containsKey(index)) {
          activeEmojis.remove(index);
        }

        setState(() {
          activeEmojis[index] = value["currentEmoji"];
        });

        // ৩ সেকেন্ড পর রিমুভ (Timer ব্যবহার করা ভালো Future.delayed এর চেয়ে)
        Timer(const Duration(seconds: 3), () {
          if (mounted && activeEmojis[index] == value["currentEmoji"]) {
            setState(() => activeEmojis.remove(index));
          }
        });
      }
    });
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
    // ১. সরাসরি সিট থেকে ডাটা নিয়ে কপি তৈরি করা
    // এখানে list.where ব্যবহার করে শুধু যারা সিটে বসে আছে (isOccupied) তাদের নেওয়া ভালো
    List<Map<String, dynamic>> seatData = seats
        .where((s) => s != null && s['isOccupied'] == true)
        .map((s) => Map<String, dynamic>.from(s))
        .toList();

    // ২. সর্টিং (বেশি গিফট পাওয়া ইউজার উপরে থাকবে)
    seatData
        .sort((a, b) => (b['giftCount'] ?? 0).compareTo(a['giftCount'] ?? 0));

    List<Map<String, dynamic>> topWinners = [];

    for (var s in seatData) {
      // যারা অন্তত ১টি গিফট পেয়েছে তাদের উইনার লিস্টে নেওয়া
      if ((s['giftCount'] ?? 0) > 0) {
        topWinners.add({
          "name": s['name'] ?? s['userName'] ?? "User",
          // আপনার লিসেনার অনুযায়ী ছবি 'userImage' এ থাকে
          "avatar": s['userImage'] ?? s['profilePic'] ?? "",
          "gifts": s['giftCount']
        });
      }
      if (topWinners.length == 3)
        break; // টপ ৩ জন দেখালে সুন্দর লাগে, আপনি চাইলে ২ জনও রাখতে পারেন
    }

    // ৩. উইনার থাকলে পপআপ দেখানো
    if (topWinners.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: true, // বাইরে ক্লিক করলে যেন বন্ধ হয়
        builder: (context) => GiftRankDialog(winners: topWinners),
      );
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
          await FirebaseDatabase.instance
              .ref('rooms/${widget.roomId}/seats/$currentSeatIndex')
              .remove();
        }

        final seatRef = FirebaseDatabase.instance
            .ref('rooms/${widget.roomId}/seats/$index');
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
        content:
            const Text("Are you sure?", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("No")),
          TextButton(
              onPressed: () async {
                await _agoraManager.becomeListener();
                await FirebaseDatabase.instance
                    .ref('rooms/${widget.roomId}/seats/$index')
                    .remove();
                if (mounted) {
                  setState(() {
                    currentSeatIndex = -1;
                    isMicOn = false;
                  });
                  Navigator.pop(dialogContext);
                }
              },
              child:
                  const Text("Yes", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  // কথা বলার স্ট্যাটাস লোকালি সেভ রাখার জন্য
  bool _lastTalkingStatus = false;

  void updateSeatPosition(int index, GlobalKey key) {
    // ফ্রেম রেন্ডার হওয়ার পর পজিশন নেওয়ার জন্য এটি নিরাপদ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final RenderBox? renderBox =
            key.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          double centerX = position.dx + (size.width / 2);
          double centerY = position.dy + (size.height / 2);

          final RenderBox? roomBox = context.findRenderObject() as RenderBox?;
          if (roomBox != null) {
            Offset newPosition =
                roomBox.globalToLocal(Offset(centerX, centerY));

            // 🔥 টিপস: যদি পজিশন আগে থেকেই একই থাকে, তবে setState কল করার দরকার নেই
            if (seatPositions[index] != newPosition) {
              setState(() {
                seatPositions[index] = newPosition;
              });
            }
          }
        }
      } catch (e) {
        debugPrint("Position Update Error: $e");
      }
    });
  }

  void _updateTalkingStatus(bool talking) async {
    // ১. যদি স্ট্যাটাস আগের মতোই থাকে (উদা: কথা বলছেনই), তবে ডাটাবেসে পাঠানোর দরকার নেই
    if (talking == _lastTalkingStatus) return;

    if (currentSeatIndex != -1) {
      try {
        _lastTalkingStatus = talking; // লোকাল স্ট্যাটাস আপডেট

        final seatRef = FirebaseDatabase.instance
            .ref('rooms/${widget.roomId}/seats/$currentSeatIndex');

        // ২. শুধুমাত্র প্রয়োজনীয় ডাটা আপডেট
        await seatRef.update({
          'isTalking': talking,
        });
      } catch (e) {
        debugPrint("Talking Status Update Error: $e");
      }
    }
  }

  void _endPKBattle() {
    if (!mounted) return;
    String winner = blueTeamPoints > redTeamPoints ? "BLUE" : "RED";
    showDialog(
      context: context,
      builder: (context) => PKWinnerDialog(
          winnerTeam: winner,
          bluePoints: blueTeamPoints,
          redPoints: redTeamPoints),
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
                // ১. টাইমস্ট্যাম্প ঠিকভাবে নেওয়া
                int giftTime = 0;
                if (lastGift['timestamp'] is int) {
                  giftTime = lastGift['timestamp'];
                } else if (lastGift['timestamp'] is Timestamp) {
                  giftTime = (lastGift['timestamp'] as Timestamp)
                      .millisecondsSinceEpoch;
                }

                int now = DateTime.now().millisecondsSinceEpoch;

                // ২. যদি ৫ সেকেন্ডের মধ্যে নতুন গিফট আসে এবং বর্তমানে কোনো অ্যানিমেশন না চলে
                if (now - giftTime < 5000 && mounted && !isGiftAnimating) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        currentGiftImage =
                            lastGift['image'] ?? lastGift['icon'] ?? '';
                        currentSenderName = lastGift['senderName'] ?? 'Someone';
                        currentReceiverName = lastGift['target'] ?? '';
                        currentGiftCount = lastGift['count'] ?? 1;

                        // *** নতুন যোগ করা হয়েছে: আইডি থেকে পাঠানো ছবিগুলো রিসিভ করা ***
                        currentSenderImage = lastGift['senderImage'] ??
                            ''; // সেন্ডারের প্রোফাইল পিক
                        currentReceiverImage = lastGift['receiverImage'] ??
                            ''; // রিসিভারের প্রোফাইল পিক

                        isGiftAnimating = true;
                      });

                      // ৩. ৫ সেকেন্ড পর অ্যানিমেশন স্টেট বন্ধ করা
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
                        flex: 2,
                        child: RepaintBoundary(child: _buildSeatGridArea()),
                      ),

                      // মেসেজ এরিয়া
                      const SizedBox(height: 10),
                      Expanded(
                        flex: 1,
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
                                  String messageText =
                                      mData['message'] ?? mData['text'] ?? "";
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
                                      color: Colors.red,
                                      shape: BoxShape.circle),
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

// ভাসমান এবং মুভেবল ব্যানার
                if (roomData['showBanner'] ??
                    false) // যদি ফায়ারবেস থেকে ব্যানার অন থাকে
                  Positioned(
                    left: bannerPosition.dx,
                    top: bannerPosition.dy,
                    child: Draggable(
                      feedback: Opacity(
                        opacity: 0.8,
                        child:
                            _buildRoomBanner(roomData), // টানার সময় কেমন দেখাবে
                      ),
                      childWhenDragging:
                          Container(), // টানার সময় আগের জায়গা খালি থাকবে
                      onDragEnd: (details) {
                        setState(() {
                          // ড্র্যাগ শেষ হলে নতুন পজিশন সেট হবে
                          bannerPosition = details.offset;
                        });
                      },
                      child:
                          _buildRoomBanner(roomData), // সাধারণ অবস্থায় ব্যানার
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
                    senderImage: currentSenderImage,
                    receiverImage: currentReceiverImage,
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

  // ইমোজি মেথড (সিট পজিশন অনুযায়ী) - আপডেট করা
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

      // যদি পজিশন 0,0 হয় (মানে ডাটা এখনো আসেনি), তবে এটি রেন্ডার করবে না
      if (leftPos == 0 && topPos == 0) return const SizedBox();

      return Positioned(
        left: leftPos - 15,
        top: topPos - 50,
        child: IgnorePointer(
          child: SizedBox(
            width: 80,
            height: 80,
            child: Lottie.network(
              lottieUrl,
              // *** এই Key টি যোগ করার ফলে একই ইমোজি বারবার পাঠালেও সাথে সাথে প্লে হবে ***
              key: ValueKey(
                  '${seatIndex}_${DateTime.now().millisecondsSinceEpoch}'),
              repeat: false,
              animate: true, // নিশ্চিত করুন এটি ট্রু আছে
              fit: BoxFit.contain,
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
          color:
              Colors.black26, // ব্যাকগ্রাউন্ড একটু ডার্ক রাখলে আইকন ফুটে উঠবে
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
          isOccupied: false);

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
    bool isAdmin = false;
    // ১. ওনার শনাক্তকরণ (এটি ঠিক কাজ করছে বলছেন, তাও নিরাপদ করে দিলাম)
    bool isOwner = false;
    String currentMyAuthId = myAuthId.toString().trim();
    String currentMyuID = myFixeduID.toString().trim();

    if (currentMyAuthId.isNotEmpty &&
        ownerAuthId.toString() == currentMyAuthId) {
      isOwner = true;
    } else if (currentMyuID.isNotEmpty &&
        (currentMyuID == ownerId.toString() ||
            currentMyuID == uID.toString())) {
      isOwner = true;
    }

    // ২. অ্যাডমিন চেক (অ্যারো থেকে)
    isAdmin = adminList.any((id) => id.toString().trim() == currentMyuID);

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
                          content: Text(
                              "Only Owner & Admin can change room picture"),
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
                        UploadTask uploadTask =
                            storageRef.putFile(File(image.path));
                        TaskSnapshot snapshot = await uploadTask;
                        String downloadUrl =
                            await snapshot.ref.getDownloadURL();

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
                          ? const Icon(Icons.camera_alt,
                              size: 18, color: Colors.white70)
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
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Only Owner & Admin can change room name"),
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
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                title: const Text("Edit Room Name",
                                    style: TextStyle(color: Colors.white)),
                                content: TextField(
                                  controller: nameEditController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: "Enter new room name",
                                    hintStyle: TextStyle(color: Colors.white54),
                                    enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.amber)),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Cancel",
                                        style:
                                            TextStyle(color: Colors.white70)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      String newName =
                                          nameEditController.text.trim();
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
                                    child: const Text("Save",
                                        style: TextStyle(color: Colors.amber)),
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
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 10),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 1,
                            height: 8,
                            color: Colors.white24,
                          ),
                          const Icon(Icons.favorite,
                              size: 10, color: Colors.pinkAccent),
                          const SizedBox(width: 3),
                          Text(
                            "$followerCount Followers",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ১. ফলোয়ার বাটন ও সংখ্যা প্রদর্শন
                if (!isOwner)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isFollowing
                              ? Icons.check_circle
                              : Icons.person_add_alt_1,
                          color: isFollowing
                              ? Colors.greenAccent
                              : Colors.blueAccent,
                          size: 20,
                        ),
                        onPressed: () async {
                          final currentUser = FirebaseAuth.instance.currentUser;
                          if (currentUser == null) {
                            print("ইউজার লগইন করা নেই!");
                            return;
                          }

                          try {
                            // ১. ডাটাবেস থেকে বর্তমান ইউজারের আসল ৬-ডিজিটের uID খুঁজে বের করা
                            // আপনার প্রোফাইল কালেকশনের নাম 'users' এবং সেখানে 'authUID' ফিল্ডে FirebaseAuth-এর আইডি থাকে
                            var userQuery = await FirebaseFirestore.instance
                                .collection('users')
                                .where('authUID', isEqualTo: currentUser.uid)
                                .limit(1)
                                .get();

                            if (userQuery.docs.isEmpty) {
                              print(
                                  "Error: আপনার প্রোফাইলে কোনো ৬-ডিজিটের uID খুঁজে পাওয়া যায়নি!");
                              return;
                            }

                            // ২. নিশ্চিতভাবে আপনার ৬-ডিজিটের আইডিটি নেওয়া হলো
                            // এখানে documentID ই আপনার কাস্টম uID
                            String activeUserID = userQuery.docs.first.id;

                            // কনসোলে চেক করার জন্য প্রিন্ট (আপনি এটি দেখতে পারবেন)
                            print(
                                "ফলো বাটনে ক্লিক করা ইউজারের আসল আইডি: $activeUserID");

                            var roomRef = FirebaseFirestore.instance
                                .collection('rooms')
                                .doc(widget.roomId);

                            var roomDoc = await roomRef.get();
                            if (!roomDoc.exists) return;

                            var data = roomDoc.data();

                            // রুমের মালিকের আইডি (এটিও ৬-ডিজিটের হওয়া উচিত)
                            String owneruIDFromDb = data?['uID']?.toString() ??
                                data?['ownerId']?.toString() ??
                                "";
                            String currentOwnerName =
                                data?['ownerName'] ?? "Unknown";

                            // মালিক নিজে নিজেকে ফলো করতে পারবে না
                            if (activeUserID == owneruIDFromDb) {
                              print(
                                  "আপনি এই রুমের মালিক, তাই নিজেকে ফলো করতে পারবেন না।");
                              return;
                            }

                            if (isFollowing) {
                              // আনফলো লজিক - এখন নিশ্চিতভাবেই ৬-ডিজিটের আইডি রিমুভ হবে
                              await roomRef.update({
                                'followers':
                                    FieldValue.arrayRemove([activeUserID]),
                                'followerCount': FieldValue.increment(-1),
                              });

                              if (mounted) {
                                setState(() {
                                  isFollowing = false;
                                  followerCount--;
                                });
                              }
                            } else {
                              // ফলো লজিক - এখন নিশ্চিতভাবেই ৬-ডিজিটের আইডি অ্যাড হবে
                              await roomRef.update({
                                'followers':
                                    FieldValue.arrayUnion([activeUserID]),
                                'followerCount': FieldValue.increment(1),
                              });

                              if (mounted) {
                                setState(() {
                                  isFollowing = true;
                                  followerCount++;
                                });
                              }
                            }
                          } catch (e) {
                            print("Follow Error: $e");
                          }
                        },
                      ),
                      Text(
                        followerCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                // ২. ইউজার লিস্ট বাটন (এটি সবাই দেখবে)
                IconButton(
                  icon: const Icon(Icons.group,
                      color: Color.fromARGB(251, 39, 243, 21), size: 20),
                  onPressed: () async {
                    var roomDoc = await FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(widget.roomId)
                        .get();

                    if (!roomDoc.exists) return;

                    var data = roomDoc.data();
                    String owneruIDFromDb =
                        data?['uID'] ?? data?['ownerId'] ?? "";

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
                  icon: const Icon(Icons.settings,
                      color: Color.fromARGB(255, 132, 217, 251), size: 20),
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
  // --- ১. মেইন সিট গ্রিড এরিয়া (স্থায়ী ফিক্স) ---
  Widget _buildSeatGridArea() {
    return StreamBuilder<DatabaseEvent>(
      stream:
          FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats').onValue,
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
          // ✅ নিচের প্যাডিং ১০ থেকে বাড়িয়ে ৪৫ করা হয়েছে যাতে নাম/আইডি না কাটে
          padding:
              const EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 30),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio:
                0.75, // ✅ হাইট কিছুটা বাড়ানো হয়েছে নাম পরিষ্কার দেখার জন্য
            mainAxisSpacing: 10, // ✅ লাইনের মাঝের গ্যাপ বাড়ানো হয়েছে
            crossAxisSpacing: 5,
          ),
          itemCount: 15,
          itemBuilder: (context, index) {
            var seatData = dbSeats[index.toString()] ?? dbSeats[index];
            bool isOccupied =
                seatData != null ? (seatData['isOccupied'] == true) : false;

            String uName = isOccupied
                ? (seatData['name']?.toString() ??
                    seatData['userName']?.toString() ??
                    "User")
                : "";
            String uImage = isOccupied
                ? (seatData['profilePic']?.toString() ??
                    seatData['userImage']?.toString() ??
                    "")
                : "";
            String uIDShow =
                isOccupied ? (seatData['uID']?.toString() ?? "") : "";
            bool isTalking =
                isOccupied ? (seatData['isTalking'] == true) : false;
            bool isMicOn = isOccupied ? (seatData['isMicOn'] == true) : false;
            bool isVipSeat = index < 5;

            // ✅ কাপা বা হ্যাং হওয়া বন্ধের লজিক: ফ্রেম রেন্ডার হওয়ার পরে পজিশন আপডেট
            if (isOccupied && seatPositions[index] == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && seatKeys[index].currentContext != null) {
                  updateSeatPosition(index, seatKeys[index]);
                }
              });
            }

            return GestureDetector(
              key: seatKeys[index],
              onTap: () {
                bool isOwner =
                    (FirebaseAuth.instance.currentUser?.uid == ownerAuthId);
                if (!isOwner && isVipSeat && (userRole != "VIP")) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        "This is a VIP King Seat! Upgrade to VIP to sit here."),
                    backgroundColor: Colors.amber,
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }
                sitOnSeat(index);
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min, // ✅ কন্টেন্ট অনুযায়ী সাইজ হবে
                children: [
                  // ✅ RepaintBoundary যোগ করা হয়েছে যাতে VoiceRipple শুধু নিজের এরিয়া রেন্ডার করে
                  // এর ফলে ভিউয়ার লিস্ট বা পাশের উইজেটগুলো কাঁপবে না।
                  RepaintBoundary(
                    child: VoiceRipple(
                      isTalking: isTalking,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isVipSeat
                                    ? Colors.amber
                                    : (isOccupied
                                        ? Colors.cyanAccent
                                        : Colors.white10),
                                width: 1.8,
                              ),
                              boxShadow: isVipSeat
                                  ? [
                                      BoxShadow(
                                          color: Colors.amber.withOpacity(0.2),
                                          blurRadius: 8,
                                          spreadRadius: 1)
                                    ]
                                  : [],
                            ),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: isVipSeat
                                  ? Colors.amber.withOpacity(0.1)
                                  : Colors.black45,
                              backgroundImage: (isOccupied && uImage.isNotEmpty)
                                  ? NetworkImage(uImage)
                                  : null,
                              child: (isOccupied)
                                  ? (uImage.isEmpty
                                      ? const Icon(Icons.person,
                                          color: Colors.white24, size: 25)
                                      : null)
                                  : Icon(
                                      isVipSeat
                                          ? Icons.workspace_premium
                                          : Icons.chair_rounded,
                                      color: isVipSeat
                                          ? Colors.amber.withOpacity(0.6)
                                          : Colors.white12,
                                      size: 22),
                            ),
                          ),
                          if (isOccupied)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white24, width: 0.5)),
                                child: Icon(isMicOn ? Icons.mic : Icons.mic_off,
                                    color: isMicOn
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    size: 11),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 0),
                  // ✅ ইউজার নেম
                  Text(
                    isOccupied
                        ? uName
                        : (isVipSeat ? "King ${index + 1}" : "${index + 1}"),
                    style: TextStyle(
                      fontSize: 10,
                      color: isOccupied
                          ? Colors.white
                          : (isVipSeat ? Colors.amber : Colors.white38),
                      fontWeight: isOccupied || isVipSeat
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // ✅ ইউজার আইডি (এখন আর কাটবে না)
                  if (isOccupied && uIDShow.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        "ID: $uIDShow",
                        style: const TextStyle(
                            fontSize: 8,
                            color: Colors.white54,
                            letterSpacing: 0.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  // ১. অ্যাকশন বার (অন্য সকল ফিচার ঠিক রেখে আপডেট করা)
  Widget _buildBottomActionArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          // ১. ইমোজি বাটন 😄 (আপনার অরিজিনাল ৩ ও ৪ সেকেন্ডের টাইমার লজিক সহ)
          buildCircularIcon(Icons.emoji_emotions_outlined,
              const Color.fromARGB(255, 250, 143, 2), () async {
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
            int mySeatIndex = seats.indexWhere((s) =>
                s != null &&
                (s['uID'].toString() == myActualId ||
                    s['userId'].toString() == myActualId ||
                    s['uid'].toString() == myActualId));

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
                      DatabaseReference seatRef = FirebaseDatabase.instance
                          .ref('rooms/${widget.roomId}/seats/$index');

                      seatRef.update({
                        'currentEmoji': url,
                        'showEmoji': true,
                        'emojiTime': ServerValue.timestamp,
                      });

                      // ৩ সেকেন্ড পর লোকাল স্ক্রিন থেকে মুছে ফেলা
                      Future.delayed(const Duration(seconds: 3), () {
                        if (mounted)
                          setState(() {
                            seats[index]['showEmoji'] = false;
                          });
                      });

                      // ৪ সেকেন্ড পর ডাটাবেস থেকে শো অপশন বন্ধ করা
                      Future.delayed(const Duration(seconds: 4), () {
                        seatRef.update({'showEmoji': false});
                      });
                    }
                  });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Take seat first")));
            }
          }),

          const SizedBox(width: 8),

          // ২. আপনার চাওয়া নতুন ফিচার: সরাসরি মেসেজ ইনপুট এরিয়া বদলে শুধু ✉️ বাটন
          _buildCircularIcon(
              Icons.mail_outline, const Color.fromARGB(191, 246, 215, 19), () {
            // বাটনে ক্লিক করলে ইনপুট বক্সটি নিচ থেকে পপ-আপ হবে
            _showChatInputBottomSheet();
          }),

          const SizedBox(width: 8),

          // ৩. রুম মোড বাটন 🏩
          _buildCircularIcon(Icons.hotel, Colors.purpleAccent, () {
            
          }), // <--- এখানে একটা কমা বা সেমিকোলন নিশ্চিত করুন এবং ব্র্যাকেট খেয়াল করুন

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
              decoration: const BoxDecoration(
                  color: Colors.black45, shape: BoxShape.circle),
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
              try {
                HapticFeedback.lightImpact();
              } catch (_) {}
              bool newMicState = !isMicOn;
              try {
                if (_agoraManager.engine != null) {
                  await _agoraManager.toggleMic(!newMicState);
                }
                FirebaseDatabase.instance
                    .ref('rooms/${widget.roomId}/seats/$currentSeatIndex')
                    .update({'isMicOn': newMicState});
                if (mounted) {
                  setState(() {
                    isMicOn = newMicState;
                    if (!newMicState &&
                        currentSeatIndex >= 0 &&
                        currentSeatIndex < seats.length) {
                      seats[currentSeatIndex]["isTalking"] = false;
                    }
                  });
                }
              } catch (e) {
                debugPrint("Mic Toggle Error: $e");
              }
            },
          ),

          // ৬. মিউজিক বাটন
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            icon: Icon(Icons.music_note,
                color: isFloatingPlayerVisible
                    ? const Color.fromARGB(255, 164, 86, 243)
                    : const Color.fromARGB(255, 117, 225, 244),
                size: 22),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => MusicPlayerWidget(
                  onMusicSelect: (path) async {
                    setState(() {
                      currentMusicUrl = path;
                      isFloatingPlayerVisible = true;
                      isRoomMusicPlaying = true;
                    });
                    try {
                      await _agoraManager.engine.stopAudioMixing();
                      await _agoraManager.engine.startAudioMixing(
                          filePath: path, loopback: false, cycle: 1);
                      await _agoraManager.engine.adjustAudioMixingVolume(100);
                    } catch (e) {
                      debugPrint("Music Error: $e");
                    }
                  },
                  onVolumeChange: (volume) => _agoraManager.engine
                      .adjustAudioMixingVolume(volume.toInt()),
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
            icon: const Icon(Icons.videogame_asset,
                color: Colors.orange, size: 22),
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
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  final String authUID =
                      FirebaseAuth.instance.currentUser?.uid ?? "";

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
                    finalSenderId =
                        userQuery.docs.first.id; // এটা হবে শর্ট আইডি (৯৭৮০৫১)
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
            backgroundImage:
                senderImage.isNotEmpty ? NetworkImage(senderImage) : null,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                            fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        msg['text'] ?? "",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
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
        icon:
            const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 22),
        onPressed: () async {
          final String currentAuthUID =
              FirebaseAuth.instance.currentUser?.uid ?? "";
          if (currentAuthUID.isEmpty) return;

          // ১. নিজের তথ্য এবং ব্যালেন্স আনা (authUID দিয়ে কোয়েরি করে)
          var userQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('authUID', isEqualTo: currentAuthUID)
              .limit(1)
              .get();

          int currentBalance = 0;
          String senderName = "User";
          String senderImgUrl = "";
          String senderDocID = ""; // আপনার ডাটাবেজের '978051' টাইপ আইডি

          if (userQuery.docs.isNotEmpty) {
            final doc = userQuery.docs.first;
            final data = doc.data();
            senderDocID = doc.id; // ডকুমেন্টের নাম (যেমন: 978051)
            currentBalance = (data['diamonds'] ?? 0).toInt();
            senderName = data['name'] ?? data['userName'] ?? "User";
            senderImgUrl =
                data['profilePic'] ?? data['image'] ?? data['userImage'] ?? "";
            debugPrint("My Photo Found: $senderImgUrl");

            debugPrint("Balance Found: $currentBalance for ID: $senderDocID");
          } else {
            debugPrint(
                "User not found in Firestore for authUID: $currentAuthUID");
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
                String giftImg = gift['image'] ?? gift['icon'] ?? "";
                String receiverImgUrl = "";
                String receiverDocID = "";

                // ২. রিসিভারের আইডি এবং ছবি খোঁজা
                if (target == "All Room" || target == "All Mic") {
                  receiverDocID = target;
                } else {
                  // সিট থেকে রিসিভার খুঁজে বের করা
                  var targetSeat = seats.firstWhere(
                    (s) =>
                        s != null &&
                        (s['userName'] == target || s['name'] == target),
                    orElse: () => <String, dynamic>{},
                  );

                  if (targetSeat != null && targetSeat.isNotEmpty) {
                    receiverImgUrl = targetSeat['profilePic'] ??
                        targetSeat['userImage'] ??
                        "";
                    // রিসিভারের শর্ট আইডি (ডকুমেন্ট আইডি) নেওয়া হচ্ছে
                    receiverDocID =
                        (targetSeat['uID'] ?? targetSeat['userId'] ?? "")
                            .toString();
                  }
                }

                // ৩. ট্রানজেকশন শুরু
                try {
                  int unitPrice = (gift['price'] ?? 0).toInt();
                  int totalAmount = unitPrice * count;
                  bool isFree =
                      (gift['isFree'] == true) || (gift['expiry'] != null);

                  // ব্যালেন্স চেক
                  if (!isFree && currentBalance < totalAmount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              "পর্যাপ্ত ডায়মন্ড নেই! খরচ: $totalAmount, আছে: $currentBalance"),
                          backgroundColor: Colors.orange),
                    );
                    return;
                  }

                  if (senderDocID.isNotEmpty && receiverDocID.isNotEmpty) {
                    await GiftTransactionHelper.processGiftTransaction(
                      senderId: senderDocID, // শর্ট আইডি (978051)
                      receiverId: receiverDocID,
                      roomId: widget.roomId,
                      senderImage: senderImgUrl, // এখন আর লাল দাগ আসবে না
                      receiverImage: receiverImgUrl, // এখন আর লাল দাগ আসবে না
                      totalPrice: totalAmount,
                      isFree: isFree,
                      giftName: gift['name'] ?? "Gift",
                    );
                  } else {
                    debugPrint("Transaction Skipped: IDs are missing.");
                    return;
                  }
                } catch (e) {
                  debugPrint("Transaction Error: $e");
                  return;
                }

                // ৪. সফল হলে UI আপডেট
                if (mounted) {
                  setState(() {
                    currentGiftImage = giftImg;
                    isGiftAnimating = true;
                    targetType = target;
                    currentSenderName = senderName;
                    currentReceiverName = target;
                    currentSenderImage = senderImgUrl;
                    currentReceiverImage = receiverImgUrl;
                  });
                }

                // ৫. ফায়ারবেস রুম ব্যানার আপডেট
                await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(widget.roomId)
                    .update({
                  'last_gift': {
                    'image': giftImg,
                    'senderName': senderName,
                    'senderImage': senderImgUrl,
                    'target': target,
                    'receiverImage': receiverImgUrl,
                    'count': count,
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                  }
                });

                // ৬. এনিমেশন টাইমার (৫ সেকেন্ড)
                Timer(const Duration(seconds: 5), () {
                  if (mounted) setState(() => isGiftAnimating = false);
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
          const Icon(Icons.groups,
              color: Color.fromARGB(255, 11, 245, 3), size: 18),
          const SizedBox(width: 8),
          const Text(
            "Viewers:",
            style: TextStyle(
                color: Color.fromARGB(255, 157, 210, 246),
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Expanded(
            // 🔥 এই 'key' এবং 'const' নিশ্চিত করবে যে লিস্টটি নড়বে না
            child: LiveViewersList(
              key: PageStorageKey('live_viewers_${widget.roomId}'),
              roomId: widget.roomId,
            ),
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
              style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
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
          final roomDoc = await FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.roomId)
              .get();
          if (roomDoc.exists) {
            String? oldUrl = roomDoc.data()?['roomWallpaper'];
            // যদি আগে থেকেই কোনো ওয়ালপেপার থাকে এবং সেটি যদি ফায়ারবেস স্টোরেজের হয়
            if (oldUrl != null &&
                oldUrl.isNotEmpty &&
                oldUrl.contains('firebase')) {
              try {
                await FirebaseStorage.instance.refFromURL(oldUrl).delete();
                debugPrint("🗑️ পুরাতন ওয়ালপেপার ডিলিট হয়েছে");
              } catch (e) {
                debugPrint("Old wallpaper delete error: $e");
              }
            }
          }

          // ২. নতুন ফাইল আপলোড লজিক
          String fileName =
              'wallpapers/${widget.roomId}.jpg'; // ফাইলনেম ফিক্সড রাখলে রিপ্লেস হতে সুবিধা হয়
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
              .update({'roomWallpaper': downloadUrl, 'wallpaper': downloadUrl});

          setState(() {
            roomWallpaperPath = downloadUrl;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Wallpaper updated and old one deleted!")),
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

  Widget _buildRoomBanner(Map<String, dynamic> roomData) {
    String bannerUrl = roomData['bannerUrl'] ?? "";

    if (bannerUrl.isEmpty) return SizedBox.shrink();

    return Material(
      // টাচ কাজ করার জন্য মেটেরিয়াল দরকার
      color: Colors.transparent,
      child: Container(
        width: 150, // ভাসমান ব্যানারের জন্য ছোট সাইজ ভালো দেখায়
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(bannerUrl),
            fit: BoxFit.cover,
          ),
          border: Border.all(color: Colors.white24),
          boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4)],
        ),
      ),
    );
  }

  Widget _buildFloatingPlayer({required bool isDragging}) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String displayPic = "https://via.placeholder.com/150";
        String displayID = "000000";

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var userData =
              snapshot.data!.docs.first.data() as Map<String, dynamic>;
          displayPic = userData['profilePic'] ?? displayPic;
          displayID = userData['uID'] ?? displayID;
        }

        return Material(
          color: Colors.transparent,
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D1F).withOpacity(0.98),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 25,
                    spreadRadius: 5),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // টপ বার
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.music_note,
                        color: Colors.pinkAccent, size: 18),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isFloatingPlayerVisible = false;
                          isRoomMusicPlaying = false;
                        });
                        _agoraManager.engine.stopAudioMixing();
                      },
                      child: const Icon(Icons.close,
                          color: Colors.white38, size: 20),
                    ),
                  ],
                ),

                // প্রোফাইল ও এনিমেশন এরিয়া (ফিক্সড হাইট)
                SizedBox(
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isRoomMusicPlaying) ...[
                        const SmoothPulseEffect(),
                        const SmoothRotatingBorder(),
                        ...List.generate(
                            3, (index) => SmoothRotatingHeart(index: index)),
                      ],
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            displayPic,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person,
                                    color: Colors.white, size: 50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Text("ID: $displayID",
                    style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text("Now Playing...",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),

                const SizedBox(height: 15),

                // ভিজুয়ালাইজার এরিয়া (ফিক্সড হাইট ২৫)
                SizedBox(
                  height: 25,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                        25,
                        (index) => SmoothVisualizerBar(
                            index: index, isPlaying: isRoomMusicPlaying)),
                  ),
                ),

                const SizedBox(height: 25),

                // কন্ট্রোল এরিয়া - নেক্সট বাটন বাদে দুই পাশে লাইট ইফেক্ট
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // বাম পাশের লাইট ইফেক্ট
                    _buildSideLight(Colors.pinkAccent),

                    const SizedBox(width: 20),

                    // প্লে/পজ বাটন (লজিক আপডেট করা হয়েছে)
                    GestureDetector(
                      onTap: () async {
                        if (isRoomMusicPlaying) {
                          await _agoraManager.engine.pauseAudioMixing();
                        } else {
                          // যদি আগে কখনো স্টার্ট না হয়ে থাকে তবে স্টার্ট করবে, নয়তো রেজুউম করবে
                          await _agoraManager.engine.resumeAudioMixing();
                        }
                        setState(() {
                          isRoomMusicPlaying = !isRoomMusicPlaying;
                        });
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF0080), Color(0xFF00B2FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: (isRoomMusicPlaying
                                        ? Colors.pinkAccent
                                        : Colors.blueAccent)
                                    .withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: 2)
                          ],
                        ),
                        child: Icon(
                            isRoomMusicPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 35),
                      ),
                    ),

                    const SizedBox(width: 20),

                    // ডান পাশের লাইট ইফেক্ট
                    _buildSideLight(Colors.cyanAccent),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// দুই পাশের লাইট ইফেক্ট উইজেট
  Widget _buildSideLight(Color color) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.8),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
        color: color,
      ),
    );
  }

  void _addUserToViewers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final roomRef = firestore.collection('rooms').doc(widget.roomId);

      // চেক করুন ইউজার অলরেডি ভিউয়ার লিস্টে আছে কি না
      final viewerDoc = await roomRef.collection('viewers').doc(user.uid).get();
      if (viewerDoc.exists) return; // থাকলে আর অ্যাড করার দরকার নেই

      final userQuery = await firestore
          .collection('users')
          .where('authUID', isEqualTo: user.uid)
          .limit(1)
          .get();

      String myName = "Guest User";
      String myPic = "";
      String myShortID = "000000";

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        myName = userData['name'] ?? "Guest";
        myPic = userData['profilePic'] ?? userData['userImage'] ?? "";
        myShortID = userData['uID']?.toString() ?? "0";
      }

      // ডাটা পাঠানো
      await roomRef.collection('viewers').doc(user.uid).set({
        'authUID': user.uid,
        'uID': myShortID,
        'name': myName,
        'profilePic': myPic,
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // কাউন্ট বাড়ানো
      await roomRef.update({'viewerCount': FieldValue.increment(1)});
    } catch (e) {
      debugPrint("Viewer Add Error: $e");
    }
  }

  void _removeUserFromViewers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final roomRef =
          FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

      // ডিলিট করার আগে চেক
      final viewerDoc = await roomRef.collection('viewers').doc(user.uid).get();
      if (!viewerDoc.exists)
        return; // না থাকলে ডিলিট বা কাউন্ট কমানোর দরকার নেই

      await roomRef.collection('viewers').doc(user.uid).delete();

      // কাউন্ট কমানো (নিরাপদভাবে)
      final roomDoc = await roomRef.get();
      int currentCount = roomDoc.data()?['viewerCount'] ?? 0;

      if (currentCount > 0) {
        await roomRef.update({'viewerCount': FieldValue.increment(-1)});
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
          Text(theme,
              style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, thickness: 1),
          if (sortedEntries.isEmpty)
            const Text("No gifts yet",
                style: TextStyle(color: Colors.white54, fontSize: 10)),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedEntries.length > 5 ? 5 : sortedEntries.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text("${index + 1}",
                        style:
                            const TextStyle(color: Colors.amber, fontSize: 11)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(sortedEntries[index].key,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                            overflow: TextOverflow.ellipsis)),
                    Text("${sortedEntries[index].value} 💎",
                        style: const TextStyle(
                            color: Colors.cyanAccent, fontSize: 11)),
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

// এগুলো আপনার মেইন ক্লাসের একদম নিচে (সব ব্র্যাকেটের বাইরে) বসান

// এগুলো আপনার মেইন ক্লাসের একদম নিচে (সব ব্র্যাকেটের বাইরে) বসান

class SmoothPulseEffect extends StatefulWidget {
  const SmoothPulseEffect({super.key});
  @override
  State<SmoothPulseEffect> createState() => _SmoothPulseEffectState();
}

class _SmoothPulseEffectState extends State<SmoothPulseEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        width: 90 + (40 * _controller.value),
        height: 90 + (40 * _controller.value),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.pinkAccent.withOpacity(0.3 * (1 - _controller.value)),
        ),
      ),
    );
  }
}

class SmoothRotatingBorder extends StatefulWidget {
  const SmoothRotatingBorder({super.key});
  @override
  State<SmoothRotatingBorder> createState() => _SmoothRotatingBorderState();
}

class _SmoothRotatingBorderState extends State<SmoothRotatingBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..repeat();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 102,
        height: 102,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
        ),
      ),
    );
  }
}

class SmoothRotatingHeart extends StatefulWidget {
  final int index;
  const SmoothRotatingHeart({super.key, required this.index});
  @override
  State<SmoothRotatingHeart> createState() => _SmoothRotatingHeartState();
}

class _SmoothRotatingHeartState extends State<SmoothRotatingHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    _controller = AnimationController(
        vsync: this, duration: Duration(seconds: 3 + widget.index))
      ..repeat();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // math.cos এবং math.sin ব্যবহারের জন্য উপরে import 'dart:math' as math; থাকতে হবে
        double angle = (_controller.value * 2 * 3.14159) + (widget.index * 2.0);
        return Transform.translate(
          offset: Offset(60 * (math.cos(angle)), 60 * (math.sin(angle))),
          child: Icon(Icons.favorite,
              color:
                  widget.index % 2 == 0 ? Colors.pinkAccent : Colors.cyanAccent,
              size: 12),
        );
      },
    );
  }
}

class SmoothVisualizerBar extends StatefulWidget {
  final int index;
  final bool isPlaying;
  const SmoothVisualizerBar(
      {super.key, required this.index, required this.isPlaying});
  @override
  State<SmoothVisualizerBar> createState() => _SmoothVisualizerBarState();
}

class _SmoothVisualizerBarState extends State<SmoothVisualizerBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    _controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + (widget.index * 50)))
      ..repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double height = widget.isPlaying ? (5 + (_controller.value * 12)) : 3;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          width: 2.5,
          height: height,
          decoration: BoxDecoration(
            color:
                widget.index % 2 == 0 ? Colors.pinkAccent : Colors.cyanAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
