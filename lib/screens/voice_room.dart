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
import 'package:pagla_chat/donggi_baba_game.dart';
import 'package:pagla_chat/full_screen_image_viewer.dart';

import 'package:pagla_chat/pk_manager.dart';
import 'package:pagla_chat/room_exit_handler.dart';
import 'package:pagla_chat/room_floating_box.dart';
import 'package:pagla_chat/room_lobby_menu_sheet.dart';
import 'package:pagla_chat/room_manager.dart';
import 'package:pagla_chat/services/floating_bubble_service.dart';
import 'package:pagla_chat/services/floating_music_player.dart';
import 'package:pagla_chat/services/gift_logic_helper.dart';
import 'package:pagla_chat/services/gift_service.dart';
import 'package:pagla_chat/services/marriage_service.dart';
import 'package:pagla_chat/services/room_active_manager.dart';
import 'package:pagla_chat/services/room_image_picker_service.dart';
import 'package:pagla_chat/services/room_invite_service.dart';
import 'package:pagla_chat/services/soulmate_xp_service.dart';
import 'package:pagla_chat/user_badges_row.dart';
import 'package:pagla_chat/viewer_ranking_widget.dart';

import 'package:pagla_chat/widgets/entry_effect_handler.dart';
import 'package:shimmer/shimmer.dart';

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

      // 🚀 **ইনভাইট লিসেনার (এখানে uID এবং authUID উভয়ই পাস করা হলো যাতে কোনোভাবেই মিস না হয়)**
      if (uID.isNotEmpty || FirebaseAuth.instance.currentUser != null) {
        RoomInviteService.listenForInvites(
          context: context,
          roomId: widget.roomId,
          currentUserId: uID, // আপনার অ্যাপের নিজস্ব uID
          currentAuthUid: FirebaseAuth.instance.currentUser?.uid ??
              "", // ফায়ারবেসের আসল uid
          onJoinSeat: (seatIndex) {
            sitOnSeat(seatIndex);
          },
        );
      } else {}
    });
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

    // ৫. ১২টি সিটের ইনিশিয়ালাইজেশন (০ থেকে ১১)
    seats = List.generate(
        12,
        (index) => {
              "isOccupied": false,
              "userName": "",
              "userImage": "",
              "userFrame": "",
              "status": "empty",
              "giftCount": 0,
              "isMicOn": false,
              "isTalking": false,
              "userId": "",
              "uID": "",
              "agorauID": "",
            });

    // ৬. রিয়েলটাইম সিট লিসেনার (১২টি সিটের জন্য আপডেট করা হলো)
    _seatSubscription = FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/seats')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (!mounted) return;

      List<Map<String, dynamic>> updatedSeats = List.generate(
          12,
          (index) => {
                "isOccupied": false,
                "userName": "",
                "userImage": "",
                "userFrame": "",
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
          // ইনডেক্স ১১ এর কম বা সমান হতে হবে
          if (index != null &&
              index >= 0 &&
              index <= 11 &&
              index < updatedSeats.length &&
              value != null) {
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

              listenForMarriageRequests();
            }
          }
        });
      }

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
    // ১. এগোরা ইনি এবং জয়েন (রুমে ঢোকার সময় শুধু লিসেনার বা অডিও শোনার জন্য)
    Future.microtask(() async {
      try {
        if (!FloatingBubbleService.isMinimized) {
          await _agoraManager.initAgora();
          final String authUID = FirebaseAuth.instance.currentUser?.uid ?? "";

          // রুমে ঢোকার সময় ইউজার শুধু শুনবে, মাইক বন্ধ থাকবে (লিসেনার মোড)
          await _agoraManager.joinAsListener(widget.roomId, authUID);

          // নিশ্চিত করার জন্য লোকাল অডিও ডিজেবল করে দেওয়া হলো যাতে রুমে ঢুকেই কলিং শুরু না হয়
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
      final int myRealAgoraId = _agoraManager.localuID ?? -999;

      for (var speaker in speakers) {
        // 🔥 এখানে নিখুঁতভাবে শুধু নিজের অ্যাগোরা আইডি (বা ০ যদি লোকাল হয়) চেক করা হচ্ছে
        // যাতে অন্য কোনো ইউজারের কথা বলার ভলিউম আপনার নিজের স্ট্যাটাসকে প্রভাবিত না করে।
        if ((speaker.uid == 0 || speaker.uid == myRealAgoraId) &&
            myRealAgoraId != -999 &&
            (speaker.volume ?? 0) > 15) {
          isMeTalking = true;
          break;
        }
      }

      // শুধুমাত্র তখনই setState কল হবে যখন নিজের টকিং স্ট্যাটাস পরিবর্তিত হবে
      if (_isMeTalkingNow != isMeTalking) {
        setState(() {
          _isMeTalkingNow = isMeTalking;
        });
        _updateTalkingStatus(isMeTalking);
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
            CachedNetworkImage(
              imageUrl: requestData['ringIcon'] ?? '',
              width: 30,
              height: 30,
              placeholder: (context, url) => const SizedBox(
                width: 30,
                height: 30,
                child: Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: Colors.white70),
                ),
              ),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.star, color: Colors.amber),
            ),
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
              backgroundColor: Colors.white12,
              backgroundImage: (requestData['fromImg'] ?? '').isNotEmpty
                  ? CachedNetworkImageProvider(requestData['fromImg']!)
                  : null,
              child: (requestData['fromImg'] ?? '').isEmpty
                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
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
                String friendAuthUID = requestData['fromAuthUID'] ?? '';

                // যদি fromAuthUID খালি থাকে, তবে fromId দিয়ে ইউজার খুঁজে বের করা
                if (friendAuthUID.isEmpty || friendAuthUID.length < 15) {
                  String potentialId = requestData['fromId'] ?? '';
                  if (potentialId.isNotEmpty) {
                    var userQuery = await FirebaseFirestore.instance
                        .collection('users')
                        .where('uID', isEqualTo: potentialId)
                        .limit(1)
                        .get();

                    if (userQuery.docs.isNotEmpty) {
                      friendAuthUID = userQuery.docs.first.id;
                    } else {
                      friendAuthUID = potentialId;
                    }
                  }
                }

                await MarriageService().completeMarriage(
                  myId:
                      myId, // 🔴 এখানে আগে uID দেওয়া ছিল, যেটার কারণে খালি স্ট্রিং পাস হচ্ছিল। এখন সঠিক 'myId' ভেরিয়েবল পাস করা হলো।
                  myAuthUID: authUID,
                  myName: myName,
                  myImg: myImg,
                  friendId:
                      requestData['fromId'] ?? '', // পার্টনারের ডকুমেন্ট আইডি
                  friendAuthUID: friendAuthUID,
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
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print("Error accepting marriage ring: $e");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("বিয়ে সম্পন্ন করতে সমস্যা হয়েছে: $e ❌"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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

  Future<void> _kickUserFromRoom(String targetuID) async {
    if (targetuID.isEmpty) return;

    try {
      // ১. ফায়ারস্টোর থেকে প্রটেক্টেড ইউজার লিস্ট ফেচ করা
      var configDoc = await FirebaseFirestore.instance
          .collection('system_config')
          .doc('app_settings')
          .get();

      List<dynamic> protectedList = [];
      if (configDoc.exists && configDoc.data() != null) {
        protectedList = configDoc.data()?['protectedUserIds'] ?? [];
      }

      // ২. প্রোটেকশন চেক (ডাটাবেজ লিস্টে থাকলে কিক হবে না)
      if (protectedList.contains(targetuID)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "This user is an official member of PaglaChat, you cannot kick them!"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return; // এখান থেকেই ফাংশন বন্ধ হয়ে যাবে, কিক হবে না
      }

      // ৩. ফায়ারস্টোরে কিক লিস্টে জমা করা এবং ফলোয়ার/অ্যাডমিন থেকে রিমুভ করা
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({
        'kickedUsers': FieldValue.arrayUnion([targetuID]),
        'followers': FieldValue.arrayRemove([targetuID]),
        'admins': FieldValue.arrayRemove([targetuID]),
      });

      // ৪. রিয়েল-টাইম ডাটাবেসে কিক সিগন্যাল পাঠানো
      await FirebaseDatabase.instance
          .ref('rooms/${widget.roomId}/kickSignal/$targetuID')
          .set({
        'action': 'kicked',
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint("Error kicking user: $e");
    }
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
  DatabaseReference? _micStatusRef;
  StreamSubscription? _micStatusSubscription;

  void _listenToMicStatus() {
    // পুরোনো লিসেনার থাকলে তা আগে ক্যানসেল করে দিতে হবে
    _micStatusSubscription?.cancel();

    if (currentSeatIndex == -1) return;

    _micStatusRef = FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/seats/$currentSeatIndex');

    _micStatusSubscription = _micStatusRef!.onValue.listen((event) {
      if (!mounted) return;

      if (event.snapshot.exists) {
        var data = event.snapshot.value as Map?;
        if (data == null) return;

        // যদি সিটটি অন্য কারো হয় বা সিট খালি থাকে, তবে নিজের মাইক কন্ট্রোল করা যাবে না
        // (নিশ্চিত করা যে এটা শুধুমাত্র নিজের বর্তমান সিটকেই হ্যান্ডেল করছে)
        bool isMicOn = data['isMicOn'] ?? true;

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
    if (index < 0 || index > 11) return;
    if (key.currentContext == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final RenderBox? renderBox =
          key.currentContext?.findRenderObject() as RenderBox?;

      final RenderBox? roomBox = context.findRenderObject() as RenderBox?;

      if (renderBox != null && roomBox != null) {
        final position =
            renderBox.localToGlobal(Offset.zero, ancestor: roomBox);
        final size = renderBox.size;

        Offset newPosition = Offset(
          position.dx + (size.width / 2),
          position.dy + (size.height / 2),
        );

        if (seatPositions.length <= index) {
          while (seatPositions.length <= index) {
            seatPositions.add(Offset.zero);
          }
        }

        if (seatPositions[index] != newPosition) {
          setState(() {
            seatPositions[index] = newPosition;
          });
        }
      } else {}
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
          // নির্দিষ্ট এই রুমের আইডি ছাড়া পুরো অ্যাপের অন্য কোনো ডাটা এখানে আসবে না
          stream: FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.roomId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Container(
                color: const Color(0xFF0B1222),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.pinkAccent),
                ),
              );
            }

            var roomData = snapshot.data!.data() as Map<String, dynamic>;
            String? wallpaperUrl = roomData['currentWallpaper'];

            bool newIsPKActive = roomData['isPKActive'] ?? false;
            Map<String, dynamic>? newPKData = roomData['pkData'];

            // এখানে শুধু স্ট্যাটাস না, স্কোর চেঞ্জ হলেও যেন স্টেট আপডেট হয় তা নিশ্চিত করা হলো
            if (_lastPKStatus != newIsPKActive ||
                currentPKData?['score1'] != newPKData?['score1'] ||
                currentPKData?['score2'] != newPKData?['score2']) {
              _lastPKStatus = newIsPKActive;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  if (!newIsPKActive) {
                    _endPKBattle();
                  }
                  setState(() {
                    isPKActive = newIsPKActive;
                    currentPKData = newPKData;
                    pkDuration = currentPKData?['duration'] ?? 0;
                    blueTeamPoints = (currentPKData?['score1'] ?? 0);
                    redTeamPoints = (currentPKData?['score2'] ?? 0);
                  });
                }
              });
            }
            // --- গিফট এবং এন্ট্রি ইফেক্টের ইনফিনাইট লুপ প্রিভেন্ট করার জন্য সেফ চেক ---
            var lastGift = roomData['last_gift'];
            if (lastGift != null && !isGiftAnimating) {
              int giftTime = 0;
              if (lastGift['timestamp'] is int) {
                giftTime = lastGift['timestamp'];
              } else if (lastGift['timestamp'] is Timestamp) {
                giftTime =
                    (lastGift['timestamp'] as Timestamp).millisecondsSinceEpoch;
              }

              int now = DateTime.now().millisecondsSinceEpoch;
              if (now - giftTime < 5000) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !isGiftAnimating) {
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

                    // ফায়ারস্টোরে আপডেট লুপ এড়াতে এটি বাইরে হ্যান্ডেল করা হয়েছে
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
            return Stack(
              children: [
                // ১. ওয়ালপেপার একদম নিচে পুরো স্ক্রিন জুড়ে থাকবে
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

                      // নতুন ডিজাইনকৃত টফি ও র‍্যাঙ্কিং কাউন্টার সহ ছোট ভিউয়ার এরিয়া
                      ViewerRankingWidget(
                        roomId: widget.roomId,
                        viewerListWidget: RepaintBoundary(
                          child: Container(
                            height:
                                40, // লম্বায় বা উচ্চতায় আরও কমিয়ে কম্প্যাক্ট করা হয়েছে
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                              children: [
                                const Icon(Icons.groups,
                                    color: Color.fromARGB(255, 11, 245, 3),
                                    size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  // 🔥 PageStorageKey এবং RepaintBoundary পুরো রুমকে রি-রেন্ডার হওয়া থেকে রক্ষা করবে
                                  child: LiveViewersList(
                                    key: PageStorageKey(
                                        'live_viewers_${widget.roomId}'),
                                    roomId: widget.roomId,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
                                      ? List.generate(12,
                                          (i) => val[i.toString()] ?? val[i])
                                      : (val is List ? val : []);
                                }

                                // রুমে সিটে বসা ইউজারদের uID সংগ্রহ করা হচ্ছে
                                List<String> seatUids = seats
                                    .where((s) => s != null && s['uID'] != null)
                                    .map((s) => s['uID'].toString())
                                    .toList();

                                if (seatUids.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                // পুরো users কালেকশন না এনে শুধু সিটে থাকা ইউজারদের ডেটা আনা হচ্ছে (হ্যাং প্রবলেম ফিক্সড)
                                return StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .where('uID', whereIn: seatUids)
                                      .snapshots(),
                                  builder: (context, userSnapshot) {
                                    if (!userSnapshot.hasData) {
                                      return const SizedBox.shrink();
                                    }

                                    Map<String, List<dynamic>> allUsers = {};
                                    for (var doc in userSnapshot.data!.docs) {
                                      var d =
                                          doc.data() as Map<String, dynamic>;
                                      String uIdStr =
                                          (d['uID'] ?? "").toString();
                                      if (uIdStr.isNotEmpty) {
                                        allUsers[uIdStr] =
                                            d['soulmates'] is List
                                                ? d['soulmates']
                                                : [];
                                      }
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

                      // ২. মেসেজ এরিয়া (নির্দিষ্ট রুমের মেসেজ, লিমিটেড ২৫ টি)
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

                                  String uId =
                                      mData['senderId'] ?? mData['uId'] ?? '';
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
                                    child: type == 'text'
                                        ? _buildMessageRow(
                                            context: context,
                                            msg: {
                                              'senderId': uId,
                                              'name': uName,
                                              'profilePic': uImage,
                                              'text': messageText,
                                            },
                                          )
                                        : _buildActivityRow(mData),
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
// ৩. ইনবক্স বাটন ও চ্যাট আনরিড কাউন্ট স্ট্রিম
                Positioned(
                  bottom: 165, // পজিশন সমন্বয় করা হয়েছে
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
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6A11CB),
                                    Color(0xFF2575FC)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                    color: Colors.cyanAccent, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.chat_bubble_rounded,
                                    color: Colors.white, size: 22),
                              ),
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

// 🔥 ডংগী বাবা গেম ওপেন করার ফ্লোটিং বাটন:
                Positioned(
                  bottom: 110,
                  right: 15,
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) =>
                            DonggiBabaGameWidget(roomId: widget.roomId),
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A103C),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amberAccent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amberAccent.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: const Center(
                        child: Text("🦁", style: TextStyle(fontSize: 22)),
                      ),
                    ),
                  ),
                ),

// 🔥 মুভেবল ব্যানারের উপরে বা লবি মেনুর ভেতরে মিউজিক ট্যাপ করার সঠিক কোড:
                Positioned(
                  bottom: 55,
                  right: 15,
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => RoomLobbyMenuSheet(
                          onMusicTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (modalContext) => MusicPlayerWidget(
                                onMusicSelect: (path) async {
                                  if (!mounted) return;

                                  // ✅ ফ্লোটিং প্লেয়ার দৃশ্যমান এবং মিউজিক প্লে করার জন্য স্টেট আপডেট করা হলো
                                  setState(() {
                                    isFloatingPlayerVisible = true;
                                    currentMusicUrl = path;
                                    isRoomMusicPlaying = true;
                                  });

                                  try {
                                    await _agoraManager.engine
                                        .stopAudioMixing();
                                    await _agoraManager.engine.startAudioMixing(
                                        filePath: path,
                                        loopback: false,
                                        cycle: 1);
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
                          onGiftToolsTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1A1A2E),
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20)),
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
                                ),
                              ),
                            );
                          },
                          onGamesTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: false,
                              backgroundColor: Colors.transparent,
                              builder: (c) => SizedBox(
                                height: MediaQuery.of(context).size.height,
                                child: GamePanelView(roomId: widget.roomId),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A103C),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.cyanAccent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.dashboard_rounded,
                            color: Colors.cyanAccent, size: 22),
                      ),
                    ),
                  ),
                ),

// 🔥 মুভেবল ব্যানারের উপরে এটি বসবে:
                RoomFloatingBox(roomId: widget.roomId),

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

                // 🔥 ৩. ট্রেজার বক্স ব্লাস্ট অ্যানিমেশন ওভারলে (রুমের সবাই দেখতে পাবে)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(widget.roomId)
                      .collection('room_box')
                      .doc('current_box')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const SizedBox.shrink();
                    }

                    var data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data == null) return const SizedBox.shrink();

                    bool isBlasted = data['isBlasted'] ?? false;
                    if (!isBlasted) return const SizedBox.shrink();

                    return Positioned.fill(
                      child: Material(
                        color: Colors.black.withOpacity(0.6),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 250,
                                height: 250,
                                child: Lottie.network(
                                  'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/officialall/box_blast.json',
                                  fit: BoxFit.contain,
                                  repeat: false,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.flash_on,
                                          color: Colors.amber, size: 80),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "🎉 Treasure Box Blasted! 🎉",
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "25,000 Diamonds Reached! Rewards distributed.",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 25),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('rooms')
                                      .doc(widget.roomId)
                                      .collection('room_box')
                                      .doc('current_box')
                                      .update({'isBlasted': false});
                                },
                                child: const Text(
                                  "Collect Rewards",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                if (showEntryEffect && currentEntryEffect != null)
                  EntryEffectHandler(
                    userName: entryUserName ?? "User",
                    userImage: entryUserImage,
                    activeFrameUrl: entryUserFrame,
                    effectUrl: currentEntryEffect!,
                    onFinished: () {
                      if (mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => showEntryEffect = false);
                        });
                      }
                    },
                  ),
                _buildStreamEmojiAnimations(),
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
    bool isImage = type == 'image'; // ✅ নতুন ইমেজ মেসেজ চেক করার জন্য

    // 🛠️ নতুন ও পুরাতন সব সম্ভাব্য কী (Key) চেক করে সঠিক সেন্ডার আইডি, নাম ও ছবি বের করা হলো
    String uId = data['senderId'] ??
        data['uID'] ??
        data['authUID'] ??
        data['uid'] ??
        data['userId'] ??
        '';
    String uName =
        data['name'] ?? data['userName'] ?? data['senderName'] ?? "User";
    String sImg =
        data['senderImage'] ?? data['profilePic'] ?? data['userImage'] ?? "";

    // 🛠️ গিফটের রিসিভারের ক্ষেত্রে সঠিক আইডি ও নাম
    String targetId =
        data['targetId'] ?? data['receiverId'] ?? data['targetUID'] ?? '';
    String targetName = data['targetName'] ?? data['receiverName'] ?? "";
    String rImg = data['receiverImage'] ?? data['targetImage'] ?? "";

    // গিফটের লিংক (ইমেজ বা লটি)
    String giftImgUrl = data['giftImage'] ?? '';
    bool isLottie = giftImgUrl.toLowerCase().endsWith('.json');

    // ✅ নতুন ইমেজ মেসেজ ও টেক্সটের জন্য ভ্যারিয়েবল
    String chatImgUrl = data['imageUrl'] ?? '';
    String messageText = data['text'] ?? '';

    // 🛠️ সঠিক মেনশন এবং ইনপুট বক্স খোলার ফাংশন
    void mentionUserAndOpenInput(String nameToMention) {
      if (nameToMention.isEmpty) return;
      setState(() {
        _messageController.text = "@$nameToMention ";
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: _messageController.text.length),
        );
      });

      _showChatInputBottomSheet();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ১. সেন্ডার বা এন্ট্রি ইউজারের ছবি ---
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => sendInvite(uId, uName),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: sImg.isNotEmpty
                  ? CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white12,
                      backgroundImage: NetworkImage(sImg),
                    )
                  : const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white12,
                      child: Icon(Icons.account_circle,
                          size: 24, color: Colors.white54),
                    ),
            ),
          ),

          const SizedBox(width: 10),

          // --- ২. নাম, আইডি ও ডিটেইলস ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // সেন্ডারের নাম
                    Flexible(
                      child: GestureDetector(
                        onTap: () => mentionUserAndOpenInput(uName),
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
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isGift
                          ? "sent a gift"
                          : (isImage
                              ? "sent an image"
                              : (messageText.isNotEmpty
                                  ? "said:"
                                  : "entered the room")),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),

                // ✅ সেন্ডারের আইডি (নামের নিচে)
                if (uId.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    "ID: $uId",
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white54,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // ✅ টেক্সট মেসেজ থাকলে দেখাবে
                if (messageText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    messageText,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],

                // ✅ ইমেজ মেসেজ প্রিভিউ (রুমের সবাই দেখতে পাবে এবং ক্লিক করলে ফুলস্ক্রিন হবে)
                if (isImage && chatImgUrl.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImageViewer(
                            imageUrl: chatImgUrl,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: chatImgUrl,
                        height: 140,
                        width: 140,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const SizedBox(
                          height: 40,
                          width: 40,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.pinkAccent,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                            Icons.broken_image,
                            color: Colors.white54),
                      ),
                    ),
                  ),
                ],

                // ✅ গিফটের রিসিভারের নাম ও আইডি
                if (isGift && targetName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        "to ",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      if (rImg.isNotEmpty && rImg.startsWith('http')) ...[
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => sendInvite(targetId, targetName),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: CircleAvatar(
                              radius: 8,
                              backgroundImage: NetworkImage(rImg),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => mentionUserAndOpenInput(targetName),
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
                            if (targetId.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(
                                "ID: $targetId",
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  color: Colors.white54,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // --- ৩. বড় সাইজের গিফট (লটি/ইমেজ) ও সংখ্যা (Count) ---
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
                      : CachedNetworkImage(
                          imageUrl: giftImgUrl,
                          height: 40,
                          width: 40,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const SizedBox(
                            width: 20,
                            height: 20,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          errorWidget: (c, e, s) => const Icon(
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

  Widget _buildStreamEmojiAnimations() {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance
          .ref('rooms/${widget.roomId}/active_emojis')
          .onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const SizedBox.shrink();
        }

        final rawData = snapshot.data!.snapshot.value;

        Map<dynamic, dynamic> dataMap = {};
        if (rawData is Map) {
          dataMap = rawData;
        } else if (rawData is List) {
          for (int i = 0; i < rawData.length; i++) {
            if (rawData[i] != null) {
              dataMap[i] = rawData[i];
            }
          }
        } else {
          return const SizedBox.shrink();
        }

        return Stack(
          children: dataMap.entries.map((entry) {
            int seatIndex = int.tryParse(entry.key.toString()) ?? -1;
            var val = entry.value;

            if (seatIndex < 0 ||
                seatIndex > 11 ||
                seatIndex >= seatPositions.length) {
              return const SizedBox.shrink();
            }

            if (seatPositions[seatIndex] == Offset.zero) {
              return const SizedBox.shrink();
            }

            String lottieUrl = "";
            if (val is Map) {
              lottieUrl = val['currentEmoji']?.toString() ?? "";
            } else if (val is String) {
              lottieUrl = val;
            }

            if (lottieUrl.isEmpty) {
              return const SizedBox.shrink();
            }

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
                    // লটি প্যাকেজ বাই-ডিফল্ট নেটওয়ার্ক ফাইল ক্যাশ করে নেয়।
                    // অ্যানিমেশন লোড হওয়ার পর এর নির্দিষ্ট সময় পর ডাটাবেস থেকে রিমুভ করার লজিক:
                    onLoaded: (composition) {
                      Future.delayed(composition.duration, () {
                        if (mounted) {
                          FirebaseDatabase.instance
                              .ref(
                                  'rooms/${widget.roomId}/active_emojis/$seatIndex')
                              .remove();
                        }
                      });
                    },
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
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

    // ৮. এগোরা ইঞ্জিন ও চ্যানেল ক্লিনআপ করার জন্য ম্যানেজার কল করুন (await ছাড়া)
    try {
      _agoraManager.leaveRoom().catchError((e) {
        debugPrint("Agora Leave Error: $e");
      });
    } catch (e) {
      debugPrint("Agora Leave Error: $e");
    }

    super.dispose();
  }

  Widget _buildTopNavBar() {
    final String myAuthId = FirebaseAuth.instance.currentUser?.uid ?? "";

    bool amIOwner = (ownerAuthId.toString() == myAuthId.toString().trim()) ||
        (myuID.toString().trim() == ownerId.toString().trim());

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
                      if (!mounted) return;
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
                      if (!mounted) return;
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

                        if (!mounted) return;
                        setState(() {
                          roomProfileImage = downloadUrl;
                        });

                        await _roomService.updateRoomFullData(
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
                        debugPrint("Room profile update error: $e");
                      }
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
                            if (!mounted) return;
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
                                    onPressed: () async {
                                      String newName =
                                          nameEditController.text.trim();
                                      if (newName.isNotEmpty) {
                                        if (mounted) {
                                          setState(() => roomName = newName);
                                        }
                                        await _roomService.updateRoomFullData(
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
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
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
                                    // অপ্টিমাইজড উইডথ ক্যালকুলেশন
                                    final textPainter = TextPainter(
                                      text: TextSpan(
                                          text: roomName,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                      textDirection: TextDirection.ltr,
                                    )..layout();

                                    double textWidth = textPainter.width;
                                    double gap = 50.0;
                                    double totalWidth = textWidth + gap;

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
                                                roomName,
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
                      GestureDetector(
                        onTap: () async {
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
                        child: Row(
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
                      ),
                    ],
                  ),
                ),

                // ১. ফলোয়ার বাটন (সংখ্যা বা কাউন্ট বাদ দেওয়া হয়েছে)
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
                          if (currentUser == null) return;

                          try {
                            var userQuery = await FirebaseFirestore.instance
                                .collection('users')
                                .where('authUID', isEqualTo: currentUser.uid)
                                .limit(1)
                                .get();

                            if (userQuery.docs.isEmpty) return;

                            String activeUserID = userQuery.docs.first.id;
                            var roomRef = FirebaseFirestore.instance
                                .collection('rooms')
                                .doc(widget.roomId);

                            var roomDoc = await roomRef.get();
                            if (!roomDoc.exists) return;

                            var data = roomDoc.data();
                            String owneruIDFromDb = data?['uID']?.toString() ??
                                data?['ownerId']?.toString() ??
                                "";

                            if (activeUserID == owneruIDFromDb) return;

                            if (isFollowing) {
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
                            debugPrint("Follow action error: $e");
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                // ৩. সেটিংস বাটন
                IconButton(
                  icon: const Icon(Icons.settings,
                      color: Color.fromARGB(255, 132, 217, 251), size: 20),
                  onPressed: _showSettings,
                ),
                const SizedBox(width: 6),

                PopupMenuButton<String>(
                  offset: const Offset(0, 45),
                  // পপ-আপ মেনুর ব্যাকগ্রাউন্ডে আপনার দেওয়া ছবির সাথে মিলিয়ে মিক্সড কালার গ্রেডিয়েন্ট এফেক্ট
                  color: const Color(0xFF0D1B2A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.cyanAccent.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // আপনার দেওয়া ছবির মতো ডিপ পার্পল, ম্যাজেন্টা ও পিংক গ্লোয়িং গ্রেডিয়েন্ট
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF007F),
                          Color(0xFF7B1FA2),
                          Color(0xFF4A154B)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      // আপনার দেওয়া ছবির মতো চারপাশের উজ্জ্বল পিংক/ম্যাজেন্টা লাইটিং এফেক্ট
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withOpacity(0.8),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: Colors.purpleAccent.withOpacity(0.5),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.power_settings_new,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  onSelected: (value) {
                    if (value == 'minimize') {
                      // মিনিমাইজ লজিক
                      FloatingBubbleService.isMinimized = true;
                      String imageUrl = roomProfileImage.isNotEmpty
                          ? roomProfileImage
                          : 'https://via.placeholder.com/150';

                      FloatingBubbleService.show(
                          context, widget.roomId, imageUrl, widget);
                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Room Minimized"),
                          backgroundColor: Colors.pinkAccent,
                        ),
                      );
                    } else if (value == 'exit') {
                      // এক্সিট বা লিভ লজিক
                      RoomSettingsHandler.showExitDialog(context, () async {
                        try {
                          await RoomExitHandler.handleExit(
                              widget.roomId,
                              myuID.toString(),
                              adminList.map((e) => e.toString()).toList(),
                              ownerId.toString());

                          await _agoraManager.engine.leaveChannel();
                          await _agoraManager.engine.release();
                        } catch (e) {
                          debugPrint(
                              "DEBUG ERROR: background cleanup failed: $e");
                        }
                      });
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'minimize',
                      child: Row(
                        children: [
                          Icon(Icons.minimize,
                              color: Colors.pinkAccent, size: 20),
                          SizedBox(width: 10),
                          Text("Minimize Room",
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'exit',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app,
                              color: Colors.redAccent, size: 20),
                          SizedBox(width: 10),
                          Text("Exit Room",
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// --- ১. মেইন সিট গ্রিড এরিয়া (১২টি সিট, এক লাইনে ৪টি করে) ---
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
          padding:
              const EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 30),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // ✅ এক লাইনে ৪টি সিট
            childAspectRatio: 0.85, // ✅ সাইজ বড় ও মানানসই রাখার জন্য অনুপাত
            mainAxisSpacing: 15,
            crossAxisSpacing: 10,
          ),
          itemCount: 12, // ✅ মোট সিট সংখ্যা ১২টি করা হলো
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

            // 🔥 প্রতিটি সিট স্ক্রিনে রেন্ডার হওয়ার সময় পজিশন আপডেট নিশ্চিত করার জন্য:
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                updateSeatPosition(index, seatKeys[index]);
              }
            });

            return SeatWidget(
              index: index,
              isOccupied: isOccupied,
              giftCount: giftCount,
              isGiftCounting: isGiftCounting,
              child: GestureDetector(
                key: seatKeys[index],
                onTap: () {
                  final String myAuthId =
                      FirebaseAuth.instance.currentUser?.uid ?? "";
                  final String currentMyuID = myuID.toString().trim();

                  bool isOwner =
                      (ownerAuthId.toString() == myAuthId.toString().trim()) ||
                          (currentMyuID == ownerId.toString().trim());

                  bool isAdmin = adminList
                      .map((e) => e.toString().trim())
                      .contains(currentMyuID);

                  if (currentSeatIndex == index) {
                    _showLeaveConfirmation(index);
                    return;
                  }

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

                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: '',
                      barrierColor: Colors.black54,
                      transitionDuration: const Duration(milliseconds: 250),
                      pageBuilder: (ctx, anim1, anim2) =>
                          const SizedBox.shrink(),
                      transitionBuilder: (ctx, anim1, anim2, child) {
                        return BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: FadeTransition(
                            opacity: anim1,
                            child: Center(
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.75,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 10),
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
                  } else {
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

                                String seatUserName =
                                    userData['name'] ?? 'User';
                                String seatUserPhoto =
                                    userData['profilePic'] ?? '';
                                String activeFrame =
                                    userData['activeFrame'] ?? "";
                                int userXp = userData['vip_xp'] ?? 0;
                                int userExpiry = userData['vip_expiry'] ?? 0;
                                int vipLevel =
                                    getVipLevelFromData(userXp, userExpiry);

                                bool isAgent = userData['isAgent'] ??
                                    userData['agencyId'] != null ||
                                        userData['isAgency'] == true;
                                bool hasVip = vipLevel > 0;
                                bool hasPremium =
                                    userData['hasPremiumCard'] == true;

                                return Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.85,
                                  decoration: BoxDecoration(
                                    // 🔥 আপনার দেওয়া ছবির সাথে মিলিয়ে আকর্ষণীয় মিক্সড কালার গ্রেডিয়েন্ট ব্যাকগ্রাউন্ড
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF0D1B2A), // ডিপ ব্লু
                                        Color(0xFF1B1A55), // মিড নাইট ব্লু
                                        Color(
                                            0xFF4A154B), // সফট পার্পল/ম্যাজেন্টা মিক্স
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.cyanAccent.withOpacity(0.3),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.cyanAccent.withOpacity(0.2),
                                        blurRadius: 25,
                                        spreadRadius: 2,
                                      ),
                                      BoxShadow(
                                        color: Colors.purpleAccent
                                            .withOpacity(0.2),
                                        blurRadius: 25,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 20),

                                      // 🔥 প্রোফাইল পিকচার এবং মেনশন বাটন পাশাপাশি দেখানোর জন্য Row ব্যবহার করা হলো
                                      // 🔥 প্রোফাইল পিকচার একদম সেন্টারে এবং মেনশন বাটন সাইডে রাখার জন্য Stack ব্যবহার করা হলো
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // ১. প্রোফাইল পিকচার এবং ফ্রেম (এটি সবসময় ডায়ালগের নিখুঁত মাঝখানে থাকবে)
                                            SizedBox(
                                              width: 100,
                                              height: 100,
                                              child: Stack(
                                                alignment: Alignment.center,
                                                clipBehavior: Clip.none,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 35,
                                                    backgroundImage:
                                                        NetworkImage(
                                                            seatUserPhoto),
                                                  ),
                                                  if (activeFrame.isNotEmpty)
                                                    Positioned(
                                                      top: -20,
                                                      child: SizedBox(
                                                        width: 153,
                                                        height: 160,
                                                        child: activeFrame
                                                                .contains(
                                                                    '.json')
                                                            ? Lottie.network(
                                                                activeFrame,
                                                                fit: BoxFit
                                                                    .contain)
                                                            : CachedNetworkImage(
                                                                imageUrl:
                                                                    activeFrame,
                                                                fit: BoxFit
                                                                    .contain,
                                                                placeholder: (context,
                                                                        url) =>
                                                                    const SizedBox
                                                                        .shrink(),
                                                                errorWidget: (context,
                                                                        error,
                                                                        stackTrace) =>
                                                                    const SizedBox
                                                                        .shrink(),
                                                              ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),

                                            // ২. মেনশন বাটন (এটি ডায়ালগের ডানপাশে পজিশন করা থাকবে)
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () async {
                                                    _messageController.text =
                                                        "@$seatUserName ";
                                                    _messageController
                                                            .selection =
                                                        TextSelection
                                                            .fromPosition(
                                                      TextPosition(
                                                          offset:
                                                              _messageController
                                                                  .text.length),
                                                    );

                                                    Navigator.of(context,
                                                            rootNavigator: true)
                                                        .pop();

                                                    await Future.delayed(
                                                        const Duration(
                                                            milliseconds: 100));

                                                    if (context.mounted) {
                                                      _showChatInputBottomSheet();
                                                    }
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 14,
                                                        vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.cyanAccent
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      border: Border.all(
                                                        color: Colors.cyanAccent
                                                            .withOpacity(0.5),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      "@",
                                                      style: TextStyle(
                                                        color:
                                                            Colors.cyanAccent,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      // --- নামের গ্লাস বর্ডার বক্স (অফিশিয়াল/সুপার এডমিনদের জন্য শিমার ও গোল্ডেন বর্ডার, নরমালদের জন্য সিম্পল) ---
                                      (() {
                                        // রোল বা স্ট্যাটাস চেক করার লজিক
                                        bool isOfficial =
                                            (userData['isOfficial'] == true) ||
                                                (userData['role'] ==
                                                    'official');
                                        bool isSuperAdmin =
                                            (userData['isSuperAdmin'] ==
                                                    true) ||
                                                (userData['role'] ==
                                                    'super_admin');
                                        bool isSpecialUser =
                                            isOfficial || isSuperAdmin;

                                        return Container(
                                          // স্লিম ও স্মুথ প্যাডিং (ব্যাজের মতো করে)
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isSpecialUser
                                                ? Colors.black.withOpacity(0.4)
                                                : Colors.white.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isSpecialUser
                                                  ? const Color(
                                                      0xFFFFD700) // গোল্ডেন বর্ডার শুধু স্পেশালদের জন্য
                                                  : Colors.white
                                                      .withOpacity(0.3),
                                              width: 1.2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isSpecialUser
                                                    ? const Color(0xFFFFD700)
                                                        .withOpacity(0.3)
                                                    : Colors.purpleAccent
                                                        .withOpacity(0.15),
                                                blurRadius:
                                                    isSpecialUser ? 6 : 10,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: isSpecialUser
                                              ? Shimmer.fromColors(
                                                  baseColor: isOfficial
                                                      ? Colors.amber
                                                      : Colors.purpleAccent,
                                                  highlightColor: Colors.white,
                                                  period: const Duration(
                                                      milliseconds: 1500),
                                                  child: Text(
                                                    seatUserName,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 0.8,
                                                      height: 1.0,
                                                    ),
                                                  ),
                                                )
                                              : Text(
                                                  seatUserName,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    letterSpacing: 0.8,
                                                    height: 1.0,
                                                  ),
                                                ),
                                        );
                                      })(),
                                      // --- নামের গ্লাস বর্ডার বক্স শেষ ---

                                      const SizedBox(height: 8),

                                      // --- আইডি সেকশন (কপি করার সুবিধা ও শিমার লুকসহ) ---
                                      GestureDetector(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(
                                              text: seatUserId.toString()));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text("ID Copied!"),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                        child: Builder(
                                          builder: (context) {
                                            bool isOfficial =
                                                (userData['isOfficial'] ==
                                                        true) ||
                                                    (userData['role'] ==
                                                        'official');
                                            bool isSuperAdmin =
                                                (userData['isSuperAdmin'] ==
                                                        true) ||
                                                    (userData['role'] ==
                                                        'super_admin');
                                            bool isSpecialUser =
                                                isOfficial || isSuperAdmin;

                                            return isSpecialUser
                                                ? Shimmer.fromColors(
                                                    baseColor:
                                                        const Color.fromARGB(
                                                            255, 4, 189, 251),
                                                    highlightColor:
                                                        Colors.white,
                                                    period: const Duration(
                                                        milliseconds: 1500),
                                                    child: Text(
                                                      "ID: $seatUserId",
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  )
                                                : Text(
                                                    "ID: $seatUserId",
                                                    style: const TextStyle(
                                                      color: Color.fromARGB(
                                                          255, 4, 189, 251),
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  );
                                          },
                                        ),
                                      ),

                                      const SizedBox(height: 15),

                                      // 🔥 ব্যাজ সেকশন: প্রতিটা ব্যাজ আলাদা আলাদা প্রিমিয়াম মিক্সড কালার ও গ্লাস বর্ডার সহ
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // -------------------------------------------------------------
                                            // 🟢 ১ম লাইন: আইকন ব্যাজসমূহ (VIP, Premium, Agency Image)
                                            // -------------------------------------------------------------
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // ১. VIP Badge (যদি থাকে)
                                                if (hasVip)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 4),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      gradient:
                                                          const LinearGradient(
                                                        colors: [
                                                          Colors.purpleAccent,
                                                          Colors
                                                              .deepOrangeAccent
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                      ),
                                                      border: Border.all(
                                                          color: Colors.white
                                                              .withOpacity(0.4),
                                                          width: 1.2),
                                                      boxShadow: [
                                                        BoxShadow(
                                                            color: Colors.purple
                                                                .withOpacity(
                                                                    0.4),
                                                            blurRadius: 6,
                                                            spreadRadius: 1)
                                                      ],
                                                    ),
                                                    child: CachedNetworkImage(
                                                      imageUrl:
                                                          getVipBadge(vipLevel),
                                                      width: 30,
                                                      height: 30,
                                                      fit: BoxFit.contain,
                                                      placeholder:
                                                          (context, url) =>
                                                              const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 1.5,
                                                            color:
                                                                Colors.white70,
                                                          ),
                                                        ),
                                                      ),
                                                      errorWidget: (context,
                                                              error,
                                                              stackTrace) =>
                                                          const SizedBox(
                                                              width: 30,
                                                              height: 30),
                                                    ),
                                                  ),

                                                // ২. Premium Card Badge (যদি থাকে)
                                                if (hasPremium)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 4),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      gradient:
                                                          const LinearGradient(
                                                        colors: [
                                                          Colors.amberAccent,
                                                          Colors.pinkAccent
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                      ),
                                                      border: Border.all(
                                                          color: Colors.white
                                                              .withOpacity(0.4),
                                                          width: 1.2),
                                                      boxShadow: [
                                                        BoxShadow(
                                                            color: Colors.amber
                                                                .withOpacity(
                                                                    0.4),
                                                            blurRadius: 6,
                                                            spreadRadius: 1)
                                                      ],
                                                    ),
                                                    child: CachedNetworkImage(
                                                      imageUrl: premiumBadgeUrl,
                                                      width: 30,
                                                      height: 30,
                                                      fit: BoxFit.contain,
                                                      placeholder:
                                                          (context, url) =>
                                                              const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 1.5,
                                                            color:
                                                                Colors.white70,
                                                          ),
                                                        ),
                                                      ),
                                                      errorWidget: (context,
                                                              error,
                                                              stackTrace) =>
                                                          const SizedBox(
                                                              width: 30,
                                                              height: 30),
                                                    ),
                                                  ),

                                                // ৩. Agency Badge (যদি থাকে)
                                                if (isAgent)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 4),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      gradient:
                                                          const LinearGradient(
                                                        colors: [
                                                          Colors.cyanAccent,
                                                          Colors.blueAccent
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                      ),
                                                      border: Border.all(
                                                          color: Colors.white
                                                              .withOpacity(0.4),
                                                          width: 1.2),
                                                      boxShadow: [
                                                        BoxShadow(
                                                            color: Colors.cyan
                                                                .withOpacity(
                                                                    0.4),
                                                            blurRadius: 6,
                                                            spreadRadius: 1)
                                                      ],
                                                    ),
                                                    child: CachedNetworkImage(
                                                      imageUrl:
                                                          "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/agancy.png",
                                                      width: 30,
                                                      height: 30,
                                                      fit: BoxFit.contain,
                                                      placeholder:
                                                          (context, url) =>
                                                              const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 1.5,
                                                            color:
                                                                Colors.white70,
                                                          ),
                                                        ),
                                                      ),
                                                      errorWidget: (context,
                                                              error,
                                                              stackTrace) =>
                                                          const SizedBox(
                                                              width: 30,
                                                              height: 30),
                                                    ),
                                                  ),
                                                // ৪. Verified Badge (যদি isVerified ট্রু হয়)
                                                if (userData['isVerified'] ==
                                                    true)
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 4),
                                                    child: const Icon(
                                                      Icons.verified,
                                                      color: Color(0xFF00FBFF),
                                                      size:
                                                          22, // সাইজ চাইলে আপনার পছন্দমতো বাড়িয়ে বা কমিয়ে নিতে পারেন
                                                    ),
                                                  ),
                                              ],
                                            ),

                                            // -------------------------------------------------------------
                                            // 🟡 ২য় লাইন: নতুন শিমার টেক্সট ব্যাজ সেকশন (ডাটাবেজ চেক সহ)
                                            // -------------------------------------------------------------
                                            const SizedBox(
                                                height:
                                                    4), // দুই লাইনের মাঝে হালকা গ্যাপ
                                            UserBadgesRow(
                                                userId: userData['uID'] ??
                                                    '') // ডাটা থাকলে শিমার শাইনিং ও গোল্ডেন বর্ডারসহ শো করবে
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 25),
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
                                                Navigator.pop(ctx);
                                                _toggleFollowUser(seatUserId);
                                              },
                                            ),
                                            _buildProfileActionButton(
                                              icon: Icons.chat_bubble_outline,
                                              label: "Chat",
                                              color: Colors.purpleAccent,
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                _goToInbox(
                                                    seatUserId, seatUserName);
                                              },
                                            ),
                                            _buildProfileActionButton(
                                              icon: Icons.card_giftcard,
                                              label: "Gift",
                                              color: Colors.orangeAccent,
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                _openGiftPanel(seatUserId);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
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
                                              _buildAdminAction(
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
                                                  int sIndex = index;
                                                  bool currentMicStatus =
                                                      seatData?['isMicOn'] ??
                                                          true;
                                                  bool newMicStatus =
                                                      !currentMicStatus;
                                                  try {
                                                    await HapticFeedback
                                                        .lightImpact();
                                                    await FirebaseDatabase
                                                        .instance
                                                        .ref(
                                                            'rooms/${widget.roomId}/seats/$sIndex')
                                                        .update({
                                                      'isMicOn': newMicStatus,
                                                      'isTalking': false,
                                                    });
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
                                                  Navigator.pop(ctx);
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RepaintBoundary(
                      child: VoiceRipple(
                        isTalking: isTalking,
                        isMicOn: isMicOn,
                        isOccupied: isOccupied,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: isOccupied
                                      ? [
                                          Colors.cyanAccent,
                                          Colors.purpleAccent,
                                          Colors.pinkAccent,
                                        ]
                                      : [
                                          Colors.white24,
                                          Colors.white10,
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: isOccupied
                                    ? [
                                        BoxShadow(
                                          color: Colors.purpleAccent
                                              .withOpacity(0.4),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                        BoxShadow(
                                          color: Colors.cyanAccent
                                              .withOpacity(0.2),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2.5),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black87,
                                        Colors.deepPurple.shade900
                                            .withOpacity(0.8),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.transparent,
                                    backgroundImage:
                                        (isOccupied && uImage.isNotEmpty)
                                            ? NetworkImage(uImage)
                                            : null,
                                    child: (isOccupied)
                                        ? (uImage.isEmpty
                                            ? const Icon(Icons.person,
                                                color: Colors.white24, size: 30)
                                            : null)
                                        : (seatData != null &&
                                                seatData['isLocked'] == true)
                                            ? Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors
                                                      .black, // প্রথম ছবির মতো ডিপ ব্ল্যাক ব্যাকগ্রাউন্ড
                                                  boxShadow: [
                                                    // সাইবার ব্লু গ্লোয়িং শ্যাডো (বাইরের দিকে ছড়াবে)
                                                    BoxShadow(
                                                      color: Colors.cyanAccent
                                                          .withOpacity(0.7),
                                                      blurRadius: 10,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                  border: Border.all(
                                                    color: Colors
                                                        .cyanAccent, // উজ্জ্বল নীল বা সায়ান রিং বর্ডার
                                                    width: 2.5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: Colors.cyanAccent
                                                            .withOpacity(
                                                                0.5), // ভেতরের গোল রিং
                                                        width: 1.2,
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons
                                                          .lock_rounded, // সাইবার লক স্টাইল
                                                      color: Colors.cyanAccent,
                                                      size: 18,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.chair_rounded,
                                                color: Colors.white12,
                                                size: 28,
                                              ),
                                  ),
                                ),
                              ),
                            ),
                            if (isOccupied && uFrame.isNotEmpty)
                              IgnorePointer(
                                child: OverflowBox(
                                  maxWidth: 160,
                                  maxHeight: 160,
                                  child: SizedBox(
                                    width: 130,
                                    height: 130,
                                    child: uFrame.contains('.json')
                                        ? Lottie.network(
                                            uFrame,
                                            fit: BoxFit.contain,
                                            errorBuilder: (c, e, s) =>
                                                const SizedBox.shrink(),
                                          )
                                        : CachedNetworkImage(
                                            imageUrl: uFrame,
                                            fit: BoxFit.contain,
                                            placeholder: (context, url) =>
                                                const SizedBox.shrink(),
                                            errorWidget: (c, e, s) =>
                                                const SizedBox.shrink(),
                                          ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOccupied ? uName : "${index + 1}",
                      style: TextStyle(
                        fontSize: 11,
                        color: isOccupied ? Colors.white : Colors.white38,
                        fontWeight:
                            isOccupied ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isOccupied && uIDShow.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          "ID: $uIDShow",
                          style: const TextStyle(
                              fontSize: 9,
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
    // সমস্ত বাটনের জন্য নির্দিষ্ট সাইজ (সমান রাখার জন্য)
    final double buttonSize = 42.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          // ১. ইমোজি বাটন 😄 (অন্যান্য বাটনের ডিজাইনের সাথে সামঞ্জস্যপূর্ণ)
          GestureDetector(
            onTap: () async {
              if (currentSeatIndex < 0 || currentSeatIndex > 11) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Take seat first")));
                return;
              }

              int mySeatIndex = currentSeatIndex;

              EmojiHandler.showPicker(
                context: context,
                seatIndex: mySeatIndex,
                onEmojiSelected: (index, url) async {
                  final String currentAuthUid =
                      FirebaseAuth.instance.currentUser?.uid ?? "";

                  DatabaseReference emojiRef = FirebaseDatabase.instance
                      .ref('rooms/${widget.roomId}/active_emojis/$index');

                  await emojiRef.set({
                    'currentEmoji': url,
                    'emojiTime': ServerValue.timestamp,
                    'senderId': currentAuthUid,
                  });

                  await FirebaseDatabase.instance
                      .ref('rooms/${widget.roomId}/seats/$index')
                      .update({
                    'currentEmoji': url,
                    'emojiTime': ServerValue.timestamp,
                  });

                  Future.delayed(const Duration(seconds: 4), () {
                    emojiRef.remove();
                    FirebaseDatabase.instance
                        .ref('rooms/${widget.roomId}/seats/$index')
                        .child('currentEmoji')
                        .remove();
                  });
                },
              );
            },
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2A1B4E).withOpacity(0.9),
                    const Color(0xFF1A1A2E),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      const Color.fromARGB(255, 250, 143, 2).withOpacity(0.7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_emotions_outlined,
                color: Color.fromARGB(255, 250, 143, 2),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ২. রুম সাউন্ড অন/অফ বাটন 🔊 (প্রথমে)
          StatefulBuilder(
            builder: (context, setButtonState) {
              return GestureDetector(
                onTap: () {
                  setButtonState(() {
                    isRoomMuted = !isRoomMuted;
                  });
                  _agoraManager.muteAllRemoteAudio(isRoomMuted);
                },
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2A1B4E).withOpacity(0.9),
                        const Color(0xFF1A1A2E),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isRoomMuted
                          ? Colors.redAccent.withOpacity(0.6)
                          : const Color(0xFFFFD700).withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    isRoomMuted ? Icons.volume_off : Icons.volume_up,
                    color: isRoomMuted
                        ? Colors.redAccent
                        : const Color(0xFFFFD700),
                    size: 20,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // ৩. মাইক কন্ট্রোল বাটন 🎤 (দ্বিতীয়)
          StatefulBuilder(
            builder: (context, setButtonState) {
              return GestureDetector(
                onTap: () async {
                  if (currentSeatIndex == -1) return;
                  try {
                    HapticFeedback.lightImpact();
                  } catch (_) {}

                  bool newMicState = !isMicOn;

                  setButtonState(() {
                    isMicOn = newMicState;
                    if (!newMicState &&
                        currentSeatIndex >= 0 &&
                        currentSeatIndex < seats.length) {
                      seats[currentSeatIndex]["isTalking"] = false;
                    }
                  });

                  try {
                    await _agoraManager.toggleMic(!newMicState);
                    await FirebaseDatabase.instance
                        .ref('rooms/${widget.roomId}/seats/$currentSeatIndex')
                        .update({'isMicOn': newMicState});
                  } catch (e) {
                    setButtonState(() {
                      isMicOn = !newMicState;
                    });
                  }
                },
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2A1B4E).withOpacity(0.9),
                        const Color(0xFF1A1A2E),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isMicOn
                          ? Colors.greenAccent.withOpacity(0.6)
                          : Colors.redAccent.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    isMicOn ? Icons.mic : Icons.mic_off,
                    color: isMicOn ? Colors.greenAccent : Colors.redAccent,
                    size: 20,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // ৪. মেসেজ ইনপুট বাটন ✉️ (তৃতীয় - সাইজ ও ডিজাইন ফিক্সড)
          GestureDetector(
            onTap: () {
              _showChatInputBottomSheet();
            },
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2A1B4E).withOpacity(0.9),
                    const Color(0xFF1A1A2E),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      const Color.fromARGB(191, 246, 215, 19).withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mail_outline,
                color: Color.fromARGB(191, 246, 215, 19),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ৫. আকর্ষণীয় গিফট বক্স ডিজাইন এনিমেটেড গিফট বাটন 🎁 (চতুর্থ/শেষে)
          Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFD700),
                  Color(0xFFFF8C00),
                  Color(0xFF9400D3)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: _buildAnimatedGiftButton(),
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
      // ✅ ট্রানজিশন এনিমেশন ফাস্ট ও ঠিক রাখা হলো
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 200),
      ),
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
              // --- ১. গ্যালারি থেকে ইমেজ সেন্ড করার বাটন (ভিআইপি চেকসহ) ---
              IconButton(
                icon: const Icon(Icons.image, color: Colors.cyanAccent),
                onPressed: () async {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  final String authUID = currentUser?.uid ?? "";
                  if (authUID.isEmpty) return;

                  // ফায়ারস্টোর থেকে বর্তমান ইউজারের ডাটা ফেচ করে ভিআইপি চেক করা
                  var userQuery = await FirebaseFirestore.instance
                      .collection('users')
                      .where('authUID', isEqualTo: authUID)
                      .limit(1)
                      .get();

                  if (userQuery.docs.isEmpty) return;

                  var myData = userQuery.docs.first.data();

                  int vipXp = myData['vip_xp'] ?? myData['xp'] ?? 0;
                  int vipExpiry = myData['vipExpiry'] ?? 0;
                  int currentTime = DateTime.now().millisecondsSinceEpoch;

                  int vipLevel = 0;
                  if (!(vipExpiry != 0 && currentTime > vipExpiry)) {
                    if (vipXp >= 35000) {
                      vipLevel = 8;
                    } else if (vipXp >= 30000) {
                      vipLevel = 7;
                    } else if (vipXp >= 25000) {
                      vipLevel = 6;
                    } else if (vipXp >= 20000) {
                      vipLevel = 5;
                    } else if (vipXp >= 13000) {
                      vipLevel = 4;
                    } else if (vipXp >= 9000) {
                      vipLevel = 3;
                    } else if (vipXp >= 5000) {
                      vipLevel = 2;
                    } else if (vipXp >= 2500) {
                      vipLevel = 1;
                    }
                  }

                  // যদি ইউজার ভিআইপি না হয় (vipLevel <= 0)
                  if (vipLevel <= 0) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Only VIP users can send images"),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    return;
                  }

                  // ভিআইপি হলে শিট বন্ধ করে ইমেজ পিকার কল করা হবে
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  await RoomImagePickerService.pickAndSendImage(
                      roomId: widget.roomId);
                },
              ),
              const SizedBox(width: 4),

              // --- ২. টেক্সট লেখার ফিল্ড ---
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

              // --- ৩. সেন্ড বাটন ---
              IconButton(
                icon: const Icon(Icons.send, color: Colors.pinkAccent),
                onPressed: () async {
                  String msgText = _messageController.text.trim();
                  if (msgText.isEmpty) return;

                  // ইনপুট ক্লিয়ার করা এবং শিট বন্ধ করা
                  _messageController.clear();
                  if (Navigator.canPop(context)) Navigator.pop(context);

                  // ব্যাকগ্রাউন্ডে ফায়ারবেসে মেসেজ পাঠানো
                  final currentUser = FirebaseAuth.instance.currentUser;
                  final String authUID = currentUser?.uid ?? "";

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
                      'type': 'text',
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

  void sendInvite(String userId, String userName, {String authUid = ""}) {
    if (userId.isEmpty && authUid.isEmpty) {
      return;
    }

    RoomInviteService.sendSeatInvite(
      roomId: widget.roomId,
      targetUserId: userId,
      targetAuthUid: authUid,
      targetUserName: userName,
      inviterName: ownerName.isNotEmpty ? ownerName : "Host",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Invitation sent to $userName 🎙️"),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ✉️ মেসেজ রো উইজেট (মেনশন এবং ইনভাইট সহ)
  Widget _buildMessageRow(
      {required BuildContext context, required Map<String, dynamic> msg}) {
    String uId = msg['senderId'] ?? msg['uId'] ?? '';
    String senderName = msg['name'] ?? "User";
    String senderImage = msg['profilePic'] ?? msg['senderImage'] ?? "";
    String messageText = msg['text'] ?? msg['message'] ?? "";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🖼️ প্রোফাইল পিকচার (ক্লিক করলে সিট ইনভাইট পাঠানো হবে)
          GestureDetector(
            onTap: () {
              if (uId.isEmpty) {
                return;
              }
              sendInvite(uId, senderName);
            },
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white10,
              backgroundImage:
                  senderImage.isNotEmpty ? NetworkImage(senderImage) : null,
              child: senderImage.isEmpty
                  ? const Icon(Icons.person, size: 16, color: Colors.white24)
                  : null,
            ),
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
                      // ✍️ নামের ওপর ক্লিক করলে চ্যাট ইনপুটে `@senderName ` মেনশন হয়ে যাবে
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _messageController.text = "@$senderName ";
                            _messageController.selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                  offset: _messageController.text.length),
                            );
                          });

                          _showChatInputBottomSheet();
                        },
                        child: Text(
                          senderName,
                          style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 10),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        messageText,
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

  // গিফট বাটন উইজেট (স্থির, নিরাপদ এবং অপ্টিমাইজড)
  Widget _buildAnimatedGiftButton() {
    return IconButton(
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      icon: const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 22),
      onPressed: () async {
        final String currentAuthUID =
            FirebaseAuth.instance.currentUser?.uid ?? "";
        if (currentAuthUID.isEmpty) return;

        // ১. নিজের তথ্য এবং ব্যালেন্স আনা (লিমিট ১ দিয়ে অপ্টিমাইজড)
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
                  receiverImgUrl =
                      targetSeat['profilePic'] ?? targetSeat['userImage'] ?? "";
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
                  if (receiverAuthUID.isEmpty) receiverAuthUID = receiverDocID;

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
                        partnerGender = seat["gender"]?.toString() ?? "Unknown";
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
                    String response = await MarriageService().sendMarriageRing(
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

              // ফায়ারবেস রুম ব্যানার এবং ডেইলি পয়েন্ট আপডেট
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

  // রুম সেটিংস ফাংশন (সম্পূর্ণ অপ্টিমাইজড, অপ্রয়োজনীয় ফুল রুম রেন্ডার রোধ করতে সুরক্ষিত)
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
      // 🔥 শেয়ার রুমের ফাংশনটি এখানে নিরাপদে যুক্ত করা হলো
      onShareRoom: () {
        Navigator.pop(context); // সেটিংস বন্ধ করা

        // সরাসরি ইনবক্স পেজে নিয়ে যাবে, যেখান থেকে বন্ধু সিলেক্ট করে চ্যাটে পাঠানো যাবে
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InboxPage(
              isSharingRoom: true,
              roomId: widget.roomId,
              roomName: roomName,
              roomImage: roomProfileImage.isNotEmpty
                  ? roomProfileImage
                  : 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/room_default.png',
            ),
          ),
        );
      },
      onClearChat: () async {
        try {
          final chatCollection = FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.roomId)
              .collection('messages');

          // একসাথে সর্বোচ্চ ৫০০টি মেসেজ ফেচ করে ব্যাচে ডিলিট করা হচ্ছে (ফাস্ট ও এক ক্লিকে)
          final chatDocs = await chatCollection.limit(500).get();

          if (chatDocs.docs.isNotEmpty) {
            WriteBatch batch = FirebaseFirestore.instance.batch();
            for (var ds in chatDocs.docs) {
              batch.delete(ds.reference);
            }
            await batch.commit();
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Chat cleared successfully!")),
            );
          }
        } catch (e) {
          debugPrint("Clear chat error: $e");
        }
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
