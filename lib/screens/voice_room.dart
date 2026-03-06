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
    
    // ১. সিট জেনারেশন
    seats = List.generate(15, (index) => {
      "isOccupied": false,
      "userName": "",
      "userImage": "",
      "isVip": index < 5, 
      "status": "empty", 
      "giftCount": 0,
      "isMicOn": false,
    });

    // ২. পিকে ম্যানেজার
    pkManager = VSPKManager(
      onTick: (seconds) => setState(() => pkSeconds = seconds),
      onFinished: () => _endPKBattle(),
    );

    // ৩. অডিও প্লেয়ার লিসেনার
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
    
    // ৪. ডাটা লোড এবং মেম্বার লিস্টে নাম তোলা
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).get().then((doc) {
      if (doc.exists && mounted) {
        setState(() {
          roomName = doc.data()?['roomName'] ?? roomName;
          roomProfileImage = doc.data()?['roomImage'] ?? roomProfileImage;
          followerCount = doc.data()?['followerCount'] ?? 0;
          isLocked = doc.data()?['isLocked'] ?? false;
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

      // 🔥 এই যে লাইনটি যেটা আড্ডায় নাম যোগ করবে
      _addUserToViewers();
    });
  }

  @override
  void dispose() {
    // 🔥 রুম থেকে বের হওয়ার সময় নাম মুছে দেওয়া
    _removeUserFromViewers(); 

    giftTimer?.cancel();
    pkManager.stopPK();
    _audioPlayer.dispose();
    _messageController.dispose();
    
    super.dispose();
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

// ১. সিটে বসার লজিক (নিজের প্রোফাইল ছবিসহ)
void sitOnSeat(int index) {
  if (currentSeatIndex == index) { 
    _showLeaveConfirmation(index); 
    return; 
  }

  if (seats[index]["isOccupied"] || seats[index]["status"] == "calling" || isRoomLocked) return;

  // সুইচিং লজিক: আগের সিট সাথে সাথে ক্লিয়ার করা
  if (currentSeatIndex != -1) {
    int oldIndex = currentSeatIndex;
    _roomService.updateSeatData(roomId: widget.roomId, seatIndex: oldIndex, uName: "", uImage: "", isOccupied: false);
    setState(() {
      seats[oldIndex]["isOccupied"] = false;
      seats[oldIndex]["status"] = "empty";
      seats[oldIndex]["userName"] = "";
      seats[oldIndex]["userImage"] = "";
      seats[oldIndex]["isMicOn"] = false;
    });
  }

  setState(() {
    seats[index]["status"] = "calling";
    seats[index]["isOccupied"] = true;
  });

  Timer(const Duration(seconds: 3), () async {
    if (!mounted) return;
    try {
      // 🔥 ফায়ারবেস থেকে কারেন্ট ইউজারের অরিজিনাল ডাটা আনা হচ্ছে
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      
      // আপনার ডাটাবেস অনুযায়ী 'name' এবং 'profilePic' ফিল্ড থেকে ডাটা আসবে
      String myActualName = userDoc.data()?['name'] ?? "User"; 
      String myActualPic = userDoc.data()?['profilePic'] ?? ""; // গ্যালারির ছবি বা অবতার যা প্রোফাইলে আছে

      await _roomService.updateSeatData(
        roomId: widget.roomId, 
        seatIndex: index,
        uName: myActualName, 
        uImage: myActualPic, 
        isOccupied: true,
      );

      setState(() {
        seats[index]["status"] = "occupied";
        seats[index]["userName"] = myActualName;
        seats[index]["userImage"] = myActualPic; // ✅ সিটে আপনার প্রোফাইল ছবি বসবে
        seats[index]["isMicOn"] = true;
        isMicOn = true;
        currentSeatIndex = index;
      });

    } catch (e) {
      if (mounted) setState(() { seats[index]["status"] = "empty"; seats[index]["isOccupied"] = false; });
    }
  });
}

// ২. সিট ছাড়ার লজিক (সব ডাটা মুছে ফেলা)
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
            // ডাটাবেস থেকে সব ক্লিয়ার
            await _roomService.updateSeatData(
              roomId: widget.roomId,
              seatIndex: index,
              uName: "",
              uImage: "",
              isOccupied: false,
            );

            // স্ক্রিন থেকে সব ক্লিয়ার (মাইক, ছবি, নাম)
            setState(() {
              seats[index]["isOccupied"] = false;
              seats[index]["status"] = "empty";
              seats[index]["userName"] = "";
              seats[index]["userImage"] = "";
              seats[index]["isMicOn"] = false; // 🔥 নীল মাইক বন্ধ
              currentSeatIndex = -1;
              isMicOn = false;
            });
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
          // ১. ওয়ালপেপার সেকশন
          if (roomWallpaperPath.isNotEmpty)
            Positioned.fill(
              child: Image.network(roomWallpaperPath, fit: BoxFit.cover),
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

          // ৩. ফ্লোটিং টুলস
          FloatingRoomTools(onGiftCountStart: _startGiftCounting),
          // 🔥 আপনার সেই হারানো ভাসমান প্লেয়ার (১০০% ফিক্সড)
          // মিউজিক বাজলে এই ভাসমান প্লেয়ারটি দেখা যাবে
          if (isRoomMusicPlaying)
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

          // ৫. গিফট অ্যানিমেশন
          if (isGiftAnimating)
            IgnorePointer(
              child: Center(child: Lottie.network(currentGiftImage, width: 300)),
            ),
        ],
      ),
    );
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
          icon: Icon(isMicOn ? Icons.mic : Icons.mic_off, color: isMicOn ? Colors.greenAccent : Colors.redAccent),
          onPressed: () {
            if (currentSeatIndex != -1) {
              setState(() { isMicOn = !isMicOn; seats[currentSeatIndex]["isMicOn"] = isMicOn; });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("আগে সিটে বসুন!")));
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
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, 
          childAspectRatio: 0.7,
        ),
        itemCount: 15,
        itemBuilder: (context, index) {
          var seat = seats[index];
          return GestureDetector(
            onTap: () => sitOnSeat(index),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      // ✅ ফিচার ১: অকুপাইড হলে নীল, না হলে সাদাটে (ঠিক আছে)
                      backgroundColor: seat["isOccupied"] ? Colors.blueAccent : Colors.white10,
                      
                      // ✅ ফিচার ২: ইমেজ থাকলে নেটওয়ার্ক ইমেজ (ঠিক আছে)
                      backgroundImage: (seat["userImage"] != null && seat["userImage"].toString().isNotEmpty) 
                          ? NetworkImage(seat["userImage"]) 
                          : null,
                      
                      // ✅ ফিচার ৩: কলিং এনিমেশন অথবা ভিআইপি/চেয়ার আইকন (ঠিক আছে)
                      child: seat["status"] == "calling" 
                          ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white) 
                          : (seat["isOccupied"] 
                              ? null 
                              : Icon(seat["isVip"] ? Icons.stars : Icons.chair, color: Colors.white24)),
                    ),
                    
                    // ✅ ফিচার ৪: মাইক অন থাকলে আইকন (ঠিক আছে)
                    if (seat["isMicOn"] == true) 
                      Positioned(
                        bottom: 0, 
                        right: 0, 
                        child: const Icon(Icons.mic, size: 12, color: Colors.greenAccent),
                      ),
                  ],
                ),
                
                // 🔥 ফিচার ৫: নাম এবং সিট নাম্বার (এখানেই পরিবর্তন ছিল)
                Text(
                  seat["isOccupied"] ? (seat["userName"] ?? "") : "${index + 1}", 
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
