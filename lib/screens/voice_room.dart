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
import 'package:pagla_chat/widgets/live_viewers_list.dart';
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
import 'package:pagla_chat/services/voice_engine.dart'; // এখানে আপনার প্রোজেক্টের নাম অনুযায়ী পাথ হবে
import 'package:pagla_chat/services/agora_manager.dart'; // আপনার ফাইলের নাম অনুযায়ী পাথ ঠিক করুন

import '../widgets/chat_input_bar.dart';
import '../widgets/emoji_handler.dart';
import '../widgets/follower_list_handler.dart';
import '../widgets/gift_overlay_handler.dart';
import '../widgets/gift_system.dart';
import '../widgets/music_player_widget.dart';
import '../widgets/room_profile_handler.dart';
import '../widgets/room_settings_handler.dart';

class VoiceRoom extends StatefulWidget {
  final String roomId; 
  const VoiceRoom({super.key, required this.roomId});

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

  @override
void initState() {
  super.initState();
  
  // ১. সিট জেনারেশন (আপনার অরিজিনাল ১৫টি সিট)
  seats = List.generate(15, (index) => {
    "isOccupied": false,
    "userName": "",
    "userImage": "",
    "isVip": index < 5, 
    "status": "empty", 
    "giftCount": 0,
    "isMicOn": false,
  });

  // 🔥 সমস্যা এখানে ছিল: ফাংশনটি ডিফাইন করা ছিল কিন্তু কল করা ছিল না।
  // আমি শুধু ফাংশনটির নাম সরিয়ে সরাসরি লিসেনারটি চালু করে দিয়েছি।
  FirebaseDatabase.instance
      .ref('rooms/${widget.roomId}/seats')
      .onValue.listen((event) {
    if (!mounted) return; // মাউন্টেড চেক যোগ করলাম যাতে ক্রাশ না করে
    final dynamic data = event.snapshot.value;
    
    setState(() {
      // আপনার অরিজিনাল লুপ: প্রথমে সব সিট খালি করুন
      for (var seat in seats) {
        seat["isOccupied"] = false;
        seat["status"] = "empty";
        seat["userName"] = "";
        seat["userImage"] = "";
        seat["isMicOn"] = false; // মাইক স্ট্যাটাসও ক্লিয়ার করা দরকার
      }
      
      // ডাটাবেসে যারা আছে তাদের বসান
      if (data != null) {
        data.forEach((key, value) {
          int index = int.parse(key.toString());
          if (index < seats.length) { // ইনডেক্স আউট অফ বাউন্ড সেফটি
            seats[index]["isOccupied"] = value["isOccupied"] ?? false;
            seats[index]["status"] = value["status"] ?? "occupied";
            seats[index]["userName"] = value["userName"] ?? "";
            seats[index]["userImage"] = value["userImage"] ?? "";
            seats[index]["isMicOn"] = value["isMicOn"] ?? false;
            seats[index]["userId"] = value["userId"] ?? ""; // আইডিটাও দরকার
          }
        });
      }
    });
  });

  // ২. পিকে ম্যানেজার (আপনার অরিজিনাল)
  pkManager = VSPKManager(
    onTick: (seconds) => setState(() => pkSeconds = seconds),
    onFinished: () => _endPKBattle(),
  );

  _agoraManager.initAgora();
  // ৩. অডিও প্লেয়ার লিসেনার (আপনার অরিজিনাল)
  _audioPlayer.onPlayerStateChanged.listen((state) {
    if (mounted) {
      setState(() {
        isRoomMusicPlaying = (state == PlayerState.playing);
      });
    }
  });

  _audioPlayer.onPlayerComplete.listen((event) {
    if (mounted) setState(() => isRoomMusicPlaying = false);
  });
  
  // ৪. ডাটা লোড এবং মেম্বার লিস্ট (আপনার অরিজিনাল)
  FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).get().then((doc) {
    if (doc.exists && mounted) {
      setState(() {
        roomName = doc.data()?['roomName'] ?? roomName;
        roomProfileImage = doc.data()?['roomImage'] ?? roomProfileImage;
        followerCount = doc.data()?['followerCount'] ?? 0;
        isRoomLocked = doc.data()?['isLocked'] ?? false;
        roomWallpaperPath = doc.data()?['wallpaper'] ?? '';
      });
    }

    // সার্ভিস আপডেট
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

  // ১. সিটে বসার মেইন লজিক (আপনার দেওয়া রিয়েল টাইম সিঙ্ক সহ)
   void sitOnSeat(int index) async {
  // ১. যদি একই সিটে আবার ক্লিক করেন (অরিজিনাল লজিক)
  if (currentSeatIndex == index) { 
    _showLeaveConfirmation(index); 
    return; 
  }
  
  // ২. সিট দখল বা রুম লক থাকলে রিটার্ন
  if (seats[index]["isOccupied"] || seats[index]["status"] == "calling" || isRoomLocked) return;

  // 🔥 ৩. পুরনো সিট পরিষ্কার এবং এগোরা ভয়েস চ্যানেল থেকে লিভ নেওয়া
  if (currentSeatIndex != -1) {
    int oldIndex = currentSeatIndex;
    
    await _agoraManager.leaveRoom();

    // Realtime Database থেকে ডিলিট
    await FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/seats/$oldIndex')
        .remove();

    setState(() {
      seats[oldIndex]["isOccupied"] = false;
      seats[oldIndex]["status"] = "empty";
      seats[oldIndex]["userName"] = "";
      seats[oldIndex]["userImage"] = "";
      seats[oldIndex]["isMicOn"] = false;
    });
  }

  // ৪. নতুন সিটে "Calling" স্ট্যাটাস দেওয়া
  setState(() {
    seats[index]["status"] = "calling";
    seats[index]["isOccupied"] = true;
    currentSeatIndex = index; 
    isMicOn = true; 
  });

  // 🚀 কলিং ফিক্স (সব ঠিক রেখে সিটে কথা বলা নিশ্চিত করা)
  try {
    // এগোরা ইঞ্জিন স্টার্ট করা (আপনার সেই সাকসেসফুল ওয়েব পারমিশন সহ)
    await _agoraManager.initAgora(); 
    
    // 🔥 ছোট বিরতি: ইঞ্জিন পুরোপুরি রেডি হওয়ার জন্য ১ সেকেন্ড অপেক্ষা
    await Future.delayed(const Duration(seconds: 1));

    // রুমে জয়েন করা
    await _agoraManager.joinRoom(widget.roomId);
    
    // নিশ্চিত করা যে রোল ব্রডকাস্টার এবং মাইক আনমিউট
    await _agoraManager.engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _agoraManager.toggleMic(false); // false মানে মাইক চালু
    
    AgoraStatusChecker.checkStatus(_agoraManager.engine, context);
  } catch (e) {
    debugPrint("Agora Join Error: $e");
    if (mounted) {
      setState(() {
        seats[index]["status"] = "empty";
        seats[index]["isOccupied"] = false;
        currentSeatIndex = -1;
      });
    }
    return; 
  }
    
  // 🔥 ৫. Realtime Database-এর মেইন কানেকশন
  final seatRef = FirebaseDatabase.instance.ref('rooms/${widget.roomId}/seats/$index');
  await seatRef.onDisconnect().remove();

  // ৬. ৩ সেকেন্ড পর প্রোফাইল ডাটা বসানো
  Timer(const Duration(seconds: 3), () async {
    if (!mounted) return;
    try {
      // টাইমারের পর কথা বলা চালু রাখা নিশ্চিত করা
      await _agoraManager.engine.muteLocalAudioStream(false);

      final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      
      String myActualName = userDoc.data()?['name'] ?? "User"; 
      String myActualPic = userDoc.data()?['profilePic'] ?? "";

      // ডাটাবেসে ডাটা সেট করা
      await seatRef.set({
        'userName': myActualName,
        'userImage': myActualPic,
        'isOccupied': true,
        'status': 'occupied',
        'isMicOn': true,
        'userId': uid,
      });

      if (mounted) {
        setState(() {
          seats[index]["status"] = "occupied";
          seats[index]["userName"] = myActualName;
          seats[index]["userImage"] = myActualPic; 
          seats[index]["isMicOn"] = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { 
          seats[index]["status"] = "empty"; 
          seats[index]["isOccupied"] = false; 
          currentSeatIndex = -1;
        });
        await _agoraManager.leaveRoom();
      }
    }
  }); 
}

  // ২. সিট ছাড়ার লজিক
  void _showLeaveConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("সিট ছেড়ে দিন", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("না")),
          TextButton(
            onPressed: () async {
              await _roomService.updateSeatData(roomId: widget.roomId, seatIndex: index, uName: "", uImage: "", isOccupied: false);
              await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('seats').doc(index.toString()).delete();
              if (mounted) {
                setState(() {
                  seats[index]["isOccupied"] = false;
                  seats[index]["status"] = "empty";
                  seats[index]["userName"] = "";
                  seats[index]["userImage"] = "";
                  seats[index]["isMicOn"] = false; 
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
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          if (roomWallpaperPath.isNotEmpty)
            Positioned.fill(child: Image.network(roomWallpaperPath, fit: BoxFit.cover)),
          
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
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(15)),
                  child: ListView.builder(
                    reverse: true,
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) => _buildMessageRow(chatMessages[chatMessages.length - 1 - index]),
                  ),
                ),
              ),
              _buildBottomActionArea(),
            ],
          ),

          FloatingRoomTools(onGiftCountStart: _startGiftCounting),
          
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

          if (isGiftAnimating)
            IgnorePointer(
              child: Center(child: Lottie.network(currentGiftImage, width: 300)),
            ),
        ],
      ),
    );
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
              isFollowing ? Icons.check_circle : Icons.person_add_alt_1, // ফলো হলে টিক মার্ক
              color: isFollowing ? Colors.greenAccent : Colors.blueAccent, 
              size: 20
            ),
            onPressed: () {
              setState(() {
                if (isFollowing) {
                  followerCount--; // আনফলো করলে ১ কমবে
                  isFollowing = false;
                } else {
                  followerCount++; // ফলো করলে ১ বাড়বে
                  isFollowing = true;
                }
              });
              // 🔥 ফায়ারবেসে আপডেট
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

          IconButton(icon: const Icon(Icons.group, color: Colors.white70), onPressed: () => FollowerListHandler.show(context, followerCount)),
          IconButton(icon: const Icon(Icons.settings, color: Colors.white70), onPressed: _showSettings),
        ],
      ),
    );
  }

Widget _buildBottomActionArea() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    color: Colors.black26,
    child: Row(
      children: [
        Expanded(
          child: ChatInputBar(
            controller: _messageController,
            onEmojiTap: () => EmojiHandler.showPicker(
              context: context, 
              seatIndex: -1, 
              onEmojiSelected: (i, url) {
                setState(() { currentGiftImage = url; isGiftAnimating = true; });
                Timer(const Duration(seconds: 3), () => setState(() => isGiftAnimating = false));
              }
            ),
            onMessageSend: (msg) => setState(() => chatMessages.add(msg)),
          ),
        ),
        const SizedBox(width: 8),

        // ১. মাইক বাটন
        IconButton(
       icon: Icon(
     isMicOn ? Icons.mic : Icons.mic_off,
    color: isMicOn ? Colors.greenAccent : Colors.redAccent,
  ),
  onPressed: () async {
    if (currentSeatIndex != -1) {
      // বর্তমান অবস্থার উল্টোটা সেট হবে
      bool newMicState = !isMicOn;

      try {
        // ১. এগোরা ইঞ্জিনে মাইক অন/অফ করা
        // !newMicState দেওয়ার কারণ: toggleMic(true) মানে মিউট, toggleMic(false) মানে আনমিউট
        await _agoraManager.toggleMic(!newMicState);

        // 🔥 ২. রিয়েলটাইম ডাটাবেসে আপডেট (যাতে অন্য সবাই দেখতে পায় আপনার মাইক অন/অফ)
        await FirebaseDatabase.instance
            .ref('rooms/${widget.roomId}/seats/$currentSeatIndex')
            .update({'isMicOn': newMicState});

        // ৩. লোকাল অ্যাপের স্টেট আপডেট করা
        setState(() {
          isMicOn = newMicState;
          seats[currentSeatIndex]["isMicOn"] = newMicState;
        });
        
        debugPrint("Mic state updated to: $newMicState");
      } catch (e) {
        debugPrint("Mic Toggle Error: $e");
      }
    } else {
      // সিটে না বসে মাইক চাপলে ওয়ার্নিং
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("আগে সিটে বসুন!"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  },
),
        
        // ২. গেম বাটন
        IconButton(
          icon: const Icon(Icons.videogame_asset, color: Colors.orange), 
          onPressed: () => showModalBottomSheet(context: context, builder: (c) => const GamePanelView())
        ),

        // 🔥 নতুন সংযোজন: ইনবক্স নোটিফিকেশন কাউন্টার
        StreamBuilder<QuerySnapshot>(
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
                IconButton(
                  icon: const Icon(Icons.mail, color: Colors.white70),
                  onPressed: () {
                    // এখানে আপনার ইনবক্স পেজে যাওয়ার কোড লিখুন
                    print("Inbox Clicked");
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

        // ৩. মিউজিক বাটন
        IconButton(
          icon: const Icon(Icons.music_note, color: Colors.cyanAccent), 
          onPressed: () async {
            final result = await showModalBottomSheet<Map<String, dynamic>>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => MusicPlayerPage(audioPlayer: _audioPlayer),
            );

            if (result != null && result['path'] != null) {
              await _audioPlayer.play(DeviceFileSource(result['path']));
              setState(() {
                isRoomMusicPlaying = true; 
              });
            }
          },
        ),
        
        // ৪. গিফট বাটন
        IconButton(
          icon: const Icon(Icons.card_giftcard, color: Colors.pinkAccent), 
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => GiftBottomSheet(
                diamondBalance: 1000, 
                onGiftSend: (gift, count, target) {
                  setState(() {
                    currentGiftImage = gift['icon']; 
                    isGiftAnimating = true;
                  });
                  Timer(const Duration(seconds: 3), () => setState(() => isGiftAnimating = false));
                },
              ),
            );
          },
        ),
      ],
    ),
  );
}
  
  Widget _buildSeatGridArea() {
  return SizedBox(
    height: 300,
    child: StreamBuilder<QuerySnapshot>(
      // 🔥 ফায়ারবেস থেকে রিয়েল-টাইম সিট ডাটা আনা হচ্ছে
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('seats')
          .snapshots(),
      builder: (context, snapshot) {
        // ডাটাবেসের সিটগুলোকে একটা ম্যাপে নিয়ে আসা
        Map<String, dynamic> firestoreSeats = {};
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            firestoreSeats[doc.id] = doc.data();
          }
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.7,
          ),
          itemCount: 15,
          itemBuilder: (context, index) {
            // ডাটাবেস থেকে ওই নির্দিষ্ট সিটের ডাটা চেক
            var dbSeat = firestoreSeats[index.toString()];
            
            // ডাটাবেসে ডাটা থাকলে সেটা নিবে, নাহলে লোকাল seats লিস্ট থেকে নিবে (সেফটি হিসেবে)
            bool isOccupied = dbSeat != null ? (dbSeat['isOccupied'] ?? false) : seats[index]['isOccupied'];
            String uName = dbSeat != null ? (dbSeat['userName'] ?? "") : seats[index]['userName'];
            String uImage = dbSeat != null ? (dbSeat['userImage'] ?? "") : seats[index]['userImage'];
            bool isMicOn = dbSeat != null ? (dbSeat['isMicOn'] ?? false) : seats[index]['isMicOn'];
            String status = dbSeat != null ? (dbSeat['status'] ?? "empty") : seats[index]['status'];
            bool isVip = seats[index]['isVip']; // এটা লোকাল থেকেই থাক

            return GestureDetector(
              onTap: () => sitOnSeat(index),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // সিটের বর্ডার ও ব্যাকগ্রাউন্ড
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isOccupied ? Colors.blueAccent : Colors.white10,
                        
                        // ✅ ইউজারের প্রোফাইল পিকচার (নেটওয়ার্ক থেকে)
                        backgroundImage: (uImage.isNotEmpty) 
                            ? NetworkImage(uImage) 
                            : null,
                        
                        // সিট খালি থাকলে আইকন অথবা কলিং এনিমেশন
                        child: status == "calling"
                            ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                            : (isOccupied 
                                ? null 
                                : Icon(isVip ? Icons.stars : Icons.chair, color: Colors.white24)),
                      ),
                      
                      // ✅ মাইক অন থাকলে আইকন
                      if (isMicOn)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: const Icon(Icons.mic, size: 12, color: Colors.greenAccent),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // ✅ ইউজারের নাম অথবা সিট নাম্বার
                  Text(
                    isOccupied ? uName : "${index + 1}",
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}
  

  Widget _buildViewerArea() { 
  return Container(
    height: 50, 
    margin: const EdgeInsets.symmetric(vertical: 5),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05), // হালকা একটা ব্যাকগ্রাউন্ড
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(Icons.groups, color: Colors.white54, size: 18),
        const SizedBox(width: 8),
        const Text(
          "আড্ডায়:", 
          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)
        ),
        const SizedBox(width: 10),
        // 🔥 এই সেই ফাইল যেটা আমরা আলাদাভাবে তৈরি করেছি
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
            text: "${msg['userName']}: ", 
            style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)
          ),
          TextSpan(
            text: "${msg['text']}", 
            style: const TextStyle(color: Colors.white, fontSize: 13)
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
      onLeave: () { _audioPlayer.stop(); Navigator.pop(context); }
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
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ],
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

  // --- মেম্বার লিস্ট ম্যানেজমেন্ট ---

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
}
