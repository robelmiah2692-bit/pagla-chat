import 'package:flutter_background_service/flutter_background_service.dart'; 
import 'vs_pk_manager.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import '../pk_battle_view.dart'; // যেহেতু এটি এক ধাপ উপরে 'lib' ফোল্ডারে আছে
// এই ইমপোর্টগুলো আপনার voice_room.dart এর উপরে বসান
import '../game_panel_view.dart';
import '../pk_winner_dialog.dart';
import 'floating_room_tools.dart';

// আপনার সেই ৮টি আলাদা ফাইল ও উইজেট
import '../widgets/chat_input_bar.dart';
import '../widgets/emoji_handler.dart';
import '../widgets/follower_list_handler.dart';
import '../widgets/gift_overlay_handler.dart';
import '../widgets/gift_system.dart';
import '../widgets/music_player_widget.dart';
import '../widgets/room_profile_handler.dart';
import '../widgets/room_settings_handler.dart';
import 'gift_rank_dialog.dart';
import 'top_room_leaderboard.dart';

class VoiceRoom extends StatefulWidget {
  final String roomId; 
  const VoiceRoom({super.key, required this.roomId});

  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  // --- আপনার সব ভেরিয়েবল ---
  bool isOwner = true; 
  String displayUserID = "Owner"; 
  String roomName = "পাগলা চ্যাট রুম";
  int followerCount = 0;
  String roomProfileImage = '';
  bool isFollowed = false; 
  List<Map<String, dynamic>> viewersList = []; 
  int activeEmojiSeatIndex = -1; 
  bool isRoomLocked = false; 
  String roomWallpaperPath = ''; 
  int blueTeamPoints = 0;
  int redTeamPoints = 0;
  bool isPKActive = false; 
  late VSPKManager pkManager;
  int pkSeconds = 300; 

  bool isRoomMusicPlaying = false; 
  Offset playerPosition = const Offset(20, 100);
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _messageController = TextEditingController();
  
  int currentSeatIndex = -1; 
  bool isMicOn = false;
  List<Map<String, String>> chatMessages = [];
  bool isGiftAnimating = false;
  String currentGiftImage = "";
  late List<Map<String, dynamic>> seats;

  // গিফট টাইমার ভেরিয়েবল
  bool isCountingGifts = false;
  int remainingSeconds = 900;
  Timer? giftTimer;

  @override
  void initState() {
    super.initState();
    // ১৫টি সিট (৫টি VIP + ১০টি সাধারণ)
    seats = List.generate(15, (index) => {
      "isOccupied": false,
      "userName": "",
      "userImage": "",
      "isVip": index < 5, 
      "status": "empty", 
      "giftCount": 0,
      "isMicOn": false,
    });

    pkManager = VSPKManager(
      onTick: (seconds) => setState(() => pkSeconds = seconds),
      onFinished: () => _endPKBattle(),
    );
  }

  // --- ফিচার: গিফট কাউন্টডাউন (১৫ মিনিট) ---
  void _startGiftCounting() {
    if (isCountingGifts) return;
    setState(() {
      isCountingGifts = true;
      remainingSeconds = 900;
    });
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

  // --- ফিচার: PK Battle লজিক ---
  void _endPKBattle() {
    String winner = blueTeamPoints > redTeamPoints ? "BLUE" : "RED";
    showDialog(
      context: context,
      builder: (context) => PKWinnerDialog(winnerTeam: winner, bluePoints: blueTeamPoints, redPoints: redTeamPoints),
    );
    setState(() => isPKActive = false);
  }

  // --- ফিচার: ৩ সেকেন্ড কলিং ও রিয়েল অবতার সিট সিস্টেম ---
  void sitOnSeat(int index) {
    if (currentSeatIndex == index) {
      _showLeaveConfirmation(index);
      return;
    }
    if (isRoomLocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("রুম এখন লক আছে!")));
      return;
    }
    if (seats[index]["isOccupied"] || seats[index]["status"] == "calling") return;

    setState(() {
      seats[index]["status"] = "calling";
      seats[index]["userName"] = "Calling...";
      seats[index]["isOccupied"] = true;
    });

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          seats[index]["status"] = "occupied";
          seats[index]["userName"] = displayUserID;
          seats[index]["userImage"] = "https://api.dicebear.com/7.x/avataaars/svg?seed=$displayUserID";
          seats[index]["isMicOn"] = true;
          isMicOn = true;
          currentSeatIndex = index;
        });
      }
    });
  }

  void _showLeaveConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("সিট ছেড়ে দিন", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("না")),
          TextButton(
            onPressed: () {
              setState(() {
                seats[index]["isOccupied"] = false;
                seats[index]["status"] = "empty";
                seats[index]["isMicOn"] = false;
                currentSeatIndex = -1;
                isMicOn = false;
              });
              Navigator.pop(context);
            },
            child: const Text("হ্যাঁ", style: TextStyle(color: Colors.redAccent)),
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
          // ওয়ালপেপার ফিচার
          if (roomWallpaperPath.isNotEmpty)
            Positioned.fill(child: Image.file(File(roomWallpaperPath), fit: BoxFit.cover)),
          
          Column(
            children: [
              const SizedBox(height: 40),
              _buildTopNavBar(),
              
              // আপনার ভয়েস রুম ফাইলের ২০৫ নম্বর লাইনে এটি আপডেট করুন
              if (isPKActive)
                PKBattleView(
                bluePoints: blueTeamPoints, 
                redPoints: redTeamPoints,
                pkSeconds: pkSeconds,      // মেইন ফাইল থেকে সেকেন্ড পাস হচ্ছে
                pkManager: pkManager,      // টাইমার ফরম্যাটের জন্য ম্যানেজার পাস হচ্ছে
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

          // ভাসমান বাটনগুলো
          FloatingRoomTools(onGiftCountStart: _startGiftCounting),

          // মিউজিক প্লেয়ার ড্র্যাগেবল ফিচার
          if (isRoomMusicPlaying)
            Positioned(
              left: playerPosition.dx, top: playerPosition.dy,
              child: Draggable(
                feedback: _buildFloatingPlayer(isDragging: true),
                onDragEnd: (details) => setState(() => playerPosition = details.offset),
                child: _buildFloatingPlayer(isDragging: false),
              ),
            ),

          if (isGiftAnimating)
            Center(child: Lottie.network(currentGiftImage, width: 300)),
        ],
      ),
    );
  }

  // --- আপনার সব কাস্টম উইজেট ফাংশন ---
  Widget _buildTopNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => RoomProfileHandler.pickRoomImage(onImagePicked: (p) => setState(() => roomProfileImage = p), showMessage: (m) {}),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: roomProfileImage.isNotEmpty ? FileImage(File(roomProfileImage)) : null,
              child: roomProfileImage.isEmpty ? const Icon(Icons.camera_alt, size: 18) : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => RoomProfileHandler.editRoomName(context: context, currentName: roomName, onNameSaved: (n) => setState(() => roomName = n)),
                  child: Text(roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                Text("ID: ${widget.roomId} | $followerCount ফলোয়ার", style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.group, color: Colors.blueAccent), onPressed: () => FollowerListHandler.show(context, followerCount)),
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
              onEmojiTap: () => EmojiHandler.showPicker(context: context, seatIndex: -1, onEmojiSelected: (i, url) {
                setState(() { currentGiftImage = url; isGiftAnimating = true; });
                Timer(const Duration(seconds: 3), () => setState(() => isGiftAnimating = false));
              }),
              onMessageSend: (msg) => setState(() => chatMessages.add(msg)),
            ),
          ),
          const SizedBox(width: 8),
          // মাইক বাটন আপনার আগের লজিকসহ
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
          _buildSmallIconButton(Icons.videogame_asset, Colors.orange, () => showModalBottomSheet(context: context, builder: (c) => const GamePanelView())),
          _buildSmallIconButton(Icons.music_note, Colors.cyanAccent, () {}),
          _buildSmallIconButton(Icons.card_giftcard, Colors.pinkAccent, () {}),
        ],
      ),
    );
  }

  Widget _buildSmallIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(8.0), child: Icon(icon, color: color, size: 24)));
  }

  Widget _buildSeatGridArea() {
    return SizedBox(
      height: 300,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.7),
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
                      backgroundColor: seat["isOccupied"] ? Colors.blueAccent : Colors.white10,
                      backgroundImage: seat["userImage"].isNotEmpty ? NetworkImage(seat["userImage"]) : null,
                      child: seat["status"] == "calling" ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white) : (seat["isOccupied"] ? null : Icon(seat["isVip"] ? Icons.stars : Icons.chair, color: Colors.white24)),
                    ),
                    if (seat["isMicOn"]) Positioned(bottom: 0, right: 0, child: Icon(Icons.mic, size: 12, color: Colors.greenAccent)),
                  ],
                ),
                Text("${index + 1}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildViewerArea() {
    return Container(height: 40, child: const Center(child: Text("Live Viewers", style: TextStyle(color: Colors.white24))));
  }

  Widget _buildMessageRow(Map<String, String> msg) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Text("${msg['userName']}: ${msg['text']}", style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  void _showSettings() {
    RoomSettingsHandler.showSettings(
      context: context,
      isLocked: isRoomLocked,
      onToggleLock: () => setState(() => isRoomLocked = !isRoomLocked),
      onSetWallpaper: (p) => setState(() => roomWallpaperPath = p),
      onMinimize: () => Navigator.pop(context),
      onLeave: () { _audioPlayer.stop(); Navigator.pop(context); Navigator.pop(context); }
    );
  }

  Widget _buildFloatingPlayer({required bool isDragging}) {
    return Container(
      width: 140, padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(30)),
      child: const Row(children: [Icon(Icons.music_note, color: Colors.greenAccent), Text(" Playing...", style: TextStyle(color: Colors.white, fontSize: 10))]),
    );
  }
}
