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
import 'package:pagla_chat/room_manager.dart';
import 'package:pagla_chat/services/floating_bubble_service.dart';
import 'package:pagla_chat/services/gift_logic_helper.dart';
import 'package:pagla_chat/services/gift_service.dart';
import 'package:pagla_chat/services/marriage_service.dart';
import 'package:pagla_chat/services/room_active_manager.dart';
import 'package:pagla_chat/services/soulmate_xp_service.dart';

import 'package:pagla_chat/widgets/entry_effect_handler.dart';
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
  final RoomActiveManager _activeManager = RoomActiveManager();
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
  String roomName = "পাগলা চ্যাট রুম";
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
  bool isPKActive = false;
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
  StreamSubscription<DocumentSnapshot>? _marriageListener;
  StreamSubscription? _soulmateListener;
  StreamSubscription? _seatSubscription;
  StreamSubscription? _emojiSubscription;
  String lastProcessedEntryId =
      ""; // এটি চেক করবে কোন আইডিটা লাস্ট প্রসেস হয়েছে
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // স্ক্রিন যাতে অফ না হয়
    listenForSoulmateRequests();
    listenForMarriageRequests();
    // --- ১. মিনিমাইজড ডাটা রিকভারি লজিক ---
    if (FloatingBubbleService.isMinimized) {
      // যদি বাবল থেকে রুমে ফিরে আসে, তবে ম্যানেজার থেকে আগের ডাটা নিন
      currentSeatIndex = RoomManager().currentSeatIndex;
      debugPrint("মিনিমাইজড মোড থেকে ফিরেছি। সিট নম্বর: $currentSeatIndex");

      // রুমে ফিরে আসার পর বাবল স্ট্যাটাস রিসেট করুন
      FloatingBubbleService.isMinimized = false;
      FloatingBubbleService.hide();
    } else {
      // নতুন করে রুমে ঢুকলে ম্যানেজার রিসেট করুন
      RoomManager().reset();
      RoomManager().activeRoomId = widget.roomId;
    }

// Firestore থেকে রুমের ডাটা লিসেন করার জন্য
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId) // এখানে আপনার রুম আইডি
        .snapshots()
        .listen((snapshot) {
      if (!mounted || !snapshot.exists) return;

      var data = snapshot.data();

      if (data != null && data.containsKey('last_gift')) {
        var giftData = data['last_gift'];

        // ম্যাপ থেকে count রিড করা
        int currentCount =
            int.tryParse(giftData['count']?.toString() ?? "0") ?? 0;

        setState(() {
          // যদি আপনি নির্দিষ্ট কোনো ইউজারের জন্য স্কোর রাখতে চান, তবে এখানে সেই ইউজার আইডি বসাতে হবে
          // আপাতত রুমের গ্লোবাল কাউন্ট হিসেবে এটি সেভ করছি
          scores['global_room_gift'] = currentCount;
          debugPrint(
              "✅ [Firestore Debug] Updated Global Gift Count: $currentCount");
        });
      }
    });

    // ২. ইউজার এবং রুম ডাটা চেক
    _fetchMyuID().then((_) {
      // 🇧🇩 [বাংলা মার্ক]: bool লজিক চেক—ইউজার রুমে আছে এবং আইডি ফাঁকা না থাকলে টাইমার চলবে ভাই
      bool isUserValidForXp =
          uID.isNotEmpty && FirebaseAuth.instance.currentUser != null;

      if (isUserValidForXp) {
        // 🎯 আপনার ক্লাসের আসল 'uID' ভেরিয়েবলটি পাস করা হলো ভাই
        _activeManager.startTimer(
          uID: uID, // আপনার ৬ ডিজিটের ইউজার আইডি (যেমন: 978051)
          authUID: FirebaseAuth.instance.currentUser?.uid ??
              "", // ফায়ারবেসের লম্বা আইডি
          email: FirebaseAuth.instance.currentUser?.email ??
              "", // ইউজারের রেজিস্টার্ড ইমেইল
          minutesInterval: 20, // আপনার শর্ত অনুযায়ী ২০ মিনিট
          xpAmount: 1, // প্রতি ইন্টারভালে ১ এক্সপি
        );
      }

      // বাবল থেকে ফিরলে লাইভ স্ট্যাটাস নতুন করে আপডেট করার দরকার নেই
      if (!FloatingBubbleService.isMinimized) {
        _updateUserLiveStatus(widget.roomId);
        _fetchRoomData();
        _checkIfFollowing();
      }
    }); // 👈 🎯 ব্র্যাকেটের জোড়া এখানে পারফেক্টলি শেষ হলো ভাই, লাল দাগ উধাও!

    _initEmojiListener();

    // ৩. এন্ট্রি লজিক (বাবল থেকে ফিরলে এগুলো কল হবে না)
    if (!FloatingBubbleService.isMinimized) {
      _addUserToViewers();
      showMyOwnEntry();

      // 🇧🇩 [বাংলা মার্ক - লাইভ কাউন্ট ফিক্স]:
      // ইউজার যখন সম্পূর্ণ নতুনভাবে রুমে পা রাখবে, তখনই ফায়ারস্টোরে এই রুমের ইউজার কাউন্ট ১ বেড়ে যাবে ভাই।
      FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
        'userCount': FieldValue.increment(1),
      }).catchError(
          (e) => debugPrint("❌ রুমে ঢোকার সময় কাউন্ট বাড়াতে সমস্যা: $e"));
    }

    // লিসেনারটি একবারই সেট হবে
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        var data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey('lastEntry')) {
          var entry = data['lastEntry'];
          String currentEntryId = entry['entryId']?.toString() ?? "";

          // শুধু তখনই setState কল হবে যখন নতুন এন্ট্রি পাওয়া যাবে
          if (currentEntryId.isNotEmpty &&
              currentEntryId != lastProcessedEntryId) {
            setState(() {
              lastProcessedEntryId = currentEntryId;
              entryUserName = entry['name'];
              entryUserImage = entry['image'];
              currentEntryEffect = entry['activeEntryUrl'];
              entryUserFrame = entry['activeFrameUrl'];
              showEntryEffect = true;
            });
          }
        }
      }
    });

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

    // ৬. রিয়েলটাইম সিট লিসেনার
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
          seat["userFrame"] = "";
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
              seats[index]["userFrame"] =
                  value["activeFrameUrl"] ?? value["userFrame"] ?? "";
              seats[index]["isMicOn"] = value["isMicOn"] ?? false;
              seats[index]["userId"] =
                  value["authUID"] ?? value["userId"] ?? "";
              seats[index]["uID"] = value["uID"] ?? "";
              seats[index]["agorauID"] = value["agorauID"]?.toString() ?? "";
              seats[index]["giftCount"] =
                  int.tryParse(value["giftCount"]?.toString() ?? "0") ?? 0;
              // 🔥 গুরুত্বপূর্ণ: ডাটাবেজ থেকে নিজের সিট খুঁজে বের করে currentSeatIndex লক করা
              if (seats[index]["userId"] ==
                  FirebaseAuth.instance.currentUser?.uid) {
                currentSeatIndex = index;
              }
            }
          });
        }
      });
    });

    // ৭. এগোরা লজিক (রিপেল ঠিক করার জন্য পুরাতন কোড ফিরিয়ে আনা হলো)
    Future.microtask(() async {
      try {
        if (!FloatingBubbleService.isMinimized) {
          await _agoraManager.initAgora();
          final String authUID = FirebaseAuth.instance.currentUser?.uid ?? "";
          await _agoraManager.joinAsListener(widget.roomId, authUID);

          if (mounted) {
            _addUserToViewers();
          }
        }

        final engine = _agoraManager.engine;
        if (engine != null) {
          await engine.enableAudioVolumeIndication(
              interval: 250, smooth: 3, reportVad: true);

          engine.registerEventHandler(
            RtcEngineEventHandler(
              onAudioVolumeIndication:
                  (connection, speakers, totalVolume, speakerNumber) {
                if (!mounted) return;

                bool isMeTalking = false;
                for (var speaker in speakers) {
                  if (speaker.uid == 0 && (speaker.volume ?? 0) > 15) {
                    isMeTalking = true;
                    break;
                  }
                }

                if (_isMeTalkingNow != isMeTalking) {
                  // 🔥 রিপেল ফিরিয়ে আনার জন্য লোকাল স্টেট আপডেট
                  setState(() {
                    _isMeTalkingNow = isMeTalking;
                  });

                  // ডাটাবেজ আপডেট (আপনার পুরাতন কোড অনুযায়ী)
                  _updateTalkingStatus(isMeTalking);
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

        // ৫. ডিবাগ প্রিন্ট - এটি দেখে আপনি বুঝবেন আপনার আইডি কখন আসছে
        print("---------------------------");
        print("ROOM REFRESHED");
        print("My local uID: '$myuID'"); // এটি খালি থাকলে এডমিন কাজ করবে না
        print("Is Owner: $isOwner");
        print("Is Admin: $isAdmin");
        print("Admin List: $newAdminList");
        print("---------------------------");
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
        // আইডি পাওয়ার পর লিসেনার চালু করুন
        _listenForKickSignal();
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
        debugPrint(
            "🎯 সফল হয়েছে! মোট $updatedCount টি পুরাতন রুম আপডেট করা হয়েছে।");
      } else {
        debugPrint("✅ সব রুমে আগে থেকেই ফিল্ড আছে, কোনো রুম বাকি নেই!");
      }
    } catch (e) {
      debugPrint("❌ পুরাতন রুম আপডেট করতে গিয়ে এরর: ${e.toString()}");
    }
  }

  void _initEmojiListener() {
    _emojiSubscription?.cancel();
    debugPrint("📡 [LISTENER]: লিসেনার স্টার্ট হয়েছে।");

    _emojiSubscription = FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/seats')
        .onValue
        .listen((event) {
      if (!mounted || event.snapshot.value == null) return;

      final Map<dynamic, dynamic> seatsData =
          Map<dynamic, dynamic>.from(event.snapshot.value as Map);

      seatsData.forEach((key, value) {
        int index = int.tryParse(key.toString()) ?? -1;

        if (index != -1 && value is Map) {
          final String? emoji = value["currentEmoji"];
          final bool showEmoji = value["showEmoji"] ?? false;

          if (emoji != null && showEmoji == true) {
            debugPrint("🔥 [INCOMING]: সিট $index এর জন্য ইমোজি আসছে...");

            // পজিশন চেক এবং গ্লোবাল ডিবাগিং
            if (index >= seatPositions.length) {
              debugPrint(
                  "❌ [CRITICAL]: সিট $index আমাদের লিস্টের (Size: ${seatPositions.length}) বাইরে! পজিশন লিস্ট তৈরি হয়নি।");
            } else {
              double x = seatPositions[index].dx;
              double y = seatPositions[index].dy;

              if (x == 0 && y == 0) {
                debugPrint(
                    "⚠️ [RENDER_ISSUE]: ডাটা আসছে, কিন্তু আপনার ফোনের স্ক্রিন সিট $index এর পজিশন এখনো মাপতে পারেনি (0,0)!");
              } else {
                debugPrint(
                    "✅ [SUCCESS]: সিট $index এর পজিশন ওকে (X: $x, Y: $y)। এখন রেন্ডার হবে।");
              }
            }

            if (activeEmojis[index] != emoji) {
              if (mounted) {
                setState(() {
                  activeEmojis[index] = emoji;
                });
              }

              Timer(const Duration(seconds: 4), () {
                if (mounted) {
                  setState(() => activeEmojis.remove(index));
                  debugPrint(
                      "🗑️ [REMOVE]: সিট $index থেকে ইমোজি মুছে ফেলা হয়েছে।");
                }
              });
            }
          }
        }
      });
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

              // 🔥 ফিক্স: এক্সেপ্ট মেথডটি যেন ৬ ডিজিটের uID দিয়ে ফায়ারস্টোরে প্রোফাইল ম্যাচ করতে পারে,
              // কিন্তু কালেকশনের ডকুমেন্ট ডিলিটের সময় যেন ভুল না হয়, তাই myId এর জায়গায় 'authUID' হ্যান্ডেল করতে হবে।
              // তবে আপনার GiftService-এর ভেতর ডিলিট লজিক 'myId' দিয়ে করা। তাই আমরা 'myId' হিসেবে 'authUID' পাস করব
              // অথবা GiftService-এর ৫ নম্বর ডিলিট লাইনে requestRef-এর ভেতর 'myId' এর বদলে কারেন্ট ইউজারের লম্বা আইডি ব্যবহার করাই বেস্ট।

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

    try {
      // ১. ফায়ারস্টোরে কিক লিস্টে জমা করা এবং ফলোয়ার থেকে সরানো
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({
        'kickedUsers': FieldValue.arrayUnion([targetuID]),
        'followers': FieldValue.arrayRemove([targetuID]),
        'admins':
            FieldValue.arrayRemove([targetuID]), // এডমিন থাকলে তাকেও সরাতে হবে
      });

      // ২. রিয়েল-টাইম ডাটাবেসে একটি কিক সিগন্যাল পাঠানো
      // যাতে ইউজার অ্যাপে থাকা অবস্থায় সাথে সাথে রুম থেকে বের হয়ে যায়
      await FirebaseDatabase.instance
          .ref('rooms/${widget.roomId}/kickSignal/$targetuID')
          .set({
        'action': 'kicked',
        'timestamp': ServerValue.timestamp,
      });

      print("User $targetuID kicked and added to Kick List");
    } catch (e) {
      debugPrint("Kick Error: $e");
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

// ৩. ইউজারের মাইক অফ করা (Admin Control)
  Future<void> _muteUserByAdmin(String targetuID, int seatIndex) async {
    // ডাটাবেজে ওই সিটের মাইক অফ করে দেওয়া
    await FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/seats/$seatIndex')
        .update({'isMicOn': false, 'isMutedByAdmin': true});
  }

  void _updateUserLiveStatus(String roomId) async {
    String authUID = FirebaseAuth.instance.currentUser?.uid ?? "";

    print("---------- LIVE STATUS DEBUG ----------");

    try {
      // ১. আপনার ৬-ডিজিটের uID দিয়ে আপডেট ট্রাই করবে।
      // .update ব্যবহার করা হয়েছে যাতে নতুন কোনো খালি আইডি তৈরি না হয়।
      if (myuID.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(myuID).update({
          'currentRoomId': roomId,
        });
        print("✅ Status Updated for uID: $myuID");
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
        print("✅ Status Updated for AuthUID: $authUID");
      }
    } catch (e) {
      // যদি আইডি খুঁজে না পায় তবে এখানে আসবে, কিন্তু নতুন হিবিজিবি আইডি তৈরি হবে না।
      print(
          "ℹ️ Firestore Update Note: নির্দিষ্ট আইডিটি পাওয়া যায়নি, তাই নতুন কোনো ডকুমেন্ট তৈরি করা হয়নি।");
    }
    print("---------------------------------------");
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
          debugPrint(
              "🎉 [PaglaChat] myuID ($myuID) এর জন্য রুম স্ট্যাটাস ডিলিট হয়েছে।");
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
          debugPrint(
              "🎉 [PaglaChat] authUID ($authUID) এর জন্য রুম স্ট্যাটাস ডিলিট হয়েছে।");
        } else {
          // ডক না থাকলে কোনো এরর থ্রো করবে না, জাস্ট লগে ওয়ার্নিং দিয়ে স্কিপ করবে ভাই
          debugPrint(
              "⚠️ [PaglaChat Warning] users কালেকশনে authUID ($authUID) ডকটি পাওয়া যায়নি, তাই স্কিপ করা হলো।");
        }
      }
    } catch (e) {
      // এখন আর মেইন এরর আসবে না, তাও কোনো সমস্যা হলে লগে দেখতে পাবেন
      debugPrint("❌ Error clearing status: $e");
    }
  }

// ৪. ফলো/আনফলো লজিক
  void _toggleFollowUser(String targetId) async {
    String myId = FirebaseAuth.instance.currentUser?.uid ?? "";
    var userRef = FirebaseFirestore.instance.collection('users').doc(myId);

    // আপনার আগের লজিক অনুযায়ী ফলোয়ার লিস্ট আপডেট করুন
    // ... (Firebase logic)
  }

// ৫. চ্যাট বা ইনবক্সে নিয়ে যাওয়া
  void _goToInbox(String peerId, String peerName) {
    // Navigator.push দিয়ে আপনার চ্যাট স্ক্রিনে পাঠিয়ে দিন
  }

// এটি লাল দাগ দূর করবে এবং গিফট প্যানেল খুলবে
  void _openGiftPanel(String targetUserId) async {
    // ১. ইউজারের কারেন্ট ডায়মন্ড ব্যালেন্স আনা
    final String myId = FirebaseAuth.instance.currentUser?.uid ?? "";
    var userDoc =
        await FirebaseFirestore.instance.collection('users').doc(myId).get();
    int currentBalance = (userDoc.data()?['diamonds'] ?? 0).toInt();

    if (!mounted) return;

    // ২. গিফট শিট ওপেন করা
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GiftBottomSheet(
        diamondBalance: currentBalance,
        currentSeats: List.from(seats),
        onGiftSend: (gift, count, target) async {
          // এখানে আপনার গিফট পাঠানোর ট্রানজেকশন লজিক কাজ করবে
          print("Sending ${gift['name']} to $target");
        },
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

        debugPrint("🚀 এন্ট্রি ডাটা রুম এবং মেসেজে পাঠানো হয়েছে!");
      }
    } catch (e) {
      debugPrint("Entry Error: $e");
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
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('messages')
            .add({
          'name': userData['name'] ?? "User",
          'uID': userData['uID'] ?? "",
          'profilePic': userData['profilePic'] ?? "",
          'timestamp': FieldValue.serverTimestamp(),
        });
        // 🔥 কোড শেষ
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
              debugPrint(
                  "DEBUG: Room update received. lastEntry ID: ${roomData['lastEntry']?['entryId']}");
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
                      Timer(const Duration(seconds: 5), () {
                        if (mounted) setState(() => isGiftAnimating = false);
                      });
                    }
                  });
                }
              }

              // --- এন্ট্রি ইফেক্ট লজিক (Simplified & Guaranteed) ---
              if (roomData.containsKey('lastEntry') &&
                  roomData['lastEntry'] != null) {
                var lastEntry = roomData['lastEntry'];
                String currentEntryId = lastEntry['entryId']?.toString() ?? "";

                // প্রিন্ট দিয়ে চেক করুন কন্ডিশন কেন কাজ করছে না
                // debugPrint("Current: $currentEntryId, Last: $lastProcessedEntryId, Showing: $showEntryEffect");

                if (currentEntryId.isNotEmpty &&
                    currentEntryId != lastProcessedEntryId) {
                  String? effectLink = lastEntry['activeEntryUrl'];

                  if (effectLink != null && effectLink.isNotEmpty) {
                    // আমরা প্রথমেই আইডি সেভ করে নেব যাতে লুপ না হয়
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
                      }
                    });
                  }
                }
              }
            }
            return Stack(
              children: [
                // ১. ওয়ালপেপার
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

                // ২. মেইন UI
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
                      // 🔥 widget এর লাল দাগ সম্পূর্ণ ফিক্স করে আপডেটেড কোড
                      Expanded(
                        flex: 2,
                        child: Stack(
                          clipBehavior: Clip
                              .none, // যেন হার্ট এনিমেশন বর্ডারের বাইরে গেলেও কেটে না যায়
                          children: [
                            // ১. আপনার সম্পূর্ণ আগের অক্ষত সিট এরিয়া (RepaintBoundary সহ)
                            RepaintBoundary(child: _buildSeatGridArea()),

                            // ২. সোলমেট হার্টের জন্য লাইভ ডাটা লেয়ার
                            StreamBuilder<DatabaseEvent>(
                              stream: FirebaseDatabase.instance
                                  .ref('rooms/${widget.roomId}/seats')
                                  .onValue,
                              builder: (context, snapshot) {
                                List<dynamic> seatsListForOverlay = [];
                                if (snapshot.hasData &&
                                    snapshot.data!.snapshot.value != null) {
                                  final dynamic value =
                                      snapshot.data!.snapshot.value;
                                  if (value is Map) {
                                    for (int i = 0; i < 15; i++) {
                                      seatsListForOverlay
                                          .add(value[i.toString()] ?? value[i]);
                                    }
                                  } else if (value is List) {
                                    seatsListForOverlay = value;
                                  }
                                }

                                // ফায়ারবেস কারেন্ট ইউজারের লম্বা আইডি
                                final String currentAuthUID =
                                    FirebaseAuth.instance.currentUser?.uid ??
                                        "";

                                // 🔥 ফিক্স: সরাসরি কালেকশন কুয়েরি করা হচ্ছে যেন ডকুমেন্ট আইডি ৬ ডিজিটের হলেও ডাটা নিখুঁতভাবে পাওয়া যায়
                                return StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .where('authUID',
                                          isEqualTo: currentAuthUID)
                                      .snapshots(),
                                  builder: (context, userSnapshot) {
                                    String dynamicPartnerId = "";

                                    // যদি authUID দিয়ে না পায়, তবে ব্যাকআপ হিসেবে userId ফিল্ড দিয়ে খুঁজবে
                                    if (userSnapshot.hasData &&
                                        userSnapshot.data!.docs.isNotEmpty) {
                                      var uDoc = userSnapshot.data!.docs.first
                                          .data() as Map<String, dynamic>;
                                      dynamicPartnerId =
                                          uDoc['soulmateId']?.toString() ??
                                              uDoc['marriagePartnerId']
                                                  ?.toString() ??
                                              "";
                                    } else {
                                      // ২য় ব্যাকআপ কুয়েরি বা ডিরেক্ট রিড (যদি আগের কোন সিস্টেমে মিল থাকে)
                                      return StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('users')
                                            .where('userId',
                                                isEqualTo: currentAuthUID)
                                            .snapshots(),
                                        builder: (context, backupSnapshot) {
                                          if (backupSnapshot.hasData &&
                                              backupSnapshot
                                                  .data!.docs.isNotEmpty) {
                                            var uDoc = backupSnapshot
                                                .data!.docs.first
                                                .data() as Map<String, dynamic>;
                                            dynamicPartnerId =
                                                uDoc['soulmateId']
                                                        ?.toString() ??
                                                    uDoc['marriagePartnerId']
                                                        ?.toString() ??
                                                    "";
                                          }

                                          print(
                                              "🔎 [ROOM SCREEN LOG] আমার UID: $currentAuthUID | পার্টনার ID (Backup): '$dynamicPartnerId'");

                                          return SoulmateAnimationService
                                              .buildSoulmateHeartOverlay(
                                            seats: seatsListForOverlay,
                                            myCurrentAuthUID: currentAuthUID,
                                            myPartnerAuthUID: dynamicPartnerId,
                                          );
                                        },
                                      );
                                    }

                                    print(
                                        "🔎 [ROOM SCREEN LOG] আমার UID: $currentAuthUID | পার্টনার ID (Main): '$dynamicPartnerId'");

                                    return SoulmateAnimationService
                                        .buildSoulmateHeartOverlay(
                                      seats: seatsListForOverlay,
                                      myCurrentAuthUID: currentAuthUID,
                                      myPartnerAuthUID: dynamicPartnerId,
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
                  Positioned(
                    left: playerPosition.dx,
                    top: playerPosition.dy,
                    child: Draggable(
                      feedback: _buildFloatingPlayer(isDragging: true),
                      childWhenDragging: Container(),
                      onDragEnd: (details) =>
                          setState(() => playerPosition = details.offset),
                      child: _buildFloatingPlayer(isDragging: false),
                    ),
                  ),
                // ৬. টুলস ও ওভারলে

                FloatingRoomTools(
                  onGiftCountStart: (minutes, theme) =>
                      _startGiftCounting(minutes, theme),
                  seats: seats,
                ),
                // Stack এর ভেতর এই অংশটি বসান:

                // আপনার Stack এর ভেতরে এই অংশটি এভাবে আপডেট করুন:

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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // --- ১. সেন্ডার বা এন্ট্রি ইউজারের ছবি ---
          if (sImg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: CircleAvatar(
                radius: 9,
                backgroundColor: Colors.white10,
                backgroundImage: NetworkImage(sImg),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child:
                  Icon(Icons.account_circle, size: 18, color: Colors.white24),
            ),

          Text(
            "$uName ",
            style: const TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),

          Text(
            isGift ? "sent a gift to " : "entered the room",
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),

          // --- ২. রিসিভারের ছবি ও নাম (শুধু গিফট হলে) ---
          if (isGift && targetName.isNotEmpty) ...[
            const SizedBox(width: 5),
            if (rImg.isNotEmpty && rImg.startsWith('http'))
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: CircleAvatar(
                  radius: 9,
                  backgroundImage: NetworkImage(rImg),
                ),
              ),
            Text(
              targetName,
              style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ],

          // --- ৩. গিফট আইকন ও কাউন্ট ---
          if (isGift) ...[
            const SizedBox(width: 6),
            Image.network(
              data['giftImage'] ?? '',
              height: 18,
              width: 18,
              errorBuilder: (c, e, s) => const Icon(Icons.card_giftcard,
                  size: 14, color: Colors.orange),
            ),
            Text(
              " x${data['giftCount'] ?? '1'}",
              style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildFloatingEmojiAnimations() {
    if (activeEmojis.isEmpty) return [];

    return activeEmojis.entries.map((entry) {
      int seatIndex = entry.key; // আপনার ভেরিয়েবল নাম seatIndex
      String lottieUrl = entry.value;

      // ১. রেঞ্জ চেক
      if (seatIndex < 0 || seatIndex >= seatPositions.length) {
        // এখানে $index ছিল, তাই লাল দাগ আসছিল। এটাকে $seatIndex করে দিয়েছি।
        debugPrint(
            "🚫 [UI_BLOCK]: সিট $seatIndex এর পজিশন নেই, তাই উইজেট রেন্ডার করা গেল না।");
        return const SizedBox();
      }

      double leftPos = seatPositions[seatIndex].dx;
      double topPos = seatPositions[seatIndex].dy;

      // ২. জিরো পজিশন চেক
      if (leftPos == 0 && topPos == 0) {
        debugPrint(
            "📍 [UI_BLOCK]: সিট $seatIndex এর পজিশন (0,0)। ইউজার হয়তো স্ক্রিনের কোণায় বা আড়ালে ইমোজি দেখছে।");
        return const SizedBox();
      }

      return Positioned(
        left: leftPos - 25,
        top: topPos - 60,
        key: ValueKey('emoji_$seatIndex'),
        child: IgnorePointer(
          child: SizedBox(
            width: 80,
            height: 80,
            child: Lottie.network(
              lottieUrl,
              repeat: false,
              animate: true,
              fit: BoxFit.contain,
              onLoaded: (composition) {
                debugPrint(
                    "🎬 [ANIMATION]: সিট $seatIndex এ ইমোজি প্লে হচ্ছে!");
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint("❌ [LOTTIE_ERROR]: ইমোজি লোড হতে পারেনি: $error");
                return const Icon(Icons.error, color: Colors.red);
              },
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
      debugPrint("মিনিমাইজড মোড: রুম ব্যাকগ্রাউন্ডে সচল রাখা হচ্ছে।");

      // নোট: এখানে return করার মানে হলো নিচের কোনো ক্লিনআপ কোড এক্সিকিউট হবে না।
      // ফলে আপনার Firestore বা Realtime Database এ সিট খালি হবে না।
      super.dispose();
      return;
    }

    // --- ২. যদি বাবল না থাকে (ইউজার যখন সরাসরি Exit বাটন চেপে বের হবে) ---

    debugPrint("ফুল এক্সিট: রুমের সব লজিক ক্লিনআপ করা হচ্ছে।");

    // 🇧🇩 [বাংলা মার্ক]: ইউজার সম্পূর্ণ এক্সিট করলে রিয়েল-টাইম একটিভ এক্সপি টাইমারটি বন্ধ করা হলো ভাই
    _activeManager.stopTimer();

    // 🇧🇩 [বাংলা মার্ক - ১০০% ফুলপ্রুফ কাউন্ট রিলিজ ফিক্স]:
    // ইউজার যখন বাবল ছাড়া সরাসরি রুম থেকে বের হবে, তখন ডাটাবেজের মান নিখুঁতভাবে চেক করে কমানো হবে।
    final roomRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    roomRef.get().then((doc) {
      if (doc.exists && doc.data() != null) {
        int currentCount = doc.data()?['userCount'] ?? 0;
        // সেফটি লজিক: যদি কাউন্ট ১ বা তার কম হয়, তবে সরাসরি ০ হবে। আর বেশি থাকলে ১ কমবে।
        int newCount = (currentCount <= 1) ? 0 : (currentCount - 1);

        roomRef
            .update({'userCount': newCount})
            .then((_) => debugPrint(
                "🎉 [PaglaChat] ইউজার বের হয়েছে সফলভাবে, নতুন লাইভ কাউন্ট: $newCount"))
            .catchError((e) => debugPrint("❌ কাউন্ট আপডেট করতে সমস্যা: $e"));
      }
    }).catchError((e) => debugPrint("❌ ফায়ারস্টোর ডাটা রিড করতে সমস্যা: $e"));

    // ৩. ভিউয়ার লিস্ট থেকে ব্যবহারকারীকে সরিয়ে ফেলা
    _removeUserFromViewers();
    _clearUserLiveStatus();

    // ৪. স্ট্রীম এবং লুপ বন্ধ করা (সবচেয়ে জরুরি)
    _seatSubscription?.cancel();
    _emojiSubscription?.cancel();
    giftTimer?.cancel();
    _soulmateListener?.cancel();
    _marriageListener?.cancel();

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

    //6. কন্ট্রোলার এবং পিকে ম্যানেজার বন্ধ করা
    if (isPKActive) pkManager.stopPK();
    _audioPlayer.dispose();
    _messageController.dispose();

    // VII. স্ক্রিন অফ হওয়ার পারমিশন রিস্টোর করা (Wakelock বন্ধ করা)
    WakelockPlus.disable();

    // ७. এগোরা ইঞ্জিন রিলিজ করা
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
            bool isVipSeat = index < 5;

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

                  // ৩. VIP চেক
                  if (!isOwner && isVipSeat && (userRole != "VIP")) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          "This is a VIP King Seat! Upgrade to VIP to sit here."),
                      backgroundColor: Colors.amber,
                      behavior: SnackBarBehavior.floating,
                    ));
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
                                              _buildAdminAction(
                                                // ১. ডাটাবেসের 'isMicOn' ভ্যালু দেখে আইকন এবং কালার পরিবর্তন হবে
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
                                                    : Colors.white70,

                                                onTap: () async {
                                                  // ১. এখান থেকে ইউজারের আইডি বের করা হচ্ছে
                                                  String seatUserId =
                                                      seatData?['userId']
                                                              ?.toString() ??
                                                          seatData?['uID']
                                                              ?.toString() ??
                                                          '';

                                                  // ২. বর্তমান লগইন করা ইউজারের আইডি নেওয়া (লাল দাগ দূর করার জন্য)
                                                  final String currentUserId =
                                                      FirebaseAuth
                                                              .instance
                                                              .currentUser
                                                              ?.uid ??
                                                          '';
                                                  // সিট ইনডেক্স বের করা
                                                  int sIndex =
                                                      seatData?['index'] ?? -1;
                                                  if (sIndex == -1) return;

                                                  // বর্তমান অবস্থা কি সেটা দেখা (true মানে মাইক অন, false মানে অফ)
                                                  bool currentMicStatus =
                                                      seatData?['isMicOn'] ??
                                                          true;
                                                  bool newMicStatus =
                                                      !currentMicStatus;

                                                  try {
                                                    // হ্যাপটিক ভাইব্রেশন
                                                    try {
                                                      HapticFeedback
                                                          .lightImpact();
                                                    } catch (_) {}

                                                    // ২. ফায়ারবেসে আপডেট করা
                                                    // এডমিন যখন 'Mute' চাপবে, ডাটাবেসে 'isMicOn' false হয়ে যাবে
                                                    await FirebaseDatabase
                                                        .instance
                                                        .ref(
                                                            'rooms/${widget.roomId}/seats/$sIndex')
                                                        .update({
                                                      'isMicOn': newMicStatus,
                                                      'isTalking':
                                                          false, // সাউন্ড অফ করার সাথে সাথে টকিং এনিমেশনও বন্ধ
                                                    });

                                                    // ৩. যদি এডমিন নিজেই নিজের সিটে বসা থাকে, তবে সরাসরি তার এগোরা মাইক অফ হবে
                                                    if (seatUserId ==
                                                            currentUserId &&
                                                        _agoraManager.engine !=
                                                            null) {
                                                      await _agoraManager
                                                          .toggleMic(
                                                              !newMicStatus);
                                                    }

                                                    // ডায়ালগ বন্ধ করা (ঐচ্ছিক, চাইলে রাখতে পারেন)
                                                    // Navigator.pop(context);
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
                  mainAxisSize: MainAxisSize.min, // ✅ কন্টেন্ট অনুযায়ী সাইজ হবে
                  children: [
                    // ✅ RepaintBoundary যোগ করা হয়েছে যাতে VoiceRipple শুধু নিজের এরিয়া রেন্ডার করে
                    // এর ফলে ভিউয়ার লিস্ট বা পাশের উইজেটগুলো কাঁপবে না।
                    RepaintBoundary(
                      child: VoiceRipple(
                        isTalking: isTalking,
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
                                            color:
                                                Colors.amber.withOpacity(0.2),
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
                                            : (isVipSeat
                                                ? Icons.workspace_premium
                                                : Icons.chair_rounded),
                                        color: (seatData != null &&
                                                seatData['isLocked'] == true)
                                            ? Colors.redAccent
                                            : (isVipSeat
                                                ? Colors.amber.withOpacity(0.6)
                                                : Colors.white12),
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
                                  child: Icon(
                                      isMicOn ? Icons.mic : Icons.mic_off,
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
          // ১. ইমোজি বাটন 😄
          buildCircularIcon(Icons.emoji_emotions_outlined,
              const Color.fromARGB(255, 250, 143, 2), () async {
            final String authId = FirebaseAuth.instance.currentUser?.uid ?? "";
            debugPrint("🔘 DEBUG: Emoji Button Clicked by AuthID: $authId");

            // ইউজারের আইডি বের করা
            var userSnap = await FirebaseFirestore.instance
                .collection('users')
                .where('authUID', isEqualTo: authId)
                .limit(1)
                .get();

            if (userSnap.docs.isEmpty) {
              debugPrint("❌ DEBUG: User not found in Firestore!");
              return;
            }

            String myActualId = userSnap.docs.first.id;
            debugPrint("👤 DEBUG: Found MyActualID: $myActualId");

            // 🔥 সিটে চেক করার সময় লক ডাটা থাকলেও যেন ইউজারকে খুঁজে পায়
            int mySeatIndex = seats.indexWhere((s) {
              if (s == null) return false;
              var uID = s['uID'] ?? s['userId'] ?? s['uid'];
              return uID.toString() == myActualId;
            });

            debugPrint("🪑 DEBUG: Seat Search Result Index: $mySeatIndex");

            if (mySeatIndex != -1) {
              EmojiHandler.showPicker(
                  context: context,
                  seatIndex: mySeatIndex,
                  onEmojiSelected: (index, url) {
                    if (index != -1 && url != null) {
                      debugPrint(
                          "🎭 DEBUG: Emoji Selected: $url for Seat: $index");

                      DatabaseReference seatRef = FirebaseDatabase.instance
                          .ref('rooms/${widget.roomId}/seats/$index');

                      // ✅ শুধুমাত্র ইমোজি ডাটা আপডেট হবে
                      seatRef.update({
                        'currentEmoji': url,
                        'showEmoji': true,
                        'emojiTime': ServerValue.timestamp,
                      }).then((_) {
                        debugPrint(
                            "✅ DEBUG: Emoji updated in RTDB for seat $index");
                      });

                      // ৩ থেকে ৪ সেকেন্ড পর রিমুভ লজিক
                      Future.delayed(const Duration(seconds: 4), () {
                        if (mounted) {
                          seatRef.update({'showEmoji': false});
                          debugPrint(
                              "🗑️ DEBUG: showEmoji set to false after 4s");
                        }
                      });
                    }
                  });
            } else {
              debugPrint(
                  "🚫 DEBUG: User is NOT on any seat. Showing SnackBar.");
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
          _buildCircularIcon(Icons.hotel, Colors.purpleAccent,
              () {}), // <--- এখানে একটা কমা বা সেমিকোলন নিশ্চিত করুন এবং ব্র্যাকেট খেয়াল করুন

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

          // ১. নিজের তথ্য এবং ব্যালেন্স আনা
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              "পর্যাপ্ত ডায়মন্ড নেই! খরচ: $totalAmount, আছে: $currentBalance"),
                          backgroundColor: Colors.orange),
                    );
                    return;
                  }

                  if (senderDocID.isNotEmpty && receiverDocID.isNotEmpty) {
                    // বক্স লজিকসহ সব প্যারামিটার পাঠানো হচ্ছে
                    await GiftLogicHelper.processGift(
                      senderAuthId: senderDocID,
                      targetAuthId: receiverDocID,
                      gift: gift,
                      count: count,
                      roomId: widget.roomId,
                      senderName: senderName,
                      roomOwnerAuthId: widget.ownerId,
                      // পুরাতন প্যারামিটারগুলো এখানে যোগ করে দেওয়া হলো যাতে কিছু হারিয়ে না যায়:
                      senderImage: senderImgUrl,
                      receiverImage: receiverImgUrl,
                      giftName: gift['name'] ?? "Gift",
                    );

                    // 🇧🇩 [বাংলা মার্ক]: গিফট ট্রানজেকশন সফল হওয়ার পর এক্সপি বাড়ানোর রিয়েল-টাইম লজিক
                    if (!isFree && totalAmount > 0) {
                      final firestore = FirebaseFirestore.instance;

                      // 🎯 ২৫০ ডায়মন্ড খরচ হলে ১ এক্সপি যোগ হবে (ভাগফল বের করা হলো ভাই)
                      int calculatedXp = totalAmount ~/ 700;

                      if (calculatedXp > 0) {
                        // ১. যে গিফট পাঠালো (Sender): তার শুধু গিফট লেভেল এক্সপি (totalGiftXp) বাড়বে ভাই
                        await firestore
                            .collection('users')
                            .doc(senderDocID)
                            .update({
                          'totalGiftXp': FieldValue.increment(calculatedXp),
                        });

                        // ২. যে গিফট রিসিভ করলো (Receiver): তার একটিভ এক্সপি বার (totalActiveXp) বাড়বে ভাই
                        await firestore
                            .collection('users')
                            .doc(receiverDocID)
                            .update({
                          'totalActiveXp': FieldValue.increment(calculatedXp),
                        });

                        // 🔍 [সঠিক লগ]: ভিআইপি টেক্সট সরিয়ে আপনার দেওয়া নতুন ফিচারের নাম সেট করা হলো ভাই
                        debugPrint(
                            "🔥 [PaglaChat Level System] XP Updated: Sender +$calculatedXp GiftXP, Receiver +$calculatedXp ActiveXp (ডায়মন্ড খরচ ছিল: $totalAmount)");
                      } else {
                        debugPrint(
                            "ℹ️ [PaglaChat] খরচ করা ডায়মন্ড ২৫০ এর কম হওয়ায় এক্সপি যোগ হয়নি ভাই।");
                      }
                    }
                  } else {
                    return;
                  }
                } catch (e) {
                  debugPrint("Transaction Error: $e");
                  return;
                }

                // গিফট পাঠানোর পর সিটের কাউন্ট আপডেট করার লজিক (এটি আপনার onGiftSend ফাংশনে যোগ করুন)

                if (receiverDocID.isNotEmpty &&
                    target != "All Room" &&
                    target != "All Mic") {
                  // ১. আপনার সিট লিস্ট থেকে রিসিভারের ইনডেক্স খুঁজে বের করুন
                  int seatIndex = seats.indexWhere((s) =>
                      s != null &&
                      (s['uID']?.toString() == receiverDocID ||
                          s['userId']?.toString() == receiverDocID));

                  if (seatIndex != -1) {
                    // ২. ফায়ারস্টোর রুমের ভেতর ওই সিটের জন্য গিফট কাউন্ট আপডেট করুন
                    await FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(widget.roomId)
                        .update({
                      // আপনার ডাটাবেস স্ট্রাকচার অনুযায়ী: seats.0.giftCount
                      'seats.$seatIndex.giftCount': FieldValue.increment(count),
                    });

                    debugPrint(
                        "🔥 [Seat Counter] সিট ইনডেক্স $seatIndex এ $count টি গিফট যোগ হয়েছে।");
                  }
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

                // ১. একদম শুরুতে এই ভ্যারিয়েবলটি তৈরি করে নিন
                bool isFree =
                    (gift['isFree'] == true) || (gift['expiry'] != null);
                // 🔥 ৫. সোলমেট রিকোয়েস্ট ও এক্সপি আপডেট প্রসেসর
                if (gift['id'] == 'soulmate_special') {
                  try {
                    print(
                        "💕 সোলমেট গিফট ডিটেক্ট হয়েছে! রিসিভারের লম্বা ফায়ারবেস UID খোঁজা হচ্ছে...");
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
                        'fromAuthUID': FirebaseAuth.instance.currentUser!.uid,
                        'fromName': senderName,
                        'fromImg': senderImgUrl,
                        'timestamp': FieldValue.serverTimestamp(),
                        'status': 'pending',
                      });
                      print("🎯 সোলমেট রিকোয়েস্ট সফলভাবে পাঠানো হয়েছে!");
                    }
                  } catch (soulmateError) {
                    print("Error sending soulmate request: $soulmateError");
                  }
                } else {
                  // 🔥 সোলমেট এক্সপি আপডেট লজিক
                  if (!isFree &&
                      totalAmount > 0 &&
                      target != "All Room" &&
                      target != "All Mic") {
                    // আপনার আগের লুপ কোড, যা থেকে আপনি receiverDocID এর ৬ ডিজিটের আইডি পাচ্ছেন
                    String receiverSixDigitId = "";
                    if (seats.isNotEmpty) {
                      for (var seat in seats) {
                        if (seat["uID"]?.toString() == receiverDocID ||
                            seat["userId"]?.toString() == receiverDocID ||
                            seat["authUID"]?.toString() == receiverDocID) {
                          // লুপ থেকেই সরাসরি ৬ ডিজিটের আইডি (uID) সেট করুন
                          receiverSixDigitId = seat["uID"]?.toString() ?? "";
                          break;
                        }
                      }
                    }

                    // যদি লুপ থেকে না পাওয়া যায়, তবে receiverDocID কে ব্যবহার করুন
                    if (receiverSixDigitId.isEmpty)
                      receiverSixDigitId = receiverDocID;

                    // সেন্ডারের আইডি (আপনার কাছে নিশ্চয়ই 'senderDocID' বা similar কোনো ভেরিয়েবল আছে)
                    String senderSixDigitId = senderDocID;

                    // সরাসরি ৬ ডিজিটের আইডি দিয়ে ফাংশন কল করুন, কোনো নতুন কুয়েরি লাগবে না
                    if (senderSixDigitId.isNotEmpty &&
                        receiverSixDigitId.isNotEmpty) {
                      SoulmateXpService.updateSoulmateXP(
                          senderSixDigitId, receiverSixDigitId, totalAmount);
                    }
                  }
                }
                // 🔥 ৫. ম্যারেজ রিং রিকোয়েস্ট প্রসেসর (জেন্ডার, সেম পার্টনার ব্যাকপ্যাক ও ওল্ড ম্যারেজ প্রটেকশন লজিক)
                if (gift['type'] == 'marriage_ring' ||
                    gift['type'] == 'vip_marriage') {
                  try {
                    print(
                        "💍 ম্যারেজ রিং ডিটেক্ট হয়েছে! পার্টনার স্ট্যাটাস, জেন্ডার ও লম্বা ফায়ারবেস UID চেক করা হচ্ছে...");

                    String receiverAuthUID = "";
                    String myGender = "Unknown";
                    String partnerGender = "Unknown";
                    final String myCurrentAuthUID =
                        FirebaseAuth.instance.currentUser?.uid ?? '';

                    // ১. সিট লিস্ট থেকে নিজের ও পার্টনারের জেন্ডার এবং পার্টনারের লম্বা ফায়ারবেস UID খুঁজে বের করা
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

                    print(
                        "💍 [DEBUG] আমার জেন্ডার: $myGender, পার্টনারের জেন্ডার: $partnerGender");
                    print("💍 [DEBUG] রিসিভারের লম্বা UID: $receiverAuthUID");

                    // ২. একই লিঙ্গের হলে রিং পাঠানো আটকে দেওয়া
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

                    // 🔒 [সিকিউরিটি লজিক]: ডাটাবেজ থেকে চেক করা হচ্ছে ইউজারের অলরেডি কোনো পার্টনার আছে কিনা
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

                    // 👥 কন্ডিশন এ: যদি রিসিভার অলরেডি কারেন্ট ইউজারের নিজেরই পার্টনার হয় (সেম পার্টনার হলে ডিরেক্ট ব্যাকপ্যাক)
                    if (myCurrentPartner != null &&
                        myCurrentPartner == receiverAuthUID) {
                      print(
                          "🎁 সেম পার্টনার ডিটেক্টেড! রিং সরাসরি 'my_special' ব্যাকপ্যাকে পাঠানো হচ্ছে...");

                      // 🔥 ফিক্স: আপনার _buildMySpecialTab এর ফিল্ড নেমগুলোর সাথে ১০০% মিল রেখে ডাটা ইনসার্ট করা হলো
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(
                              receiverAuthUID) // রিসিভার পার্টনারের ব্যাকপ্যাকে যাবে
                          .collection('my_special')
                          .add({
                        'name': gift['name'] ?? 'Marriage Ring',
                        'image_url': gift['icon'] ??
                            '', // আপনার ব্যাকপ্যাকের url ভ্যারিয়েবলের সাথে মিল রেখে
                        'type': 'Marriage Ring', // টাইপ সেট করা হলো
                        'expiryDate': Timestamp.fromDate(DateTime.now().add(
                            const Duration(days: 30))), // ডিফল্ট ৩০ দিন মেয়াদ
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
                      return; // ডায়মন্ড ডিস্ট্রিবিউশন লজিক স্কিপ করতে এখানেই রিটার্ন করা হলো (ইউজার ডায়মন্ড পাবে না)
                    }

                    // 🚫 কন্ডিশন বি: যদি ইউজারের আগে থেকেই অন্য কোনো পার্টনারের সাথে বিয়ে বা রিং থাকে
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

                    // ৩. নতুন রিলেশনের জন্য পেন্ডিং রিকোয়েস্ট পাঠানো (আইডি সঠিক থাকলে)
                    if (receiverAuthUID.isNotEmpty &&
                        receiverAuthUID.length > 15) {
                      // 💎 [ডায়মন্ড প্রোটেকশন]: রিং গিফটের ক্ষেত্রে কোনো ডায়মন্ড আর্নিং হবে না, শুধু রিং এর ডেটা যাবে
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
                      } else {
                        print(
                            "🎯 ম্যারেজ রিং রিকোয়েস্ট সফলভাবে $receiverAuthUID এর কাছে পেন্ডিং পাঠানো হয়েছে!");
                      }
                    } else {
                      print(
                          "❌ এরর: রিসিভারের লম্বা authUID পাওয়া যায়নি বা ইনভ্যালিড!");
                    }
                  } catch (marriageError) {
                    print("Error sending marriage request: $marriageError");
                  }
                }

                // 🔥 ৫. ফায়ারবেস রুম ব্যানার এবং ডেলি পয়েন্ট আপডেট (২৫০ ডায়মন্ডে ১ পয়েন্ট)
                int pointsToIncrement = totalAmount ~/ 250;

                // এখানে পুরাতন মেইন ব্যানার ফিচারের ম্যাপটি তৈরি করা হলো (যাতে আগের ফিচার ঠিক থাকে)
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

                // যদি পয়েন্ট ১ বা তার বেশি হয়, তবেই এই ম্যাপের ভেতর 'dailyPoints' ফিল্ডটি যুক্ত হবে
                if (pointsToIncrement > 0) {
                  roomUpdateData['dailyPoints'] =
                      FieldValue.increment(pointsToIncrement);
                }

                // এবার একটি মাত্র আপডেট রিকোয়েস্টে ব্যানার ও ডেলি পয়েন্ট একসাথে সেভ হবে (কোনো কোড মিস হবে না)
                await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(widget.roomId)
                    .update(roomUpdateData);

                // 🔥 ৫.১ টপ গিফটার লিডারবোর্ডের সাব-কালেকশন আপডেট
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

                // 🔥 ৬. মেসেজ লিস্টে ছবিসহ গিফট হিস্ট্রি পাঠানো (পুরাতন ফিচার অক্ষুণ্ন রাখা হলো)
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

                // ৭. এনিমেশন টাইমার
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
      onMinimize: () {
        // ১. আগে ফ্ল্যাগটি ট্রু করুন (যাতে dispose বুঝতে পারে এটি মিনিমাইজ)
        FloatingBubbleService.isMinimized = true;

        // ২. ইমেজ ইউআরএল সেট করা
        String imageUrl = roomProfileImage.isNotEmpty
            ? roomProfileImage
            : 'https://via.placeholder.com/150';

        // ৩. গ্লোবাল বাবল দেখানো
        FloatingBubbleService.show(
          context,
          widget.roomId,
          imageUrl,
          widget, // বর্তমান রুম উইজেট (VoiceRoom)
        );

        // ৪. সবশেষে পপ করুন (রুম পেজ থেকে বের হওয়া)
        Navigator.of(context).pop();

        // ইউজারকে মেসেজ দেখানো
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("রুম মিনিমাইজ করা হয়েছে"),
            duration: Duration(seconds: 2),
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

  // একদম নিচের দিকে, শেষ ব্র্যাকেটের একটু উপরে এই ফাংশনটি বসান
  void _leaveRoomInternally() async {
    try {
      if (_agoraManager.engine != null) {
        await _agoraManager.engine?.leaveChannel();
      }
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
      debugPrint("Error: $e");
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
