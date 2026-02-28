import 'package:flutter_background_service/flutter_background_service.dart';
import 'game_panel_view.dart'; 
import 'vs_pk_manager.dart';
import 'pk_winner_dialog.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';

// উইজেট ও হ্যান্ডলার ইমপোর্ট
import '../widgets/chat_input_bar.dart';
import '../widgets/emoji_handler.dart';
import '../widgets/follower_list_handler.dart';
import '../widgets/gift_overlay_handler.dart';
import '../widgets/gift_system.dart';
import '../widgets/music_player_widget.dart';
import '../widgets/room_profile_handler.dart';
import '../widgets/room_settings_handler.dart';
import 'floating_room_tools.dart'; 
import 'gift_rank_dialog.dart';

class VoiceRoom extends StatefulWidget {
  final String roomId; 
  const VoiceRoom({super.key, required this.roomId});

  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  // --- ১. আপনার দেওয়া মালিক শনাক্তকরণ ও অন্যান্য স্টেট ---
  bool isOwner = true; 
  String displayUserID = "Hridoy_Owner"; // [2026-02-25] মালিক শনাক্তকরণ কোড
  String roomName = "পাগলা চ্যাট রুম";
  int followerCount = 0;
  String roomProfileImage = '';
  bool isFollowed = false;
  List<Map<String, dynamic>> viewersList = []; 
  int activeEmojiSeatIndex = -1; 
  bool isRoomLocked = false; 
  String roomWallpaperPath = ''; 
  
  // PK ও গিফট টাইমার স্টেট
  int blueTeamPoints = 0;
  int redTeamPoints = 0;
  bool isPKActive = false; 
  late VSPKManager pkManager;
  int pkSeconds = 300; 
  bool isCountingGifts = false;
  int remainingSeconds = 900;
  Timer? giftTimer;

  // মিউজিক ও কন্ট্রোল
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

  @override
  void initState() {
    super.initState();
    // PK ম্যানেজার সেটআপ
    pkManager = VSPKManager(
      onTick: (seconds) => setState(() => pkSeconds = seconds),
      onFinished: () => _endPKBattle(),
    );

    // ১৫টি সিট জেনারেট (৫টি VIP + ১০টি সাধারণ)
    seats = List.generate(15, (index) => {
      "isOccupied": false,
      "userName": "",
      "userImage": "",
      "isVip": index < 5, 
      "status": "empty", 
      "isMicOn": false,
      "giftCount": 0,
    });

    // ডামি ভিউয়ার লিস্ট (রিয়েল টাইপ অবতারের জন্য)
    viewersList = List.generate(5, (index) => {
      "avatar": "https://api.dicebear.com/7.x/avataaars/svg?seed=user$index"
    });
  }

  @override
  void dispose() {
    giftTimer?.cancel();
    _audioPlayer.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // --- ২. সিট ম্যানেজমেন্ট (আপনার কলিং রুলস অনুযায়ী) ---
  void sitOnSeat(int index) {
    if (currentSeatIndex == index) {
      _showLeaveConfirmation(index);
      return;
    }

    if (isRoomLocked) {
      _showSnack("রুম এখন লক আছে! 🔒");
      return;
    }

    if (seats[index]["isOccupied"] || seats[index]["status"] == "calling") {
      _showSnack("এই সিটটি খালি নেই!");
      return;
    }

    setState(() {
      // আগের সিট খালি করা
      if (currentSeatIndex != -1) {
        seats[currentSeatIndex]["isOccupied"] = false;
        seats[currentSeatIndex]["status"] = "empty";
        seats[currentSeatIndex]["isMicOn"] = false;
      }
      
      seats[index]["status"] = "calling";
      seats[index]["userName"] = "Calling...";
      seats[index]["isOccupied"] = true;
    });

    // ৩ সেকেন্ড পর সিটে বসা ও মাইক ওপেন (আপনার রুলস [2026-02-17])
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          seats[index]["status"] = "occupied";
          seats[index]["userName"] = displayUserID;
          // নতুন রিয়েল টাইপের অবতার [2026-02-21]
          seats[index]["userImage"] = "https://api.dicebear.com/7.x/avataaars/svg?seed=$displayUserID";
          seats[index]["isMicOn"] = true; 
          isMicOn = true;               
          currentSeatIndex = index;     
        });
      }
    });
  }

  // --- ৩. গিফট ও PK লজিক ---
  void _startGiftCounting() {
    if (isCountingGifts) return;
    setState(() {
      isCountingGifts = true;
      remainingSeconds = 900; 
    });
    _showSnack("💎 ১৫ মিনিটের গিফট কাউন্টডাউন শুরু!");
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
    List<Map<String, dynamic>> topWinners = seatData
        .where((s) => s['giftCount'] > 0 && s['isOccupied'])
        .take(2)
        .map((s) => {"name": s['userName'], "avatar": s['userImage'], "gifts": s['giftCount']})
        .toList();

    if (topWinners.isNotEmpty) {
      showDialog(context: context, builder: (context) => GiftRankDialog(winners: topWinners));
    } else {
      _showSnack("কেউ গিফট পায়নি, তাই উইনার নেই!");
    }
  }

  void _endPKBattle() {
    String winner = blueTeamPoints > redTeamPoints ? "BLUE" : "RED";
    showDialog(
      context: context,
      builder: (context) => PKWinnerDialog(
        winnerTeam: winner,
        bluePoints: blueTeamPoints,
        redPoints: redTeamPoints,
      ),
    );
    setState(() => isPKActive = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --- ৪. UI বিল্ড সেকশন ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      resizeToAvoidBottomInset: true, 
      body: Stack(
        children: [
          // ওয়ালপেপার সাপোর্ট
          if (roomWallpaperPath.isNotEmpty)
            Positioned.fill(child: Image.file(File(roomWallpaperPath), fit: BoxFit.cover)),
          
          Column(
            children: [
              const SizedBox(height: 40),
              _buildTopNavBar(),
              if (isPKActive) PKBattleView(bluePoints: blueTeamPoints, redPoints: redTeamPoints),
              _buildViewerArea(),
              _buildSeatGridArea(),
              
              // চ্যাট এরিয়া
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(15)),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    reverse: true,
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = chatMessages[chatMessages.length - 1 - index];
                      return _buildMessageRow(msg);
                    },
                  ),
                ),
              ),
              _buildBottomActionArea(),
            ],
          ),

          // ফ্লোটিং টুলস
          FloatingRoomTools(onGiftCountStart: _startGiftCounting),

          // মিউজিক প্লেয়ার ড্র্যাগেবল
          if (isRoomMusicPlaying)
            Positioned(
              left: playerPosition.dx,
              top: playerPosition.dy,
              child: Draggable(
                feedback: _buildFloatingPlayer(isDragging: true),
                onDragEnd: (details) => setState(() => playerPosition = details.offset),
                child: _buildFloatingPlayer(isDragging: false),
              ),
            ),

          // গিফট এনিমেশন ওভারলে
          if (isGiftAnimating)
            Center(child: Lottie.network(currentGiftImage, width: 300)),
        ],
      ),
    );
  }

  // --- ৫. ছোট উইজেট ফাংশনসমূহ ---
  Widget _buildTopNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => RoomProfileHandler.pickRoomImage(
              onImagePicked: (path) => setState(() => roomProfileImage = path),
              showMessage: _showSnack,
            ),
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => RoomProfileHandler.editRoomName(
                        context: context,
                        currentName: roomName,
                        onNameSaved: (newName) => setState(() => roomName = newName),
                      ),
                      child: Text(roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () { if (!isFollowed) setState(() { followerCount++; isFollowed = true; }); },
                      child: Icon(isFollowed ? Icons.check_circle : Icons.add_circle, color: isFollowed ? Colors.green : Colors.blue, size: 18),
                    ),
                  ],
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
              onEmojiTap: () => EmojiHandler.showPicker(
                context: context, seatIndex: -1,
                onEmojiSelected: (index, url) {
                  setState(() { currentGiftImage = url; isGiftAnimating = true; });
                  Timer(const Duration(seconds: 3), () => setState(() => isGiftAnimating = false));
                },
              ),
              onMessageSend: (msg) => setState(() => chatMessages.add(msg)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(isMicOn ? Icons.mic : Icons.mic_off, color: isMicOn ? Colors.green : Colors.red),
            onPressed: () {
              if (currentSeatIndex == -1) {
                _showSnack("আগে সিটে বসুন!");
              } else {
                setState(() { isMicOn = !isMicOn; seats[currentSeatIndex]["isMicOn"] = isMicOn; });
              }
            },
          ),
          IconButton(icon: const Icon(Icons.videogame_asset, color: Colors.orange), onPressed: () => showModalBottomSheet(context: context, builder: (c) => const GamePanelView())),
          IconButton(icon: const Icon(Icons.music_note, color: Colors.cyan), onPressed: _openMusicPlayer),
          IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.pink), onPressed: () {}), // গিফট প্যানেল
        ],
      ),
    );
  }

  // সিট গ্রিড এবং অন্যান্য হেল্পার ফাংশন এখানে থাকবে...
  Widget _buildViewerArea() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const SizedBox(width: 15),
          Text("👀 ${viewersList.length}", style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
          const SizedBox(width: 10),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: viewersList.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(radius: 14, backgroundImage: NetworkImage(viewersList[index]['avatar'])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatGridArea() {
    return SizedBox(
      height: 280,
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
                CircleAvatar(
                  radius: 24,
                  backgroundColor: seat["isOccupied"] ? Colors.blueAccent : Colors.white10,
                  backgroundImage: seat["userImage"] != "" ? NetworkImage(seat["userImage"]) : null,
                  child: seat["status"] == "calling" ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : (seat["isOccupied"] ? null : Icon(seat["isVip"] ? Icons.stars : Icons.chair)),
                ),
                Text("${index + 1}", style: TextStyle(color: seat["isVip"] ? Colors.amber : Colors.white54, fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openMusicPlayer() async {
    final result = await showModalBottomSheet(context: context, builder: (c) => const MusicPlayerPage());
    if (result != null && result is Map) {
      await _audioPlayer.play(DeviceFileSource(result['path']));
      setState(() => isRoomMusicPlaying = true);
    }
  }

  void _showSettings() {
    RoomSettingsHandler.showSettings(
      context: context,
      isLocked: isRoomLocked,
      onToggleLock: () => setState(() => isRoomLocked = !isRoomLocked),
      onSetWallpaper: (path) => setState(() => roomWallpaperPath = path),
      onMinimize: () => Navigator.pop(context),
      onLeave: () { _audioPlayer.stop(); Navigator.pop(context); Navigator.pop(context); }
    );
  }

  void _showLeaveConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Leave Seat?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(onPressed: () {
            setState(() { seats[index]["isOccupied"] = false; seats[index]["status"] = "empty"; currentSeatIndex = -1; isMicOn = false; });
            Navigator.pop(context);
          }, child: const Text("Yes")),
        ],
      ),
    );
  }

  Widget _buildMessageRow(Map<String, String> msg) {
    return Text("${msg['userName']}: ${msg['text']}", style: const TextStyle(color: Colors.white, fontSize: 12));
  }

  Widget _buildFloatingPlayer({required bool isDragging}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
      child: const Icon(Icons.music_note, color: Colors.greenAccent),
    );
  }
}
