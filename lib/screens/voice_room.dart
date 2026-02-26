import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

// সব হ্যান্ডলার ফাইল ইম্পোর্ট করা হলো
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
  // --- ১. স্টেট ভেরিয়েবলসমূহ ---
  bool isOwner = false;
  String displayUserID = "";
  String displayRoomID = "";
  int activeEmojiSeatIndex = -1; 
  String currentLottieEmojiUrl = "";
  
  bool isLocked = false; 
  bool isMicOn = true; 
  int diamondBalance = 1000; 
  String roomWallpaper = ""; 
  String roomName = "পাগলা রুম";
  int followerCount = 0;
  bool isFollowing = false;
  String roomImageURL = "";

  final TextEditingController _messageController = TextEditingController();
  List<Map<String, String>> chatMessages = []; 
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<String> savedMusicPaths = [];
  Offset playerPosition = const Offset(20, 100);
  bool isRoomMusicPlaying = false;

  bool isGiftAnimating = false;
  String currentGiftImage = "";
  bool isFullScreenBinding = false;

  late List<Map<String, dynamic>> seats;

  @override
  void initState() {
    super.initState();
    // ১৫-২০টি সিটের ডাটা ইনিশিয়ালাইজ
    seats = List.generate(20, (index) => {
      "isOccupied": false,
      "userName": "",
      "userImage": "",
      "isVip": index < 5, 
      "status": "empty", 
    });
    checkOwnership();
    loadSavedMusic();
  }

  // --- ২. ফিচার লজিক ---

  void checkOwnership() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          displayUserID = doc['uID'] ?? "Hridoy";
          displayRoomID = doc['roomID'] ?? "";
          isOwner = (displayRoomID == widget.roomId); 
        });
      }
    }
  }

  Future<void> loadSavedMusic() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedMusicPaths = prefs.getStringList('my_music') ?? [];
    });
  }

  void sitOnSeat(int index) {
    if (seats[index]["isOccupied"] || seats[index]["status"] == "calling") return;
    if (seats[index]["isVip"] && !isOwner) {
       _showMessage("এটি VIP সিট!");
       return;
    }

    setState(() {
      // আগের সিট খালি করা
      for (var seat in seats) {
        if (seat["userName"] == displayUserID) {
          seat["isOccupied"] = false;
          seat["userName"] = "";
          seat["status"] = "empty";
        }
      }
      seats[index]["status"] = "calling";
      seats[index]["userName"] = "Calling...";
      seats[index]["isOccupied"] = true;
    });

    // ৩ সেকেন্ড কলিং লজিক
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          seats[index]["status"] = "occupied";
          seats[index]["userName"] = displayUserID;
          seats[index]["userImage"] = "https://api.dicebear.com/7.x/avataaars/svg?seed=$displayUserID"; // রিয়েল অবতার
        });
      }
    });
  }

  void _showGiftBox() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GiftBottomSheet(
        diamondBalance: diamondBalance,
        onGiftSend: (gift, count, target) {
          setState(() {
            diamondBalance -= ((gift["price"] as num).toInt() * count);
            currentGiftImage = gift["icon"];
            isFullScreenBinding = gift["isVipGift"] ?? false;
            isGiftAnimating = true;
          });
          Timer(const Duration(seconds: 5), () => setState(() => isGiftAnimating = false));
        },
      ),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --- ৩. UI বিল্ড ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ব্যাকগ্রাউন্ড ওয়ালপেপার
          Container(
            decoration: BoxDecoration(
              image: roomWallpaper.isNotEmpty 
                  ? DecorationImage(image: NetworkImage(roomWallpaper), fit: BoxFit.cover)
                  : null,
              color: const Color(0xFF0F0F1E),
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildHeader(), // প্রোফাইল ও সেটিংস সহ হেডার
                _buildSeatGrid(), // কলিং ও ইমোজি সাপোর্ট সহ গ্রিড
                
                // চ্যাট লিস্ট
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    reverse: true,
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = chatMessages[chatMessages.length - 1 - index];
                      return _buildMessageRow(msg);
                    },
                  ),
                ),

                // ইনপুট বার
                ChatInputBar(
                  controller: _messageController,
                  onEmojiTap: () {
                    // EmojiHandler ওপেন হবে
                    showModalBottomSheet(
                      context: context,
                      builder: (c) => EmojiHandler(onEmojiSelected: (url) {
                        setState(() {
                          currentLottieEmojiUrl = url;
                          activeEmojiSeatIndex = 0; // উদাহরন হিসেবে ১ নং সিটে
                        });
                      }),
                    );
                  },
                  onMessageSend: (newMessage) {
                    setState(() => chatMessages.add(newMessage));
                  },
                ),
              ],
            ),
          ),

          // মিউজিক প্লেয়ার
          if (isRoomMusicPlaying)
            Positioned(
              left: playerPosition.dx,
              top: playerPosition.dy,
              child: Draggable(
                feedback: _buildPlayerUI(true),
                childWhenDragging: Container(),
                onDragEnd: (details) {
                  setState(() => playerPosition = Offset(details.offset.dx, details.offset.dy - 50));
                },
                child: _buildPlayerUI(false),
              ),
            ),

          // গিফট এনিমেশন
          if (isGiftAnimating) GiftOverlayHandler(giftUrl: currentGiftImage, isFullScreen: isFullScreenBinding),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return RoomProfileHandler(
      roomName: roomName,
      roomId: widget.roomId,
      roomImage: roomImageURL,
      onSettingsTap: () {
        showModalBottomSheet(context: context, builder: (c) => RoomSettingsHandler(isLocked: isLocked));
      },
      onGiftTap: _showGiftBox,
    );
  }

  Widget _buildSeatGrid() {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(10),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.7),
        itemCount: seats.length,
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
                      radius: 22,
                      backgroundColor: seat["isOccupied"] ? Colors.blue : Colors.white10,
                      backgroundImage: (seat["userImage"] != null && seat["userImage"] != "") 
                          ? NetworkImage(seat["userImage"]) : null,
                      child: !seat["isOccupied"] ? const Icon(Icons.chair, size: 20, color: Colors.white30) : null,
                    ),
                    if (seat["status"] == "calling") const CircularProgressIndicator(strokeWidth: 2),
                    // ইমোজি ডিসপ্লে
                    if (activeEmojiSeatIndex == index) Lottie.network(currentLottieEmojiUrl, width: 40, height: 40),
                  ],
                ),
                Text(seat["userName"].isEmpty ? "${index+1}" : seat["userName"], style: const TextStyle(color: Colors.white, fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageRow(Map<String, String> msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(radius: 12, backgroundImage: NetworkImage(msg['userImage'] ?? 'https://via.placeholder.com/50')),
          const SizedBox(width: 8),
          Text("${msg['userName']}: ", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(child: Text(msg['text']!, style: const TextStyle(color: Colors.white, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildPlayerUI(bool isDragging) {
    return MusicPlayerPage(audioPlayer: _audioPlayer, isDragging: isDragging);
  }
}
