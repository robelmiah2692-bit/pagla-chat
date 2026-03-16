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

  
  String userProfilePic = ""; // এটি আপনার নিজের প্রোফাইল ছবি রাখার জন্য
  // --- সব ভেরিয়েবল ---
  String myPersonalAvatar = ""; // এটি ইউজারের নিজের প্রোফাইল ছবি
  bool isOwner = true; 
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
          }
        });
      }
    });
  });

  // ৩. পিকে ম্যানেজার (আপনার অরিজিনাল)
  pkManager = VSPKManager(
    onTick: (seconds) => setState(() => pkSeconds = seconds),
    onFinished: () => _endPKBattle(),
  );

  // 🔥 ৪. এগোরা ম্যানেজার ব্যবহার করে ভয়েস ডিটেকশন (সব ফিচার নিশ্চিত)
  Future.microtask(() async {
  try {
    await _agoraManager.initAgora(); 
    
    final String myActualUid = FirebaseAuth.instance.currentUser?.uid ?? "guest_${Random().nextInt(10000)}";
    
    await _agoraManager.joinAsListener(widget.roomId, myActualUid);

    _agoraManager.engine.registerEventHandler(
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

        onAudioVolumeIndication: (RtcConnection connection, List<AudioVolumeInfo> speakers, int totalVolume, int speakerNumber) {
          if (!mounted) return;
          
          bool hasChanged = false;

          // ১. প্রতিবার লুপে ঢোকার আগে লোকালি সবার কথা বলা বন্ধ ধরি
          for (int i = 0; i < seats.length; i++) {
            if (seats[i]["isTalking"] == true) {
              seats[i]["isTalking"] = false;
              hasChanged = true;
            }
          }

          // ২. এগোরা থেকে আসা স্পিকারদের ডেটা চেক করি
          for (var speaker in speakers) {
            final int sUid = speaker.uid ?? 0;
            final int managerUid = _agoraManager.localUid ?? 0;
            final int currentSpeakerUid = (sUid == 0) ? managerUid : sUid;
            final int vol = speaker.volume ?? 0;

            if (vol > 10) { // যদি কেউ কথা বলে
              for (int i = 0; i < seats.length; i++) {
                final String seatUserId = seats[i]["userId"]?.toString() ?? "";
                final String seatAgoraUid = seats[i]["agoraUid"]?.toString() ?? "";
                final String speakerUidStr = currentSpeakerUid.toString();

                // নিজের জন্য বা অন্যদের জন্য আইডি ম্যাচ করানো
                bool isMe = (sUid == 0 && seatUserId == myActualUid);
                bool isOthers = (seatAgoraUid == speakerUidStr);

                if (isMe || isOthers) {
                  if (seats[i]["isTalking"] == false) {
                    seats[i]["isTalking"] = true;
                    hasChanged = true;
                  }
                }
              }
            }
          }

          // ৩. ফায়ারবেসে না পাঠিয়ে শুধু নিজের স্ক্রিনে আপডেট করছি
          if (hasChanged && mounted) {
            setState(() {});
          }
        },
      ),
    );
    debugPrint("✅ সব সচল! ফায়ারবেস রাইট ছাড়াই রিপেল কাজ করবে।");
  } catch (e) {
    debugPrint("❌ Agora Error: $e");
  }
});

  // ৫. অডিও প্লেয়ার লিসেনার
  _audioPlayer.onPlayerStateChanged.listen((state) {
  if (mounted) {
    setState(() {
      // ওয়েবে অনেক সময় state চেক করতে সমস্যা হয়, তাই সরাসরি কন্ডিশন দিলাম
      isRoomMusicPlaying = (state == PlayerState.playing);
    });
    
    // সাউন্ড নিশ্চিত করতে প্লে হওয়া মাত্র ভলিউম আবার চেক করা
    if (state == PlayerState.playing) {
      _audioPlayer.setVolume(1.0);
    }
  }
});

_audioPlayer.onPlayerComplete.listen((event) {
  if (mounted) {
    setState(() {
      isRoomMusicPlaying = false; 
      // গান শেষ হলে প্লেয়ার যেন জ্যাম না হয়, তাই স্টপ করে রাখা ভালো
    });
    _audioPlayer.stop(); 
  }
});
  
  // ৬. ফায়ারস্টোর ডাটা লোড
  FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).get().then((doc) {
    if (doc.exists && mounted) {
      setState(() {
        roomName = doc.data()?['roomName'] ?? roomName;
        roomProfileImage = doc.data()?['roomImage'] ?? roomProfileImage;
        followerCount = doc.data()?['followerCount'] ?? 0;
        isRoomLocked = doc.data()?['isLocked'] ?? false;
        roomWallpaperPath = doc.data()?['roomWallpaper'] ?? doc.data()?['wallpaper'] ?? '';
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
} // initState পুরোপুরি শেষ
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

  // ১. সিটে বসার মেইন লজিক (আপনার দেওয়া রিয়েল টাইম সিঙ্ক সহ)
  void sitOnSeat(int index) async {
    // ১. বেসিক চেক
    if (currentSeatIndex == index) { 
      _showLeaveConfirmation(index); 
      return; 
    }
    
    if (seats[index]["isOccupied"] || isRoomLocked) return;

    // ২. অডিও এবং ব্রডকাস্টার মোড এনাবল করা
    try {
      // ব্রাউজার স্লিপ মোড প্রতিরোধ
      if (kIsWeb) {
        await WakelockPlus.enable();
      }

      // Agora Manager-এর মাধ্যমে ব্রডকাস্টিং শুরু
      await _agoraManager.becomeBroadcaster();
      
      // গুরুত্বপূর্ণ: ভলিউম ডাটা এনাবল করা (রিপেল এর জন্য)
      await _agoraManager.engine.enableAudioVolumeIndication(
        interval: 250, 
        smooth: 3, 
        reportVad: true
      );

      debugPrint("✅ ওয়েব কলিং ইঞ্জিন প্রস্তুত!");
    } catch (e) {
      debugPrint("Agora Web Error: $e");
      // মাইক পারমিশন না দিলে বা এরর হলে সিটে বসতে বাধা দেওয়া ভালো
      return; 
    }

    // ৩. পুরাতন সিট ক্লিয়ার করা (যদি আগে অন্য সিটে থাকে)
    if (currentSeatIndex != -1) {
      int oldIndex = currentSeatIndex;
      await FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$oldIndex').remove();
      // লোকাল স্টেট আপডেট নিচে একবারে হবে
    }

    // ৪. ডাটাবেস এবং স্টেট আপডেট
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final String uid = currentUser.uid;
      final String myName = currentUser.displayName ?? "User";
      final String myPic = currentUser.photoURL ?? "";

      // 👑 মালিক শনাক্তকরণ (Hridoy)
      if (myName.toLowerCase() == "hridoy") {
        _sendOwnerJoinMessage();
      }

      final seatRef = FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$index');
      
      // এগোরা থেকে পাওয়া ইউনিক আইডি
      final int myAgoraUid = _agoraManager.localUid ?? 0;

      await seatRef.set({
        'userName': myName,
        'userImage': myPic,
        'isOccupied': true,
        'status': 'occupied',
        'isMicOn': true,
        'userId': uid,
        'isTalking': false,
        'agoraUid': myAgoraUid, // এটি অবশ্যই দিতে হবে নাহলে রিপেল কাজ করবে না
      });
      
      seatRef.onDisconnect().remove();

      if (mounted) {
        setState(() {
          // পুরাতন সিট ডাটা ক্লিন
          if (currentSeatIndex != -1) {
            seats[currentSeatIndex]["isOccupied"] = false;
            seats[currentSeatIndex]["status"] = "empty";
          }
          
          // নতুন সিট ডাটা সেট
          currentSeatIndex = index;
          isMicOn = true;
          seats[index] = {
            "status": "occupied",
            "isOccupied": true,
            "userName": myName,
            "userImage": myPic,
            "isMicOn": true,
            "userId": uid,
            "agoraUid": myAgoraUid,
            "isTalking": false,
          };
        });
      }
      
      debugPrint("👑 সিট এখন আপনার দখলে!");
    } catch (e) {
      debugPrint("Firebase Update Error: $e");
    }
}

  // মালিকের জন্য বিশেষ মেসেজ ফাংশন
  void _sendOwnerJoinMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("সম্মানিত মালিক Hridoy ভাই সিটে বসেছেন!"),
        backgroundColor: Colors.blueAccent,
        duration: Duration(seconds: 3),
      ),
    );
  }
    
  // ২. সিট ছাড়ার লজিক
  void _showLeaveConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("সিট ছেড়ে দিন", style: TextStyle(color: Colors.white, fontSize: 18)),
        content: const Text("আপনি কি নিশ্চিতভাবে এই সিটটি ছেড়ে দিতে চান?", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("না", style: TextStyle(color: Colors.blue))),
          TextButton(
            onPressed: () async {
              // ১. এগোরাকে লিসেনার মোডে নেওয়া এবং মাইক্রোফোন অফ করা
              try {
                await _agoraManager.becomeListener();
                // ওয়াক-লক বন্ধ করা (যদি আপনি সিটে বসার সময় এটি এনাবল করে থাকেন)
                if (kIsWeb) {
                  await WakelockPlus.disable();
                }
                debugPrint("🔇 এগোরা এখন লিসেনার মোডে। মাইক বন্ধ।");
              } catch (e) {
                debugPrint("Agora Error while leaving: $e");
              }

              // ২. ডাটাবেস আপডেট (সিট খালি করা)
              try {
                // Realtime Database থেকে সিট রিমুভ করা
                await FirebaseDatabase.instance
                    .ref('rooms/${widget.roomId}/seats/$index')
                    .remove();

                // যদি আপনি ফায়ারস্টোরেও আলাদা করে সিট ডাটা রাখেন তবে এটি রাখুন (ঐচ্ছিক)
                // await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('seats').doc(index.toString()).delete();
                
                debugPrint("🧹 ডাটাবেস থেকে সিট ক্লিয়ার করা হয়েছে।");
              } catch (e) {
                debugPrint("Database Update Error: $e");
              }
              
              // ৩. লোকাল স্টেট আপডেট
              if (mounted) {
                setState(() {
                  seats[index]["isOccupied"] = false;
                  seats[index]["status"] = "empty";
                  seats[index]["userName"] = "";
                  seats[index]["userImage"] = "";
                  seats[index]["userId"] = "";
                  seats[index]["agoraUid"] = "";
                  seats[index]["isMicOn"] = false; 
                  seats[index]["isTalking"] = false; // রিপেল এনিমেশন অফ করা
                  currentSeatIndex = -1;
                  isMicOn = false;
                });
              }
              
              if (mounted) Navigator.pop(context);
            }, 
            child: const Text("হ্যাঁ", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF0F0F1E),
    resizeToAvoidBottomInset: true, 
    body: Stack(
      children: [
        // ১. ছবি অনুযায়ী পুরো বডিতে একই ব্যাকগ্রাউন্ড বা ওয়ালপেপার (min-height: 100vh লজিক)
        if (roomWallpaperPath.isNotEmpty)
          Positioned.fill(
            child: Image.network(
              roomWallpaperPath, 
              fit: BoxFit.cover, // ছবি অনুযায়ী background-size: cover
            ),
          ),
        
        // ২. মেইন কন্টেন্ট যা ওয়ালপেপারের ওপর ভাসবে
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

            // ৩. সমাধান: চ্যাট বক্সকে পুরোপুরি স্বচ্ছ (Transparent) করা
            const SizedBox(height: 10), 
            SizedBox(
              height: 180, 
              width: double.infinity,
              child: Container(
                margin: const EdgeInsets.only(left: 10, right: 90),
                // ছবির ৩ নম্বর পয়েন্ট অনুযায়ী ব্যাকগ্রাউন্ড স্বচ্ছ করা হলো
                decoration: const BoxDecoration(
                  color: Colors.transparent, 
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
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
                        return Align(
                          alignment: Alignment.bottomLeft,
                          child: _buildMessageRow({
                            'userName': data['userName'] ?? "User",
                            'userImage': data['userImage'] ?? "",
                            'text': data['text'] ?? "",
                          }),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // ৪. এটি নিচের কালো ঘরকে নিচে রাখবে কিন্তু আলাদা ব্যাকগ্রাউন্ড দেবে না
            const Expanded(child: SizedBox.shrink()), 

            // ৫. টাইপিং বার এবং আইকন (এটিও এখন স্বচ্ছ স্ক্রিনের অংশ)
            _buildBottomActionArea(),
          ],
        ),
        // ৫. মিউজিক ভাসমান প্লেয়ার
        if (isFloatingPlayerVisible)
          Positioned(
            left: playerPosition.dx, 
            top: playerPosition.dy,
            child: Draggable(
              feedback: _buildFloatingPlayer(isDragging: true),
              childWhenDragging: Container(),
              onDragEnd: (details) {
                setState(() { 
                  // স্ক্রিনের বাউন্ডারি অনুযায়ী পজিশন সেট করা
                  playerPosition = details.offset; 
                });
              },
              child: _buildFloatingPlayer(isDragging: false),
            ),
          ),

        // ৬. ফ্লোটিং টুলস
        FloatingRoomTools(onGiftCountStart: _startGiftCounting),
        
        // ৭. গিফট অ্যানিমেশন (ইমেজ)
        GiftOverlayHandler(
          isGiftAnimating: isGiftAnimating,
          currentGiftImage: currentGiftImage,
          isFullScreenBinding: isGiftAnimating, 
          senderName: currentSenderName, 
          receiverName: targetType, 
        ),

        // ৮. গ্লোবাল গিফট লিসেনার (ফিক্সড কোড)
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.roomId)
              .collection('gift_animations')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // লজিক: যদি গিফটটি অন্য কেউ পাঠায় এবং এখন এনিমেশন না চলে
                if (mounted && !isGiftAnimating && data['senderName'] != currentSenderName) {
                  setState(() {
                    currentGiftImage = data['giftIcon'];
                    currentSenderName = data['senderName'];
                    targetType = data['receiverName']; 
                    isGiftAnimating = true;
                  });
                  
                  Timer(const Duration(seconds: 3), () {
                    if (mounted) {
                      setState(() { isGiftAnimating = false; });
                    }
                  });
                }
              });
            }
            return const SizedBox.shrink(); 
          },
        ),

        // ৮. মেইল বাটন ও ইনবক্স
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
              stream: FirebaseFirestore.instance
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
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$unreadCount', 
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), 
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ], // Stack children closed
                ); // Stack closed
              }, // Builder closed
            ), // StreamBuilder closed
          ), // GestureDetector closed
        ), // Positioned closed

        // ৯. সিট ইমোজি অ্যানিমেশন
        ..._buildFloatingEmojiAnimations(), 
      ], // Main Stack children closed
    ), // Main Stack closed
  ); // Final widget closed
}
        
// বিল্ড এরর ফিক্স করতে এই মেথডটি আপনার _VoiceRoomState ক্লাসের ভেতরে অবশ্যই থাকতে হবে
List<Widget> _buildFloatingEmojiAnimations() {
  // আপনার ইমোজি অ্যানিমেশনের লজিক এখানে থাকবে। 
  // আপাতত বিল্ড ঠিক করার জন্য খালি লিস্ট পাঠানো হলো।
  return []; 
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // 🖼️ রুমের প্রোফাইল পিকচার (ক্লিক করলে সেভ হবে)
          GestureDetector(
            onTap: () => RoomProfileHandler.pickRoomImage(
              onImagePicked: (p) {
                setState(() => roomProfileImage = p);
                // 🔥 ডাটাবেসে ছবি সেভ
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
            ),
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
                  onTap: () => RoomProfileHandler.editRoomName(
                    context: context, 
                    currentName: roomName, 
                    onNameSaved: (n) {
                      setState(() => roomName = n);
                      // 🔥 ডাটাবেসে নাম সেভ
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
                  ),
                  child: Text(roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                Text("ID: ${widget.roomId} | $followerCount ফলোয়ার", style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),

          // ➕ ফলোয়ার বাটন (Toggle Logic: একবার ক্লিক করলে ফলো, আবার করলে আনফলো)
          IconButton(
            icon: Icon(
              isFollowing ? Icons.check_circle : Icons.person_add_alt_1,
              color: isFollowing ? Colors.greenAccent : Colors.blueAccent, 
              size: 20
            ),
            onPressed: () async {
              final String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";
              if (myUid.isEmpty) return;

              var roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
              
              // আপনার স্ক্রিনশট অনুযায়ী 'adminId' ই হচ্ছে আসল ওনার
              if (isFollowing) {
                // আনফলো লজিক
                await roomRef.update({
                  'followers': FieldValue.arrayRemove([myUid]),
                  'followerCount': FieldValue.increment(-1), // এটি আপনার স্ক্রিনশটের ফিল্ড নাম অনুযায়ী
                });
                setState(() {
                  isFollowing = false;
                  followerCount--;
                });
              } else {
                // ফলো লজিক (FieldValue.arrayUnion নিশ্চিত করে এক ইউজার বারবার অ্যাড হবে না)
                await roomRef.update({
                  'followers': FieldValue.arrayUnion([myUid]),
                  'followerCount': FieldValue.increment(1),
                });
                setState(() {
                  isFollowing = true;
                  followerCount++;
                });
              }

              // ডাটা সিঙ্ক করার জন্য আপনার আগের সার্ভিস কল (যদি প্রয়োজন হয়)
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

          // ২য় বাটন (লিস্ট দেখার বাটন) আগের মতোই থাকবে
          IconButton(
            icon: const Icon(Icons.group, color: Colors.white70),
            onPressed: () async {
              var roomDoc = await FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .get();
          
              if (!roomDoc.exists) return;
          
              var data = roomDoc.data();
              // স্ক্রিনশট অনুযায়ী মালিকের আইডি 'adminId' ফিল্ডে আছে
              String ownerUid = data?['adminId'] ?? "";
          
              if (!context.mounted) return;
          
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => RoomFollowerSheet(
                  roomId: widget.roomId,
                  ownerId: ownerUid,
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
                DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                bool isUserVip = (userDoc.data() as Map<String, dynamic>?)?['isVip'] ?? false;
                if (!isUserVip) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("এই রাজকীয় সিটটি শুধুমাত্র VIP মেম্বারদের জন্য!")),
                  );
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
                // ১. বর্তমান ইউজারের আইডি বের করা
                final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
                
                // ২. ইউজার কোন সিটে আছে তা বের করা
                int mySeatIndex = seats.indexWhere((s) => s != null && s['uid'] == currentUid);

                // EmojiHandler ব্যবহার করে পিকার দেখানো
                EmojiHandler.showPicker(
                  context: context, 
                  seatIndex: mySeatIndex, 
                  onEmojiSelected: (index, url) {
                    // ৩. অ্যানিমেটেড ইমোজি সিটে দেখানোর লজিক
                    if (index != -1) {
                      setState(() { 
                        // অ্যানিমেটেড ইমোজি আপডেট (যদি ভেরিয়েবল থাকে)
                      });
                      
                      // ডাটাবেসে আপডেট
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
                
                // সঠিক নাম নিশ্চিত করা
                String finalName = msg['userName'] ?? user?.displayName ?? "User";

                // ৪. মেসেজ ফায়ারবেসে পাঠানো
                await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(widget.roomId)
                    .collection('messages')
                    .add({
                  'userName': finalName,
                  'userImage': msg['userImage'],
                  'text': msg['text'],
                  'senderId': senderId,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                // ৫. ইমোজি হলে সিটে এনিমেশন ট্রিগার করা
                int senderSeat = seats.indexWhere((s) => s != null && s['uid'] == senderId);
                if (senderSeat != -1) {
                  // এনিমেশন কোড এখানে থাকবে
                }
              },
            ),
          ),
        
          // ২. মাইক
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            icon: Icon(
              isMicOn ? Icons.mic : Icons.mic_off,
              color: isMicOn ? Colors.greenAccent : Colors.redAccent,
              size: 22,
            ),
            onPressed: () async {
              if (currentSeatIndex != -1) {
                // ১. মোবাইল ভাইব্রেশন (Services import না থাকলে এরর দিবে)
                try {
                  HapticFeedback.lightImpact();
                } catch (e) {
                  debugPrint("Haptic error: $e");
                }

                bool newMicState = !isMicOn;
                
                try {
                  // ২. এগোরা মাইক কন্ট্রোল
                  await _agoraManager.toggleMic(!newMicState); 

                  // ৩. রিয়েলটাইম ডাটাবেস আপডেট
                  await FirebaseDatabase.instance
                      .ref('rooms/${widget.roomId}/seats/$currentSeatIndex')
                      .update({'isMicOn': newMicState});

                  // ৪. লোকাল স্টেট আপডেট
                  if (mounted) {
                    setState(() { 
                      isMicOn = newMicState; 
                      if (!newMicState) {
                        if (seats.length > currentSeatIndex) {
                          seats[currentSeatIndex]["isTalking"] = false;
                        }
                      }
                    });
                  }
                } catch (e) {
                  debugPrint("❌ Mic Toggle Error: $e");
                }
              }
            },
          ),
          // ৩. মিউজিক (ড্র্যাগেবল প্লেয়ার অন/অফ)
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            icon: Icon(
              Icons.music_note, 
              color: isFloatingPlayerVisible ? Colors.blueAccent : Colors.white70, 
              size: 22
            ),
            onPressed: () {
              // মিউজিক সিলেকশন বার (BottomSheet) ওপেন করা
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
                      // ১. আগের গান পুরোপুরি বন্ধ করা
                      await _audioPlayer.stop();

                      // ২. সরাসরি কন্ডিশন দিয়ে প্লে করা
                      if (path.startsWith('http')) {
                        // ইন্টারনেটের গানের জন্য
                        await _audioPlayer.play(UrlSource(path));
                      } else {
                        // মোবাইলের লোকাল গানের জন্য
                        await _audioPlayer.play(DeviceFileSource(path));
                      }

                      // ৩. ভলিউম নিশ্চিত করা
                      await _audioPlayer.setVolume(1.0);
                      
                    } catch (e) {
                      print("Error: $e");
                    }
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
                currentBalance = userDoc.data()!['diamonds'] ?? 0;
                senderName = userDoc.data()!['name'] ?? "User"; 
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

                    // ২. গ্লোবাল এনিমেশন ট্রিগার (অন্যদের দেখানোর জন্য)
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

                    // ৩. পুরাতন ট্রানজেকশন লজিক ঠিক রাখা হয়েছে
                    try {
                      bool isFree = gift['isFree'] ?? false;
                      String receiverId = gift['targetId'] ?? ""; 
                      int unitPrice = gift['price'] ?? 0;
                      int totalAmount = unitPrice * count;

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
                    Timer(const Duration(seconds: 3), () {
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
              builder: (c) => const GamePanelView(),
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
                BoxShadow(color: Colors.cyanAccent.withOpacity(0.4), blurRadius: 15)
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
                    await _audioPlayer.pause();
                  } else {
                    await _audioPlayer.setVolume(1.0);
                    
                    // 🔥 সংশোধন: ওয়েবে শুধু resume কাজ না করলে play(Source) দিতে হয়
                    if (currentMusicUrl.isNotEmpty) {
                      if (currentMusicUrl.startsWith('http')) {
                        await _audioPlayer.play(UrlSource(currentMusicUrl));
                      } else {
                        await _audioPlayer.play(DeviceFileSource(currentMusicUrl));
                      }
                    }
                  }
                  setState(() {
                    isRoomMusicPlaying = !isRoomMusicPlaying;
                  });
                } catch (e) {
                  print("Play/Pause Error: $e");
                }
              },
            ),
          ),
        ),
        
        // ক্রস বাটন
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              await _audioPlayer.stop();
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
