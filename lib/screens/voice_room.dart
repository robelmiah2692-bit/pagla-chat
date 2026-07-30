import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
// Firebase & Agora
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

// Third Party Packages
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:lottie/lottie.dart';
import 'package:pagla_chat/RoomLevelHelper.dart';

import 'package:pagla_chat/VideoGiftOverlay.dart';
import 'package:pagla_chat/chat_screen.dart';
import 'package:pagla_chat/ludo_game/dice_model.dart';
import 'package:pagla_chat/ludo_game/game_state.dart';
import 'package:pagla_chat/ludo_game/gameplay.dart';
import 'package:pagla_chat/ludo_game/position.dart';
import 'package:pagla_chat/ludo_game/token.dart';
import 'package:pagla_chat/ludo_helper.dart';
import 'package:pagla_chat/ludo_lobby_popup.dart';

import 'package:pagla_chat/pk_manager.dart';
import 'package:pagla_chat/protected_users.dart';
import 'package:pagla_chat/room_exit_handler.dart';
import 'package:pagla_chat/room_manager.dart';
import 'package:pagla_chat/services/floating_bubble_service.dart';
import 'package:pagla_chat/services/floating_music_player.dart';
import 'package:pagla_chat/services/gift_logic_helper.dart';
import 'package:pagla_chat/services/gift_service.dart';
import 'package:pagla_chat/services/marriage_service.dart';
import 'package:pagla_chat/services/room_active_manager.dart';
import 'package:pagla_chat/services/soulmate_xp_service.dart';

import 'package:pagla_chat/widgets/entry_effect_handler.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:image_picker/image_picker.dart';

// Your Project Files (Paths simplified, ensure they match your project)
import 'package:pagla_chat/room_follower_sheet.dart';
import 'package:pagla_chat/inbox_page.dart';
import 'package:pagla_chat/widgets/voice_ripple.dart';
import '../services/room_service.dart';
import 'package:pagla_chat/room_sync_service.dart';
import 'package:pagla_chat/services/database_service.dart';
import 'package:pagla_chat/services/soulmate_animation_service.dart';
import 'package:pagla_chat/widgets/live_viewers_list.dart';
import '../pk_battle_view.dart';
import '../pk_winner_dialog.dart';
import '../game_panel_view.dart';
import '../vs_pk_manager.dart';
import '../floating_room_tools.dart';
import '../gift_rank_dialog.dart';
import 'package:pagla_chat/services/agora_manager.dart';
import '../widgets/emoji_handler.dart';
import '../widgets/gift_overlay_handler.dart';
import '../widgets/gift_system.dart';
import '../widgets/music_player_widget.dart';
import '../widgets/room_settings_handler.dart';

// আপনার ফাইলের লোকেশন অনুযায়ী পাথটি চেক করুন
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

class _VoiceRoomState extends State<VoiceRoom>
    with SingleTickerProviderStateMixin {
  // Services
  final RoomActiveManager _activeManager = RoomActiveManager();
  final RoomService _roomService = RoomService();
  final RoomSyncService _syncService = RoomSyncService();
  final DatabaseService _dbService = DatabaseService();
  final AgoraManager _agoraManager = AgoraManager();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _messageController = TextEditingController();
  Offset bannerPosition = Offset(20, 120); // শুরুতে ব্যানারটি কোথায় থাকবে
// VoiceRoomState ক্লাসের শুরুতে এটি যোগ করুন
  List<Token> gameTokens = List.generate(
      16,
      (index) =>
          Token(TokenType.green, Position(0, 0), TokenState.initial, index));
  bool showLudoLobby = false; // পপ-আপ দেখানোর জন্য শুধু এই একটি ভেরিয়েবল
  int currentBet = 2; // রুম মালিকের ডাইমন্ড কন্ট্রোলের জন্য
  // এগুলো স্টেট ক্লাসের শুরুতে রাখুন
  List<Map<String, dynamic>> gameJoinedUsers = [];
  bool isGameStarted = false;
  // Room States
  bool isRoomMuted = false;
  bool isCalculatorActive = false;
  String activityTheme = "";
  Map<String, dynamic> roomData = {};
  Map<String, int> roomScores = {};
  Map<int, String> activeEmojis = {};
  Offset pkBannerOffset = const Offset(20, 150);
  Map<String, int> scores =
      {}; // এই লাইনটি ক্লাসের একদম উপরে অন্যান্য ভেরিয়েবলের সাথে লিখুন
  List<Offset> seatPositions = List.generate(15, (index) => Offset.zero);
  List<GlobalKey> seatKeys = List.generate(15, (index) => GlobalKey());
  bool isAdmin = false; // এটি যোগ করুন
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
  String roomName = "paglachat_room";
  int followerCount = 0;
  String roomProfileImage = '';
  bool isFollowing = false;
  int activeEmojiSeatIndex = -1;
  bool isRoomLocked = false;
  String roomWallpaperPath = '';
  String? entryUserName;
  String? entryUserImage;
  String? currentEntryEffect;
  bool showEntryEffect = false;
  String? entryUserFrame; // 🔥 ফ্রেমের জন্য এই নতুন লাইনটি যোগ করুন
  // PK Battle Info
  int blueTeamPoints = 0;
  int redTeamPoints = 0;
  bool isPKActive = false; // পিকে চলছে কি না
  bool _lastPKStatus = false;
  Map<String, dynamic>? currentPKData; // পিকের ডাটা
  int pkDuration = 0;
  late VSPKManager pkManager;
  int pkSeconds = 300;
  int currentGiftCount = 0;
  String myuID = "";
  // Music Feature
  bool isMusicBarVisible = false;
  bool isFloatingPlayerVisible = false;
  String currentPlayingMusicName = "";
  List<Map<String, dynamic>> userAddedMusicList = [];
  bool isMusicLoading = false;
  String currentMusicUrl = "";
  Offset playerPosition = const Offset(150, 400);
  bool isRoomMusicPlaying = false;
  bool isPKEnding = false; // এটি এন্ড লজিক লক করার জন্য
  // Realtime States
  Map<String, dynamic> currentUserData = {};
  int currentSeatIndex = -1;
  bool isMicOn = false;
  List<Map<String, String>> chatMessages = [];
  bool isGiftAnimating = false;
  String currentGiftImage = "";
  // late বাদ দিয়ে দিন
  List<Map<String, dynamic>> seats = [];
  bool _isMeTalkingNow = false; // এটি লাল দাগ দূর করবে
  // Timer & Gift Logic
  bool isCountingGifts = false;
  int remainingSeconds = 900;
  Timer? giftTimer;
  String targetType = "";
  String currentSenderName = "";
  String currentReceiverName = "";
  StreamSubscription<DocumentSnapshot>? _marriageListener;
  StreamSubscription? _soulmateListener;
  StreamSubscription? _seatSubscription;
  StreamSubscription? _volumeSubscription;
  StreamSubscription? _emojiSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _roomSnapshotSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _entrySnapshotSubscription;

// ক্লাসের শুরুতে এগুলো যোগ করুন:
  StreamSubscription? _ludoLobbySub;
  StreamSubscription? _ludoPlayersSub;
  StreamSubscription? _ludoGameStateSub;
  StreamSubscription? _roomEndedSub;
  StreamSubscription? _roomDataSnapshotSub;
  String lastProcessedEntryId =
      ""; // এটি চেক করবে কোন আইডিটা লাস্ট প্রসেস হয়েছে
  String? activeGlobalVideoUrl;
  StreamSubscription? _videoGiftSubscription;
  late ScrollController _roomNameScrollController;
  Timer? _scrollTimer;
  late AnimationController _marqueeController;

  @override
  void initState() {
    super.initState();
    _roomNameScrollController = ScrollController();

    // স্মুথ ইনফিনিট মারকিউ অ্যানিমেশন কন্ট্রোলার
    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _setupAgoraAndRipple();

    // ১. রুম সুইচিং চেক
    if (RoomManager().activeRoomId != null &&
        RoomManager().activeRoomId != widget.roomId) {
      RoomManager().forceExitOldRoom();
    }

    // ২. ক্লিনআপ লজিক সেট করা
    RoomManager().onForceExit = () {
      if (mounted) {
        _removeUserFromViewers();
        _clearUserLiveStatus();

        if (currentSeatIndex != -1) {
          _roomService.updateSeatData(
              roomId: widget.roomId,
              seatIndex: currentSeatIndex,
              uName: "",
              uImage: "",
              isOccupied: false);

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
            'isMicOn': false
          });
        }
        _activeManager.stopTimer();
      }
    };

    RoomManager().activeRoomId = widget.roomId;

    WakelockPlus.enable();
    listenForSoulmateRequests();
    listenForMarriageRequests();

    // ১. সবার আগে স্টেট সেভ করে নিন
    bool isComingFromBubble = FloatingBubbleService.isMinimized;

    // --- ১. মিনিমাইজড ডাটা রিকভারি লজিক ---
    if (FloatingBubbleService.isMinimized) {
      currentSeatIndex = RoomManager().currentSeatIndex;

      // শুধু ওভারলে উইজেট সরাব, কিন্তু isMinimized ফ্ল্যাগ ধরে রাখব যাতে নিচের চেক কাজ করে
      FloatingBubbleService.clearOverlayOnly();

      // কাজ শেষে একেবারে সেফ টাইমে isMinimized ফলস করে দেবো
      Future.delayed(const Duration(milliseconds: 500), () {
        FloatingBubbleService.isMinimized = false;
      });
    } else {
      RoomManager().reset();
      RoomManager().activeRoomId = widget.roomId;
    }
    // 👈 [অপ্টিমাইজড ১] রুম গিফট লিসেনার (ভেরিয়েবলে স্টোর করা হলো যাতে ডিসপোজ করা যায়)
    _roomSnapshotSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || !snapshot.exists) return;

      var data = snapshot.data();
      if (data != null && data.containsKey('last_gift')) {
        var giftData = data['last_gift'];
        int currentCount =
            int.tryParse(giftData['count']?.toString() ?? "0") ?? 0;

        setState(() {
          scores['global_room_gift'] = currentCount;
        });
      }
    });

    // ২. ইউজার এবং রুম ডাটা চেক
    _fetchMyuID().then((_) {
      bool isUserValidForXp =
          uID.isNotEmpty && FirebaseAuth.instance.currentUser != null;

      if (isUserValidForXp) {
        _activeManager.startTimer(
          uID: uID,
          authUID: FirebaseAuth.instance.currentUser?.uid ?? "",
          email: FirebaseAuth.instance.currentUser?.email ?? "",
          minutesInterval: 20,
          xpAmount: 1,
        );
      }

      if (!FloatingBubbleService.isMinimized) {
        _updateUserLiveStatus(widget.roomId);
        _fetchRoomData();
        _checkIfFollowing();
      }
    });

    _initEmojiListener();

    FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/latestVideoGift')
        .remove();

    _initGlobalVideoGiftListener();

    if (!isComingFromBubble) {
      _addUserToViewers();
      showMyOwnEntry();

      FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
        'userCount': FieldValue.increment(1),
      }).catchError(
          (e) => debugPrint("❌ রুমে ঢোকার সময় কাউন্ট বাড়াতে সমস্যা: $e"));
    }

    // ৫. ১৫টি সিটের ইনিশিয়ালাইজেশন
    seats = List.generate(
        15,
        (index) => {
              "isOccupied": false,
              "userName": "",
              "userImage": "",
              "userFrame": "",
              "isVip": index < 5,
              "status": "empty",
              "giftCount": 0,
              "isMicOn": false,
              "isTalking": false,
              "userId": "",
              "uID": "",
              "agorauID": "",
            });

    // ৬. রিয়েলটাইম সিট লিসেনার (লুপ ও ফ্রিকোয়েন্সি প্রিভেন্টেড এবং ক্লিনড)
    _seatSubscription = FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/seats')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (!mounted) return;

      List<Map<String, dynamic>> updatedSeats = List.generate(
          15,
          (index) => {
                "isOccupied": false,
                "userName": "",
                "userImage": "",
                "userFrame": "",
                "isVip": index < 5,
                "status": "empty",
                "giftCount": 0,
                "isMicOn": false,
                "isTalking": false,
                "userId": "",
                "uID": "",
                "agorauID": "",
              });

      if (data != null) {
        Map<dynamic, dynamic> dataMap =
            (data is Map) ? data : (data as List).asMap();
        dataMap.forEach((key, value) {
          int? index = int.tryParse(key.toString());
          if (index != null && index < updatedSeats.length && value != null) {
            final seatMap = Map<dynamic, dynamic>.from(value as Map);

            updatedSeats[index]["isOccupied"] = seatMap["isOccupied"] ?? false;
            updatedSeats[index]["userName"] =
                seatMap["name"] ?? seatMap["userName"] ?? "";
            updatedSeats[index]["userImage"] =
                seatMap["profilePic"] ?? seatMap["userImage"] ?? "";
            updatedSeats[index]["userFrame"] =
                seatMap["activeFrameUrl"] ?? seatMap["userFrame"] ?? "";
            updatedSeats[index]["isMicOn"] = seatMap["isMicOn"] ?? false;
            updatedSeats[index]["userId"] =
                seatMap["authUID"] ?? seatMap["userId"] ?? "";
            updatedSeats[index]["uID"] = seatMap["uID"] ?? "";
            updatedSeats[index]["agorauID"] =
                seatMap["agorauID"]?.toString() ?? "";
            updatedSeats[index]["giftCount"] =
                int.tryParse(seatMap["giftCount"]?.toString() ?? "0") ?? 0;

            if (updatedSeats[index]["userId"] ==
                FirebaseAuth.instance.currentUser?.uid) {
              currentSeatIndex = index;

              gameJoinedUsers = updatedSeats
                  .where((s) => s["isOccupied"] == true)
                  .map((s) => {"name": s["userName"], "avatar": s["userImage"]})
                  .toList();

              // আপনার অরিজিনাল কোডের সেই জরুরি রিকোয়েস্ট লিসেনার
              listenForMarriageRequests();
            }
          }
        });
      }

      // 🛡️ ডেটা পরিবর্তন না হলে setState কল হবে না (লুপ জেনারেটর ব্লকড)
      bool isSeatDataChanged = true;
      try {
        isSeatDataChanged = jsonEncode(seats) != jsonEncode(updatedSeats);
      } catch (_) {}

      if (mounted && isSeatDataChanged) {
        setState(() {
          seats = updatedSeats;
        });
      }
    });

// ১. লবির স্টেট লিসেনার - এটি সবার ফোনে লবি ও গেম স্টার্ট সিঙ্ক করবে
    _ludoLobbySub?.cancel();
    _ludoLobbySub = FirebaseDatabase.instance
        .ref('ludo_rooms/${widget.roomId}/lobby_status')
        .onValue
        .listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && mounted) {
        setState(() {
          showLudoLobby = data["showLobby"] ?? false;
          isGameStarted = data["isStarted"] ?? false;
          currentBet = data["betAmount"] ?? 2;
        });
      }
    });

// ২. লবিতে জয়েন করা প্লেয়ারদের লিস্ট সিঙ্ক করার লজিক
    _ludoPlayersSub?.cancel();
    _ludoPlayersSub = FirebaseDatabase.instance
        .ref('ludo_rooms/${widget.roomId}/players')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;

      if (mounted) {
        setState(() {
          gameJoinedUsers = [];

          if (data != null) {
            // Firebase ডাটা Map হিসেবে আসছে
            Map<dynamic, dynamic> playersMap = data as Map<dynamic, dynamic>;

            playersMap.forEach((key, value) {
              // এখানে 'color' ডাটাবেস থেকে আসছে যা onJoin এ সেট করেছিলেন
              String color = (value["color"] != null)
                  ? value["color"].toString().toLowerCase()
                  : "green";

              gameJoinedUsers.add({
                "name": value["name"] ?? "Player",
                "avatar": value["avatar"] ?? "",
                "uid": key,
                "color":
                    color // এটি এখন আপনার অন-জয়েন লজিক অনুযায়ী সঠিক কালার পাবে
              });
            });
          }
        });
      }
    });

// ৪. নতুন গেম স্টেট লিসেনার (যেখানে টোকেন পজিশন লাইভ সিঙ্ক হবে)
    _ludoGameStateSub?.cancel();
    _ludoGameStateSub = FirebaseDatabase.instance
        .ref('ludo_rooms/${widget.roomId}/game_state')
        .onValue
        .listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && mounted) {
        setState(() {
          // টোকেন ডাটা আপডেট লজিক
          List<dynamic> tokensFromDb = data['tokens'];
          for (var t in tokensFromDb) {
            int id = t['id'];
            // আপনার গেমের গুটিগুলোর স্টেট আপডেট করা
            // ধরুন gameTokens আপনার VoiceRoomState এর একটি লিস্ট
            if (id < gameTokens.length) {
              gameTokens[id].tokenPosition = Position(t['row'], t['column']);
              gameTokens[id].positionInPath = t['pathPos'];
              // যদি স্টেট আপডেট করতে হয়
              // gameTokens[id].tokenState = ... (আপনার স্টেট অনুযায়ী)
            }
          }
        });
      }
    });
    _roomEndedSub?.cancel();
    _roomEndedSub = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        var data = snapshot.data() as Map<String, dynamic>;
        bool isActive = data['isActive'] ?? true;

        // চেক করুন myuID খালি কি না
        if (myuID.isEmpty) return; // আইডি না আসা পর্যন্ত পপ-আপ দেখাবে না

        String dbOwnerId = data['ownerId']?.toString() ?? "";
        List<dynamic> adminListFromDb = data['admins'] ?? [];
        List<String> adminIds =
            adminListFromDb.map((e) => e.toString()).toList();

        bool isOwnerOrAdmin = (myuID == dbOwnerId || adminIds.contains(myuID));

        if (!isActive && !isOwnerOrAdmin) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: const Text("Room Ended",
                  style: TextStyle(color: Colors.white)),
              content: const Text("The owner has closed the room.",
                  style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK",
                      style: TextStyle(color: Colors.blueAccent)),
                ),
              ],
            ),
          );
        }
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
    } catch (e) {}
  }

  void _fetchRoomData() {
    _roomDataSnapshotSub?.cancel(); // আগেরটা থাকলে ক্যানসেল করে নেওয়া হলো
    _roomDataSnapshotSub = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        final rData = doc.data() as Map<String, dynamic>;

        // ১. ডাটাবেস থেকে নতুন এডমিন লিস্ট আনা
        List newAdminList = (rData['admins'] as List?) ?? [];

        // ২. রুমের তথ্যগুলো লোকাল ভেরিয়েবলে সেট করা (সব সময় আপডেট হবে)
        setState(() {
          roomData = rData;
          adminList = List.from(newAdminList);
          roomName = rData['roomName'] ?? 'Love Line';
          roomProfileImage = rData['roomImage'] ?? '';
          ownerId =
              rData['ownerId']?.toString() ?? rData['uID']?.toString() ?? "";
          ownerName = rData['ownerName'] ?? 'Hridoy';
          ownerPic = rData['ownerPic'] ?? "";
          ownerAuthId = rData['ownerAuthId'] ?? "";
          followerCount = rData['followerCount'] ?? 0;

          // ৩. ওনার চেক
          isOwner = (ownerAuthId == FirebaseAuth.instance.currentUser?.uid);

          // ৪. অ্যাডমিন চেক (অত্যন্ত গুরুত্বপূর্ণ অংশ)
          String myCurrentID = myuID.toString().trim();

          if (myCurrentID.isNotEmpty) {
            // যদি নিজের আইডি থাকে, তবে লিস্টে চেক করো
            isAdmin = newAdminList
                .any((admin) => admin.toString().trim() == myCurrentID);
          } else {
            // যদি আইডি এখনো না এসে থাকে, তবে আপাতত false
            isAdmin = false;
          }
        });
      }
    });
  }

  Future<void> _fetchMyuID() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (userDoc.docs.isNotEmpty) {
        setState(() {
          myuID = userDoc.docs.first.data()['uID']?.toString() ?? "";
        });
        await _ensureRoomIsActive();

        // আইডি পাওয়ার পর লিসেনার চালু করুন
        _listenForKickSignal();
      }
    }
  }

  Future<void> _ensureRoomIsActive() async {
    final roomRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    final doc = await roomRef.get();

    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      String dbOwnerId = data['ownerId']?.toString() ?? "";
      List<dynamic> adminListFromDb = data['admins'] ?? [];
      List<String> adminIds = adminListFromDb.map((e) => e.toString()).toList();

      // বর্তমান ইউজার মালিক বা অ্যাডমিন কি না চেক
      // এখানে 'myuID' ব্যবহার করা হয়েছে যা আপনি _fetchMyuID() থেকে পাচ্ছেন
      bool isMeOwnerOrAdmin = (myuID == dbOwnerId || adminIds.contains(myuID));

      // মালিক বা অ্যাডমিন ঢুকলে রুম অ্যাক্টিভ করে দিন
      if (isMeOwnerOrAdmin) {
        await roomRef.update({'isActive': true});
      }
    }
  }

  Future<void> updateOldRoomsWithDailyPoints() async {
    try {
      // ১. ডাটাবেজের সব রুমের ডাটা তুলে আনা হচ্ছে
      final roomsSnapshot =
          await FirebaseFirestore.instance.collection('rooms').get();

      final batch = FirebaseFirestore.instance.batch();
      int updatedCount = 0;

      // ২. লুপ চালিয়ে প্রতিটি রুম চেক করা হচ্ছে
      for (var doc in roomsSnapshot.docs) {
        final data = doc.data();

        // যদি রুমে 'dailyPoints' ফিল্ডটি আগে থেকে না থাকে, তবেই শুধু আপডেট করবে
        if (!data.containsKey('dailyPoints')) {
          batch.update(doc.reference, {
            'dailyPoints': 0, // ডিফল্ট পয়েন্ট ০ বসবে
            'ownerImage':
                data['ownerPic'] ?? '', // ওনারের আগের পিকচারটি এখানে কপি হবে
            'ownerFrame': '', // ডিফল্ট ফ্রেম ফাঁকা থাকবে
          });
          updatedCount++;
        }
      }

      // ৩. এক ক্লিকে ফায়ারবেসের সব পুরাতন রুম আপডেট করা
      if (updatedCount > 0) {
        await batch.commit();
      }
    } catch (e) {}
  }

  void _setupAgoraAndRipple() {
    // ১. এগোরা ইনি এবং জয়েন (রুমে ঢোকার সময় শুধু লিসেনার বা অডিও শোনার জন্য)
    Future.microtask(() async {
      try {
        if (!FloatingBubbleService.isMinimized) {
          await _agoraManager.initAgora();
          final String authUID = FirebaseAuth.instance.currentUser?.uid ?? "";

          // রুমে ঢোকার সময় ইউজার শুধু শুনবে, মাইক বন্ধ থাকবে (লিসেনার মোড)
          await _agoraManager.joinAsListener(widget.roomId, authUID);

          // নিশ্চিত করার জন্য লোকাল অডিও ডিজেবল করে দেওয়া হলো যাতে রুমে ঢুকেই কলিং শুরু না হয়
          await _agoraManager.engine.enableLocalAudio(false);
          await _agoraManager.engine
              .setClientRole(role: ClientRoleType.clientRoleAudience);

          if (mounted) {
            _addUserToViewers();
          }
        }
      } catch (e) {}
    });

    // ২. ম্যানেজারের স্ট্রিম থেকে সরাসরি স্পিকার ডেটা শোনা (রিপেল অ্যানিমেশনের জন্য)
    _volumeSubscription = _agoraManager.volumeStream.listen((speakers) {
      if (!mounted) return;

      bool isMeTalking = false;
      for (var speaker in speakers) {
        if (speaker.uid == 0 && (speaker.volume ?? 0) > 15) {
          isMeTalking = true;
          break;
        }
      }

      if (_isMeTalkingNow != isMeTalking) {
        setState(() {
          _isMeTalkingNow = isMeTalking;
        });
        _updateTalkingStatus(isMeTalking);
      }
    });
  }

  void _initEmojiListener() {
    _emojiSubscription?.cancel();

    // রুমের active_emojis নোড শুনব, যাতে রুমের যেকোনো প্রান্ত থেকে যেকেউ ইমোজি বাজালে সবাই দেখতে পায়
    _emojiSubscription = FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/active_emojis')
        .onValue
        .listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value;
      if (data == null) {
        if (mounted) {
          setState(() {
            activeEmojis.clear();
          });
        }
        return;
      }

      Map<int, String> newActiveEmojis = {};

      // ১. যদি ডাটা Map আকারে থাকে (০ থেকে ১৪ পর্যন্ত সিটের জন্য)
      if (data is Map) {
        data.forEach((key, value) {
          int index = -1;
          if (key is int) {
            index = key;
          } else {
            index = int.tryParse(key.toString()) ?? -1;
          }

          // ইনডেক্স ০ থেকে ১৪ (মোট ১৫টি সিট) এর মধ্যে হতে হবে
          if (index >= 0 && index <= 14 && value is Map) {
            String? emojiUrl = value['currentEmoji']?.toString();
            if (emojiUrl != null && emojiUrl.isNotEmpty) {
              newActiveEmojis[index] = emojiUrl;
            }
          }
        });
      }
      // ২. যদি ডাটা List আকারে থাকে
      else if (data is List) {
        for (int i = 0; i < data.length && i <= 14; i++) {
          var value = data[i];
          if (value is Map) {
            String? emojiUrl = value['currentEmoji']?.toString();
            if (emojiUrl != null && emojiUrl.isNotEmpty) {
              newActiveEmojis[i] = emojiUrl;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          activeEmojis = newActiveEmojis;
        });
      }
    });
  }

  DatabaseReference get _videoGiftRef =>
      FirebaseDatabase.instance.ref('${widget.roomId}/latestVideoGift');
  void _initGlobalVideoGiftListener() {
    _videoGiftSubscription =
        _videoGiftRef.onValue.listen((DatabaseEvent event) {
      if (!mounted) return;

      final data = event.snapshot.value;

      // ডাটা না থাকলে বা ভিডিও না থাকলে থামিয়ে দিন
      if (data == null) return;

      if (data is Map) {
        String? videoUrl = data['url']?.toString();

        // শুধুমাত্র তখনই ভিডিও দেখাবে যদি ভিডিওর URL নাল না হয়
        if (videoUrl != null && videoUrl.isNotEmpty) {
          // ভিডিওর বয়স চেক করুন (যদি ভিডিওটি ১ মিনিটের বেশি পুরনো হয়, তবে লোড করবেন না)
          int sendTime = int.tryParse(data['sendTime']?.toString() ?? '0') ?? 0;
          int currentTime = DateTime.now().millisecondsSinceEpoch;

          if (currentTime - sendTime < 60000) {
            // ১ মিনিট (60,000 ms) এর মধ্যে হলে দেখাবে
            setState(() {
              activeGlobalVideoUrl = videoUrl;
            });
          }
        }
      }
    });
  }

  void sendRoomVideoGift(String giftUrl) {
    // ১. আপনার বর্তমান Realtime Database কোড (এটি যা আছে তা-ই থাকবে)
    FirebaseDatabase.instance.ref('${widget.roomId}/latestVideoGift').set({
      'url': giftUrl,
      'sendTime': ServerValue.timestamp,
    });

    // ২. শুধুমাত্র এই একটি বাড়তি লাইন যোগ করুন (এটি সবাইকে ভিডিওটি দেখাতে সাহায্য করবে)
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'latestVideoGift': {'url': giftUrl}
    });
  }

// 🟢 ১. সোলমেট রিকোয়েস্ট লিসেনার ফাংশন (কোনো লুপ ছাড়া, একদম সেফ)
  void listenForSoulmateRequests() {
    final String authUID = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (authUID.isEmpty) return;

    // 🔥 সমাধান: শুরুতে লুপ না চালিয়ে সরাসরি authUID দিয়ে ফায়ারস্টোরে নজর রাখা শুরু করবে।
    // এর ফলে রুমে ঢোকার সময় seats খালি থাকলেও অ্যাপ বিন্দুমাত্র ক্র্যাশ করবে না!
    _soulmateListener = FirebaseFirestore.instance
        .collection('soulmate_requests')
        .doc(authUID) // সরাসরি ফায়ারবেস UID দিয়ে লিসেন করবে
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data() as Map<String, dynamic>;

        if (data['status'] == 'pending') {
          // স্ক্রিনে পপ-আপ ডায়ালগ শো করা
          _showSoulmateRequestDialog(data);
        }
      }
    });
  }

// 🟢 ২. সোলমেট রিকোয়েস্ট পপ-আপ ডায়ালগ (আইডি জটলা মুক্ত ফিক্সড কোড)
  void _showSoulmateRequestDialog(Map<String, dynamic> requestData) async {
    final String authUID = FirebaseAuth.instance.currentUser?.uid ?? '';

    String myName = "User";
    String myImg = "";
    String myId =
        authUID; // ব্যাকআপ ৬ ডিজিটের আইডি না পাওয়া গেলে লম্বা আইডিই থাকবে

    // রুমে থাকা সিট লিস্ট থেকে নিজের ৬ ডিজিটের uID খুঁজে বের করা
    if (seats.isNotEmpty) {
      for (var seat in seats) {
        if (seat["userId"] == authUID || seat["authUID"] == authUID) {
          myName = seat["userName"] ?? "User";
          myImg = seat["userImage"] ?? "";
          if (seat["uID"] != null && seat["uID"].toString().isNotEmpty) {
            myId = seat["uID"].toString(); // সফলভাবে ৬ ডিজিটের uID পেলাম
          }
          break;
        }
      }
    }

    if (myName == "User" || myName.isEmpty) {
      myName = FirebaseAuth.instance.currentUser?.displayName ?? "User";
      myImg = FirebaseAuth.instance.currentUser?.photoURL ?? "";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.favorite, color: Colors.pinkAccent),
            SizedBox(width: 10),
            Text("Soulmate Request!",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(requestData['fromImg'] ?? ''),
              backgroundColor: Colors.white12,
              child: (requestData['fromImg'] == null ||
                      requestData['fromImg'].toString().isEmpty)
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 15),
            Text(
              "${requestData['fromName']} wants to be your Soulmate! 💕",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          // 🔴 রিজেক্ট বাটন
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
            onPressed: () async {
              Navigator.pop(context);
              // 🔥 ফিক্স: ডিলিট করার জন্য অবশ্যই নিজের লম্বা authUID পাস করতে হবে
              await GiftService().rejectSoulmateRequest(authUID);
            },
            child: const Text("Reject", style: TextStyle(color: Colors.white)),
          ),
          // 🟢 এক্সেপ্ট বাটন
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            onPressed: () async {
              Navigator.pop(context);

              await GiftService().acceptSoulmateGift(
                myId:
                    authUID, // 🔥 ফায়ারস্টোরে রিকোয়েস্ট ডকুমেন্ট ডিলিট করার জন্য এখানে লম্বা authUID দেওয়া আবশ্যক!
                myName: myName,
                myImg: myImg,
                friendId: requestData['fromId'] ?? '', // বন্ধুর ৬ ডিজিটের uID
                friendName: requestData['fromName'] ?? 'Unknown',
                friendImg: requestData['fromImg'] ?? '',
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text("Congratulations! You are now Soulmates! 🎉"),
                      backgroundColor: Colors.green),
                );
              }
            },
            child: const Text("Accept",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

// 🟢 ম্যারেজ রিকোয়েস্ট লিসেনার ফাংশন
  void listenForMarriageRequests() {
    final String authUID = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (authUID.isEmpty) return;

    _marriageListener = FirebaseFirestore.instance
        .collection('marriage_requests')
        .doc(authUID)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data() as Map<String, dynamic>;

        if (data['status'] == 'pending') {
          // স্ক্রিনে ম্যারেজ পপ-আপ ডায়ালগ শো করা
          _showMarriageRequestDialog(data);
        }
      }
    });
  }

  bool _isMarriageDialogShowing = false;

// 🟢 ম্যারেজ রিকোয়েস্ট পপ-আপ ডায়ালগ (ক্র্যাশ ও ডাবল-ক্লিক সেফ কোড)
  void _showMarriageRequestDialog(Map<String, dynamic> requestData) async {
    if (_isMarriageDialogShowing) return;
    _isMarriageDialogShowing = true;

    final String authUID = FirebaseAuth.instance.currentUser?.uid ?? '';
    String myName = "User";
    String myImg = "";
    String myId = authUID;

    if (seats.isNotEmpty) {
      for (var seat in seats) {
        if (seat["userId"] == authUID || seat["authUID"] == authUID) {
          myName = seat["userName"] ?? "User";
          myImg = seat["userImage"] ?? "";
          if (seat["uID"] != null && seat["uID"].toString().isNotEmpty) {
            myId = seat["uID"].toString();
          }
          break;
        }
      }
    }

    if (myName == "User" || myName.isEmpty) {
      myName = FirebaseAuth.instance.currentUser?.displayName ?? "User";
      myImg = FirebaseAuth.instance.currentUser?.photoURL ?? "";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Image.network(requestData['ringIcon'] ?? '',
                width: 30,
                height: 30,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.star, color: Colors.amber)),
            const SizedBox(width: 10),
            const Text("Marriage Proposal!",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(requestData['fromImg'] ?? ''),
              backgroundColor: Colors.white12,
            ),
            const SizedBox(height: 15),
            Text(
              "${requestData['fromName']} has proposed to you with ${requestData['ringName']}! 💍💕",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          // 🔴 Reject Proposal
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
            onPressed: () async {
              _isMarriageDialogShowing = false;
              Navigator.of(dialogContext).pop();
              await MarriageService().rejectMarriageRequest(authUID);
            },
            child: const Text("Reject", style: TextStyle(color: Colors.white)),
          ),
          // 🟢 Accept Proposal
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            onPressed: () async {
              _isMarriageDialogShowing = false;
              Navigator.of(dialogContext).pop();

              try {
                // রিকোয়েস্ট থেকে বন্ধুর লম্বা authUID নেওয়া
                String friendAuthUID = requestData['fromAuthUID'] ?? '';
                if (friendAuthUID.isEmpty) {
                  friendAuthUID = requestData['fromId'] ?? ''; // সেফটি ব্যাকআপ
                }

                await MarriageService().completeMarriage(
                  myId: myId, // নিজের ৬ ডিজিটের uID
                  myAuthUID: authUID, // নিজের লম্বা authUID
                  myName: myName,
                  myImg: myImg,
                  friendId: requestData['fromId'] ?? '', // বন্ধুর ৬ ডিজিটের uID
                  friendAuthUID: friendAuthUID, // বন্ধুর লম্বা authUID
                  friendName: requestData['fromName'] ?? 'Unknown',
                  friendImg: requestData['fromImg'] ?? '',
                  ringName: requestData['ringName'] ?? 'Marriage Ring',
                  ringIcon: requestData['ringIcon'] ?? '',
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "Congratulations! You are now happily Married! 🎉💍"),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                print("Error accepting marriage ring: $e");
              }
            },
            child: const Text("Accept",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).then((_) {
      _isMarriageDialogShowing = false;
    });
  }

// ১. এডমিন বানানো বা রিমুভ করা
  void _toggleAdmin(String targetuID, bool isAlreadyAdmin) {
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'admins': isAlreadyAdmin
          ? FieldValue.arrayRemove([targetuID])
          : FieldValue.arrayUnion([targetuID]),
    });
  }

  void _kickUserFromRoom(String targetuID) async {
    if (targetuID.isEmpty) return;

    // নতুন ফিচার: প্রোটেকশন চেক
    if (protectedUserIds.contains(targetuID)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "This user is an official member of PaglaChat, you cannot kick them!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return; // এখান থেকেই ফাংশন বন্ধ হয়ে যাবে, কিক হবে না
    }

    try {
      // ১. ফায়ারস্টোরে কিক লিস্টে জমা করা...
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({
        'kickedUsers': FieldValue.arrayUnion([targetuID]),
        'followers': FieldValue.arrayRemove([targetuID]),
        'admins': FieldValue.arrayRemove([targetuID]),
      });

      // ২. রিয়েল-টাইম ডাটাবেসে কিক সিগন্যাল...
      await FirebaseDatabase.instance
          .ref('rooms/${widget.roomId}/kickSignal/$targetuID')
          .set({
        'action': 'kicked',
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {}
  }

  void _listenForKickSignal() {
    if (myuID.isEmpty) return; // আইডি না থাকলে লিসেনার কাজ করবে না

    FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/kickSignal/$myuID')
        .onValue
        .listen((event) {
      if (event.snapshot.exists) {
        // ইউজারকে কিক করা হয়েছে!
        _leaveRoomInternally();

        if (mounted) {
          // কিক সিগন্যালটি ডাটাবেস থেকে মুছে ফেলা (যাতে পরে আবার ঢুকতে সমস্যা না হয়)
          FirebaseDatabase.instance
              .ref('rooms/${widget.roomId}/kickSignal/$myuID')
              .remove();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You have been kicked from this room!"),
              backgroundColor: Colors.red,
            ),
          );

          // রুম থেকে বের করে দেওয়া
          Navigator.of(context).pop();
        }
      }
    });
  }

// ১. গিটহাবের বেস লিঙ্ক
  final String githubBaseUrl =
      "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main";

// ২. VIP বেইজ লিংকের ফাংশন (ডায়ালগ থেকে কল করার জন্য)
  String getVipBadge(int level) {
    if (level <= 0) return "";
    // আপনার গিটহাবের ফাইল নেম অনুযায়ী (vip1.png, vip2.png ইত্যাদি)
    return "$githubBaseUrl/vip$level.png";
  }

// ৩. প্রিমিয়াম ব্যাজের জন্য লিঙ্ক
  String get premiumBadgeUrl => "$githubBaseUrl/premium.png";

// ৪. VIP লেভেল ক্যালকুলেশন (ডায়ালগের ডাটা অনুযায়ী)
  int getVipLevelFromData(int userXp, int userExpiry) {
    int currentTime = DateTime.now().millisecondsSinceEpoch;

    // যদি মেয়াদ থাকে এবং শেষ হয়ে যায়
    if (userExpiry != 0 && currentTime > userExpiry) {
      return 0;
    }

    if (userXp >= 35000) return 8;
    if (userXp >= 30000) return 7;
    if (userXp >= 25000) return 6;
    if (userXp >= 20000) return 5;
    if (userXp >= 13000) return 4;
    if (userXp >= 9000) return 3;
    if (userXp >= 5000) return 2;
    if (userXp >= 2500) return 1;
    return 0;
  }

  // ১. ফিক্সড মাইক স্ট্যাটাস লিসেনার (লুপ ও অতিরিক্ত কলিং বন্ধ করার জন্য)
  bool _lastKnownMicState = true;

  void _listenToMicStatus() {
    if (currentSeatIndex == -1) return;

    FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/seats/$currentSeatIndex')
        .onValue
        .listen((event) {
      if (event.snapshot.exists) {
        var data = event.snapshot.value as Map?;
        bool isMicOn = data?['isMicOn'] ?? true;

        // শুধুমাত্র স্টেটে পরিবর্তন আসলেই অ্যাগোরায় রিকোয়েস্ট যাবে, বারবার লুপ হবে না
        if (_lastKnownMicState != isMicOn) {
          _lastKnownMicState = isMicOn;
          _agoraManager.remoteMuteControl(!isMicOn);
        }
      }
    });
  }

// ৩. ইউজারের মাইক অফ করা (Admin Control)
  Future<void> _muteUserByAdmin(String targetuID, int seatIndex) async {
    // ডাটাবেজে ওই সিটের মাইক অফ করে দেওয়া
    await FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/seats/$seatIndex')
        .update({'isMicOn': false, 'isMutedByAdmin': true});
  }

  void _updateUserLiveStatus(String roomId) async {
    String authUID = FirebaseAuth.instance.currentUser?.uid ?? "";

    try {
      // ১. আপনার ৬-ডিজিটের uID দিয়ে আপডেট ট্রাই করবে।
      // .update ব্যবহার করা হয়েছে যাতে নতুন কোনো খালি আইডি তৈরি না হয়।
      if (myuID.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(myuID).update({
          'currentRoomId': roomId,
        });
      }

      // ২. Auth UID দিয়ে আপডেট ট্রাই করবে।
      // যদি এই আইডিটি ডাটাবেসে না থাকে, তবে এটি কোনো নতুন ডকুমেন্ট বানাবে না।
      if (authUID.isNotEmpty && authUID != myuID) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(authUID)
            .update({
          'currentRoomId': roomId,
        });
      }
    } catch (e) {
      // যদি আইডি খুঁজে না পায় তবে এখানে আসবে, কিন্তু নতুন হিবিজিবি আইডি তৈরি হবে না।
    }
  }

  // 🇧🇩 [বাংলা মার্ক - ১০০% ফিক্সড ও সেফটি প্রুফ স্ট্যাটাস ক্লিন মেথড]
  void _clearUserLiveStatus() async {
    String authUID = FirebaseAuth.instance.currentUser?.uid ?? "";

    try {
      // ১. প্রথমে myuID (শর্ট আইডি) দিয়ে চেক এবং আপডেট
      if (myuID.isNotEmpty) {
        final shortIdRef =
            FirebaseFirestore.instance.collection('users').doc(myuID);
        final shortIdSnap = await shortIdRef.get();

        // 🎯 সেফটি চেক: যদি ফায়ারস্টোরে এই শর্ট আইডির ডক আসলেই থাকে, তবেই আপডেট হবে ভাই
        if (shortIdSnap.exists) {
          await shortIdRef.update({
            'currentRoomId': FieldValue.delete(),
          });
        }
      }

      // ২. এবার authUID (ফায়ারবেস অ্যাথ ইউআইডি) দিয়ে চেক এবং আপডেট
      if (authUID.isNotEmpty && authUID != myuID) {
        final authIdRef =
            FirebaseFirestore.instance.collection('users').doc(authUID);
        final authIdSnap = await authIdRef.get();

        // 🎯 সেফটি চেক: যদি ফায়ারস্টোরে এই অ্যাথ আইডির ডক আসলেই থাকে, তবেই আপডেট হবে
        if (authIdSnap.exists) {
          await authIdRef.update({
            'currentRoomId': FieldValue.delete(),
          });
        }
      }
    } catch (e) {}
  }

// ৪. ফলো/আনফলো লজিক
  void _toggleFollowUser(String targetId) async {
    String myId = FirebaseAuth.instance.currentUser?.uid ?? "";
    var userRef = FirebaseFirestore.instance.collection('users').doc(myId);

    // আপনার আগের লজিক অনুযায়ী ফলোয়ার লিস্ট আপডেট করুন
    // ... (Firebase logic)
  }

  void _goToInbox(String peerId, String peerName) async {
    // ১. PeerId টি কি ৬-ডিজিটের uID নাকি authUID তা যাচাই করা
    // আপনার কোড অনুযায়ী চ্যাট স্ক্রিনে 'receiverId' হিসেবে ৬-ডিজিটের uID পাঠাতে হয়।

    String finalPeerUID = peerId;

    // যদি peerId টি authUID হয়, তবে আমরা ফায়ারবেস থেকে তার ৬-ডিজিটের uID বের করে নেবো
    // যদি already ৬-ডিজিটের আইডি হয়, তবে এটি প্রয়োজন নেই।
    // তবে নিরাপত্তার জন্য চেক করে নেওয়া ভালো:
    try {
      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: peerId)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        finalPeerUID = userQuery.docs.first.data()['uID']?.toString() ?? peerId;
      }
    } catch (e) {}

    // ২. চ্যাট স্ক্রিনে নেভিগেট করা
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          receiverId: finalPeerUID, // এখানে ৬-ডিজিটের আইডি পাঠাচ্ছি
          receiverName: peerName,
        ),
      ),
    );
  }

  void _openGiftPanel(String targetUserId) async {
    // ১. বর্তমান ইউজারের সঠিক AuthUID বের করা
    final String currentAuthUID = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (currentAuthUID.isEmpty) return;

    // ২. ডাটাবেস থেকে ব্যালেন্স এবং ইউজার ডিটেইলস নিয়ে আসা (মেইন গিফট বক্সের মতো)
    var userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('authUID', isEqualTo: currentAuthUID)
        .limit(1)
        .get();

    int currentBalance = 0;
    if (userQuery.docs.isNotEmpty) {
      currentBalance = (userQuery.docs.first.data()['diamonds'] ?? 0).toInt();
    }

    if (!mounted) return;

    // ৩. এখন প্যানেলটি খুলুন
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GiftBottomSheet(
        roomId: widget.roomId,
        diamondBalance: currentBalance, // আপডেট হওয়া ব্যালেন্স পাঠানো হচ্ছে
        currentSeats: List.from(seats),
        onGiftSend: (gift, count, target) async {},
      ),
    );
  }

  void showMyOwnEntry() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var userData = querySnapshot.docs.first.data();

        // ১. নিজের স্ক্রিনে এনিমেশন দেখানোর ডাটা সেট
        if (mounted) {
          setState(() {
            entryUserName = userData['name'] ?? "User";
            entryUserImage = userData['profilePic'] ?? "";
            currentEntryEffect = userData['activeEntryUrl'];
            entryUserFrame = userData['activeFrameUrl'] ?? "";
            showEntryEffect = (userData['activeEntryUrl'] != null &&
                userData['activeEntryUrl'].toString().isNotEmpty);
          });
        }

        // 🔥 গুরুত্বপূর্ণ: রুম ডকুমেন্টে 'lastEntry' আপডেট করা (যাতে অন্য সবাই এনিমেশন দেখে)
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .update({
          'lastEntry': {
            'name': userData['name'] ?? "User",
            'image': userData['profilePic'] ?? "",
            'activeEntryUrl': userData['activeEntryUrl'] ?? "",
            'activeFrameUrl': userData['activeFrameUrl'] ?? "",
            'timestamp': FieldValue.serverTimestamp(),
            'entryId': DateTime.now()
                .millisecondsSinceEpoch
                .toString(), // 🔥 এটি প্রতিবার ডাটাকে ইউনিক করবে
          }
        });
        // ২. মেসেজ লিস্টে এন্ট্রি ডাটা পাঠানো (মেসেজ হিসেবে দেখানোর জন্য)
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('messages')
            .add({
          'name': userData['name'] ?? "User",
          'uID': userData['uID'] ?? "",
          'senderImage': userData['profilePic'] ?? "",
          'type': 'entry',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {}
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
        .where((s) => s['isOccupied'] == true)
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
          'activeFrameUrl': userData['activeFrameUrl'] ?? "",
          'uID': userData['uID'] ?? "",
          'authUID': currentUser.uid,
          'isOccupied': true,
          'isMicOn': true,
          'agorauID': myAgorauID,
          'status': 'occupied',
          'at': ServerValue.timestamp,
        });

        await seatRef.onDisconnect().remove();
        // 🔥 ঠিক এখানে এই নিচের কোডটুকু বসিয়ে দিন (Firestore-এ ডাটা পাঠানোর জন্য)

        // 🔥 কোড শেষ
        if (mounted) {
          setState(() {
            currentSeatIndex = index;
            isMicOn = true;
          });

          _listenToMicStatus();
          Future.delayed(const Duration(milliseconds: 300), () {
            updateSeatPosition(index, seatKeys[index]);
          });
        }
      }
    } catch (e) {}
  }

  void _showLeaveConfirmation(int index) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => Container(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // গ্লাস ব্লার ইফেক্ট
          child: FadeTransition(
            opacity: anim1,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  decoration: BoxDecoration(
                    color:
                        Colors.black.withOpacity(0.4), // আধা-স্বচ্ছ ডার্ক গ্লাস
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      const Icon(Icons.exit_to_app_rounded,
                          color: Colors.redAccent, size: 30),
                      const SizedBox(height: 10),
                      const Text(
                        "Leave Seat",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Are you sure you want to leave?",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.white10, height: 1),
                      // 🔥 YES বাটন (সিট ছাড়ার আসল লজিক)
                      _buildPremiumButton(
                        text: "Yes, Leave",
                        icon: Icons.check_circle_outline,
                        textColor: Colors.redAccent,
                        onTap: () async {
                          Navigator.pop(ctx); // ডায়ালগ বন্ধ হবে
                          await _agoraManager.becomeListener();
                          await FirebaseDatabase.instance
                              .ref('rooms/${widget.roomId}/seats/$index')
                              .remove();
                          if (mounted) {
                            setState(() {
                              currentSeatIndex = -1;
                              isMicOn = false;
                            });
                          }
                        },
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      // 🔥 NO বাটন (ক্যান্সেল)
                      _buildPremiumButton(
                        text: "No, Stay",
                        icon: Icons.cancel_outlined,
                        textColor: Colors.white70,
                        onTap: () => Navigator.pop(ctx),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // কথা বলার স্ট্যাটাস লোকালি সেভ রাখার জন্য
  bool _lastTalkingStatus = false;

  void updateSeatPosition(int index, GlobalKey key) {
    // ১. ইনডেক্স এবং কি (key) ঠিক আছে কি না তা কঠোরভাবে চেক করা (০ সহ ১৪ পর্যন্ত)
    if (index < 0 || index > 14) return;
    if (key.currentContext == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final RenderBox? renderBox =
          key.currentContext?.findRenderObject() as RenderBox?;

      final RenderBox? roomBox = context.findRenderObject() as RenderBox?;

      if (renderBox != null && roomBox != null) {
        // সিটের পজিশন ক্যালকুলেট করুন
        final position =
            renderBox.localToGlobal(Offset.zero, ancestor: roomBox);
        final size = renderBox.size;

        Offset newPosition = Offset(
          position.dx + (size.width / 2),
          position.dy + (size.height / 2),
        );

        // ২. পজিশন পরিবর্তন হলে বা প্রথমবার সেট হওয়ার সময় ০ নম্বর ইনডেক্স সহ আপডেট নিশ্চিত করা
        if (seatPositions.length <= index) {
          // যদি লিস্টের সাইজ ছোট থাকে, তবে সাইজ বাড়িয়ে নেওয়া
          while (seatPositions.length <= index) {
            seatPositions.add(Offset.zero);
          }
        }

        if (seatPositions[index] != newPosition) {
          setState(() {
            seatPositions[index] = newPosition;
          });
        }
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
      } catch (e) {}
    }
  }

  void _showLudoLobby(BuildContext context) {
    bool isAuthorized =
        (ownerId.toString().trim() == myuID.toString().trim()) ||
            adminList.contains(myuID.toString().trim());
    LudoHelper.showLudoLobby(context, seats, isAuthorized);
  }

  void _startPKBattle(
      Map<String, dynamic> u1, Map<String, dynamic> u2, int duration) {
    // ডাটাবেজে পিকে স্ট্যাটাস আপডেট করুন যাতে সবাই দেখতে পায়
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'isPKActive': true,
      'pkData': {
        'u1': u1,
        'u2': u2,
        'duration': duration,
        'score1': 0, // শুরুতে স্কোর ০
        'score2': 0,
        'startTime': FieldValue.serverTimestamp(),
      }
    });
  }

  void _endPKBattle() {
    if (!mounted) return;

    // বর্তমান স্কোর ডাটাবেজ থেকে আসা ভেরিয়েবল থেকে নিন (যা অলরেডি currentPKData তে আছে)
    int finalBlue =
        int.tryParse(currentPKData?['score1']?.toString() ?? "0") ?? 0;
    int finalRed =
        int.tryParse(currentPKData?['score2']?.toString() ?? "0") ?? 0;

    String winner = finalBlue > finalRed ? "BLUE" : "RED";

    showDialog(
      context: context,
      builder: (context) => PKWinnerDialog(
        winnerTeam: winner,
        bluePoints: finalBlue, // লোকাল ভেরিয়েবলের বদলে ফাইনাল ভ্যালু পাঠান
        redPoints: finalRed,
      ),
    );

    setState(() => isPKActive = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1222),
      resizeToAvoidBottomInset: false,
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
              Map<String, dynamic> roomData =
                  snapshot.data!.data() as Map<String, dynamic>;

              // Firestore এ আপনার ফিল্ডের নাম যদি 'latestVideoGift' হয়:
              var videoData = roomData['latestVideoGift'];
              String? activeGlobalVideoUrl =
                  videoData != null ? videoData['url'] : null;

              // ১. ডেটা আপডেট (সরাসরি ভেরিয়েবল আপডেট, বিল্ড মেথড নিজেই স্টেট রিফ্রেশ করবে)
              wallpaperUrl = roomData['currentWallpaper'];
              bool newIsPKActive = roomData['isPKActive'] ?? false;
              Map<String, dynamic>? newPKData = roomData['pkData'];

              // ২. পিকের স্ট্যাটাস চেঞ্জ হলে লজিক হ্যান্ডেল করা
              if (_lastPKStatus == true && newIsPKActive == false) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _endPKBattle();
                });
              }

              // ৩. আপডেট লোকাল ভেরিয়েবলগুলো
              isPKActive = newIsPKActive;
              currentPKData = newPKData;
              pkDuration = currentPKData?['duration'] ?? 0;
              blueTeamPoints = (currentPKData?['score1'] ?? 0);
              redTeamPoints = (currentPKData?['score2'] ?? 0);

              _lastPKStatus = newIsPKActive;
              // --- গিফট অ্যানিমেশনের লজিক ---
              var lastGift = roomData['last_gift'];
              if (lastGift != null) {
                int giftTime = 0;
                if (lastGift['timestamp'] is int) {
                  giftTime = lastGift['timestamp'];
                } else if (lastGift['timestamp'] is Timestamp) {
                  giftTime = (lastGift['timestamp'] as Timestamp)
                      .millisecondsSinceEpoch;
                }

                int now = DateTime.now().millisecondsSinceEpoch;
                if (now - giftTime < 5000 && mounted && !isGiftAnimating) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        currentGiftImage =
                            lastGift['image'] ?? lastGift['icon'] ?? '';
                        currentSenderName = lastGift['senderName'] ?? 'Someone';
                        currentReceiverName = lastGift['target'] ?? '';
                        currentGiftCount = lastGift['count'] ?? 1;
                        currentSenderImage = lastGift['senderImage'] ?? '';
                        currentReceiverImage = lastGift['receiverImage'] ?? '';
                        isGiftAnimating = true;
                      });

                      // গিফট দেখানোর পর ফায়ারস্টোরে গিফট ফিল্ডটি খালি করে দিন
                      FirebaseFirestore.instance
                          .collection('rooms')
                          .doc(widget.roomId)
                          .update({
                        'last_gift': FieldValue.delete(),
                      });

                      Timer(const Duration(seconds: 5), () {
                        if (mounted) setState(() => isGiftAnimating = false);
                      });
                    }
                  });
                }
              }

              // --- এন্ট্রি ইফেক্ট লজিক (Fixed & Clean) ---
              if (roomData.containsKey('lastEntry') &&
                  roomData['lastEntry'] != null) {
                var lastEntry = roomData['lastEntry'];
                String currentEntryId = lastEntry['entryId']?.toString() ?? "";

                if (currentEntryId.isNotEmpty &&
                    currentEntryId != lastProcessedEntryId) {
                  String? effectLink = lastEntry['activeEntryUrl'];

                  if (effectLink != null && effectLink.isNotEmpty) {
                    lastProcessedEntryId = currentEntryId;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          entryUserName = lastEntry['name'] ?? "User";
                          entryUserImage = lastEntry['image'] ?? "";
                          entryUserFrame = lastEntry['activeFrameUrl'] ?? "";
                          currentEntryEffect = effectLink;
                          showEntryEffect = true;
                        });

                        // 🔥 অত্যন্ত গুরুত্বপূর্ণ: এন্ট্রি একবার ট্রিগার হওয়ার সাথে সাথেই ফায়ারবেস থেকে ফিল্ড মুছে দিন
                        // এতে রুমে অন্য কেউ ঢুকলে বা রিফ্রেশ হলে আর বারবার পুরোনো এন্ট্রি দেখাবে না।
                        FirebaseFirestore.instance
                            .collection('rooms')
                            .doc(widget.roomId)
                            .update({
                          'lastEntry': FieldValue.delete(),
                        });
                      }
                    });
                  }
                }
              }
            }
            return Stack(
              children: [
                // ১. ওয়ালপেপার একদম নিচে পুরো স্ক্রিন (স্ট্যাটাসবার সহ) জুড়ে থাকবে
                Positioned.fill(
                  child: RepaintBoundary(
                    child: (wallpaperUrl != null && wallpaperUrl.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: wallpaperUrl,
                            fit: BoxFit.cover,
                            color: Colors.black.withOpacity(0.2),
                            colorBlendMode: BlendMode.darken,
                            placeholder: (context, url) =>
                                Container(color: const Color(0xFF0B1222)),
                            errorWidget: (context, url, error) =>
                                Container(color: const Color(0xFF0B1222)),
                          )
                        : Container(color: const Color(0xFF0B1222)),
                  ),
                ),
                // ২. মেইন UI
                SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 5),
                      _buildTopNavBar(),

                      _buildViewerArea(),
                      Expanded(
                        flex: 2,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            RepaintBoundary(child: _buildSeatGridArea()),
                            StreamBuilder<DatabaseEvent>(
                              stream: FirebaseDatabase.instance
                                  .ref('rooms/${widget.roomId}/seats')
                                  .onValue,
                              builder: (context, snapshot) {
                                List<dynamic> seats = [];
                                if (snapshot.hasData &&
                                    snapshot.data!.snapshot.value != null) {
                                  var val = snapshot.data!.snapshot.value;
                                  seats = (val is Map)
                                      ? List.generate(15,
                                          (i) => val[i.toString()] ?? val[i])
                                      : (val is List ? val : []);
                                }

                                return StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .snapshots(),
                                  builder: (context, userSnapshot) {
                                    if (!userSnapshot.hasData)
                                      return const SizedBox.shrink();

                                    // ম্যাপ তৈরি করছি: {ডকুমেন্ট_আইডি : সোলমেট_লিস্ট}
                                    Map<String, List<dynamic>> allUsers = {};
                                    for (var doc in userSnapshot.data!.docs) {
                                      var d =
                                          doc.data() as Map<String, dynamic>;
                                      allUsers[doc.id] = d['soulmates'] is List
                                          ? d['soulmates']
                                          : [];
                                    }

                                    return SoulmateAnimationService
                                        .buildSoulmateHeartOverlay(
                                      seats: seats,
                                      allUsersSoulmates: allUsers,
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // মেসেজ এবং অ্যাক্টিভিটি এরিয়া
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

                                  // সেন্ডারের ডাটা
                                  String uName = mData['name'] ??
                                      mData['userName'] ??
                                      "User";
                                  String uImage = mData['senderImage'] ??
                                      mData['profilePic'] ??
                                      mData['userImage'] ??
                                      "";
                                  String messageText =
                                      mData['message'] ?? mData['text'] ?? "";
                                  String type = mData['type'] ?? 'text';

                                  return Align(
                                    alignment: Alignment.bottomLeft,
                                    child: GestureDetector(
                                      onTap: () {
                                        // 🔥 এখানে আইডি এর বদলে নাম (uName) সেট করা হয়েছে
                                        setState(() {
                                          _messageController.text = "@$uName ";
                                          _messageController.selection =
                                              TextSelection.fromPosition(
                                            TextPosition(
                                                offset: _messageController
                                                    .text.length),
                                          );
                                        });
                                      },
                                      child: type == 'text'
                                          ? _buildMessageRow({
                                              'name': uName,
                                              'profilePic': uImage,
                                              'text': messageText,
                                            })
                                          : _buildActivityRow(
                                              mData), // এটি আপনার গিফট/এন্ট্রি রো দেখাবে ছবিসহ
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

                // ৩. ইনবক্স বাটন
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

                // ৪. মুভেবল ব্যানার
                if (roomData['showBanner'] ?? false)
                  Positioned(
                    left: bannerPosition.dx,
                    top: bannerPosition.dy,
                    child: Draggable(
                      feedback: _buildRoomBanner(roomData),
                      childWhenDragging: Container(),
                      onDragEnd: (details) =>
                          setState(() => bannerPosition = details.offset),
                      child: _buildRoomBanner(roomData),
                    ),
                  ),

                // ৫. মিউজিক প্লেয়ার
                if (isFloatingPlayerVisible)
                  FloatingMusicPlayer(
                    initialPosition: playerPosition,
                    isRoomMusicPlaying: isRoomMusicPlaying,
                    onDragEnd: (newOffset) {
                      playerPosition = newOffset;
                    },
                    onPlayPauseToggle: () async {
                      if (isRoomMusicPlaying) {
                        await _agoraManager.engine.pauseAudioMixing();
                      } else {
                        await _agoraManager.engine.resumeAudioMixing();
                      }
                      if (mounted) {
                        setState(() {
                          isRoomMusicPlaying = !isRoomMusicPlaying;
                        });
                      }
                    },
                    onClose: () {
                      if (mounted) {
                        setState(() {
                          isFloatingPlayerVisible = false;
                          isRoomMusicPlaying = false;
                        });
                      }
                      _agoraManager.engine.stopAudioMixing();
                    },
                  ),

                if (isPKActive && currentPKData != null)
                  Positioned(
                    left: pkBannerOffset.dx,
                    top: pkBannerOffset.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          pkBannerOffset = Offset(
                            pkBannerOffset.dx + details.delta.dx,
                            pkBannerOffset.dy + details.delta.dy,
                          );
                        });
                      },
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: PersonalPKView(
                          // ৩. এখানে Key যোগ করুন, এটি টাইমার এবং উইজেট লাইফসাইকেল ঠিক রাখবে
                          key: const ValueKey('active_pk_view'),
                          user1: currentPKData!['u1'],
                          user2: currentPKData!['u2'],
                          duration: pkDuration,
                          score1: int.tryParse(
                                  currentPKData!['score1']?.toString() ??
                                      "0") ??
                              0,
                          score2: int.tryParse(
                                  currentPKData!['score2']?.toString() ??
                                      "0") ??
                              0,
                          onTimerEnd: () async {
                            // ৪. আরও শক্তিশালী চেক: যদি অলরেডি পপআপ দেখানোর প্রসেস চলছে
                            if (isPKEnding) return;

                            setState(() {
                              isPKEnding = true;
                            });

                            // ডাটাবেজে আপডেট পাঠানোর আগে ভ্যালুগুলো সেভ করে নিন
                            int finalScore1 = int.tryParse(
                                    currentPKData!['score1']?.toString() ??
                                        "0") ??
                                0;
                            int finalScore2 = int.tryParse(
                                    currentPKData!['score2']?.toString() ??
                                        "0") ??
                                0;

                            try {
                              // Firebase আপডেট
                              await FirebaseFirestore.instance
                                  .collection('rooms')
                                  .doc(widget.roomId)
                                  .update({
                                'isPKActive': false,
                                'pkData': FieldValue.delete(),
                              });
                            } catch (e) {}

                            String winner =
                                finalScore1 >= finalScore2 ? "BLUE" : "RED";

                            if (mounted) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => PKWinnerDialog(
                                  winnerTeam: winner,
                                  bluePoints: finalScore1,
                                  redPoints: finalScore2,
                                ),
                              ).then((_) {
                                // পপআপ বন্ধ হওয়ার পর ফ্ল্যাগ রিসেট
                                isPKEnding = false;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),

                if (isGiftCounting)
                  Positioned(
                    left: bannerPosition.dx,
                    top: bannerPosition.dy,
                    child: Draggable(
                      // ড্র্যাগ করার সময় ব্যানারটি কেমন দেখাবে
                      feedback: Opacity(
                        opacity: 0.8,
                        child: GiftCalculatorBanner(
                          minutes: (remainingSeconds / 60).toInt(),
                          theme: activityTheme,
                          seats: seats,
                          roomId: widget.roomId, // এখানে roomId পাস করলাম
                          onClose: () {},
                        ),
                      ),
                      // ড্র্যাগ করার সময় অরিজিনাল জায়গা খালি রাখা
                      childWhenDragging: Container(),

                      // ড্র্যাগ শেষ হলে পজিশন সেভ করা
                      onDragEnd: (details) {
                        setState(() {
                          bannerPosition = details.offset;
                        });
                      },

                      // আসল ব্যানারটি
                      child: GiftCalculatorBanner(
                        minutes: (remainingSeconds / 60).toInt(),
                        theme: activityTheme,
                        seats: seats,
                        roomId: widget.roomId, // এখানে roomId পাস করলাম
                        onClose: () {
                          setState(() {
                            isGiftCounting = false;
                            giftTimer?.cancel();
                          });
                        },
                      ),
                    ),
                  ),

// ১. ইমেজ গিফট ওভারলে (ভিডিও থাকলে এটি সম্পূর্ণ বন্ধ থাকবে)
                if ((activeGlobalVideoUrl == null ||
                        activeGlobalVideoUrl!.isEmpty) &&
                    isGiftAnimating &&
                    currentGiftImage.isNotEmpty)
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

// ২. ভিডিও গিফট ওভারলে (এখানেও কঠোর কন্ডিশন ব্যবহার করা হয়েছে)
                if (activeGlobalVideoUrl != null &&
                    activeGlobalVideoUrl!.isNotEmpty)
                  Positioned.fill(
                    child: Material(
                      color: Colors.black.withOpacity(
                          0.5), // থাম্বনেইল যেন ব্যাকগ্রাউন্ডের সাথে মিশে না যায়
                      child: VideoGiftOverlay(
                        url: activeGlobalVideoUrl!,
                        onFinished: () async {
                          // রিমুভাল লজিক
                          await FirebaseDatabase.instance
                              .ref('rooms/${widget.roomId}/latestVideoGift')
                              .remove();

                          await FirebaseFirestore.instance
                              .collection('rooms')
                              .doc(widget.roomId)
                              .update({'latestVideoGift': FieldValue.delete()});

                          if (mounted) {
                            setState(() {
                              // সব স্টেট পরিষ্কার করা হলো
                              activeGlobalVideoUrl = null;
                              isGiftAnimating = false;
                              currentGiftImage = "";
                              currentSenderImage = "";
                              currentReceiverImage = "";
                            });
                          }
                        },
                      ),
                    ),
                  ),
                // ১. লবি পপ-আপ
                if (showLudoLobby)
                  Positioned(
                    top: 150,
                    left: 20,
                    right: 20,
                    child: LudoLobbyPopup(
                      joinedUsers: gameJoinedUsers,
                      isAdmin: (ownerId.toString().trim() ==
                              myuID.toString().trim()) ||
                          adminList.contains(myuID.toString().trim()),
                      betAmount: currentBet,

                      onJoin: () async {
                        // ১. বর্তমান ইউজার কোন সিটে বসে আছে খুঁজে বের করুন
                        var mySeat = seats.firstWhere(
                            (s) =>
                                s["userId"] ==
                                FirebaseAuth.instance.currentUser?.uid,
                            orElse: () => {});

                        if (mySeat.isEmpty || mySeat["userName"] == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("আপনি সিটে বসে নেই!")));
                          return;
                        }

                        // ২. ডাটাবেস থেকে বর্তমান প্লেয়ারদের লিস্ট আনুন
                        DatabaseEvent event = await FirebaseDatabase.instance
                            .ref("ludo_rooms/${widget.roomId}/players")
                            .once();
                        List<String> takenColors = [];

                        if (event.snapshot.value != null) {
                          Map<dynamic, dynamic> players =
                              event.snapshot.value as Map;
                          players.forEach((key, value) {
                            if (value["color"] != null) {
                              takenColors
                                  .add(value["color"].toString().toLowerCase());
                            }
                          });
                        }

                        // ৩. চেক করুন ইউজার কি অলরেডি জয়েন করেছে?
                        if (takenColors.length >= 4) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("লবি ফুল হয়ে গেছে!")));
                          return;
                        }

                        // ৪. কালার পুল থেকে যেটা নেওয়া হয়নি সেটি সিলেক্ট করুন
                        List<String> colorPool = [
                          "green",
                          "yellow",
                          "red",
                          "blue"
                        ];
                        String assignedColor = colorPool.firstWhere(
                            (color) => !takenColors.contains(color),
                            orElse: () => "green");

                        // ৫. ডাটাবেসে ডাটা আপডেট করুন
                        FirebaseDatabase.instance
                            .ref("ludo_rooms/${widget.roomId}/players/$myuID")
                            .set({
                          "name": mySeat["userName"],
                          "avatar": mySeat["userImage"],
                          "color": assignedColor,
                        }).then((_) {});
                      },
                      // গেম স্টার্ট লজিক: ডাটাবেসে আপডেট করলে সবার ফোনে গেম শুরু হবে
                      onStart: () {
                        FirebaseDatabase.instance
                            .ref("ludo_rooms/${widget.roomId}/lobby_status")
                            .update({
                          "showLobby": false,
                          "isStarted": true,
                        });
                      },

                      // 🎯 আপডেট করা onClose লজিক এখানে বসান:
                      onClose: () {
                        FirebaseDatabase.instance
                            .ref("ludo_rooms/${widget.roomId}/lobby_status")
                            .update({"showLobby": false});
                      },

                      onUpdateBet: (newBet) {
                        setState(() => currentBet = newBet);
                        FirebaseDatabase.instance
                            .ref("ludo_rooms/${widget.roomId}/lobby_status")
                            .update({"betAmount": newBet});
                      },
                    ),
                  ),

// ২. গেম বোর্ড (যখন গেম স্টার্ট হবে)
                if (isGameStarted)
                  Positioned(
                    top: 100,
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: MultiProvider(
                      providers: [
                        ChangeNotifierProvider(create: (_) => GameState()),
                        ChangeNotifierProvider(create: (_) => DiceModel()),
                      ],
                      child: Builder(
                        builder: (context) {
                          return StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('rooms')
                                .doc(widget.roomId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              // Consumer ব্যবহার করার ফলে এটি নিশ্চিত করে যে GameState প্রোভাইডার থেকে ডাটা পেয়েছে
                              return Consumer<GameState>(
                                builder: (context, gameState, child) {
                                  return GamePlay(
                                    GlobalKey(),
                                    gameState, // প্রোভাইডার থেকে পাওয়া লেটেস্ট স্টেট
                                    players: gameJoinedUsers,
                                    roomId: widget.roomId,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                if (showEntryEffect && currentEntryEffect != null)
                  EntryEffectHandler(
                    userName: entryUserName ?? "User",
                    userImage: entryUserImage,
                    activeFrameUrl: entryUserFrame,
                    effectUrl: currentEntryEffect!,
                    onFinished: () {
                      // এনিমেশন শেষ হলে নিরাপদে স্টেট আপডেট
                      if (mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() => showEntryEffect = false);
                        });
                      }
                    },
                  ),
                ..._buildFloatingEmojiAnimations(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap, // ক্লিক এখন কাজ করবে
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAdminAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildActivityRow(Map<String, dynamic> data) {
    String type = data['type'] ?? 'entry';
    bool isGift = type == 'gift';

    // সেন্ডার/এন্ট্রি ইউজারের ডাটা
    String uName = data['name'] ?? data['userName'] ?? "User";
    String sImg = data['senderImage'] ?? "";

    // রিসিভারের ডাটা (শুধুমাত্র গিফটের জন্য)
    String targetName = data['targetName'] ?? "";
    String rImg = data['receiverImage'] ?? "";

    // গিফটের লিংক (ইমেজ বা লটি)
    String giftImgUrl = data['giftImage'] ?? '';
    bool isLottie = giftImgUrl.toLowerCase().endsWith('.json');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- ১. সেন্ডার বা এন্ট্রি ইউজারের ছবি (বড় সাইজ) ---
          if (sImg.isNotEmpty)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white12,
              backgroundImage: NetworkImage(sImg),
            )
          else
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white12,
              child:
                  Icon(Icons.account_circle, size: 24, color: Colors.white54),
            ),

          const SizedBox(width: 10),

          // --- ২. নাম ও ডিটেইলস ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        uName,
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isGift ? "sent a gift" : "entered the room",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                if (isGift && targetName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Text(
                        "to ",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      if (rImg.isNotEmpty && rImg.startsWith('http')) ...[
                        CircleAvatar(
                          radius: 8,
                          backgroundImage: NetworkImage(rImg),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          targetName,
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // --- ৩. বড় সাইজের গিফট (লটি/ইমেজ) ও সংখ্যা (Count) ---
          if (isGift) ...[
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 40,
                  width: 40,
                  child: isLottie && giftImgUrl.isNotEmpty
                      ? Lottie.network(
                          giftImgUrl,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.card_giftcard,
                                  size: 28, color: Colors.orange),
                        )
                      : Image.network(
                          giftImgUrl,
                          height: 40,
                          width: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(
                              Icons.card_giftcard,
                              size: 28,
                              color: Colors.orange),
                        ),
                ),
                const SizedBox(width: 4),
                Text(
                  "x${data['giftCount'] ?? '1'}",
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildFloatingEmojiAnimations() {
    if (activeEmojis.isEmpty) return [];

    return activeEmojis.entries.map((entry) {
      int seatIndex = entry.key;
      String lottieUrl = entry.value;

      // ১. সিট ইনডেক্স ০ থেকে ১৪ (মোট ১৫টি সিট) এর মধ্যে আছে কি না তা নিখুঁতভাবে চেক করা
      if (seatIndex < 0 ||
          seatIndex >= 15 ||
          seatIndex >= seatPositions.length) {
        return const SizedBox();
      }

      // ২. পজিশন ক্যালকুলেট হয়েছে কি না চেক করা (০ এবং ১ নম্বর সিটের পজিশন সহ)
      if (seatPositions[seatIndex] == Offset.zero) {
        return const SizedBox();
      }

      // পজিশন সরাসরি সিট পজিশন লিস্ট থেকে নিন
      Offset pos = seatPositions[seatIndex];

      return Positioned(
        left: pos.dx - 40,
        top: pos.dy - 60,
        child: IgnorePointer(
          child: SizedBox(
            width: 80,
            height: 80,
            child: Lottie.network(
              lottieUrl,
              repeat: false,
              animate: true,
              errorBuilder: (ctx, err, stack) => const SizedBox(),
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
    // ১. চেক করছি বাবল কি স্ক্রিনে আছে?
    // যদি থাকে, তবে আমরা ডাটাবেস আপডেট বা এগোরা বন্ধ কিছুই করবো না।
    if (FloatingBubbleService.isMinimized) {
      // নোট: এখানে return করার মানে হলো নিচের কোনো ক্লিনআপ কোড এক্সিকিউট হবে না।
      super.dispose();
      return;
    }

    // ইউজার সম্পূর্ণ এক্সিট করলে রিয়েল-টাইম একটিভ এক্সপি টাইমারটি বন্ধ করা হলো
    _activeManager.stopTimer();

    // ইউজার যখন বাবল ছাড়া সরাসরি রুম থেকে বের হবে, তখন ডাটাবেজের মান নিখুঁতভাবে চেক করে কমানো হবে।
    final roomRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    roomRef.get().then((doc) {
      if (doc.exists && doc.data() != null) {
        int currentCount = doc.data()?['userCount'] ?? 0;
        // সেফটি লজিক: যদি কাউন্ট ১ বা তার কম হয়, তবে সরাসরি ০ হবে। আর বেশি থাকলে ১ কমবে।
        int newCount = (currentCount <= 1) ? 0 : (currentCount - 1);

        roomRef.update({'userCount': newCount}).catchError((e) {
          // এরর হ্যান্ডেলিং
        });
      }
    }).catchError((e) {
      // এরর হ্যান্ডেলিং
    });

    // ৩. ভিউয়ার লিস্ট থেকে ব্যবহারকারীকে সরিয়ে ফেলা
    _removeUserFromViewers();
    _clearUserLiveStatus();

    // ৪. স্ট্রীম এবং লুপ বন্ধ করা (সবগুলো পুরোনো এবং নতুন সাবস্ক্রিপশন এখানে নিরাপদে বাতিল করা হলো)
    _seatSubscription?.cancel();
    _emojiSubscription?.cancel();
    giftTimer?.cancel();
    _soulmateListener?.cancel();
    _marriageListener?.cancel();
    _videoGiftSubscription?.cancel();
    _volumeSubscription?.cancel();
    _roomSnapshotSubscription?.cancel();
    _entrySnapshotSubscription?.cancel();
    _ludoLobbySub?.cancel(); // 👈 নতুন যুক্ত হলো
    _ludoPlayersSub?.cancel(); // 👈 নতুন যুক্ত হলো
    _ludoGameStateSub?.cancel(); // 👈 নতুন যুক্ত হলো
    _roomEndedSub?.cancel(); // 👈 নতুন যুক্ত হলো
    _roomDataSnapshotSub?.cancel(); // 👈 নতুন যুক্ত হলো

    // ৫. সিটে বসে থাকলে সেটি অটোমেটিক খালি করে দেওয়া
    if (currentSeatIndex != -1) {
      // Firestore এবং Service আপডেট
      _roomService.updateSeatData(
          roomId: widget.roomId,
          seatIndex: currentSeatIndex,
          uName: "",
          uImage: "",
          isOccupied: false);

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

    // ৬. কন্ট্রোলার এবং পিকে ম্যানেজার বন্ধ করা
    if (isPKActive) pkManager.stopPK();
    _audioPlayer.dispose();
    _messageController.dispose();

    _scrollTimer?.cancel();
    _roomNameScrollController.dispose();
    _marqueeController.dispose();

    // ৭. স্ক্রিন অফ হওয়ার পারমিশন রিস্টোর করা (Wakelock বন্ধ করা)
    WakelockPlus.disable();

    // ৮. এগোরা ইঞ্জিন রিলিজ করা
    try {
      _agoraManager.engine.leaveChannel();
      _agoraManager.engine.release();
    } catch (e) {
      debugPrint("Agora Dispose Error: $e");
    }

    super.dispose();
  }

  Widget _buildTopNavBar() {
    final String myAuthId = FirebaseAuth.instance.currentUser?.uid ?? "";

    // ওনার চেক (আরও শক্তিশালী করা হলো)
    bool amIOwner = (ownerAuthId.toString() == myAuthId.toString().trim()) ||
        (myuID.toString().trim() == ownerId.toString().trim());

    // ২. অ্যাডমিন চেক (অ্যারো থেকে)
    // অ্যাডমিন চেক (adminList থেকে)
    bool amIAdmin = adminList
        .map((e) => e.toString().trim())
        .contains(myuID.toString().trim());

    bool hasPermission = amIOwner || amIAdmin;
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
                      } catch (e) {}
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white12,
                      backgroundImage: roomProfileImage.isNotEmpty
                          ? CachedNetworkImageProvider(roomProfileImage)
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
                        child: SizedBox(
                          height: 20,
                          width: 150,
                          child: ClipRect(
                            child: AnimatedBuilder(
                              animation: _marqueeController,
                              builder: (context, child) {
                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    // টেক্সটের মাপ বের করার জন্য
                                    final textPainter = TextPainter(
                                      text: TextSpan(
                                        text: roomName,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      textDirection: TextDirection.ltr,
                                    )..layout();

                                    double textWidth = textPainter.width;
                                    double gap = 50.0;
                                    double totalWidth = textWidth + gap;

                                    // কন্ট্রোলারের মান অনুযায়ী নিখুঁত লিনিয়ার অফসেট হিসাব
                                    double dx = -(_marqueeController.value *
                                        totalWidth);

                                    return Stack(
                                      children: [
                                        Positioned(
                                          left: dx,
                                          top: 0,
                                          bottom: 0,
                                          child: Row(
                                            children: [
                                              Text(
                                                roomName,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14),
                                              ),
                                              SizedBox(width: gap),
                                              Text(
                                                roomName,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14),
                                              ),
                                              SizedBox(width: gap),
                                              Text(
                                                roomName, // ট্রিপল টেক্সট লুপ ব্যবহার করায় মাঝখানে একটুও ব্রেক বা থামবে না
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                              return;
                            }

                            // ২. নিশ্চিতভাবে আপনার ৬-ডিজিটের আইডিটি নেওয়া হলো
                            // এখানে documentID ই আপনার কাস্টম uID
                            String activeUserID = userQuery.docs.first.id;

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
                          } catch (e) {}
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
            int giftCount = seatData != null ? (seatData['giftCount'] ?? 0) : 0;

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
            String uFrame = isOccupied
                ? (seatData['activeFrameUrl']?.toString() ?? "")
                : "";

            bool isTalking =
                isOccupied ? (seatData['isTalking'] == true) : false;
            bool isMicOn = isOccupied ? (seatData['isMicOn'] == true) : false;

            // ✅ কাপা বা হ্যাং হওয়া বন্ধের লজিক: ফ্রেম রেন্ডার হওয়ার পরে পজিশন আপডেট
            if (isOccupied && seatPositions[index] == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && seatKeys[index].currentContext != null) {
                  updateSeatPosition(index, seatKeys[index]);
                }
              });
            }

            return SeatWidget(
              index: index,
              isOccupied: isOccupied,
              giftCount: giftCount,
              // এটি বড় ব্যানারের স্টেট (ব্যানার অন থাকলে true, অফ থাকলে false)
              isGiftCounting: isGiftCounting,
              child: GestureDetector(
                key: seatKeys[index],
                onTap: () {
                  // ১. বর্তমান ইউজারের আইডি গুলো সংগ্রহ (NavBar এর মত করে)
                  final String myAuthId =
                      FirebaseAuth.instance.currentUser?.uid ?? "";
                  final String currentMyuID = myuID
                      .toString()
                      .trim(); // আপনার গ্লোবাল/ক্লাস ভেরিয়েবল myuID

                  // ২. মালিক বা এডমিন কি না চেক করা (NavBar এর শক্তিশালী লজিক অনুযায়ী)
                  bool isOwner =
                      (ownerAuthId.toString() == myAuthId.toString().trim()) ||
                          (currentMyuID == ownerId.toString().trim());

                  bool isAdmin = adminList
                      .map((e) => e.toString().trim())
                      .contains(currentMyuID);

                  // ১. চেক করা: ইউজার কি বর্তমানে এই সিটেই বসা?
                  if (currentSeatIndex == index) {
                    _showLeaveConfirmation(index);
                    return;
                  }

                  // ৪. সিট খালি থাকলে পপআপ মেনু ওপেন হবে
                  bool isSeatOccupied = isOccupied;
                  bool isLocked =
                      seatData != null ? (seatData['isLocked'] == true) : false;

                  if (!isSeatOccupied) {
                    if (isLocked && !isOwner && !isAdmin) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("This seat is locked!"),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ));
                      return;
                    }

                    // 🔥 প্রিমিয়াম গ্লাস লুক ডায়ালগ
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: '',
                      barrierColor: Colors.black54,
                      transitionDuration: const Duration(milliseconds: 250),
                      pageBuilder: (ctx, anim1, anim2) => Container(),
                      transitionBuilder: (ctx, anim1, anim2, child) {
                        return BackdropFilter(
                          filter: ImageFilter.blur(
                              sigmaX: 5, sigmaY: 5), // ব্লার ইফেক্ট
                          child: FadeTransition(
                            opacity: anim1,
                            child: Center(
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.75,
                                  decoration: BoxDecoration(
                                    // আধা-স্বচ্ছ গ্লাস ব্যাকগ্রাউন্ড
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 10),
                                      // Take the Mic বাটন
                                      _buildPremiumButton(
                                        text: "Take the Mic",
                                        icon: Icons.mic_external_on,
                                        textColor: Colors.cyanAccent,
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          sitOnSeat(index);
                                        },
                                      ),
                                      const Divider(
                                          color: Colors.white10, height: 1),
                                      // Lock the Mic বাটন
                                      if (isOwner || isAdmin) ...[
                                        _buildPremiumButton(
                                          text: isLocked
                                              ? "Unlock the Mic"
                                              : "Lock the Mic",
                                          icon: isLocked
                                              ? Icons.lock_open
                                              : Icons.lock_outline,
                                          textColor: Colors.amberAccent,
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            FirebaseDatabase.instance
                                                .ref()
                                                .child(
                                                    'rooms/${widget.roomId}/seats/$index')
                                                .update({
                                              'isLocked': !isLocked,
                                            });
                                          },
                                        ),
                                        const Divider(
                                            color: Colors.white10, height: 1),
                                      ],
                                      // Cancel বাটন
                                      _buildPremiumButton(
                                        text: "Cancel",
                                        icon: Icons.close,
                                        textColor: Colors.white70,
                                        onTap: () => Navigator.pop(ctx),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  // ৪. সিট যদি খালি না থাকে (অন্য ইউজার বসা থাকে)
                  else {
                    // seatData থেকে সরাসরি আইডি না নিয়ে StreamBuilder ব্যবহার করা হয়েছে যাতে তথ্য রিয়েল-টাইম থাকে
                    String seatUserId = seatData?['userId']?.toString() ??
                        seatData?['uID']?.toString() ??
                        '';

                    if (seatUserId.isEmpty) return;

                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: 'Dismiss',
                      barrierColor: Colors.black54,
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (ctx, anim1, anim2) {
                        return Center(
                          child: Material(
                            color: Colors.transparent,
                            child: StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(seatUserId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData ||
                                    snapshot.data?.data() == null) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                var userData = snapshot.data!.data()
                                    as Map<String, dynamic>;

                                // ডাটা রিট্রিভ
                                String seatUserName =
                                    userData['name'] ?? 'User';
                                String seatUserPhoto =
                                    userData['profilePic'] ?? '';
                                String activeFrame =
                                    userData['activeFrame'] ?? "";
                                int userXp = userData['vip_xp'] ?? 0;
                                int userExpiry = userData['vip_expiry'] ?? 0;
                                bool hasPremiumCard =
                                    userData['hasPremiumCard'] ?? false;
                                int vipLevel =
                                    getVipLevelFromData(userXp, userExpiry);

                                return Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.85,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 30),

                                      // ১. প্রোফাইল পিকচার ও রিয়েল টাইপ অবতার ফ্রেম
                                      SizedBox(
                                        height:
                                            100, // এখানে ফিক্সড হাইট দিলে নাম আর নিচে নামবে না
                                        child: Stack(
                                          alignment: Alignment.center,
                                          clipBehavior: Clip
                                              .none, // ফ্রেম যেন কেটে না যায়
                                          children: [
                                            // প্রোফাইল পিকচার
                                            CircleAvatar(
                                              radius: 35,
                                              backgroundImage:
                                                  NetworkImage(seatUserPhoto),
                                            ),

                                            // অবতার ফ্রেম (এটি এখন প্রোফাইল পিকের উপর ভাসমান থাকবে)
                                            if (activeFrame.isNotEmpty)
                                              Positioned(
                                                top:
                                                    -20, // ফ্রেমকে সামান্য উপরে তুলে দেওয়া হলো যাতে নিচের নাম ডিস্টার্ব না হয়
                                                child: SizedBox(
                                                  width: 153,
                                                  height: 160,
                                                  child: activeFrame
                                                          .contains('.json')
                                                      ? Lottie.network(
                                                          activeFrame,
                                                          fit: BoxFit.contain)
                                                      : Image.network(
                                                          activeFrame,
                                                          fit: BoxFit.contain),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(seatUserName,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      Text("ID: $seatUserId",
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12)),

                                      const SizedBox(height: 15),

                                      // ২. ব্যাজ সেকশন (VIP & Premium)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (vipLevel > 0)
                                            Image.network(getVipBadge(vipLevel),
                                                width: 35, height: 35),
                                          if (hasPremiumCard)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 8.0),
                                              child: Image.network(
                                                  premiumBadgeUrl,
                                                  width: 35,
                                                  height: 35),
                                            ),
                                        ],
                                      ),

                                      const SizedBox(height: 25),

                                      // ৩. অ্যাকশন বাটনস (Follow, Chat, Gift) - কার্যকরী onTap সহ
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildProfileActionButton(
                                              icon: Icons.person_add,
                                              label: "Follow",
                                              color: Colors.blueAccent,
                                              onTap: () {
                                                Navigator.pop(context);
                                                _toggleFollowUser(seatUserId);
                                              },
                                            ),
                                            _buildProfileActionButton(
                                              icon: Icons.chat_bubble_outline,
                                              label: "Chat",
                                              color: Colors.purpleAccent,
                                              onTap: () {
                                                Navigator.pop(context);
                                                _goToInbox(
                                                    seatUserId, seatUserName);
                                              },
                                            ),
                                            _buildProfileActionButton(
                                              icon: Icons.card_giftcard,
                                              label: "Gift",
                                              color: Colors.orangeAccent,
                                              onTap: () {
                                                Navigator.pop(context);
                                                _openGiftPanel(seatUserId);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),

                                      // ৪. এডমিন কন্ট্রোল (শুধুমাত্র ওনার বা এডমিনদের জন্য)
                                      if (isOwner || isAdmin) ...[
                                        const Divider(
                                            color: Colors.white10, height: 30),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 20),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              _buildAdminAction(
                                                icon: Icons.verified_user,
                                                label: "Admin",
                                                color: adminList
                                                        .contains(seatUserId)
                                                    ? Colors.green
                                                    : Colors.white70,
                                                onTap: () => _toggleAdmin(
                                                    seatUserId,
                                                    adminList
                                                        .contains(seatUserId)),
                                              ),
                                              // আপনার রুমের যেখানে লুপ চলছে বা বাটন রেন্ডার হচ্ছে, সেখানে নিশ্চয়ই 'index' বা 'i' নামে ইনডেক্সটি আছে।
                                              _buildAdminAction(
                                                // লজিক: মাইক অফ (false) হলে Mic Off আইকন এবং লাল কালার, অন (true) হলে Mic আইকন এবং সবুজ কালার
                                                icon: (seatData?['isMicOn'] ==
                                                        false)
                                                    ? Icons.mic_off
                                                    : Icons.mic,
                                                label: (seatData?['isMicOn'] ==
                                                        false)
                                                    ? "Unmute"
                                                    : "Mute",
                                                color: (seatData?['isMicOn'] ==
                                                        false)
                                                    ? Colors.redAccent
                                                    : Colors.greenAccent,
                                                onTap: () async {
                                                  int sIndex =
                                                      index; // লুপের ইনডেক্স
                                                  debugPrint(
                                                      "--- Mute Button Clicked for Index: $sIndex ---");

                                                  String seatUserId =
                                                      seatData?['userId']
                                                              ?.toString() ??
                                                          seatData?['uID']
                                                              ?.toString() ??
                                                          '';
                                                  final String currentUserId =
                                                      FirebaseAuth
                                                              .instance
                                                              .currentUser
                                                              ?.uid ??
                                                          '';

                                                  // বর্তমান অবস্থা থেকে নতুন অবস্থা নির্ধারণ
                                                  bool currentMicStatus =
                                                      seatData?['isMicOn'] ??
                                                          true;
                                                  bool newMicStatus =
                                                      !currentMicStatus;

                                                  try {
                                                    await HapticFeedback
                                                        .lightImpact();

                                                    // ফায়ারবেস আপডেট
                                                    await FirebaseDatabase
                                                        .instance
                                                        .ref(
                                                            'rooms/${widget.roomId}/seats/$sIndex')
                                                        .update({
                                                      'isMicOn': newMicStatus,
                                                      'isTalking': false,
                                                    });

                                                    // যদি নিজের মাইক হয়, তবে লোকাল অ্যাগোরা কন্ট্রোল
                                                    if (seatUserId ==
                                                        currentUserId) {
                                                      // newMicStatus 'false' হলে মিউট হবে (অর্থাৎ! অন), তাই এখানে লজিক মিলিয়ে নিন
                                                      await _agoraManager
                                                          .toggleMic(
                                                              newMicStatus ==
                                                                  false);
                                                    }

                                                    debugPrint(
                                                        "Update Successful: Mic is now ${newMicStatus ? 'ON' : 'OFF'}");
                                                  } catch (e) {
                                                    debugPrint(
                                                        "Admin Control Error: $e");
                                                  }
                                                },
                                              ),

                                              _buildAdminAction(
                                                icon: Icons.gavel,
                                                label: "Kick",
                                                color: Colors.redAccent,
                                                onTap: () {
                                                  // ডায়ালগ বন্ধ করা
                                                  Navigator.pop(context);
                                                  // কিক ফাংশন কল করা
                                                  _kickUserFromRoom(seatUserId);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      // ব্লার এবং ফেড এনিমেশন
                      transitionBuilder: (ctx, anim1, anim2, child) {
                        return BackdropFilter(
                          filter: ImageFilter.blur(
                              sigmaX: 8 * anim1.value, sigmaY: 8 * anim1.value),
                          child: FadeTransition(opacity: anim1, child: child),
                        );
                      },
                    );
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // ✅ কন্টেন্ট অনুযায়ী সাইজ হবে
                  children: [
                    // এর ফলে ভিউয়ার লিস্ট বা পাশের উইজেটগুলো কাঁপবে না।
                    RepaintBoundary(
                      child: VoiceRipple(
                        isTalking: isTalking,
                        isMicOn:
                            isMicOn, // তোমার কাছে থাকা মাইকের স্টেট ভেরিয়েবলটি এখানে দাও
                        isOccupied: isOccupied,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isOccupied
                                      ? Colors.cyanAccent
                                      : Colors.white10,
                                ),
                                boxShadow: const [],
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.black45,
                                backgroundImage:
                                    (isOccupied && uImage.isNotEmpty)
                                        ? NetworkImage(uImage)
                                        : null,
                                child: (isOccupied)
                                    ? (uImage.isEmpty
                                        ? const Icon(Icons.person,
                                            color: Colors.white24, size: 25)
                                        : null)
                                    : Icon(
                                        // 🔥 লক আইকন চেক (খালি সিটের জন্য)
                                        (seatData != null &&
                                                seatData['isLocked'] == true)
                                            ? Icons.lock
                                            : Icons.chair_rounded,
                                        color: (seatData != null &&
                                                seatData['isLocked'] == true)
                                            ? Colors.redAccent
                                            : Colors.white12,
                                        size: 22,
                                      ),
                              ),
                            ),
                            // ২. 🔥 ফ্রেম (OverflowBox ব্যবহার করে)
                            if (isOccupied && uFrame.isNotEmpty)
                              IgnorePointer(
                                child: OverflowBox(
                                  maxWidth: 130,
                                  maxHeight: 130,
                                  child: SizedBox(
                                    width: 100, // আপনার আগের সাইজ
                                    height: 100,
                                    child: uFrame.contains('.json') // লটি চেক
                                        ? Lottie.network(
                                            uFrame,
                                            fit: BoxFit.contain,
                                            errorBuilder: (c, e, s) =>
                                                const SizedBox.shrink(),
                                          )
                                        : Image.network(
                                            uFrame,
                                            fit: BoxFit.contain,
                                            errorBuilder: (c, e, s) =>
                                                const SizedBox.shrink(),
                                          ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 0),
                    // ✅ ইউজার নেম
                    Text(
                      isOccupied ? uName : "${index + 1}",
                      style: TextStyle(
                        fontSize: 10,
                        color: isOccupied ? Colors.white : Colors.white38,
                        fontWeight:
                            isOccupied ? FontWeight.bold : FontWeight.normal,
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomActionArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          // ১. ইমোজি বাটন 😄
          // ১. ইমোজি বাটন 😄 (সম্পূর্ণ অপরিবর্তিত ও নিরাপদ)
          buildCircularIcon(
            Icons.emoji_emotions_outlined,
            const Color.fromARGB(255, 250, 143, 2),
            () async {
              final String currentAuthUid =
                  FirebaseAuth.instance.currentUser?.uid ?? "";

              // Firestore থেকে ইউজারের আসল ডকুমেন্ট আইডি বের করা
              var userSnap = await FirebaseFirestore.instance
                  .collection('users')
                  .where('authUID', isEqualTo: currentAuthUid)
                  .limit(1)
                  .get();

              String myActualId =
                  userSnap.docs.isNotEmpty ? userSnap.docs.first.id : "";

              int mySeatIndex = -1;

              // ১. প্রথমে সরাসরি রিয়েলটাইম ডাটাবেস থেকে সিকিউরড ও ডাইরেক্ট চেক করা (০ থেকে ১৪ পর্যন্ত সিটের জন্য)
              final roomSeatsSnap = await FirebaseDatabase.instance
                  .ref('rooms/${widget.roomId}/seats')
                  .get();

              if (roomSeatsSnap.exists) {
                final rawData = roomSeatsSnap.value;

                if (rawData is Map) {
                  rawData.forEach((key, value) {
                    if (value is Map) {
                      var sUid = value['authUID'] ??
                          value['uID'] ??
                          value['userId'] ??
                          value['uid'];
                      if (sUid != null &&
                          (sUid.toString() == myActualId ||
                              sUid.toString() == currentAuthUid)) {
                        mySeatIndex = int.tryParse(key.toString()) ?? -1;
                      }
                    }
                  });
                } else if (rawData is List) {
                  for (int i = 0; i < rawData.length; i++) {
                    var value = rawData[i];
                    if (value is Map) {
                      var sUid = value['authUID'] ??
                          value['uID'] ??
                          value['userId'] ??
                          value['uid'];
                      if (sUid != null &&
                          (sUid.toString() == myActualId ||
                              sUid.toString() == currentAuthUid)) {
                        mySeatIndex = i;
                        break;
                      }
                    }
                  }
                }
              }

              // ২. যদি রিয়েলটাইম ডাটাবেসে না পাওয়া যায়, তবে লোকাল `seats` লিস্ট চেক করা
              if (mySeatIndex == -1 && seats.isNotEmpty) {
                for (int i = 0; i < seats.length; i++) {
                  var s = seats[i];
                  if (s != null && s is Map) {
                    var seatUid =
                        s['authUID'] ?? s['uID'] ?? s['userId'] ?? s['uid'];
                    if (seatUid != null &&
                        (seatUid.toString() == myActualId ||
                            seatUid.toString() == currentAuthUid)) {
                      mySeatIndex = i;
                      break;
                    }
                  }
                }
              }

              if (mySeatIndex != -1) {
                EmojiHandler.showPicker(
                  context: context,
                  seatIndex: mySeatIndex,
                  onEmojiSelected: (index, url) async {
                    // সুনিশ্চিত করার জন্য active_emojis এবং seats দুটো জায়গাতেই একসাথে ডাটা পুশ করা হলো
                    DatabaseReference emojiRef = FirebaseDatabase.instance
                        .ref('rooms/${widget.roomId}/active_emojis/$index');

                    await emojiRef.set({
                      'currentEmoji': url,
                      'emojiTime': ServerValue.timestamp,
                    });

                    // পাশাপাশি সিটের ভেতরেও আপডেট রাখা হলো যাতে পুরোনো কোনো সিংক ইস্যু না থাকে
                    await FirebaseDatabase.instance
                        .ref('rooms/${widget.roomId}/seats/$index')
                        .update({
                      'currentEmoji': url,
                      'emojiTime': ServerValue.timestamp,
                    });

                    // ৪ সেকেন্ড পর ডাটাবেস থেকে ইমোজি মুছে ফেলা
                    Future.delayed(const Duration(seconds: 4), () {
                      emojiRef.remove();
                      FirebaseDatabase.instance
                          .ref('rooms/${widget.roomId}/seats/$index')
                          .child('currentEmoji')
                          .remove();
                    });
                  },
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Take seat first")));
              }
            },
          ),

          const SizedBox(width: 5),

          // ২. আপনার চাওয়া নতুন ফিচার: সরাসরি মেসেজ ইনপুট এরিয়া বদলে শুধু ✉️ বাটন
          _buildCircularIcon(
              Icons.mail_outline, const Color.fromARGB(191, 246, 215, 19), () {
            // বাটনে ক্লিক করলে ইনপুট বক্সটি নিচ থেকে পপ-আপ হবে
            _showChatInputBottomSheet();
          }),

          const SizedBox(width: 5),

          // ৩. স্টার/গিফট টুলস বাটন ⭐ (সম্পূর্ণ অপরিবর্তিত ও নিরাপদ)
          _buildCircularIcon(Icons.star, Colors.purpleAccent, () {
            // Icons.star ঠিক রাখা হলো
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: FloatingRoomTools(
                  onGiftCountStart: (minutes, theme) {
                    _startGiftCounting(minutes, theme);
                  },
                  seats: seats,
                  isPKActive: isPKActive,
                  onStartPK: _startPKBattle,
                  ownerId: ownerId,
                  myuID: myuID,
                  adminList: adminList,
                  gameJoinedUsers: seats
                      .where((s) => s["isOccupied"] == true)
                      .map((s) => {
                            "name": s["userName"].toString(),
                            "avatar": s["userImage"].toString()
                          })
                      .toList(),
                  // আপনার বাটন লজিক:
                  onOpenLudo: () {
                    // শুধু ডাটাবেস আপডেট হবে, লবি ওপেন করবে আপনার initState এর লিসেনার
                    FirebaseDatabase.instance
                        .ref("ludo_rooms/${widget.roomId}/lobby_status")
                        .set({
                      "showLobby": true,
                      "isStarted": false,
                      "betAmount": 2,
                    });
                    Navigator.pop(context); // বটম শিট বন্ধ হবে
                  },
                ),
              ),
            );
          }),
          const SizedBox(width: 5),

          // ৪. রুম মিউট বাটন 🔊 (StatefulBuilder সহ অপ্টিমাইজড)
          StatefulBuilder(
            builder: (context, setButtonState) {
              return GestureDetector(
                onTap: () {
                  setButtonState(() {
                    isRoomMuted = !isRoomMuted;
                  });
                  // পুরো রুমের setState বাদ দিয়ে শুধুমাত্র অডিও টগল করা হলো
                  _agoraManager.muteAllRemoteAudio(isRoomMuted);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1), // গ্লাস কালার
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          Colors.white.withOpacity(0.3), // বর্ডার গ্লাস ইফেক্ট
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    isRoomMuted ? Icons.volume_off : Icons.volume_up,
                    color: isRoomMuted ? Colors.redAccent : Colors.greenAccent,
                    size: 20,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 5),

          // ৫. মাইক কন্ট্রোল বাটন (StatefulBuilder সহ অপ্টিমাইজড)
          StatefulBuilder(
            builder: (context, setButtonState) {
              return GestureDetector(
                onTap: () async {
                  if (currentSeatIndex == -1) return;
                  try {
                    HapticFeedback.lightImpact();
                  } catch (_) {}

                  bool newMicState = !isMicOn;

                  // শুধু এই বাটনের স্টেট আপডেট করা হলো যাতে পুরো রুম রি-রেন্ডার না হয়
                  setButtonState(() {
                    isMicOn = newMicState;
                    if (!newMicState &&
                        currentSeatIndex >= 0 &&
                        currentSeatIndex < seats.length) {
                      seats[currentSeatIndex]["isTalking"] = false;
                    }
                  });

                  try {
                    // অ্যাগোরা এবং ফায়ারবেস ব্যাকগ্রাউন্ডে আপডেট করুন
                    await _agoraManager.toggleMic(!newMicState);
                    await FirebaseDatabase.instance
                        .ref('rooms/${widget.roomId}/seats/$currentSeatIndex')
                        .update({'isMicOn': newMicState});
                  } catch (e) {
                    // এরর হলে আগের অবস্থায় ফিরিয়ে নিন
                    setButtonState(() {
                      isMicOn = !newMicState;
                    });
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.all(8), // বাটন সাইজ ঠিক রাখতে প্যাডিং
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1), // গ্লাস ব্যাকগ্রাউন্ড
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3), // গ্লাস বর্ডার
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    isMicOn ? Icons.mic : Icons.mic_off,
                    color: isMicOn ? Colors.greenAccent : Colors.redAccent,
                    size: 22,
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 5),
          // ৬. মিউজিক বাটন (StatefulBuilder সহ অপ্টিমাইজড)
          StatefulBuilder(
            builder: (context, setButtonState) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (modalContext) => MusicPlayerWidget(
                        onMusicSelect: (path) async {
                          // ✅ সেফটি চেক: ফাইল সিলেক্ট করার পর উইজেট লাইভ আছে কি না নিশ্চিত করা
                          if (!mounted) return;

                          // শুধু এই বাটনের স্টেট এবং মূল স্ক্রিনের স্টেট আপডেট করা হলো
                          setButtonState(() {
                            isFloatingPlayerVisible = true;
                          });
                          setState(() {
                            currentMusicUrl = path;
                            isRoomMusicPlaying = true;
                          });

                          try {
                            await _agoraManager.engine.stopAudioMixing();
                            await _agoraManager.engine.startAudioMixing(
                                filePath: path, loopback: false, cycle: 1);
                            await _agoraManager.engine
                                .adjustAudioMixingVolume(100);
                          } catch (e) {
                            debugPrint("Audio Mixing Error: $e");
                          }
                        },
                        onVolumeChange: (volume) => _agoraManager.engine
                            .adjustAudioMixingVolume(volume.toInt()),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.music_note,
                    color: isFloatingPlayerVisible
                        ? const Color.fromARGB(255, 164, 86, 243)
                        : const Color.fromARGB(255, 117, 225, 244),
                    size: 22,
                  ),
                ),
              );
            },
          ),
          // ৭. এনিমেটেড গিফট বাটন 🎁 (নড়াচড়া করার ফিচার সহ)
          _buildAnimatedGiftButton(),

          // ৮. গেম বাটন 🎮 (সম্পূর্ণ অপরিবর্তিত ও নিরাপদ)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: false,
                backgroundColor: Colors.transparent,
                builder: (c) => SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: GamePanelView(roomId: widget.roomId),
                ),
              ),
              child: const Icon(Icons.videogame_asset,
                  color: Colors.orange, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  void _showChatInputBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // কিবোর্ড এনিমেশনের সাথে সাথে সাথে ইনস্ট্যান্ট পপ-আপ হওয়ার জন্য:
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
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

                  // ১. সাথে সাথে চ্যাট ইনপুট ক্লিয়ার করে এবং শিট বন্ধ করে ইউআই ইনস্ট্যান্ট ফ্রি করে দেওয়া হলো
                  _messageController.clear();
                  if (Navigator.canPop(context)) Navigator.pop(context);

                  // ২. ব্যাকগ্রাউন্ডে ফায়ারবেসে মেসেজ পাঠানো হচ্ছে (যাতে ইউআইতে কোনো ল্যাগ না করে)
                  final currentUser = FirebaseAuth.instance.currentUser;
                  final String authUID = currentUser?.uid ?? "";

                  // যদি আপনার লোকাল ভেরিয়েবলে ইউজারের নাম/ছবি সেভ করা থাকে তা ব্যবহার করবেন,
                  // অথবা ব্যাকগ্রাউন্ডে কুয়েরি চালাবেন যেন ইনস্ট্যান্ট ফিল হয়:
                  FirebaseFirestore.instance
                      .collection('users')
                      .where('authUID', isEqualTo: authUID)
                      .limit(1)
                      .get()
                      .then((userQuery) {
                    String finalName = currentUser?.displayName ?? "User";
                    String finalImage = currentUser?.photoURL ?? "";
                    String finalSenderId = authUID;

                    if (userQuery.docs.isNotEmpty) {
                      var uData = userQuery.docs.first.data();
                      finalName = uData['name'] ?? finalName;
                      finalImage = uData['profilePic'] ?? finalImage;
                      finalSenderId = userQuery.docs.first.id;
                    }

                    FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(widget.roomId)
                        .collection('messages')
                        .add({
                      'userName': finalName,
                      'profilePic': finalImage,
                      'text': msgText,
                      'senderId': finalSenderId,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // মেসেজ রো উইজেট (সম্পূর্ণ অপরিবর্তিত ও নিরাপদ)
  Widget _buildMessageRow(Map<String, dynamic> msg) {
    // আপনার দেওয়া ফিল্ড নেম অনুযায়ী ডাটা নেওয়া
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

  // অ্যানিমেটেড গিফট বাটন উইজেট (সম্পূর্ণ ফিচার অক্ষুণ্ন রেখে নিরাপদ ও অপ্টিমাইজড)
  Widget _buildAnimatedGiftButton() {
    return TweenAnimationBuilder<double>(
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

          // ১. নিজের তথ্য এবং ব্যালেন্স আনা (লিমিট ১ দিয়ে অপ্টিমাইজড)
          var userQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('authUID', isEqualTo: currentAuthUID)
              .limit(1)
              .get();

          int currentBalance = 0;
          String senderName = "User";
          String senderImgUrl = "";
          String senderDocID = "";

          if (userQuery.docs.isNotEmpty) {
            final doc = userQuery.docs.first;
            final data = doc.data();
            senderDocID = doc.id;
            currentBalance = (data['diamonds'] ?? 0).toInt();
            senderName = data['name'] ?? data['userName'] ?? "User";
            senderImgUrl =
                data['profilePic'] ?? data['image'] ?? data['userImage'] ?? "";
          }

          if (!context.mounted) return;

          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => GiftBottomSheet(
              roomId: widget.roomId,
              diamondBalance: currentBalance,
              currentSeats: List.from(seats),
              onGiftSend: (gift, count, target) async {
                String giftImg = gift['lottieUrl'] ??
                    gift['lottie'] ??
                    gift['animationUrl'] ??
                    gift['image'] ??
                    gift['icon'] ??
                    "";
                String receiverImgUrl = "";
                String receiverDocID = "";

                // ২. রিসিভারের আইডি এবং ছবি খোঁজা
                if (target == "All Room" || target == "All Mic") {
                  receiverDocID = target;
                } else {
                  var targetSeat = seats.firstWhere(
                    (s) => (s['userName'] == target || s['name'] == target),
                    orElse: () => <String, dynamic>{},
                  );

                  if (targetSeat.isNotEmpty) {
                    receiverImgUrl = targetSeat['profilePic'] ??
                        targetSeat['userImage'] ??
                        "";
                    receiverDocID =
                        (targetSeat['uID'] ?? targetSeat['userId'] ?? "")
                            .toString();
                  }
                }

                // ৩. ট্রানজেকশন শুরু
                int unitPrice = (gift['price'] ?? 0).toInt();
                int totalAmount = unitPrice * count;

                try {
                  bool isFree =
                      (gift['isFree'] == true) || (gift['expiry'] != null);

                  if (!isFree && currentBalance < totalAmount) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "পর্যাপ্ত ডায়মন্ড নেই! খরচ: $totalAmount, আছে: $currentBalance"),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    return;
                  }

                  if (senderDocID.isNotEmpty && receiverDocID.isNotEmpty) {
                    // বক্স লজিকসহ মূল গিফট প্রসেসর কল
                    await GiftLogicHelper.processGift(
                      senderAuthId: senderDocID,
                      targetAuthId: receiverDocID,
                      gift: gift,
                      count: count,
                      roomId: widget.roomId,
                      senderName: senderName,
                      roomOwnerAuthId: widget.ownerId,
                      senderImage: senderImgUrl,
                      receiverImage: receiverImgUrl,
                      giftName: gift['name'] ?? "Gift",
                    );

                    // রুমের এক্সপি আপডেট
                    if (!isFree && totalAmount > 0) {
                      await RoomLevelHelper.addXpToRoom(
                          widget.roomId, totalAmount);
                    }

                    // পিকে স্কোর আপডেট লজিক
                    if (isPKActive && currentPKData != null) {
                      if (receiverDocID ==
                              currentPKData!['u1']?['uID']?.toString() ||
                          receiverDocID ==
                              currentPKData!['u1']?['userId']?.toString()) {
                        await FirebaseFirestore.instance
                            .collection('rooms')
                            .doc(widget.roomId)
                            .update({
                          'pkData.score1': FieldValue.increment(totalAmount),
                        });
                      } else if (receiverDocID ==
                              currentPKData!['u2']?['uID']?.toString() ||
                          receiverDocID ==
                              currentPKData!['u2']?['userId']?.toString()) {
                        await FirebaseFirestore.instance
                            .collection('rooms')
                            .doc(widget.roomId)
                            .update({
                          'pkData.score2': FieldValue.increment(totalAmount),
                        });
                      }
                    }

                    // এক্সপি ডিস্ট্রিবিউশন লজিক
                    if (!isFree && totalAmount > 0) {
                      final firestore = FirebaseFirestore.instance;
                      int calculatedXp = totalAmount ~/ 700;

                      if (calculatedXp > 0) {
                        await firestore
                            .collection('users')
                            .doc(senderDocID)
                            .update({
                          'totalGiftXp': FieldValue.increment(calculatedXp),
                        });

                        await firestore
                            .collection('users')
                            .doc(receiverDocID)
                            .update({
                          'totalActiveXp': FieldValue.increment(calculatedXp),
                        });
                      }
                    }
                  } else {
                    return;
                  }
                } catch (e) {
                  return;
                }

                // সিট কাউন্ট আপডেট লজিক
                if (receiverDocID.isNotEmpty &&
                    target != "All Room" &&
                    target != "All Mic") {
                  int seatIndex = seats.indexWhere((s) =>
                      (s['uID']?.toString() == receiverDocID ||
                          s['userId']?.toString() == receiverDocID));

                  if (seatIndex != -1) {
                    await FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(widget.roomId)
                        .update({
                      'seats.$seatIndex.giftCount': FieldValue.increment(count),
                    });
                  }
                }

                // ৪. সফল হলে UI আপডেট
                if (context.mounted) {
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

                bool isFree =
                    (gift['isFree'] == true) || (gift['expiry'] != null);

                // ৫. সোলমেট রিকোয়েস্ট ও এক্সপি আপডেট প্রসেসর
                if (gift['id'] == 'soulmate_special') {
                  try {
                    String receiverAuthUID = "";

                    if (seats.isNotEmpty) {
                      for (var seat in seats) {
                        if (seat["uID"]?.toString() == receiverDocID ||
                            seat["userId"]?.toString() == receiverDocID ||
                            seat["authUID"]?.toString() == receiverDocID) {
                          receiverAuthUID = seat["userId"]?.toString() ??
                              seat["authUID"]?.toString() ??
                              '';
                          break;
                        }
                      }
                    }
                    if (receiverAuthUID.isEmpty)
                      receiverAuthUID = receiverDocID;

                    if (receiverAuthUID.isNotEmpty &&
                        receiverAuthUID.length > 15) {
                      await FirebaseFirestore.instance
                          .collection('soulmate_requests')
                          .doc(receiverAuthUID)
                          .set({
                        'fromId': senderDocID,
                        'fromAuthUID':
                            FirebaseAuth.instance.currentUser?.uid ?? '',
                        'fromName': senderName,
                        'fromImg': senderImgUrl,
                        'timestamp': FieldValue.serverTimestamp(),
                        'status': 'pending',
                      });
                    }
                  } catch (soulmateError) {}
                } else {
                  // সোলমেট এক্সপি আপডেট লজিক
                  if (!isFree &&
                      totalAmount > 0 &&
                      target != "All Room" &&
                      target != "All Mic") {
                    String receiverSixDigitId = "";
                    if (seats.isNotEmpty) {
                      for (var seat in seats) {
                        if (seat["uID"]?.toString() == receiverDocID ||
                            seat["userId"]?.toString() == receiverDocID ||
                            seat["authUID"]?.toString() == receiverDocID) {
                          receiverSixDigitId = seat["uID"]?.toString() ?? "";
                          break;
                        }
                      }
                    }

                    if (receiverSixDigitId.isEmpty) {
                      receiverSixDigitId = receiverDocID;
                    }

                    String senderSixDigitId = senderDocID;

                    if (senderSixDigitId.isNotEmpty &&
                        receiverSixDigitId.isNotEmpty) {
                      SoulmateXpService.updateSoulmateXP(
                          senderSixDigitId, receiverSixDigitId, totalAmount);
                    }
                  }
                }

                // ম্যারেজ রিং রিকোয়েস্ট প্রসেসর
                if (gift['type'] == 'marriage_ring' ||
                    gift['type'] == 'vip_marriage') {
                  try {
                    String receiverAuthUID = "";
                    String myGender = "Unknown";
                    String partnerGender = "Unknown";
                    final String myCurrentAuthUID =
                        FirebaseAuth.instance.currentUser?.uid ?? '';

                    if (seats.isNotEmpty) {
                      for (var seat in seats) {
                        if (seat["userId"] == myCurrentAuthUID ||
                            seat["authUID"] == myCurrentAuthUID) {
                          myGender = seat["gender"]?.toString() ?? "Unknown";
                        }

                        if (seat["uID"]?.toString() == receiverDocID ||
                            seat["userId"]?.toString() == receiverDocID ||
                            seat["authUID"]?.toString() == receiverDocID) {
                          receiverAuthUID = seat["userId"]?.toString() ??
                              seat["authUID"]?.toString() ??
                              '';
                          partnerGender =
                              seat["gender"]?.toString() ?? "Unknown";
                        }
                      }
                    }

                    if (receiverAuthUID.isEmpty) {
                      receiverAuthUID = receiverDocID;
                    }

                    if (myGender != "Unknown" &&
                        partnerGender != "Unknown" &&
                        myGender.trim().toLowerCase() ==
                            partnerGender.trim().toLowerCase()) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "দুঃখিত! একই লিঙ্গের আইডি দিয়ে রিং পাঠানো বা বিয়ে সম্ভব নয়। ❌"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }

                    var myUserDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(myCurrentAuthUID)
                        .get();
                    var targetUserDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(receiverAuthUID)
                        .get();

                    String? myCurrentPartner =
                        myUserDoc.data()?['marriagePartnerId'];
                    String? targetCurrentPartner =
                        targetUserDoc.data()?['marriagePartnerId'];

                    if (myCurrentPartner != null &&
                        myCurrentPartner == receiverAuthUID) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(receiverAuthUID)
                          .collection('my_special')
                          .add({
                        'name': gift['name'] ?? 'Marriage Ring',
                        'image_url': gift['icon'] ?? '',
                        'type': 'Marriage Ring',
                        'expiryDate': Timestamp.fromDate(
                            DateTime.now().add(const Duration(days: 30))),
                        'receivedAt': FieldValue.serverTimestamp(),
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "আপনার পার্টনারের জন্য রিংটি সরাসরি ব্যাকপ্যাকে (Special) যুক্ত করা হয়েছে! 🎒💍"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      return;
                    }

                    if ((myCurrentPartner != null &&
                            myCurrentPartner.isNotEmpty) ||
                        (targetCurrentPartner != null &&
                            targetCurrentPartner.isNotEmpty)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "রিং পাঠানো সম্ভব নয়! অলরেডি অন্য পার্টনারের সাথে রিলেশন বিদ্যমান আছে। ❌"),
                            backgroundColor: Colors.deepOrange,
                          ),
                        );
                      }
                      return;
                    }

                    if (receiverAuthUID.isNotEmpty &&
                        receiverAuthUID.length > 15) {
                      String response =
                          await MarriageService().sendMarriageRing(
                        receiverAuthUID: receiverAuthUID,
                        senderDocID: senderDocID,
                        senderAuthUID: myCurrentAuthUID,
                        senderName: senderName,
                        senderImgUrl: senderImgUrl,
                        ringName: gift['name'] ?? 'Marriage Ring',
                        ringIconUrl: gift['icon'] ?? '',
                        myGender: myGender,
                        partnerGender: partnerGender,
                      );

                      if (response != "SUCCESS" && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(response),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  } catch (marriageError) {}
                }

                // ফায়ারবেস রুম ব্যানার এবং ডেইলি পয়েন্ট আপডেট
                int pointsToIncrement = totalAmount ~/ 250;

                Map<String, dynamic> roomUpdateData = {
                  'last_gift': {
                    'image': giftImg,
                    'senderName': senderName,
                    'senderImage': senderImgUrl,
                    'target': target,
                    'receiverImage': receiverImgUrl,
                    'count': count,
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                  }
                };

                if (pointsToIncrement > 0) {
                  roomUpdateData['dailyPoints'] =
                      FieldValue.increment(pointsToIncrement);
                }

                await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(widget.roomId)
                    .update(roomUpdateData);

                // টপ গিফটার লিডারবোর্ডের সাব-কালেকশন আপডেট
                if (pointsToIncrement > 0 && senderDocID.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(widget.roomId)
                      .collection('daily_gifters')
                      .doc(senderDocID)
                      .set({
                    'gifterName': senderName,
                    'gifterPic': senderImgUrl,
                    'giftedAmount': FieldValue.increment(pointsToIncrement),
                  }, SetOptions(merge: true));
                }

                // মেসেজ লিস্টে ছবিসহ গিফট হিস্ট্রি পাঠানো
                await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(widget.roomId)
                    .collection('messages')
                    .add({
                  'type': 'gift',
                  'name': senderName,
                  'senderImage': senderImgUrl,
                  'targetName': target,
                  'receiverImage': receiverImgUrl,
                  'giftImage': giftImg,
                  'giftCount': count,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                // এনিমেশন টাইমার
                Timer(const Duration(seconds: 5), () {
                  if (context.mounted) {
                    setState(() => isGiftAnimating = false);
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }

// হেল্পার বাটন ফাংশন (PK এবং অন্যান্য আইকনের জন্য সম্পূর্ণ নিরাপদ ও অপ্টিমাইজড)
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
        // এখানে আইকনের পরিবর্তে আপনার দেওয়া PK শর্তটি অক্ষুণ্ন রাখা হয়েছে
        child: icon == Icons.star
            ? const Row(
                mainAxisSize: MainAxisSize.min, // বাটন সাইজ ঠিক রাখার জন্য
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "PK",
                    style: TextStyle(
                      color: Color.fromARGB(255, 68, 151, 246),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  SizedBox(width: 2), // লেখা ও স্টারের মাঝে গ্যাপ
                  Icon(
                    Icons.star,
                    size: 10,
                    color: Color.fromARGB(255, 246, 226, 4),
                  ),
                ],
              )
            : Icon(icon, color: color, size: 22),
      ),
    );
  }

  // ভিউয়ার্স এরিয়া উইজেট (সম্পূর্ণ অপ্টিমাইজড ও আইসোলেটেড, যাতে পুরো রুম রেন্ডার না হয়)
  Widget _buildViewerArea() {
    return RepaintBoundary(
      child: Container(
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
              // 🔥 PageStorageKey এবং RepaintBoundary পুরো রুমকে রি-রেন্ডার হওয়া থেকে রক্ষা করবে
              child: LiveViewersList(
                key: PageStorageKey('live_viewers_${widget.roomId}'),
                roomId: widget.roomId,
              ),
            ),
          ],
        ),
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

  // রুম সেটিংস ফাংশন (সম্পূর্ণ অপ্টিমাইজড, অপ্রয়োজনীয় ফুল রুম রেন্ডার রোধ করতে সুরক্ষিত)
  void _showSettings() {
    // এখানে মালিকানা এবং এডমিনশিপ যাচাই করছি
    bool isOwner = (ownerId.toString() == myuID.toString());
    bool isAdmin = (adminList.contains(myuID.toString()));

    RoomSettingsHandler.showSettings(
      context: context,
      roomId: widget.roomId,
      isLocked: isRoomLocked,
      isOwner: isOwner,
      isAdmin: isAdmin,
      onToggleLock: () async {
        // লোকাল স্টেট আপডেট শুধুমাত্র সেফলি ট্রিগার করা হলো
        if (mounted) {
          setState(() => isRoomLocked = !isRoomLocked);
        }
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .update({'isLocked': isRoomLocked});
      },
      onSetWallpaper: (path) async {
        if (path.isEmpty) return;
        try {
          final roomDoc = await FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.roomId)
              .get();

          if (roomDoc.exists) {
            String? oldUrl = roomDoc.data()?['roomWallpaper'];
            if (oldUrl != null &&
                oldUrl.isNotEmpty &&
                oldUrl.contains('firebase')) {
              try {
                await FirebaseStorage.instance.refFromURL(oldUrl).delete();
              } catch (e) {}
            }
          }

          final compressedBytes = await FlutterImageCompress.compressWithFile(
            path,
            quality: 60,
            minWidth: 800,
            minHeight: 800,
          );

          if (compressedBytes == null) return;

          String fileName = 'wallpapers/${widget.roomId}.jpg';
          var storageRef = FirebaseStorage.instance.ref().child(fileName);

          UploadTask uploadTask = storageRef.putData(
            compressedBytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );

          var snapshot = await uploadTask;
          String downloadUrl = await snapshot.ref.getDownloadURL();

          await FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.roomId)
              .update({'roomWallpaper': downloadUrl, 'wallpaper': downloadUrl});

          if (mounted) {
            setState(() => roomWallpaperPath = downloadUrl);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Wallpaper updated!")),
            );
          }
        } catch (e) {}
      },
      onMinimize: () {
        FloatingBubbleService.isMinimized = true;
        String imageUrl = roomProfileImage.isNotEmpty
            ? roomProfileImage
            : 'https://via.placeholder.com/150';

        FloatingBubbleService.show(context, widget.roomId, imageUrl, widget);
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("রুম মিনিমাইজ করা হয়েছে"),
            backgroundColor: Colors.pinkAccent,
          ),
        );
      },
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
        } catch (e) {}
      },
      onLeave: () async {
        RoomSettingsHandler.showExitDialog(context, () async {
          try {
            // ব্যাকগ্রাউন্ডে ডাটা ক্লিনিং এবং আগোরা বন্ধ হবে
            await RoomExitHandler.handleExit(
                widget.roomId,
                myuID.toString(),
                adminList.map((e) => e.toString()).toList(),
                ownerId.toString());

            await _agoraManager.engine.leaveChannel();
            await _agoraManager.engine.release();
          } catch (e) {
            debugPrint("DEBUG ERROR: background cleanup failed: $e");
          }
        });
      },
    );
  }

  Widget _buildRoomBanner(Map<String, dynamic> roomData) {
    String bannerUrl = roomData['bannerUrl'] ?? "";

    if (bannerUrl.isEmpty) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 150,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
        ),
        // CachedNetworkImage ব্যবহার করে পারফরম্যান্স বৃদ্ধি
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: bannerUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  // ভিউয়ার যুক্ত করার ফাংশন (শুধুমাত্র ব্যাকগ্রাউন্ডে ভিউয়ার্স ডাটা নিয়ে কাজ করবে, মেইন রুমের UI রি-রেন্ডার করবে না)
  void _addUserToViewers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final rtdb = FirebaseDatabase.instance.ref();
      final viewerRef =
          rtdb.child('rooms/${widget.roomId}/viewers/${user.uid}');
      final firestore = FirebaseFirestore.instance;
      final roomRef = firestore.collection('rooms').doc(widget.roomId);

      // ১. ইউজার আগে থেকেই আছে কিনা চেক
      final snapshot = await viewerRef.get();
      if (snapshot.exists) {
        return;
      }

      // ২. ইউজারের তথ্য ফায়ারস্টোর থেকে আনা (একটিভ UI ব্লক না করে)
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

      // ৩. RTDB-তে ডাটা সেট করা
      viewerRef.onDisconnect().remove();
      await viewerRef.set({
        'authUID': user.uid,
        'uID': myShortID,
        'name': myName,
        'profilePic': myPic,
        'joinedAt': ServerValue.timestamp,
      });

      // ৪. ফায়ারস্টোরে ভিউয়ার কাউন্ট বাড়ানো (কোনো setState ছাড়াই)
      await roomRef.update({'viewerCount': FieldValue.increment(1)});
    } catch (e) {
      // ব্যাকগ্রাউন্ড সাইলেন্ট ক্যাচ
    }
  }

// ভিউয়ার রিমুভ করার ফাংশন (শুধুমাত্র ব্যাকগ্রাউন্ডে কাজ করবে)
  void _removeUserFromViewers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final rtdb = FirebaseDatabase.instance
          .ref('rooms/${widget.roomId}/viewers/${user.uid}');
      final firestore = FirebaseFirestore.instance;
      final roomRef = firestore.collection('rooms').doc(widget.roomId);

      // ১. চেক করা RTDB-তে ইউজার আছে কিনা
      final snapshot = await rtdb.get();
      if (!snapshot.exists) {
        return;
      }

      // ২. RTDB থেকে রিমুভ
      await rtdb.remove();

      // ৩. ফায়ারস্টোরে কাউন্ট কমানো (কোনো UI রেন্ডার বা setState ছাড়া)
      final roomDoc = await roomRef.get();
      int currentCount = roomDoc.data()?['viewerCount'] ?? 0;
      if (currentCount > 0) {
        await roomRef.update({'viewerCount': FieldValue.increment(-1)});
      }
    } catch (e) {
      // ব্যাকগ্রাউন্ড সাইলেন্ট ক্যাচ
    }
  }

  void _leaveRoomInternally() async {
    try {
      await _agoraManager.engine.leaveChannel();
      if (currentSeatIndex != -1) {
        FirebaseDatabase.instance
            .ref('rooms/${widget.roomId}/seats/$currentSeatIndex')
            .update({
          'userId': '',
          'userName': '',
          'userPhoto': '',
          'uID': '',
          'isMicOn': false,
          'isTalking': false,
        });
      }
      if (mounted) {
        setState(() {
          isMicOn = false;
          currentSeatIndex = -1;
        });
      }
    } catch (e) {
      // ক্যাচ ব্লকের প্রিন্ট রিমুভ করা হয়েছে
    }
  }
} // <--- এইটা হলো ক্লাসের একদম শেষ ব্র্যাকেট, এর ঠিক উপরে বসাবেন।

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

Widget _buildPremiumButton(
    {required String text,
    required IconData icon,
    required Color textColor,
    required VoidCallback onTap}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Text(text,
              style: TextStyle(
                  fontSize: 17, color: textColor, fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );
}

// এই উইজেটটি আপনার সিটের ডিজাইন হ্যান্ডেল করবে
class SeatWidget extends StatelessWidget {
  final int index;
  final bool isOccupied;
  final int giftCount;
  final bool isGiftCounting;
  final Widget child; // আপনার আগের সিটের ডিজাইন এখানে ঢুকবে

  const SeatWidget({
    required this.index,
    required this.isOccupied,
    required this.giftCount,
    required this.isGiftCounting,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child, // আপনার আগের সিটের ডিজাইন

        // এই অংশটি পরিবর্তন করুন:
        // '&& giftCount > 0' কন্ডিশনটি সরিয়ে দিয়েছি যাতে 0 থাকলেও কাউন্টার দেখায়।
        if (isGiftCounting && isOccupied)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber, width: 1.5),
              ),
              child: Text(
                "$giftCount", // এখন ব্যানার চালু থাকলেই এখানে 0, 1, 2... দেখাবে
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
