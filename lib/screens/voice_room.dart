import 'package:pagla_chat/widgets/user_profile_dialog.dart';
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

 // এই ভেরিয়েবলগুলো ক্লাসের ওপরের দিকে যোগ করুন
  bool isRoomMuted = false; // শুরুতে সাউন্ড অন থাকবে
  bool isCalculatorActive = false; 
  String activityTheme = "";
  Map<String, dynamic> roomData = {}; // এটিই মিসিং ছিল
  Map<String, int> roomScores = {};
  // --- বিল্ড এরর ফিক্স করার জন্য ভ্যারিয়েবল ---
  Map<int, String> activeEmojis = {}; 
  List<Offset> seatPositions = List.generate(8, (index) => Offset.zero); 
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; 

  bool isGiftCounting = false; 
  String uID = ""; 
  String ownerName = "";
  String userProfilePic = ""; 

  // --- সব ভেরিয়েবল ---
  String roomOwnerId = ""; 
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
  int blueTeamPoints = 0;
  int redTeamPoints = 0;
  bool isPKActive = false; 
  late VSPKManager pkManager;
  int pkSeconds = 300; 
  int currentGiftCount = 0;

  // --- মিউজিক ফিচারের ভেরিয়েবল ---
  bool isMusicBarVisible = false;      
  bool isFloatingPlayerVisible = false; 
  String currentPlayingMusicName = "";  
  List<Map<String, dynamic>> userAddedMusicList = []; 
  bool isMusicLoading = false;         
  String currentMusicUrl = "";         
  Offset playerPosition = const Offset(150, 400); 
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

    // ১. সিট জেনারেশন (১৫টি সিট ও VIP লজিক)
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
      "uId": "", // মালিকের ৬-ডিজিটের ইউনিক আইডি
      "agoraUid": "", 
    });

    // ২. রিয়েলটাইম ডাটাবেস লিসেনার (চোরমুক্ত লজিক)
    FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/seats')
        .onValue.listen((event) {
      if (!mounted) return;
      final dynamic data = event.snapshot.value;
      
      setState(() {
        // রিসেট লজিক
        for (var seat in seats) {
          seat["isOccupied"] = false;
          seat["status"] = "empty";
          seat["userName"] = "";
          seat["userImage"] = "";
          seat["isMicOn"] = false;
          seat["isTalking"] = false;
          seat["uId"] = "";
        }
        
        if (data != null) {
          data.forEach((key, value) {
            int? index = int.tryParse(key.toString());
            if (index != null && index < seats.length) {
              seats[index]["isOccupied"] = value["isOccupied"] ?? false;
              seats[index]["status"] = value["status"] ?? "occupied";
              seats[index]["userName"] = value["userName"] ?? value["name"] ?? "";
              seats[index]["userImage"] = value["userImage"] ?? value["profilePic"] ?? "";
              seats[index]["isMicOn"] = value["isMicOn"] ?? false;
              seats[index]["userId"] = value["userId"] ?? "";
              seats[index]["uId"] = value["uId"] ?? "";
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

    // ৪. এগোরা ম্যানেজার ও ভয়েস ডিটেকশন
    Future.microtask(() async {
      try {
        await _agoraManager.initAgora(); 
        final String authUid = FirebaseAuth.instance.currentUser?.uid ?? "";
        await _agoraManager.joinAsListener(widget.roomId, authUid);

        final engine = _agoraManager.engine;
        if (engine != null) {
          await engine.enableAudioVolumeIndication(interval: 250, smooth: 3, reportVad: true);
          engine.registerEventHandler(
            RtcEngineEventHandler(
              onUserJoined: (connection, remoteUid, elapsed) {
                if (mounted) _addUserToViewers(); 
              },
              onAudioVolumeIndication: (connection, speakers, totalVolume, speakerNumber) {
                if (!mounted) return;
                bool hasChanged = false;
                List<String> currentTalkingUids = speakers
                    .where((s) => (s.volume ?? 0) > 5)
                    .map((s) => s.uid == 0 ? authUid : s.uid.toString())
                    .toList();

                for (var seat in seats) {
                  bool isUserTalkingNow = currentTalkingUids.contains(seat["userId"]) || 
                                        currentTalkingUids.contains(seat["agoraUid"]) ||
                                        currentTalkingUids.contains(seat["uId"]);
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
      } catch (e) { debugPrint("Agora Error: $e"); }
    });

    // ৫. ফায়ারস্টোর ডাটা লোড ও ওনার ভেরিফিকেশন (সবচেয়ে গুরুত্বপূর্ণ অংশ)
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).get().then((doc) {
      if (doc.exists && mounted) {
        final data = doc.data();
        
        // ⚔️ চোর জবাই: FirebaseAuth থেকে লম্বা আইডি না নিয়ে শুধু ৬-ডিজিটের আইডি ব্যবহার করুন
        // যদি AppData.myID ফেইল করে, তবে এটা সরাসরি widget.ownerId বা অন্য সোর্স থেকে নিন।
        final String currentSessionID = data?['uID'] ?? ""; 

        setState(() {
          roomName = data?['roomName'] ?? 'Pagla Chat Room';
          roomProfileImage = data?['roomImage'] ?? '';
          followerCount = data?['followerCount'] ?? 0;
          isRoomLocked = data?['isLocked'] ?? false;
          roomWallpaperPath = data?['roomWallpaper'] ?? data?['wallpaper'] ?? '';

          // শুধু uID এবং ownerId চেক হবে (কোনো লম্বা আইডি ঢুকবে না)
          roomOwnerId = data?['uID'] ?? data?['ownerId'] ?? widget.ownerId; 
          ownerName = data?['ownerName'] ?? 'Unknown Owner';
          
          adminList = List<String>.from(data?['admins'] ?? []);

          // রোল সেট করা
          // দ্রষ্টব্য: এখানে 'AppData.myID' এর পরিবর্তে আপনার গ্লোবাল ৬-ডিজিটের আইডি ভেরিয়েবল ব্যবহার করুন
          String myGlobalID = widget.ownerId; // উদাহরণ হিসেবে, আপনার প্রোফাইল থেকে আসা ID

          if (myGlobalID == roomOwnerId) {
            userRole = "Owner";
            isOwner = true;
          } else if (adminList.contains(myGlobalID)) {
            userRole = "Admin";
            isOwner = false;
          } else {
            userRole = "Guest";
            isOwner = false;
          }
        });

        // ডাটাবেস আপডেট (চোরমুক্ত)
        _roomService.updateRoomFullData(
          roomId: widget.roomId,
          roomName: roomName,
          roomImage: roomProfileImage,
          isLocked: isRoomLocked,
          wallpaper: roomWallpaperPath,
          followers: followerCount,
          totalDiamonds: data?['totalDiamonds'] ?? 0,
          uID: roomOwnerId, 
          ownerName: ownerName,
          // 'admin' বা 'adminList' ফিল্ডে ডাটা পাঠানো বন্ধ করা হয়েছে এখান থেকে
        );
        
        _addUserToViewers();
      }
    });
  }
  // --- গিফট লজিক ও উইনার পপআপ ---
  void _startGiftCounting(int minutes, String theme) {
    if (isGiftCounting) return;
    setState(() { 
      isGiftCounting = true; 
      activityTheme = theme; 
      remainingSeconds = minutes * 60; 
    });

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
          // ডাটাবেস কি (Key) অনুযায়ী নাম ও ছবি ফিক্সড
          "name": s['userName'] ?? s['name'] ?? "User", 
          "avatar": s['userImage'] ?? s['profilePic'] ?? "", 
          "gifts": s['giftCount']
        });
      }
      if (topWinners.length == 2) break;
    }

    if (topWinners.isNotEmpty) {
      showDialog(context: context, builder: (context) => GiftRankDialog(winners: topWinners));
    }
  }

  // --- সিট হ্যান্ডলিং লজিক ---
  void sitOnSeat(int index) async {
    // ১. ক্লিক করলে যদি নিজের সিট হয় তবে লিভ কনফার্মেশন দেখাবে
    if (currentSeatIndex == index) { 
      _showLeaveConfirmation(index); 
      return; 
    }
    
    if (seats[index]["isOccupied"] || isRoomLocked) return;

    try {
      if (kIsWeb) await WakelockPlus.enable();
      await _agoraManager.becomeBroadcaster();
      await _agoraManager.engine?.muteLocalAudioStream(false);

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final String authUid = currentUser.uid;
      // আপনার আজীবন uId প্রোটোকল (currentUserData থেকে নেওয়া)
      final String myFixedUid = currentUserData['uId'] ?? currentUserData['uid'] ?? authUid; 
      final String myName = currentUser.displayName ?? "User";
      final String myPic = currentUser.photoURL ?? "";
      final int myAgoraUid = _agoraManager.localUid ?? 0;

      // ২. পুরাতন সিট রিমুভ (মুভ করার ক্ষেত্রে)
      if (currentSeatIndex != -1) {
        await FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$currentSeatIndex').remove();
      }

      final seatRef = FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$index');
      await seatRef.onDisconnect().remove();

      // ৩. ডাটাবেসে সেভ (রিপেল ও উইনার পপআপের জন্য সব কি দেওয়া হলো)
      await seatRef.set({
        'userName': myName,
        'userImage': myPic,
        'name': myName,         // উইনার পপআপের জন্য এক্সট্রা ব্যাকআপ
        'profilePic': myPic,    // উইনার পপআপের জন্য এক্সট্রা ব্যাকআপ
        'isOccupied': true,
        'status': 'occupied',
        'isMicOn': true,
        'userId': authUid,
        'uId': myFixedUid, 
        'isTalking': false,
        'agoraUid': myAgoraUid, 
        'giftCount': 0,
      });
      
      if (mounted) {
        setState(() {
          currentSeatIndex = index;
          isMicOn = true;
          // ওনার মেসেজ চেক
          if (myFixedUid == roomOwnerId) _sendOwnerJoinMessage();
        });
      }
    } catch (e) { debugPrint("Sit Error: $e"); }
  }

  void _showLeaveConfirmation(int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Leave Seat", style: TextStyle(color: Colors.white)),
        content: const Text("আপনি কি সিট ছেড়ে দিতে চান?", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("না")),
          TextButton(
            onPressed: () async {
              try {
                await _agoraManager.becomeListener();
                await FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$index').onDisconnect().cancel();
                await FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$index').remove();
                
                if (mounted) {
                  setState(() {
                    currentSeatIndex = -1;
                    isMicOn = false;
                  });
                  Navigator.pop(dialogContext);
                }
              } catch (e) { debugPrint("Leave Error: $e"); }
            }, 
            child: const Text("হ্যাঁ", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }

  void _sendOwnerJoinMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("সম্মানিত মালিক $ownerName সিটে বসেছেন!", 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

// --- পিকে ব্যাটেল লজিক (এটি না থাকলে এরর আসবে) ---
  void _endPKBattle() {
    if (!mounted) return;
    
    // উইনার নির্ধারণ (পয়েন্টের ভিত্তিতে)
    String winner = blueTeamPoints > redTeamPoints ? "BLUE" : "RED";
    
    showDialog(
      context: context,
      builder: (context) => PKWinnerDialog(
        winnerTeam: winner, 
        bluePoints: blueTeamPoints, 
        redPoints: redTeamPoints
      ),
    );
    
    setState(() => isPKActive = false);
  }
  
  @override
Widget build(BuildContext context) {
  // কিবোর্ডের উচ্চতা মাপার জন্য
  double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

  return Scaffold(
    // ব্যাকগ্রাউন্ড কালার আপনার ছবির সাথে সামঞ্জস্য রেখে আপডেট করা হয়েছে
    backgroundColor: const Color(0xFF0B1222), 
    resizeToAvoidBottomInset: false, 
    body: GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
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
                          
                          String uName = data['userName'] ?? "User";
                          String uId = (data['uID'] ?? data['uid'] ?? data['userId'] ?? uName).toString();
                          String uImage = data['userImage'] ?? "";

                          return Align(
                            alignment: Alignment.bottomLeft,
                            child: GestureDetector(
                              onTap: () {
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

              // ৫. বটম অ্যাকশন এরিয়া (এখানে চ্যাট আইকন এবং সাউন্ড বাটন যোগ করা হয়েছে)
              _buildBottomActionArea(),
            ],
          ),

          // 🔥 সমাধান: টাইপ বক্স (কিবোর্ড ওপেন হলে মেসেজ আইকনের লজিক থেকে আসবে)
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
                            hintText: "type message...",
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
                        final currentUser = FirebaseAuth.instance.currentUser;
                        
                        if (msg.isNotEmpty && currentUser != null) {
                          _firestore
                              .collection('rooms')
                              .doc(widget.roomId)
                              .collection('messages')
                              .add({
                            'userName': currentUser.displayName ?? "User",
                            'userImage': currentUser.photoURL ?? "",
                            'uID': currentUser.uid,
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

          // মিউজিক প্লেয়ার
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

          GiftOverlayHandler(
            isGiftAnimating: isGiftAnimating,
            currentGiftImage: currentGiftImage,
            isFullScreenBinding: isGiftAnimating, 
            senderName: currentSenderName, 
            receiverName: targetType, 
          ),

          // গিফট লিসেনার
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

          // ৮. মেইল বাটন ও ইনবক্স (অপরিবর্তিত)
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

          // ৯. ইমোজি অ্যানিমেশন
          ..._buildFloatingEmojiAnimations(), 
        ],
      ),
    ),
  );
}

// ইমোজি মেথড (সিট পজিশন অনুযায়ী)
List<Widget> _buildFloatingEmojiAnimations() {
  return activeEmojis.entries.map((entry) {
    int seatIndex = entry.key;
    String lottieUrl = entry.value;

    return Positioned(
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
    
    // রুম ওনার আইডি হিসেবে ডাটাবেসের uID ব্যবহার করা হচ্ছে
    final String roomOwnerId = uID; 
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Only Owner & Admin can change room picture"))
                );
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
                  
                  // 🔥 ডাটাবেসে ছবি সেভ (uID ও ownerName সহ সার্ভিস কল)
                  _roomService.updateRoomFullData(
                    roomId: widget.roomId,
                    roomName: roomName,
                    roomImage: p,
                    isLocked: isRoomLocked,
                    wallpaper: roomWallpaperPath,
                    followers: followerCount,
                    totalDiamonds: 0,
                    uID: roomOwnerId,
                    ownerName: ownerName,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Only Owner & Admin can change room name"))
                      );
                      return;
                    }
                    
                    RoomProfileHandler.editRoomName(
                      context: context, 
                      currentName: roomName, 
                      onNameSaved: (n) {
                        setState(() => roomName = n);
                        
                        // 🔥 ডাটাবেসে নাম সেভ (uID ও ownerName সহ সিঙ্ক)
                        _roomService.updateRoomFullData(
                          roomId: widget.roomId,
                          roomName: n,
                          roomImage: roomProfileImage,
                          isLocked: isRoomLocked,
                          wallpaper: roomWallpaperPath,
                          followers: followerCount,
                          totalDiamonds: 0,
                          uID: roomOwnerId,
                          ownerName: ownerName,
                        );
                      }
                    );
                  },
                  child: Text(roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                Text("ID: ${widget.roomId} | $followerCount Followers", style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),

          // ➕ ১. ফলোয়ার বাটন (টগল লজিক + সঠিক ডাটা সিঙ্ক)
          IconButton(
            icon: Icon(
              isFollowing ? Icons.check_circle : Icons.person_add_alt_1,
              color: isFollowing ? Colors.greenAccent : Colors.blueAccent, 
              size: 20
            ),
            onPressed: () async {
              if (myUid.isEmpty) return;

              var roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
              
              // ডাটাবেস থেকে মালিকের আইডি এবং নাম সংগ্রহ (সিঙ্ক করার জন্য)
              var roomDoc = await roomRef.get();
              if (!roomDoc.exists) return;
              var data = roomDoc.data();
              
              String ownerUidFromDb = data?['uID'] ?? data?['ownerId'] ?? "";
              String currentOwnerName = data?['ownerName'] ?? "Unknown";

              // মালিক নিজে নিজেকে ফলো করতে পারবে না
              if (myUid == ownerUidFromDb) return;

              if (isFollowing) {
                await roomRef.update({
                  'followers': FieldValue.arrayRemove([myUid]),
                  'followerCount': FieldValue.increment(-1),
                });
                setState(() {
                  isFollowing = false;
                  followerCount--;
                });
              } else {
                await roomRef.update({
                  'followers': FieldValue.arrayUnion([myUid]),
                  'followerCount': FieldValue.increment(1),
                });
                setState(() {
                  isFollowing = true;
                  followerCount++;
                });
              }

              // ✅ ডাটা সিঙ্ক: uID এবং ownerName পাস করা হয়েছে
              _roomService.updateRoomFullData(
                roomId: widget.roomId,
                roomName: roomName,
                roomImage: roomProfileImage,
                isLocked: isRoomLocked,
                wallpaper: roomWallpaperPath,
                followers: followerCount,
                totalDiamonds: 0,
                uID: ownerUidFromDb,
                ownerName: currentOwnerName,
              );
            },
          ),

          // ➕ ২. লিস্ট দেখার বাটন (মালিকের আইডি uID থেকে নিশ্চিত করা হয়েছে)
          IconButton(
            icon: const Icon(Icons.group, color: Colors.white70),
            onPressed: () async {
              var roomDoc = await FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .get();
          
              if (!roomDoc.exists) return;
          
              var data = roomDoc.data();
              String ownerUidFromDb = data?['uID'] ?? data?['ownerId'] ?? "";
          
              if (!context.mounted) return;
          
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => RoomFollowerSheet(
                  roomId: widget.roomId,
                  ownerId: ownerUidFromDb, 
                ),
              );
            },
          ),
          
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70), 
            onPressed: _showSettings
          ),
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

              // ১. ভিআইপি সিট চেক (uID এবং uid দুইভাবেই ডাটা খোঁজা হবে)
          if (isVipSeat) {
            // বর্তমান ইউজারের আইডি বের করা
            final String myCurrentId = FirebaseAuth.instance.currentUser?.uid ?? "";
            
            if (myCurrentId.isEmpty) return;

            // সরাসরি ফায়ারস্টোর থেকে ইউজারের ডাটা আনা হচ্ছে
            DocumentSnapshot userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(myCurrentId)
                .get();

            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>?;

              // --- আইডি চেক (uID অথবা uid দুইভাবেই লজিক রাখা হলো) ---
              String foundUid = userData?['uID'] ?? userData?['uid'] ?? "";
              
              // --- ভিআইপি চেক (True/False চেক) ---
              bool isUserVip = userData?['isVip'] == true;

              // যদি ইউজার ভিআইপি না হয়
              if (!isUserVip) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Only VIP Users can sit here!"),
                    backgroundColor: Colors.redAccent,
                    duration: Duration(seconds: 2),
                  ),
                );
                return; // ফাংশন এখানেই শেষ হবে, ইউজার সিটে বসতে পারবে না
              }
              
              debugPrint("VIP User Identity Verified: $foundUid");
            } else {
              // যদি ডাটাবেসে ইউজারের প্রোফাইলই না থাকে
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
   // --- ২. অ্যাকশন বার (মাইক, গেম, চ্যাট ইনপুট এবং রুম মোড) ---
Widget _buildBottomActionArea() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: Row(
      children: [
        // ১. ইমোজি বাটন 😄 (অরিজিনাল ৩ ও ৪ সেকেন্ডের টাইমার লজিক সহ)
        _buildCircularIcon(Icons.emoji_emotions_outlined, Colors.orangeAccent, () {
          final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
          int mySeatIndex = seats.indexWhere((s) => s != null && 
              (s['uID'] == currentUid || s['uid'] == currentUid || s['userId'] == currentUid));

          if (mySeatIndex != -1) {
            EmojiHandler.showPicker(context: context, seatIndex: mySeatIndex, 
              onEmojiSelected: (index, url) {
                if (index != -1 && url != null) {
                  setState(() {
                    seats[index]['showEmoji'] = true;
                    seats[index]['currentEmoji'] = url;
                  });

                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) setState(() { seats[index]['showEmoji'] = false; });
                  });

                  FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$index').update({
                    'currentEmoji': url,
                    'showEmoji': true,
                    'emojiTime': ServerValue.timestamp,
                  });

                  Future.delayed(const Duration(seconds: 4), () {
                    FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$index').update({
                      'showEmoji': false,
                    });
                  });
                }
              });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("সিটে বসুন আগে!")));
          }
        }),

        const SizedBox(width: 8),

        // ২. মেসেজ ইনপুট এরিয়া ✉️ (সঠিক profilePic লজিক সহ)
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Icon(Icons.mail_outline, color: Colors.white70, size: 20),
                ),
                Expanded(
                  child: ChatInputBar(
                    controller: _messageController,
                    onEmojiTap: null,
                    onMessageSend: (msg) async {
                      final String senderId = FirebaseAuth.instance.currentUser?.uid ?? "";
                      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();

                      String finalName = "User";
                      String finalImage = "";

                      if (userDoc.exists) {
                        final uData = userDoc.data() as Map<String, dynamic>;
                        finalName = uData['name'] ?? uData['userName'] ?? "User";
                        finalImage = uData['profilePic'] ?? ""; 
                      }

                      await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('messages').add({
                        'userName': finalName,
                        'userImage': finalImage,
                        'text': msg['text'],
                        'senderId': senderId,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // ৩. রুম মোড বাটন 🏩 (অরিজিনাল ফিচার)
        _buildCircularIcon(Icons.hotel, Colors.purpleAccent, () {
          // এখানে আপনার রুম মোড পরিবর্তনের লজিক
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

// গিফট বাটনের জন্য স্পেশাল এনিমেটেড ফাংশন (লজিক বাদ না দিয়ে)
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
        // --- আপনার অরিজিনাল গিফট লজিক ---
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get();
        int currentBalance = 0;
        String senderName = "User";
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
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
              setState(() {
                currentGiftImage = gift['icon'];
                isGiftAnimating = true;
                targetType = target;
                currentSenderName = senderName;
                currentReceiverName = target;
              });
              try {
                await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('gift_animations').add({
                  'giftIcon': gift['icon'],
                  'senderName': senderName,
                  'receiverName': target,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                bool isFree = gift['isFree'] ?? false;
                int unitPrice = gift['price'] ?? 0;
                int totalAmount = unitPrice * count;
                var targetSeat = seats.firstWhere((s) => s != null && (s['userName'] == target || s['name'] == target), orElse: () => <String, dynamic>{});
                String receiverId = "";
                if (targetSeat.isNotEmpty) { receiverId = targetSeat['uID'] ?? targetSeat['uid'] ?? ""; }
                if (receiverId.isNotEmpty) {
                  await GiftTransactionHelper.processGiftTransaction(
                    senderId: FirebaseAuth.instance.currentUser!.uid,
                    receiverId: receiverId,
                    totalPrice: totalAmount,
                    isFree: isFree,
                    giftName: gift['name'] ?? "Gift",
                  );
                  if (isGiftCounting) {
                    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('gift_counts').add({
                      'senderName': senderName, 'receiverName': target, 'points': totalAmount, 'timestamp': FieldValue.serverTimestamp(),
                    });
                  }
                }
              } catch (e) { debugPrint("Transaction Error: $e"); }
              Timer(const Duration(seconds: 5), () { if (mounted) setState(() { isGiftAnimating = false; }); });
            },
          ),
        );
      },
    ),
  );
}

// হেল্পার বাটন
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
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data();
        
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('viewers')
            .doc(user.uid)
            .set({
          // --- আপনার ডাটাবেস প্রোটোকল অনুযায়ী আপডেট করা হয়েছে ---
          'uID': user.uid, 
          'userName': userData?['userName'] ?? userData?['name'] ?? 'User',
          'userImage': userData?['userImage'] ?? userData?['profilePic'] ?? '',
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }
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
