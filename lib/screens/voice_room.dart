import 'package:flutter/services.dart';
import 'package:pagla_chat/room_follower_sheet.dart';
import '../services/gift_transaction_helper.dart';
import 'package:pagla_chat/inbox_page.dart'; // ফাইল পাথ অনুযায়ী এটি দিন
import 'package:pagla_chat/widgets/voice_ripple.dart';
import 'dart:math';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 🔥 dart:io সরানো হয়েছে, kIsWeb ব্যবহারের জন্য foundation যোগ করা হয়েছে
import 'package:flutter/foundation.dart'; 
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import '../services/room_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:pagla_chat/room_sync_service.dart';
import 'package:pagla_chat/services/database_service.dart';
import 'package:pagla_chat/services/soulmate_animation_service.dart';
import 'package:pagla_chat/services/agora_status_checker.dart';
// --- নতুন আলাদা করা ফাইলগুলোর ইম্পোর্ট ---
import 'package:pagla_chat/services/seat_sync_service.dart'; // সিট সিঙ্ক করার জন্য
import 'package:pagla_chat/widgets/live_viewers_list.dart';   // ভিউয়ার লিস্ট দেখানোর জন্য
// আপনার সব ফাইল ইমপোর্ট
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
import 'package:pagla_chat/services/agora_manager.dart'; // আপনার ফাইলের নাম অনুযায়ী পাথ ঠিক করুন

import '../widgets/chat_input_bar.dart';
import '../widgets/emoji_handler.dart';
import '../widgets/gift_overlay_handler.dart';
import '../widgets/gift_system.dart';
import '../widgets/music_player_widget.dart';
import '../widgets/room_profile_handler.dart';
import '../widgets/room_settings_handler.dart';
import 'package:firebase_storage/firebase_storage.dart'; // এটি নেই, এটি যোগ করতে হবে
import 'package:image_picker/image_picker.dart'; // গ্যালারি থেকে ছবি নিতে এটি লাগবে

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
 final RoomService _roomService = RoomService();
 final RoomSyncService _syncService = RoomSyncService();
 final DatabaseService _dbService = DatabaseService();
 final AgoraManager _agoraManager = AgoraManager();

  // --- বিল্ড এরর ফিক্স করার জন্য নতুন ভ্যারিয়েবল (অবশ্যই যোগ করবেন) ---
  Map<int, String> activeEmojis = {}; // ইমোজি ডাটা রাখার জন্য
  List<Offset> seatPositions = List.generate(8, (index) => Offset.zero); // সিটের পজিশন রাখার জন্য
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // ফায়ারবেস এর জন্য
  
  String userProfilePic = ""; // এটি আপনার নিজের প্রোফাইল ছবি রাখার জন্য
  // --- সব ভেরিয়েবল ---
  String roomOwnerId = ""; 
  List<dynamic> adminList = [];
  String userRole = "Guest";
  String myPersonalAvatar = ""; // এটি ইউজারের নিজের প্রোফাইল ছবি
  bool isOwner = false;
  String displayUserID = "Hridoy"; 
  String roomName = "পাগলা চ্যাট রুম";
  int followerCount = 0;
  String roomProfileImage = '';
  bool isFollowing = false;
  int activeEmojiSeatIndex = -1; 
  bool isRoomLocked = false; 
  String roomWallpaperPath = ''; 
  int blueTeamPoints = 0;
  int redTeamPoints = 0;
  bool isPKActive = false; 
  late VSPKManager pkManager;
  int pkSeconds = 300; 
  int currentGiftCount = 0;
  // --- মিউজিক ফিচারের জন্য নতুন সংযোজন ---
  bool isMusicBarVisible = false;      // মিউজিক সিলেকশন বার দেখানোর জন্য
  bool isFloatingPlayerVisible = false; // ভাসমান প্লেয়ারটি স্ক্রিনে আনার জন্য
  String currentPlayingMusicName = "";  // গানের নাম স্টোর করার জন্য
  List<Map<String, dynamic>> userAddedMusicList = []; // ফোনের গানের লিস্ট
  bool isMusicLoading = false;         // গান লোড হওয়ার এনিমেশনের জন্য
  String currentMusicUrl = "";         // গানের লোকেশন/পাথ রাখার জন্য
  Offset playerPosition = const Offset(150, 400); // প্লেয়ারটি ড্র্যাগ করে সরানোর জন্য
  bool isRoomMusicPlaying = false; 
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _messageController = TextEditingController();

  Map<String, dynamic> currentUserData = {};
  int currentSeatIndex = -1; 
  bool isMicOn = false;
  List<Map<String, String>> chatMessages = [];
  bool isGiftAnimating = false;
  String currentGiftImage = "";
  late List<Map<String, dynamic>> seats;

  bool isCountingGifts = false;
  int remainingSeconds = 900;
  Timer? giftTimer;
  String targetType = ""; 
  String currentSenderName = "";
  String currentReceiverName = "";
  
  @override
void initState() {
  super.initState();
  
  // ১. সিট জেনারেশন (অরিজিনাল ১৫টি সিট ও আপনার VIP লজিক)
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
    "agoraUid": "", // এটি নিশ্চিত করার জন্য যোগ করা হলো
  });

  // ২. রিয়েলটাইম ডাটাবেস লিসেনার (আগের মতোই + Talking রিসেট)
  FirebaseDatabase.instance
      .ref('rooms/${widget.roomId}/seats')
      .onValue.listen((event) {
    if (!mounted) return;
    final dynamic data = event.snapshot.value;
    
    setState(() {
      for (var seat in seats) {
        seat["isOccupied"] = false;
        seat["status"] = "empty";
        seat["userName"] = "";
        seat["userImage"] = "";
        seat["isMicOn"] = false;
        seat["isTalking"] = false;
      }
      
      if (data != null) {
        data.forEach((key, value) {
          int? index = int.tryParse(key.toString());
          if (index != null && index < seats.length) {
            seats[index]["isOccupied"] = value["isOccupied"] ?? false;
            seats[index]["status"] = value["status"] ?? "occupied";
            seats[index]["userName"] = value["userName"] ?? "";
            seats[index]["userImage"] = value["userImage"] ?? "";
            seats[index]["isMicOn"] = value["isMicOn"] ?? false;
            seats[index]["userId"] = value["userId"] ?? "";
            // আগোরা ইউআইডি স্টোর করা যাতে রিপেল সঠিক সিটে দেখায়
            seats[index]["agoraUid"] = value["agoraUid"]?.toString() ?? "";
          }
        });
      }
    });
  });

  // ৩. পিকে ম্যানেজার
  pkManager = VSPKManager(
    onTick: (seconds) => setState(() => pkSeconds = seconds),
    onFinished: () => _endPKBattle(),
  );

  // ৪. এগোরা ম্যানেজার ব্যবহার করে ভয়েস ডিটেকশন ও মিউজিক রিপেল
  Future.microtask(() async {
    try {
      await _agoraManager.initAgora(); 
      
      final String myActualUid = FirebaseAuth.instance.currentUser?.uid ?? "guest_${Random().nextInt(10000)}";
      await _agoraManager.joinAsListener(widget.roomId, myActualUid);

      final engine = _agoraManager.engine;
      
      if (engine != null) {
        // ✅ রিপেল ইফেক্টের জন্য ভলিউম ইন্ডিকেশন ইনাবল করা
        await engine.enableAudioVolumeIndication(
          interval: 250, 
          smooth: 3, 
          reportVad: true
        );

        engine.registerEventHandler(
          RtcEngineEventHandler(
            onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
              debugPrint("👥 Remote user joined: $remoteUid");
              if (mounted) {
                setState(() {
                  _addUserToViewers(); 
                });
              }
            },

            onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
              debugPrint("👋 Remote user left: $remoteUid");
              if (mounted) setState(() {});
            },

            // ✅ গান শেষ হলে বা পজ হলে বাটন স্টেট আপডেট করার জন্য
            onAudioMixingStateChanged: (AudioMixingStateType state, AudioMixingReasonType reason) {
              if (mounted) {
                setState(() {
                  isRoomMusicPlaying = (state == AudioMixingStateType.audioMixingStatePlaying);
                });
              }
            },

            onAudioVolumeIndication: (RtcConnection connection, List<AudioVolumeInfo> speakers, int totalVolume, int speakerNumber) {
              if (!mounted) return;
              
              bool hasChanged = false;

              // লোকালি সবার কথা বলা বন্ধ ধরি শুরুতে
              for (int i = 0; i < seats.length; i++) {
                if (seats[i]["isTalking"] == true) {
                  seats[i]["isTalking"] = false;
                  hasChanged = true;
                }
              }

              // এগোরা থেকে আসা স্পিকারদের ডেটা চেক (গান বা ভয়েস দুইটাই এখানে আসবে)
              for (var speaker in speakers) {
                final int sUid = speaker.uid ?? 0;
                final int managerUid = _agoraManager.localUid ?? 0;
                final int currentSpeakerUid = (sUid == 0) ? managerUid : sUid;
                final int vol = speaker.volume ?? 0;

                // ভলিউম ৫ এর বেশি হলে রিপেল দেখাবে (গান বাজলে এটা কাজ করবে)
                if (vol > 5) { 
                  for (int i = 0; i < seats.length; i++) {
                    final String seatUserId = seats[i]["userId"]?.toString() ?? "";
                    final String seatAgoraUid = seats[i]["agoraUid"]?.toString() ?? "";

                    bool isMe = (sUid == 0 && seatUserId == myActualUid);
                    bool isOthers = (seatAgoraUid == currentSpeakerUid.toString());

                    if (isMe || isOthers) {
                      if (seats[i]["isTalking"] == false) {
                        seats[i]["isTalking"] = true;
                        hasChanged = true;
                      }
                    }
                  }
                }
              }

              if (hasChanged && mounted) {
                setState(() {});
              }
            },
          ),
        );
        debugPrint("✅ সব সচল! EventHandler রেজিস্টার্ড হয়েছে।");
      }
    } catch (e) {
      debugPrint("❌ Agora Error: $e");
    }
  });

  // ৫. পুরাতন অডিও প্লেয়ার লিসেনার সরিয়ে আগোরার সাথে সিঙ্ক (দরকার হলে রাখা হয়েছে)
  // তবে গান এখন সরাসরি আগোরার EventHandler থেকেই কন্ট্রোল হচ্ছে।

  // ৬. ফায়ারস্টোর ডাটা লোড
   FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).get().then((doc) {
    if (doc.exists && mounted) {
      final data = doc.data();
      setState(() {
        roomName = data?['roomName'] ?? roomName;
        roomProfileImage = data?['roomImage'] ?? roomProfileImage;
        followerCount = data?['followerCount'] ?? 0;
        isRoomLocked = data?['isLocked'] ?? false;
        roomWallpaperPath = data?['roomWallpaper'] ?? data?['wallpaper'] ?? '';

        // --- ওনার, এডমিন এবং মেহমান চেনার লজিক (uId প্রোটোকল) ---
        String ownerUID = data?['uId'] ?? data?['uid'] ?? ''; // রুমের ওনারের uId
        List<dynamic> adminList = data?['admins'] ?? [];      // এডমিনদের uId লিস্ট
        String myUID = currentUserData['uId'] ?? '';          // বর্তমান ইউজারের uId

        if (myUID == ownerUID) {
          userRole = "Owner"; // সে রুমের মালিক
        } else if (adminList.contains(myUID)) {
          userRole = "Admin"; // সে রুমের এডমিন
        } else {
          userRole = "Guest"; // সে সাধারণ মেহমান
        }
      });
      
      _roomService.updateRoomFullData(
        roomId: widget.roomId,
        roomName: roomName,
        roomImage: roomProfileImage,
        isLocked: isRoomLocked,
        wallpaper: roomWallpaperPath,
        followers: followerCount,
        totalDiamonds: 0,
      );
      
      _addUserToViewers();
    }
  });
}
   
  // --- গিফট লজিক ---
  void _startGiftCounting() {
    if (isCountingGifts) return;
    setState(() { isCountingGifts = true; remainingSeconds = 900; });
    giftTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        if (mounted) setState(() => remainingSeconds--);
      } else {
        timer.cancel();
        if (mounted) setState(() => isCountingGifts = false);
        _showWinnerPopup();
      }
    });
  }

  void _showWinnerPopup() {
    List<Map<String, dynamic>> seatData = List.from(seats);
    seatData.sort((a, b) => b['giftCount'].compareTo(a['giftCount']));
    List<Map<String, dynamic>> topWinners = [];
    for (var s in seatData) {
      if (s['giftCount'] > 0 && s['isOccupied']) {
        topWinners.add({"name": s['userName'], "avatar": s['userImage'], "gifts": s['giftCount']});
      }
      if (topWinners.length == 2) break;
    }
    if (topWinners.isNotEmpty) {
      showDialog(context: context, builder: (context) => GiftRankDialog(winners: topWinners));
    }
  }

  // --- PK Battle ---
  void _endPKBattle() {
    String winner = blueTeamPoints > redTeamPoints ? "BLUE" : "RED";
    showDialog(
      context: context,
      builder: (context) => PKWinnerDialog(winnerTeam: winner, bluePoints: blueTeamPoints, redPoints: redTeamPoints),
    );
    setState(() => isPKActive = false);
  }
             
  // ১. সিটে বসার মেইন লজিক (আপনার দেওয়া রিয়েল টাইম সিঙ্ক সহ)
   void sitOnSeat(int index) async {
  // ১. বেসিক চেক (সিট খালি আছে কিনা এবং ইউজার অলরেডি সেখানে আছে কিনা)
  if (currentSeatIndex == index) { 
    _showLeaveConfirmation(index); 
    return; 
  }
  
  if (seats[index]["isOccupied"] || isRoomLocked) return;

  // ২. অডিও এবং ব্রডকাস্টার মোড এনাবল করা (সিটে বসার মুহূর্তে কলিং শুরু)
  try {
    if (kIsWeb) {
      await WakelockPlus.enable();
    }

    // এগোরা ম্যানেজারের মাধ্যমে ব্রডকাস্টিং শুরু করা (রুমে ঢোকার সময় এটি Audience ছিল)
    await _agoraManager.becomeBroadcaster();
    
    // 🛡️ মাইক আনমিউট করা (যাতে বসার সাথে সাথে কথা বলা যায়)
    await _agoraManager.engine?.muteLocalAudioStream(false);

    // ভলিউম ইন্ডিকেশন চালু করা (রিপেল এনিমেশনের জন্য)
    await _agoraManager.engine?.enableAudioVolumeIndication(
      interval: 200, 
      smooth: 3, 
      reportVad: true
    );

    debugPrint("✅ কলিং ইঞ্জিন সিটে বসার পর প্রস্তুত হলো!");
  } catch (e) {
    debugPrint("⚠️ Agora Setup Error: $e");
    return; 
  }

  // ৩. পুরাতন সিট ক্লিয়ার করা (যদি ইউজার অন্য সিট থেকে মুভ করে)
  if (currentSeatIndex != -1) {
    int oldIndex = currentSeatIndex;
    try {
      await FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$oldIndex').onDisconnect().cancel();
      await FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$oldIndex').remove();
    } catch (e) {
      debugPrint("Old seat clear error: $e");
    }
  }

  // ৪. ডাটাবেস এবং স্টেট আপডেট
  try {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final String authUid = currentUser.uid; // মেইন আইডি
    final String myFixedUid = currentUserData['uId'] ?? currentUserData['uid'] ?? authUid; // আপনার আজীবন uId প্রোটোকল
    final String myName = currentUser.displayName ?? "User";
    final String myPic = currentUser.photoURL ?? "";

    final seatRef = FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$index');
    final int myAgoraUid = _agoraManager.localUid ?? 0;

    // ৫. নেট ডিসকানেক্ট হলে অটো সিট রিমুভ (onDisconnect)
    await seatRef.onDisconnect().remove();

    // ৬. ফায়ারবেসে সিট ডেটা পুশ (uId সিলসহ)
    await seatRef.set({
      'userName': myName,
      'userImage': myPic,
      'isOccupied': true,
      'status': 'occupied',
      'isMicOn': true,
      'userId': authUid,
      'uId': myFixedUid, // ✅ আজীবনের জন্য uId সিল মারা হলো
      'isTalking': false,
      'agoraUid': myAgoraUid, 
    });
    
    // ৭. লোকাল UI আপডেট
    if (mounted) {
      setState(() {
        if (currentSeatIndex != -1) {
          seats[currentSeatIndex]["isOccupied"] = false;
          seats[currentSeatIndex]["status"] = "empty";
        }
        
        currentSeatIndex = index;
        isMicOn = true;
        userRole = (myFixedUid == roomOwnerId) ? "Owner" : (adminList.contains(myFixedUid) ? "Admin" : "Speaker");

        seats[index] = {
          "status": "occupied",
          "isOccupied": true,
          "userName": myName,
          "userImage": myPic,
          "isMicOn": true,
          "userId": authUid,
          "uId": myFixedUid,
          "agoraUid": myAgoraUid,
          "isTalking": false,
        };
      });
    }
    
    debugPrint("👑 সিট সফলভাবে দখল এবং কলিং শুরু হয়েছে!");
  } catch (e) {
    debugPrint("❌ Firebase Update Error: $e");
  }
}

  // মালিকের জন্য বিশেষ মেসেজ ফাংশন (নিরাপদ ভার্সন)
  void _sendOwnerJoinMessage() {
    if (!mounted) return;
    
    // আগের স্নাকবার থাকলে তা সরিয়ে নতুনটা দেখানো
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("সম্মানিত মালিক Hridoy ভাই সিটে বসেছেন!", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ২. সিট ছাড়ার লজিক
  void _showLeaveConfirmation(int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog( // context-এর নাম পরিবর্তন করলাম বোঝার সুবিধার্থে
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("সিট ছেড়ে দিন", style: TextStyle(color: Colors.white, fontSize: 18)),
        content: const Text("আপনি কি নিশ্চিতভাবে এই সিটটি ছেড়ে দিতে চান?", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: const Text("না", style: TextStyle(color: Colors.blue))
          ),
          TextButton(
            onPressed: () async {
              // ১. এগোরা লজিক (নিরাপদ ভার্সন)
              try {
                // আপনার ১৯২ লাইনের ম্যানেজারের অরিজিনাল মেথড
                await _agoraManager.becomeListener();
                
                if (kIsWeb) {
                  // WakelockPlus সরাসরি কল না করে ট্রাই-ক্যাচে রাখা ভালো
                  try { await WakelockPlus.disable(); } catch (_) {}
                }
                debugPrint("🔇 এগোরা লিসেনার মোডে।");
              } catch (e) {
                debugPrint("Agora Leaving Error: $e");
              }

              // ২. ফায়ারবেস ডাটাবেস আপডেট (সিট খালি করা)
              try {
                final seatRef = FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$index');
                
                // 🛡️ ফিক্স: সিট ছাড়ার সময় ডিসকানেক্ট লজিক বাতিল করা জরুরি
                await seatRef.onDisconnect().cancel();
                await seatRef.remove();
                
                debugPrint("🧹 ফায়ারবেস ক্লিয়ার।");
              } catch (e) {
                debugPrint("Firebase Update Error: $e");
              }
              
              // ৩. লোকাল স্টেট আপডেট (রিপেল এবং মাইক বন্ধ করা)
              if (mounted) {
                setState(() {
                  seats[index]["isOccupied"] = false;
                  seats[index]["status"] = "empty";
                  seats[index]["userName"] = "";
                  seats[index]["userImage"] = "";
                  seats[index]["userId"] = "";
                  
                  // গুরুত্বপূর্ণ: আপনার রিপেল লজিকের সাথে মিল রেখে ০ সেট করা
                  seats[index]["agoraUid"] = 0; 
                  
                  seats[index]["isMicOn"] = false; 
                  seats[index]["isTalking"] = false; 
                  
                  // গ্লোবাল ভেরিয়েবল রিসেট
                  currentSeatIndex = -1;
                  isMicOn = false;
                });
              }
              
              // ৪. ডায়ালগ বন্ধ করা (নিরাপদভাবে)
              if (mounted) {
                Navigator.of(dialogContext).pop();
              }
            }, 
            child: const Text("হ্যাঁ", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  // কিবোর্ডের উচ্চতা মাপার জন্য
  double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

  return Scaffold(
    backgroundColor: const Color(0xFF0F0F1E),
    // resizeToAvoidBottomInset false রাখছি যাতে কিবোর্ড আসলে আপনার মেইল বাটন বা অন্য বাটন উপরে লাফিয়ে না ওঠে
    resizeToAvoidBottomInset: false, 
    body: Stack(
      children: [
        // ১. ওয়ালপেপার
        if (roomWallpaperPath.isNotEmpty)
          Positioned.fill(
            child: Image.network(
              roomWallpaperPath, 
              fit: BoxFit.cover,
            ),
          ),
        
        // ২. মেইন কন্টেন্ট
        Column(
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
            _buildSeatGridArea(), 

            // ৩. মেসেজ ভিউ (ইউজার প্রোফাইল থেকে নাম, ছবি এবং uID/uid সাপোর্ট)
            const SizedBox(height: 10), 
            SizedBox(
              height: 180, 
              width: double.infinity,
              child: Container(
                margin: const EdgeInsets.only(left: 10, right: 90),
                decoration: const BoxDecoration(color: Colors.transparent),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('rooms')
                      .doc(widget.roomId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .limit(30)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    var docs = snapshot.data!.docs;
                    return ListView.builder(
                      reverse: true,
                      padding: EdgeInsets.zero,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        
                        // uID, uid বা userId যাই থাকুক না কেন তা শনাক্ত করবে
                        String uName = data['userName'] ?? "User";
                        String uId = (data['uID'] ?? data['uid'] ?? data['userId'] ?? uName).toString();
                        String uImage = data['userImage'] ?? "";

                        return Align(
                          alignment: Alignment.bottomLeft,
                          child: GestureDetector(
                            onTap: () {
                              // আইডি ছোট বা বড় হাতের যাই হোক মেনশন সাপোর্ট
                              setState(() {
                                _messageController.text = "@$uId ";
                                _messageController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: _messageController.text.length),
                                );
                              });
                            },
                            child: _buildMessageRow({
                              'userName': uName,
                              'userImage': uImage, 
                              'text': data['text'] ?? "",
                            }),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            const Expanded(child: SizedBox.shrink()), 

            // ৫. টাইপিং বার (বটম অ্যাকশন এরিয়া - আপনার পুরাতন ফিচার যা আছে তাই থাকবে)
            _buildBottomActionArea(),
          ],
        ),

        // 🔥 সমাধান ২: টাইপ বক্স (কিবোর্ডের উপরে ভেসে উঠবে)
        if (keyboardHeight > 0)
          Positioned(
            bottom: keyboardHeight,
            left: 0, right: 0,
            child: Container(
              color: const Color(0xFF1A1A2E), 
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(25)),
                      child: TextField(
                        controller: _messageController,
                        autofocus: true, 
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "মেসেজ লিখুন...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.pinkAccent),
                    onPressed: () {
                      String msg = _messageController.text.trim();
                      if (msg.isNotEmpty) {
                        // আপনার অরিজিনাল ফায়ারবেস লজিক (uID সহ)
                        _firestore
                            .collection('rooms')
                            .doc(widget.roomId)
                            .collection('messages')
                            .add({
                          'userName': roomName, // বা আপনার ইউজারনেম ভেরিয়েবল
                          'userImage': myPersonalAvatar, 
                          'uID': FirebaseAuth.instance.currentUser?.uid,
                          'text': msg,
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                        _messageController.clear(); 
                        FocusScope.of(context).unfocus(); 
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

        // মিউজিক প্লেয়ার (আপনার পুরাতন ফিচার)
        if (isFloatingPlayerVisible)
          Positioned(
            left: playerPosition.dx, 
            top: playerPosition.dy,
            child: Draggable(
              feedback: _buildFloatingPlayer(isDragging: true),
              childWhenDragging: Container(),
              onDragEnd: (details) {
                setState(() { playerPosition = details.offset; });
              },
              child: _buildFloatingPlayer(isDragging: false),
            ),
          ),

        FloatingRoomTools(onGiftCountStart: _startGiftCounting),
        
        GiftOverlayHandler(
          isGiftAnimating: isGiftAnimating,
          currentGiftImage: currentGiftImage,
          isFullScreenBinding: isGiftAnimating, 
          senderName: currentSenderName, 
          receiverName: targetType, 
        ),

        // গিফট লিসেনার (অপরিবর্তিত)
        StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('rooms').doc(widget.roomId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              var lastGift = data['last_gift'];
              if (lastGift != null) {
                int giftTime = lastGift['timestamp'] ?? 0;
                int now = DateTime.now().millisecondsSinceEpoch;
                if (now - giftTime < 5000) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !isGiftAnimating) {
                      setState(() {
                        currentGiftImage = lastGift['image'] ?? '';
                        currentSenderName = lastGift['senderName'] ?? 'Someone';
                        targetType = lastGift['target'] ?? ''; 
                        currentGiftCount = lastGift['count'] ?? 1;
                        isGiftAnimating = true;
                      });
                      Timer(const Duration(seconds: 5), () {
                        if (mounted) setState(() { isGiftAnimating = false; });
                      });
                    }
                  });
                }
              }
            }
            return const SizedBox.shrink(); 
          },
        ),

        // ৮. মেইল বাটন ও ইনবক্স (আপনার পুরাতন কোড - একদম হাত দেইনি)
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7, 
                    child: const InboxPage(), 
                  ),
                ),
              );
            },
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .where('receiverId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .where('isSeen', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                int unreadCount = (snapshot.hasData) ? snapshot.data!.docs.length : 0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: const Icon(Icons.mail, color: Colors.white, size: 24),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0, top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),

        // ৯. সমাধান ৩: ইমোজি অ্যানিমেশন (আপনার ভেরিয়েবল activeEmojis ব্যবহার করে)
        ..._buildFloatingEmojiAnimations(), 
      ],
    ),
  );
}

// ইমোজি মেথড (আপনার ভেরিয়েবল seatPositions এবং activeEmojis ব্যবহার করে)
List<Widget> _buildFloatingEmojiAnimations() {
  return activeEmojis.entries.map((entry) {
    int seatIndex = entry.key;
    String lottieUrl = entry.value;

    return Positioned(
      // আপনার সিট পজিশন ভেরিয়েবল অনুযায়ী পজিশন হবে
      left: (seatIndex < seatPositions.length) ? seatPositions[seatIndex].dx - 15 : 0, 
      top: (seatIndex < seatPositions.length) ? seatPositions[seatIndex].dy - 40 : 0,
      child: IgnorePointer(
        child: SizedBox(
          width: 80, height: 80,
          child: Lottie.network(lottieUrl, repeat: false), 
        ),
      ),
    );
  }).toList();
}
 // 🔥 এটিই আপনার ফাইনাল এবং একমাত্র dispose ফাংশন
  @override
  void dispose() {
    // ১. আড্ডা (Viewers List) থেকে নাম মুছে ফেলা
    _removeUserFromViewers(); 

    // ২. সিটে বসা থাকলে সেই সিটটি অটো খালি করে দেওয়া (Real-time Sync)
    if (currentSeatIndex != -1) {
      _roomService.updateSeatData(
        roomId: widget.roomId, 
        seatIndex: currentSeatIndex, 
        uName: "", 
        uImage: "", 
        isOccupied: false
      );
      
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
    }

    // ৩. মেমোরি ক্লিনআপ (টাইমার, পিকে, অডিও এবং মেসেজ কন্ট্রোলার বন্ধ করা)
    giftTimer?.cancel();
    pkManager.stopPK();
    _audioPlayer.dispose();
    _messageController.dispose();
    
    super.dispose();
  }

  // --- উইজেট ফাংশনসমূহ ---
  Widget _buildTopNavBar() {
  // ১. পারমিশন চেক করার ভ্যারিয়েবল (মালিক বা এডমিন কি না)
  final String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";
  bool hasPermission = (myUid == roomOwnerId) || adminList.contains(myUid);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        // 🖼️ রুমের প্রোফাইল পিকচার (ক্লিক করলে সেভ হবে)
        GestureDetector(
          onTap: () {
            // শুধুমাত্র মালিক ও এডমিন পারবে
            if (!hasPermission) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("শুধুমাত্র মালিক ও এডমিন ছবি বদলাতে পারবে")));
              return;
            }
            
            RoomProfileHandler.pickRoomImage(
              onImagePicked: (p) async {
                // 🔥 পুরাতন ছবি ডিলিট করার লজিক (স্টোরেজ ক্লিন রাখা)
                if (roomProfileImage.isNotEmpty && roomProfileImage.contains("firebasestorage")) {
                  try {
                    await FirebaseStorage.instance.refFromURL(roomProfileImage).delete();
                  } catch (e) {
                    debugPrint("failed $e");
                  }
                }

                setState(() => roomProfileImage = p);
                // 🔥 ডাটাবেসে ছবি সেভ (আপনার মূল সার্ভিস কল)
                _roomService.updateRoomFullData(
                  roomId: widget.roomId,
                  roomName: roomName,
                  roomImage: p,
                  isLocked: isRoomLocked,
                  wallpaper: roomWallpaperPath,
                  followers: followerCount,
                  totalDiamonds: 0,
                );
              }, 
              showMessage: (m) {}
            );
          },
          child: CircleAvatar(
            radius: 20,
            backgroundImage: roomProfileImage.isNotEmpty ? NetworkImage(roomProfileImage) : null,
            child: roomProfileImage.isEmpty ? const Icon(Icons.camera_alt, size: 18) : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📝 রুমের নাম (এডিট করলে সেভ হবে)
              GestureDetector(
                onTap: () {
                  // শুধুমাত্র মালিক ও এডমিন পারবে
                  if (!hasPermission) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("শুধুমাত্র মালিক ও এডমিন নাম বদলাতে পারবে")));
                    return;
                  }
                  
                  RoomProfileHandler.editRoomName(
                    context: context, 
                    currentName: roomName, 
                    onNameSaved: (n) {
                      setState(() => roomName = n);
                      // 🔥 ডাটাবেসে নাম সেভ (আপনার মূল সার্ভিস কল)
                      _roomService.updateRoomFullData(
                        roomId: widget.roomId,
                        roomName: n,
                        roomImage: roomProfileImage,
                        isLocked: isRoomLocked,
                        wallpaper: roomWallpaperPath,
                        followers: followerCount,
                        totalDiamonds: 0,
                      );
                    }
                  );
                },
                child: Text(roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              Text("ID: ${widget.roomId} | $followerCount ফলোয়ার", style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        ),

        // ➕ ফলোয়ার বাটন (আপনার হুবহু টগল লজিক)
        IconButton(
          icon: Icon(
            isFollowing ? Icons.check_circle : Icons.person_add_alt_1,
            color: isFollowing ? Colors.greenAccent : Colors.blueAccent, 
            size: 20
          ),
          onPressed: () async {
            if (myUid.isEmpty) return;

            var roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
            
            if (isFollowing) {
              // আনফলো লজিক (হুবহু আপনার কোড)
              await roomRef.update({
                'followers': FieldValue.arrayRemove([myUid]),
                'followerCount': FieldValue.increment(-1),
              });
              setState(() {
                isFollowing = false;
                followerCount--;
              });
            } else {
              // ফলো লজিক (হুবহু আপনার কোড)
              await roomRef.update({
                'followers': FieldValue.arrayUnion([myUid]),
                'followerCount': FieldValue.increment(1),
              });
              setState(() {
                isFollowing = true;
                followerCount++;
              });
            }

            // ডাটা সিঙ্ক (আপনার মূল সার্ভিস কল)
            _roomService.updateRoomFullData(
              roomId: widget.roomId,
              roomName: roomName,
              roomImage: roomProfileImage,
              isLocked: isRoomLocked,
              wallpaper: roomWallpaperPath,
              followers: followerCount,
              totalDiamonds: 0,
            );
          },
        ),

        // ২য় বাটন (লিস্ট দেখার বাটন - মালিকের আইডি adminId থেকে আসবে)
        IconButton(
          icon: const Icon(Icons.group, color: Colors.white70),
          onPressed: () async {
            var roomDoc = await FirebaseFirestore.instance
                .collection('rooms')
                .doc(widget.roomId)
                .get();
        
            if (!roomDoc.exists) return;
        
            var data = roomDoc.data();
            // ডাটাবেজের 'ownerId' ফিল্ড থেকে মালিকের আইডি নিশ্চিত করা হচ্ছে
            String ownerUidFromDb = data?['ownerId'] ?? data?['adminId'] ?? "";
        
            if (!context.mounted) return;
        
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => RoomFollowerSheet(
                roomId: widget.roomId,
                ownerId: ownerUidFromDb, // ডাটাবেজের অরিজিনাল মালিক
              ),
            );
          },
        ),
        
        IconButton(icon: const Icon(Icons.settings, color: Colors.white70), onPressed: _showSettings),
      ],
    ),
  );
}
 
  // --- ১. মেইন সিট গ্রিড এরিয়া (যা আপনি build এ কল করেছেন) ---
   Widget _buildSeatGridArea() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('seats')
        .snapshots(),
    builder: (context, snapshot) {
      Map<String, dynamic> firestoreSeats = {};
      if (snapshot.hasData) {
        for (var doc in snapshot.data!.docs) {
          firestoreSeats[doc.id] = doc.data();
        }
      }

      return GridView.builder(
        shrinkWrap: true, 
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 0.7,
        ),
        itemCount: 15,
        itemBuilder: (context, index) {
          var dbSeat = firestoreSeats[index.toString()];
          bool isOccupied = dbSeat != null ? (dbSeat['isOccupied'] ?? false) : false;
          
          String uName = dbSeat != null ? (dbSeat['name'] ?? "") : ""; 
          String uImage = dbSeat != null ? (dbSeat['profilePic'] ?? "") : ""; 
          String uFrame = dbSeat != null ? (dbSeat['userFrame'] ?? "") : ""; 

          bool isMicOnLocal = dbSeat != null ? (dbSeat['isMicOn'] ?? false) : false;
          String status = dbSeat != null ? (dbSeat['status'] ?? "empty") : "empty";
          bool isTalking = dbSeat != null ? (dbSeat['isTalking'] ?? false) : false;
          
          bool isVipSeat = index < 5; 
          bool hasSoulmate = dbSeat != null && (dbSeat['soulmateId'] != null); 

          return GestureDetector(
            onTap: () async {
              if (isOccupied) return;

              final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

              // ১. ভিআইপি সিট চেক
              if (isVipSeat) {
                // সরাসরি আপনার ডাটাবেস অনুযায়ী 'uID' দিয়ে ইউজার খোঁজা হচ্ছে
                DocumentSnapshot userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid) 
                    .get();

                if (userDoc.exists) {
                  final userData = userDoc.data() as Map<String, dynamic>?;
                  
                  // আপনার স্ক্রিনশট অনুযায়ী 'isVip' চেক করা হচ্ছে
                  bool isUserVip = userData?['isVip'] == true;

                  if (!isUserVip) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        // নিচের লাইনে কোটেশন (") ঠিক করে দেওয়া হয়েছে
                        content: Text("Only VIP Users can sit here!"), 
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return; 
                  }
                } else {
                  return; 
                }
              }

              // ২. পুরাতন সিট ক্লিন লজিক (রিয়েল-টাইম ক্লিন)
              var myOldSeats = await FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .collection('seats')
                  .where('userId', isEqualTo: uid)
                  .get();

              for (var doc in myOldSeats.docs) {
                await doc.reference.set({ 
                  'isOccupied': false,
                  'userId': '',
                  'name': '',
                  'profilePic': '',
                  'status': 'empty',
                  'isMicOn': false,
                  'isTalking': false,
                  'userFrame': '',
                }, SetOptions(merge: true));
              }

              // ৩. নতুন সিটে বসা (সব ফিচার বজায় রেখে)
              DocumentSnapshot myProfile = await FirebaseFirestore.instance.collection('users').doc(uid).get();
              var myData = myProfile.data() as Map<String, dynamic>?;

              if (myData != null) {
                // set with merge: true দেওয়ার কারণে সিট ডিলিট হয়ে থাকলেও এখন ক্লিক করলে কাজ করবে
                await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(widget.roomId)
                    .collection('seats')
                    .doc(index.toString())
                    .set({
                  'isOccupied': true,
                  'userId': uid,
                  'name': myData['name'] ?? "User", 
                  'profilePic': myData['profilePic'] ?? "", 
                  'userFrame': myData['userFrame'] ?? "",
                  'status': 'occupied',
                  'isMicOn': true,
                  'isTalking': false,
                }, SetOptions(merge: true));
                
                sitOnSeat(index); // ভয়েস কানেকশন কল
              }
            },
            child: Column(
              children: [
                VoiceRipple(
                  isTalking: isOccupied && isTalking, 
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isVipSeat ? Colors.amber : Colors.cyan.withOpacity(0.6), 
                            width: 2,
                          ),
                          boxShadow: isVipSeat ? [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 5)] : [],
                        ),
                        child: CircleAvatar(
                          radius: 23,
                          backgroundColor: isVipSeat ? Colors.amber.withOpacity(0.1) : Colors.white10,
                          backgroundImage: (isOccupied && uImage.isNotEmpty) ? NetworkImage(uImage) : null,
                          child: status == "calling"
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : (isOccupied ? null : Icon(isVipSeat ? Icons.workspace_premium : Icons.chair, 
                                  color: isVipSeat ? Colors.amber : Colors.white24, size: 20)),
                        ),
                      ),
                      // ফ্রেম ফিচার
                      if (isOccupied && uFrame.isNotEmpty)
                        SizedBox(width: 60, height: 60, child: Image.network(uFrame, fit: BoxFit.contain)),
                      // সোলমেট ফিচার
                      if (isOccupied && hasSoulmate)
                        Positioned(top: -2, child: Icon(Icons.favorite, color: Colors.pinkAccent, size: 14)),
                      // মাইক ফিচার
                      if (isOccupied && isMicOnLocal)
                        Positioned(
                          bottom: 0, right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.mic, size: 10, color: Colors.greenAccent),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOccupied ? uName : (isVipSeat ? "King ${index + 1}" : "${index + 1}"),
                  style: TextStyle(
                    color: isVipSeat ? Colors.amberAccent : (isOccupied ? Colors.white : Colors.white54), 
                    fontSize: 9,
                    fontWeight: isVipSeat || isOccupied ? FontWeight.bold : FontWeight.normal,
                  ),
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
  
  // --- ২. অ্যাকশন বার (মাইক, গেম এবং চ্যাট ইনপুট) ---
   Widget _buildBottomActionArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      color: Colors.transparent,
      child: Row(
        children: [
          // ১. চ্যাট ও ইমোজি
          Expanded(
            child: ChatInputBar(
              controller: _messageController,
              onEmojiTap: () {
                // ১. বর্তমান ইউজারের আইডি
                final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
                
                // ২. ইউজার কোন সিটে আছে (uID বড় হাতের চেক করা হচ্ছে)
                int mySeatIndex = seats.indexWhere((s) => s != null && (s['uID'] == currentUid || s['uid'] == currentUid));

                // EmojiHandler দিয়ে পিকার দেখানো
                EmojiHandler.showPicker(
                  context: context, 
                  seatIndex: mySeatIndex, 
                  onEmojiSelected: (index, url) {
                    if (index != -1) {
                      // ৩. অ্যানিমেটেড ইমোজি সিটে দেখানোর জন্য লোকাল স্টেট আপডেট
                      setState(() {
                        seats[index]['showEmoji'] = true;
                        seats[index]['currentEmoji'] = url;
                      });

                      // ইমোজি যেন ৩ সেকেন্ড পর চলে যায় তার জন্য টাইমার
                      Future.delayed(const Duration(seconds: 3), () {
                        if (mounted) {
                          setState(() {
                            seats[index]['showEmoji'] = false;
                          });
                        }
                      });
                      
                      // 🔥 রিয়েলটাইম ডাটাবেসে আপডেট (সিটের ওপর ইমোজি দেখানোর জন্য)
                      FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$index').update({
                        'currentEmoji': url,
                        'emojiTime': ServerValue.timestamp,
                      });

                      // ফায়ারস্টোরে আপডেট
                      FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
                        'lastEmoji': url,
                        'emojiIndex': index,
                        'emojiTime': FieldValue.serverTimestamp(),
                      });
                    }
                  }
                );
              },
              onMessageSend: (msg) async {
                final user = FirebaseAuth.instance.currentUser;
                final String senderId = user?.uid ?? "";
                
                // আপনার প্রোফাইল ডাটা থেকে সঠিক নাম ও ছবি নিশ্চিত করা
                String finalName = currentUserData['userName'] ?? currentUserData['name'] ?? user?.displayName ?? "User";
                String finalImage = currentUserData['userImage'] ?? currentUserData['profileImage'] ?? msg['userImage'] ?? "";

                // ৪. মেসেজ ফায়ারবেসে পাঠানো
                await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(widget.roomId)
                    .collection('messages')
                    .add({
                  'userName': finalName,
                  'userImage': finalImage,
                  'text': msg['text'],
                  'senderId': senderId,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                // ৫. মেসেজ পাঠানোর সময়ও যদি সিটে এনিমেশন ট্রিগার করতে চান (uID চেক)
                int senderSeat = seats.indexWhere((s) => s != null && (s['uID'] == senderId || s['uid'] == senderId));
                if (senderSeat != -1) {
                   // এখানেও চাইলে ইমোজি বা পপ-আপ এনিমেশন লজিক দিতে পারেন
                }
              },
            ),
          ),
        
           // --- মাইক কন্ট্রোল বাটন শুরু ---
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  icon: Icon(
                    isMicOn ? Icons.mic : Icons.mic_off,
                    color: isMicOn ? Colors.greenAccent : Colors.redAccent,
                    size: 22,
                  ),
                  onPressed: () async {
                    // ১. চেক: ইউজার কোনো সিটে বসে আছে কি না
                    if (currentSeatIndex == -1) return;

                    // ২. ভাইব্রেশন ফিডব্যাক
                    try {
                      HapticFeedback.lightImpact();
                    } catch (_) {}

                    bool newMicState = !isMicOn;

                    try {
                      // ৩. এগোরা মাইক কন্ট্রোল
                      // নতুন ম্যানেজার অনুযায়ী: মাইক অফ করলেও গান (Mixing) বন্ধ হবে না
                      if (_agoraManager.engine != null) {
                        await _agoraManager.toggleMic(!newMicState); 
                      }

                      // ৪. ফায়ারবেস রিয়েলটাইম ডাটাবেস আপডেট
                      FirebaseDatabase.instance
                          .ref('rooms/${widget.roomId}/seats/$currentSeatIndex')
                          .update({'isMicOn': newMicState});

                      // ৫. লোকাল ইউআই (UI) পরিবর্তন
                      if (mounted) {
                        setState(() {
                          isMicOn = newMicState;
                          
                          // মাইক অফ করলে রিপেল এনিমেশন সাথে সাথে বন্ধ করে দেওয়া
                          if (!newMicState) {
                            if (currentSeatIndex >= 0 && currentSeatIndex < seats.length) {
                              seats[currentSeatIndex]["isTalking"] = false;
                            }
                          }
                        });
                      }
                      
                      debugPrint("🎤 মাইক স্ট্যাটাস: ${newMicState ? "চালু" : "বন্ধ"}");
                      
                    } catch (e) {
                      debugPrint("❌ Mic Toggle Error: $e");
                    }
                  },
                ),
                // --- মাইক কন্ট্রোল বাটন শেষ ---
           // ৩. মিউজিক (ড্র্যাগেবল প্লেয়ার অন/অফ)
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            icon: Icon(
              Icons.music_note, 
              color: isFloatingPlayerVisible ? Colors.blueAccent : Colors.white70, 
              size: 22,
            ),
            onPressed: () {
              // মিউজিক সিলেকশন বার (BottomSheet) ওপেন করা
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => MusicPlayerWidget(
                  // ১. গান সিলেক্ট করলে যা হবে
                  onMusicSelect: (path) async {
                    setState(() {
                      currentMusicUrl = path; 
                      isFloatingPlayerVisible = true;
                      isRoomMusicPlaying = true;
                    });

                    try {
                      // আগোরাতে আগে কোনো গান চললে তা বন্ধ করা
                      await _agoraManager.engine.stopAudioMixing();

                      // নতুন গান আগোরার মাধ্যমে চালানো (যাতে সবাই শোনে)
                      await _agoraManager.engine.startAudioMixing(
                        filePath: path,
                        loopback: false, // নিজের আওয়াজ ইকো হবে না
                        cycle: 1,        // একবার বাজবে (replace: false মুছে দেওয়া হয়েছে)
                      );

                      // ডিফল্ট ভলিউম সেট করা
                      await _agoraManager.engine.adjustAudioMixingVolume(100);

                    } catch (e) {
                      debugPrint("Agora Audio Mixing Error: $e");
                    }
                  },
                  // ২. ভলিউম স্লাইডার নাড়ালে যা হবে
                  onVolumeChange: (volume) {
                    // আগোরার মিউজিক ভলিউম সেট করা
                    _agoraManager.engine.adjustAudioMixingVolume(volume.toInt());
                  },
                ),
              );
            },
          ),
          // ৪. গিফট বাটন
          IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          icon: const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 22),
          onPressed: () async {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .get();
            
            int currentBalance = 0;
            String senderName = "User"; 
            
            if (userDoc.exists && userDoc.data() != null) {
              final data = userDoc.data()!;
              // --- সংশোধন: আপনার ডাটাবেস অনুযায়ী diamonds এবং userName ---
              currentBalance = data['diamonds'] ?? 0;
              senderName = data['userName'] ?? data['name'] ?? "User"; 
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
                  // ১. লোকাল ফোনে এনিমেশন আপডেট
                  setState(() {
                    currentGiftImage = gift['icon'];
                    isGiftAnimating = true;
                    targetType = target; 
                    currentSenderName = senderName; 
                    currentReceiverName = target; 
                  });

                  // ২. গ্লোবাল এনিমেশন ট্রিগার
                  try {
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
                  } catch (e) {
                    debugPrint("Animation Trigger Error: $e");
                  }

                  // ৩. ট্রানজেকশন লজিক (uID এবং receiverId নিশ্চিত করা)
                  try {
                    bool isFree = gift['isFree'] ?? false;
                    int unitPrice = gift['price'] ?? 0;
                    int totalAmount = unitPrice * count;

                    // --- সংশোধন: target থেকে আইডি খুঁজে বের করা ---
                    String receiverId = "";
                    var targetSeat = seats.firstWhere(
                      (s) => s != null && (s['userName'] == target || s['name'] == target),
                      orElse: () => null,
                    );
                    
                    if (targetSeat != null) {
                      receiverId = targetSeat['uID'] ?? targetSeat['uid'] ?? "";
                    }

                    if (receiverId.isNotEmpty) {
                      await GiftTransactionHelper.processGiftTransaction(
                        senderId: FirebaseAuth.instance.currentUser!.uid,
                        receiverId: receiverId,
                        totalPrice: totalAmount,
                        isFree: isFree,
                        giftName: gift['name'] ?? "Gift",
                      );
                    }
                  } catch (e) {
                    debugPrint("Transaction Error: $e");
                  }

                  // ৪. এনিমেশন টাইমার
                  Timer(const Duration(seconds: 5), () {
                    if (mounted) {
                      setState(() { isGiftAnimating = false; });
                    }
                  });
                },
              ),
            );
          },
        ),
          // ৫. গেম বাটন
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            icon: const Icon(Icons.videogame_asset, color: Colors.orange, size: 22), 
            onPressed: () => showModalBottomSheet(
              context: context, 
              isScrollControlled: true, // ফুল স্ক্রিন করার জন্য প্রথম শর্ত
              useSafeArea: false,       // নচ বা স্ট্যাটাস বারের ওপর দিয়ে যাওয়ার জন্য
              backgroundColor: Colors.transparent, // ব্যাকগ্রাউন্ড ক্লিয়ার রাখার জন্য
              builder: (c) => SizedBox(
                height: MediaQuery.of(context).size.height, // পুরো স্ক্রিনের হাইট
                child: GamePanelView(roomId: widget.roomId),
              ),
            ),
          ),
        ], // Row children closed
      ), // Row closed
    ); // Container closed
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
            "আড্ডায়:", 
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

  Widget _buildMessageRow(Map<String, String> msg) { 
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
      isLocked: isRoomLocked,
      onToggleLock: () async {
        setState(() => isRoomLocked = !isRoomLocked);
        // ১. রুম লক ফিচার
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .update({'isLocked': isRoomLocked});
      },
      onSetWallpaper: (path) async {
        if (path.isEmpty) return;
        try {
          // ইউজারের সুবিধার জন্য লোকালি আগে সেট করে দেখানো
          setState(() => roomWallpaperPath = path);

          // ২. স্থায়ী আপলোড লজিক
          String fileName = 'wallpapers/${widget.roomId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          var storageRef = FirebaseStorage.instance.ref().child(fileName);

          // XFile দিয়ে বাইটস রিড করা (এটিই blob কে আসল ছবিতে রূপান্তর করবে)
          final XFile imageFile = XFile(path);
          final bytes = await imageFile.readAsBytes();
          
          // ফায়ারবেস স্টোরেজে পুশ করা
          UploadTask uploadTask = storageRef.putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );

          // আপলোড শেষ হওয়া পর্যন্ত অপেক্ষা
          var snapshot = await uploadTask;
          
          // ৩. স্থায়ী ডাউনলোড ইউআরএল (https://...) নেওয়া
          String downloadUrl = await snapshot.ref.getDownloadURL();

          // ৪. ডাটাবেসে সেভ (সব নামেই আপডেট করে দিচ্ছি যাতে ভুল না হয়)
          await FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.roomId)
              .update({
                'roomWallpaper': downloadUrl,
                'wallpaper': downloadUrl // ব্যাকআপ ফিল্ড
              });

          // স্টেট আপডেট যাতে পার্মানেন্ট লিঙ্কটা সেট হয়
          setState(() {
            roomWallpaperPath = downloadUrl;
          });

          debugPrint("🖼️ পার্মানেন্ট লিঙ্ক সেভ হয়েছে: $downloadUrl");
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Wallpaper saved permanently for everyone!")),
            );
          }
        } catch (e) {
          debugPrint("Wallpaper Error: $e");
        }
      },
      onMinimize: () => Navigator.pop(context), // ৫. মিনিমাইজ ফিচার
      onClearChat: () async {
        try {
          // ৬. চ্যাট ক্লিন লজিক
          final chatDocs = await FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.roomId)
              .collection('messages') 
              .get();

          for (var ds in chatDocs.docs) {
            await ds.reference.delete();
          }
          
          debugPrint("🧹 চ্যাট পরিষ্কার করা হয়েছে!");
          
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
        // ৭. লিভ ফিচার
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
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('viewers')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'userName': userDoc.data()?['name'] ?? 'User',
        'userImage': userDoc.data()?['profilePic'] ?? '',
        'joinedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _removeUserFromViewers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('viewers')
          .doc(user.uid)
          .delete();
    }
  }
} // <--- এই একটি ব্র্যাকেট দিয়ে ক্লাস শেষ করুন
