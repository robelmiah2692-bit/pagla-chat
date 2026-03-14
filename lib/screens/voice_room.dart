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
  
  bool isRoomMusicPlaying = false; 
  Offset playerPosition = const Offset(150, 400); // পজিশন একটু নিচে ও মাঝখানে আনা হলো
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

          onRemoteAudioStateChanged: (RtcConnection connection, int remoteUid, RemoteAudioState state, RemoteAudioStateReason reason, int elapsed) {
            debugPrint("🔊 Audio State Changed for $remoteUid: $state");
          },

          onAudioVolumeIndication: (RtcConnection connection, List<AudioVolumeInfo> speakers, int totalVolume, int speakerNumber) {
            if (!mounted) return;
            
            setState(() {
              for (int i = 0; i < seats.length; i++) {
                seats[i]["isTalking"] = false;
              }

              for (var speaker in speakers) {
                final int sUid = speaker.uid ?? 0;
                final int managerUid = _agoraManager.localUid ?? 0;
                final int currentSpeakerUid = (sUid == 0) ? managerUid : sUid;

                for (int i = 0; i < seats.length; i++) {
                  final String seatUserId = seats[i]["userId"]?.toString() ?? "";
                  final String seatAgoraUid = seats[i]["agoraUid"]?.toString() ?? "";
                  final String speakerUidStr = currentSpeakerUid.toString();

                  bool isMe = (sUid == 0 && seatUserId == myActualUid.toString());
                  bool isOthers = (seatAgoraUid == speakerUidStr || seatUserId == speakerUidStr);

                  if (isMe || isOthers) {
                    final int vol = speaker.volume ?? 0;
                    final bool talkingNow = vol > 10; 

                    if (seats[i]["isTalking"] != talkingNow) {
                      seats[i]["isTalking"] = talkingNow;

                      FirebaseFirestore.instance
                          .collection('rooms')
                          .doc(widget.roomId)
                          .collection('seats')
                          .doc(i.toString())
                          .update({"isTalking": talkingNow})
                          .catchError((e) => debugPrint("Firestore Error: $e"));
                    }
                  }
                }
              }
            });
          },
        ),
      );
      debugPrint("✅ সব ফিচার (ইউজার লিস্ট + অডিও + রিপেল) এখন সচল!");
    } catch (e) {
      debugPrint("❌ Agora Error: $e");
    }
  }); // মাইক্রোটাস্ক শেষ

  // ৫. অডিও প্লেয়ার লিসেনার
  _audioPlayer.onPlayerStateChanged.listen((state) {
    if (mounted) {
      setState(() => isRoomMusicPlaying = (state == PlayerState.playing));
    }
  });

  _audioPlayer.onPlayerComplete.listen((event) {
    if (mounted) setState(() => isRoomMusicPlaying = false);
  });
  
  // ৬. ফায়ারস্টোর ডাটা লোড
  FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).get().then((doc) {
    if (doc.exists && mounted) {
      setState(() {
        roomName = doc.data()?['roomName'] ?? roomName;
        roomProfileImage = doc.data()?['roomImage'] ?? roomProfileImage;
        followerCount = doc.data()?['followerCount'] ?? 0;
        isRoomLocked = doc.data()?['isLocked'] ?? false;
        roomWallpaperPath = doc.data()?['wallpaper'] ?? '';
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
  // ১. বেসিক চেক (আগের মতোই ঠিক আছে)
  if (currentSeatIndex == index) { 
    _showLeaveConfirmation(index); 
    return; 
  }
  if (seats[index]["isOccupied"] || isRoomLocked) return;

  // 🔥 ২. এগোরা এবং অডিও সিকোয়েন্স (আঠার মতো লেগে থাকার জন্য)
  try {
    // অডিও ইঞ্জিন রেজুউম করা
    await _agoraManager.forceResumeAudio(); 
    
    // ব্রডকাস্টার রোল সেট করা (যাতে কথা বলতে পারে)
    await _agoraManager.becomeBroadcaster();
    
    // ম্যানুয়ালি ভলিউম ২০০% করা এবং আনমিউট করা
    await _agoraManager.engine.muteLocalAudioStream(false);
    await _agoraManager.engine.adjustRecordingSignalVolume(200);
    
    // 🎤 অডিও ভলিউম ইন্ডিকেশন চালু করা (পানির ঢেউ এনিমেশনের জন্য)
    await _agoraManager.engine.enableAudioVolumeIndication(
      interval: 250, 
      smooth: 3, 
      reportVad: true
    );
    
    debugPrint("✅ কলিং এবং ভয়েস এনিমেশন লজিক সফল!");
  } catch (e) {
    debugPrint("Agora Error: $e");
  }

  // ৩. পুরাতন সিট ক্লিয়ার করা (অন্য ফিচার বাদ পড়েনি)
  if (currentSeatIndex != -1) {
    int oldIndex = currentSeatIndex;
    FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$oldIndex').remove();
    setState(() {
      seats[oldIndex]["isOccupied"] = false;
      seats[oldIndex]["status"] = "empty";
      seats[oldIndex]["isTalking"] = false; // এনিমেশন অফ
    });
  }

  // ৪. ফায়ারবেস আপডেট এবং আপনার আইডি শনাক্তকরণ
  try {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    
    // মালিক শনাক্তকরণ এবং ডাটা আনা
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    String myName = userDoc.data()?['name'] ?? "User"; 
    String myPic = userDoc.data()?['profilePic'] ?? "";

    final seatRef = FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$index');
    
    // সব ফিচার ডাটাবেসে পাঠানো হচ্ছে
    await seatRef.set({
      'userName': myName,
      'userImage': myPic,
      'isOccupied': true,
      'status': 'occupied',
      'isMicOn': true,
      'userId': uid,
      'isTalking': false, // ডিফল্ট সাইলেন্ট
    });
    
    // ৫. ডিসকানেক্ট হলে অটো সিট খালি হওয়া
    await seatRef.onDisconnect().remove();

    if (mounted) {
      setState(() {
        currentSeatIndex = index;
        isMicOn = true;
        seats[index]["status"] = "occupied";
        seats[index]["isOccupied"] = true;
        seats[index]["userName"] = myName;
        seats[index]["userImage"] = myPic; 
        seats[index]["isMicOn"] = true;
        seats[index]["userId"] = uid;
        seats[index]["isTalking"] = false;
      });
    }
    
    debugPrint("👑 সিট সফলভাবে দখল হয়েছে!");
  } catch (e) {
    debugPrint("Database Update Error: $e");
  }
}
  // ২. সিট ছাড়ার লজিক
  void _showLeaveConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("সিট ছেড়ে দিন", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("না")),
          TextButton(
            onPressed: () async {
              // 🔥 ১. এগোরাকে লিসেনার মোডে নেওয়া (যাতে কথা বলা বন্ধ হয়)
              try {
                await _agoraManager.becomeListener();
                debugPrint("🔇 এগোরা এখন লিসেনার মোডে।");
              } catch (e) {
                debugPrint("Agora Error: $e");
              }

              // ২. আপনার ডাটাবেস আপডেট লজিক (আগের মতোই)
              await _roomService.updateSeatData(roomId: widget.roomId, seatIndex: index, uName: "", uImage: "", isOccupied: false);
              await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('seats').doc(index.toString()).delete();
              
              if (mounted) {
                setState(() {
                  seats[index]["isOccupied"] = false;
                  seats[index]["status"] = "empty";
                  seats[index]["userName"] = "";
                  seats[index]["userImage"] = "";
                  seats[index]["isMicOn"] = false; 
                  seats[index]["isTalking"] = false; // রিপেল অফ করা
                  currentSeatIndex = -1;
                  isMicOn = false;
                });
              }
              Navigator.pop(context);
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
    // কিবোর্ড সমস্যা সমাধানের জন্য এটি অবশ্যই true থাকবে
    resizeToAvoidBottomInset: true, 
    body: Stack(
      children: [
        // ১. ওয়ালপেপার ফিচার (পুরাতন লজিক অক্ষত)
        if (roomWallpaperPath.isNotEmpty)
          Positioned.fill(
            child: Image.network(roomWallpaperPath, fit: BoxFit.cover),
          ),
        
        // মেইন কন্টেন্ট লেআউট (সবকিছু এক পার্টে থাকবে)
        Column(
          children: [
            const SizedBox(height: 40),
            _buildTopNavBar(), // টপ বার
            
            // ২. পিকে ব্যাটল
            if (isPKActive)
              PKBattleView(
                bluePoints: blueTeamPoints, 
                redPoints: redTeamPoints, 
                pkSeconds: pkSeconds,
                pkManager: pkManager,
              ),
            
            _buildViewerArea(), // ভিউয়ার এরিয়া
            _buildSeatGridArea(), // সিট গ্রিড (এটি তার অরিজিনাল সাইজেই থাকবে)
            
            // ৩. ম্যাজিক পার্ট: এই Expanded আপনার সিট আর চ্যাটের মাঝখানের 
            // সব "কালো গর্ত" মুছে দিয়ে সেখানে ওয়ালপেপার ফুটিয়ে তুলবে।
            const Expanded(
              child: SizedBox.shrink(), // এটি সিটকে উপরে আর চ্যাটকে নিচে ঠেলে রাখবে মাঝখানে গ্যাপ না বাড়িয়ে
            ),

            // ৪. রুম চ্যাট লিস্ট (পুরোপুরি ওয়ালপেপারের ওপর ভাসবে)
            SizedBox(
              height: 180, 
              width: double.infinity,
              child: Container(
                margin: const EdgeInsets.only(left: 10, right: 90),
                color: Colors.transparent,
                child: StreamBuilder<QuerySnapshot>(
                  // ফায়ারবেস থেকে রিয়েল-টাইম মেসেজ ডাটা নেওয়া হচ্ছে
                  stream: FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(widget.roomId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .limit(30) // শেষ ৩০টি মেসেজ দেখাবে
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    var docs = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true, // নতুন মেসেজ সবসময় নিচে দেখাবে
                      padding: EdgeInsets.zero,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        
                        // আপনার আগের মেসেজ ডিজাইন ফাংশনটি এখানে কল করা হয়েছে
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

            // ৫. টাইপিং বার এবং নিচের আইকনগুলো
            _buildBottomActionArea(),
          ],
        ),
        // ৫. মিউজিক ভাসমান প্লেয়ার
        if (isRoomMusicPlaying)
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

        // ৬. ফ্লোটিং টুলস
        FloatingRoomTools(onGiftCountStart: _startGiftCounting),
        
        // ৭. গিফট অ্যানিমেশন (ইমেজ)
        GiftOverlayHandler(
          isGiftAnimating: isGiftAnimating,
          currentGiftImage: currentGiftImage,
          isFullScreenBinding: isGiftAnimating, 
          senderName: lastGiftSenderName, 
          receiverName: targetType, 
        ),

        // ৮. ভিডিও গিফট অ্যানিমেশন
        if (currentVideoUrl != null && currentVideoUrl.isNotEmpty)
          Positioned.fill(
            child: GiftVideoPlayerWidget(
              url: currentVideoUrl,
              onComplete: () {
                setState(() {
                  currentVideoUrl = ""; 
                });
              },
            ),
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

      return SizedBox(
        height: 250, // সিট গ্রিডের উচ্চতা
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.7,
          ),
          itemCount: 15,
          itemBuilder: (context, index) {
            var dbSeat = firestoreSeats[index.toString()];
            bool isOccupied = dbSeat != null ? (dbSeat['isOccupied'] ?? false) : seats[index]['isOccupied'];
            String uName = dbSeat != null ? (dbSeat['userName'] ?? "") : seats[index]['userName'];
            String uImage = dbSeat != null ? (dbSeat['userImage'] ?? "") : seats[index]['userImage'];
            bool isMicOnLocal = dbSeat != null ? (dbSeat['isMicOn'] ?? false) : seats[index]['isMicOn'];
            String status = dbSeat != null ? (dbSeat['status'] ?? "empty") : seats[index]['status'];
            bool isVip = seats[index]['isVip'] ?? false; 
            bool isTalking = dbSeat != null ? (dbSeat['isTalking'] ?? false) : (seats[index]['isTalking'] ?? false);

            return GestureDetector(
              onTap: () => sitOnSeat(index),
              child: Column(
                children: [
                  VoiceRipple(
                    isTalking: isOccupied && isTalking, 
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isOccupied ? Colors.blueAccent : Colors.white10,
                          backgroundImage: (isOccupied && uImage.isNotEmpty) ? NetworkImage(uImage) : null,
                          child: status == "calling"
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : (isOccupied ? null : Icon(isVip ? Icons.stars : Icons.chair, color: Colors.white24, size: 20)),
                        ),
                        if (isOccupied && isMicOnLocal)
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                              child: const Icon(Icons.mic, size: 10, color: Colors.greenAccent),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOccupied ? uName : "${index + 1}",
                    style: TextStyle(
                      color: isOccupied ? Colors.white : Colors.white54, 
                      fontSize: 10,
                      fontWeight: isOccupied ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
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
                // ১. বর্তমান ইউজারের আইডি বের করা (যাতে myUid এরর না আসে)
                final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
                
                // ২. ইউজার কোন সিটে আছে তা বের করা
                int mySeatIndex = seats.indexWhere((s) => s != null && s['uid'] == currentUid);

                // আপনার EmojiHandler ব্যবহার করে পিকার দেখানো
                EmojiHandler.showPicker(
                  context: context, 
                  seatIndex: mySeatIndex, 
                  onEmojiSelected: (index, url) {
                    // ৩. অ্যানিমেটেড ইমোজি সিটে দেখানোর লজিক
                    if (index != -1) {
                      setState(() { 
                        // এখানে আপনার অ্যাপের অ্যানিমেটেড ইমোজি ভেরিয়েবলগুলো বসবে
                        // উদাহরণস্বরূপ: currentAnimatedEmoji = url; 
                        // এবং showEmojiAnimation = true;
                      });
                      
                      // ডাটাবেসে আপডেট করুন যাতে অন্য ইউজাররাও আপনার সিটে ইমোজিটি দেখতে পায়
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

                // ৪. মেসেজ ফায়ারবেসে পাঠানো (সবার জন্য লাইভ)
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
                  // আপনার অ্যানিমেটেড ইমোজি দেখানোর কোড
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
              bool newMicState = !isMicOn;
              await _agoraManager.toggleMic(!newMicState);
              await FirebaseDatabase.instance
                  .ref('rooms/${widget.roomId}/seats/$currentSeatIndex')
                  .update({'isMicOn': newMicState});
              setState(() { isMicOn = newMicState; });
            }
          },
        ),

        // ৩. মিউজিক (ড্র্যাগেবল প্লেয়ার অন/অফ)
        IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          icon: Icon(
            Icons.music_note, 
            color: isRoomMusicPlaying ? Colors.blueAccent : Colors.white70, 
            size: 22
          ),
          onPressed: () => setState(() => isRoomMusicPlaying = !isRoomMusicPlaying),
        ),

        // ৪. গিফট বাটন (ইউজার প্রোফাইল থেকে ডায়মন্ড ব্যালেন্স সহ)
         // ১. গিফট বাটন
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
                
                setState(() {
                  currentGiftImage = gift['icon'];
                  isGiftAnimating = true;
                  targetType = target; 
                  currentSenderName = senderName; 
                  currentReceiverName = target; 
                });

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

                Timer(const Duration(seconds: 3), () {
                  if (mounted) {
                    setState(() {
                      isGiftAnimating = false;
                    });
                  }
                });
              },
            ),
          );
        },
      ),

       // ২. গেম বাটন
      IconButton(
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        icon: const Icon(Icons.videogame_asset, color: Colors.orange, size: 22), 
        onPressed: () => showModalBottomSheet(
          context: context, 
          builder: (c) => const GamePanelView(),
        ),
      ),
    ]; // <--- এখানে সেমিকোলনটি নিশ্চিত করুন যদি এটি কোনো লিস্টের ভেতর থাকে
  }

  // --- হেল্পার উইজেটস (ফাংশনগুলো ক্লাসের ভেতর থাকবে) ---

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
      onToggleLock: () => setState(() => isRoomLocked = !isRoomLocked),
      onSetWallpaper: (p) => setState(() => roomWallpaperPath = p),
      onMinimize: () => Navigator.pop(context),
      onClearChat: () async {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('chats')
            .get()
            .then((snapshot) {
              for (DocumentSnapshot ds in snapshot.docs) {
                ds.reference.delete();
              }
            });
        debugPrint("🧹 চ্যাট পরিষ্কার করা হয়েছে!");
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
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.cyanAccent, width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.music_note, color: Colors.cyanAccent, size: 30),
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: () {
                  _audioPlayer.stop();
                  setState(() {
                    isRoomMusicPlaying = false;
                  });
                },
                child: const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.close, size: 10, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
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
