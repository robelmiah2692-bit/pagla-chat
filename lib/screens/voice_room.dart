import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

// ফাইলগুলো widgets ফোল্ডারে থাকায় '../widgets/' ব্যবহার করতে হবে
import '../widgets/chat_input_bar.dart';
import '../widgets/emoji_handler.dart';
import '../widgets/follower_list_handler.dart';
import '../widgets/gift_overlay_handler.dart';
import '../widgets/gift_system.dart';
import '../widgets/music_player_widget.dart';
import '../widgets/room_profile_handler.dart';
import '../widgets/room_settings_handler.dart';


class VoiceRoom extends StatefulWidget {
  final String roomId; // রুম আইডিটি কনস্ট্রাক্টরে থাকা জরুরি
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

  // চ্যাট ও মিউজিক স্টেট
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, String>> chatMessages = []; // নাম ও ছবিসহ মেসেজ রাখার জন্য ম্যাপ লিস্ট
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<String> savedMusicPaths = [];
  Offset playerPosition = const Offset(20, 100);
  bool isRoomMusicPlaying = false;
  String currentSongName = "";

  // গিফট এনিমেশন স্টেট
  bool isGiftAnimating = false;
  String currentGiftImage = "";
  bool isFullScreenBinding = false;

  // ১৫-২০টি সিটের ডাটা
  late List<Map<String, dynamic>> seats;

  @override
  void initState() {
    super.initState();
    checkOwnership();
    loadSavedMusic();
    // সিট ইনিশিয়ালাইজেশন
    seats = List.generate(20, (index) => {
      "isOccupied": false,
      "userName": "",
      "userImage": "",
      "isVip": index < 5, 
      "isMuted": false,
    });
  }

  // --- ২. ফাংশনসমূহ (লজিক) ---

  void checkOwnership() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // ওনার আইডেন্টিফিকেশন কোড (আপনার রিকোয়ারমেন্ট অনুযায়ী)
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          displayUserID = doc['uID'] ?? "";
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
    if (seats[index]["isOccupied"]) return;

    // VIP চেক
    if (seats[index]["isVip"] && !isOwner) { // উদাহরণস্বরূপ ওনার বা ভিআইপি চেক
       _showMessage("এটি VIP সিট!");
       return;
    }

    setState(() {
      // আগের সিট খালি করা
      for (var seat in seats) {
        if (seat["userName"] == displayUserID) {
          seat["isOccupied"] = false;
          seat["userName"] = "";
        }
      }
      seats[index]["userName"] = "Calling..."; 
      seats[index]["isOccupied"] = true; 
    });

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          seats[index]["userName"] = displayUserID.isNotEmpty ? displayUserID : "User ${index + 1}";
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
            diamondBalance -= (gift["price"] as int) * count;
            currentGiftImage = gift["icon"];
            isFullScreenBinding = gift["isVipGift"] ?? false;
            isGiftAnimating = true;
          });
          Timer(const Duration(seconds: 5), () {
            if (mounted) setState(() => isGiftAnimating = false);
          });
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
          // ব্যাকগ্রাউন্ড
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
                _buildHeader(),
                _buildSeatGrid(),
                
                // চ্যাট লিস্ট এরিয়া
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

                // আলাদা করা চ্যাট কন্ট্রোল বার
                ChatInputBar(
                  controller: _messageController,
                  onEmojiTap: () => {}, // ইমোজি পিকার কল
                  onMessageSend: (newMessage) {
                    setState(() {
                      chatMessages.add(newMessage);
                    });
                  },
                ),
              ],
            ),
          ),

          // ভাসমান মিউজিক প্লেয়ার
          if (isRoomMusicPlaying)
            Positioned(
              left: playerPosition.dx,
              top: playerPosition.dy,
              child: Draggable(
                feedback: _buildPlayerUI(true),
                childWhenDragging: Container(),
                onDragEnd: (details) {
                  setState(() {
                    playerPosition = Offset(details.offset.dx, details.offset.dy - 50);
                  });
                },
                child: _buildPlayerUI(false),
              ),
            ),

          // গিফট এনিমেশন লেয়ার
          if (isGiftAnimating) _buildGiftOverlay(),
        ],
      ),
    );
  }

  // সাব-উইজেটসমূহ (সংক্ষিপ্ত)
  Widget _buildHeader() {
    return ListTile(
      leading: CircleAvatar(backgroundImage: roomImageURL.isNotEmpty ? FileImage(File(roomImageURL)) : null),
      title: Text(roomName, style: const TextStyle(color: Colors.white)),
      subtitle: Text("ID: $displayRoomID", style: const TextStyle(color: Colors.white54)),
      trailing: Wrap(
        children: [
          IconButton(onPressed: _showGiftBox, icon: const Icon(Icons.card_giftcard, color: Colors.pinkAccent)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildSeatGrid() {
    return Container(
      height: 250, // গ্রিডের জন্য নির্দিষ্ট উচ্চতা
      padding: const EdgeInsets.all(10),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.8),
        itemCount: seats.length,
        itemBuilder: (context, index) {
          var seat = seats[index];
          return GestureDetector(
            onTap: () => sitOnSeat(index),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: seat["isOccupied"] ? Colors.green : Colors.white10,
                  child: seat["isOccupied"] ? const Icon(Icons.person) : const Icon(Icons.chair),
                ),
                Text(seat["isOccupied"] ? seat["userName"] : "${index + 1}", 
                     style: const TextStyle(color: Colors.white, fontSize: 10)),
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
          CircleAvatar(radius: 12, backgroundImage: NetworkImage(msg['userImage']!)),
          const SizedBox(width: 8),
          Text("${msg['userName']}: ", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          Expanded(child: Text(msg['text']!, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildGiftOverlay() {
    return Center(
      child: Lottie.network(currentGiftImage, width: isFullScreenBinding ? 400 : 200),
    );
  }

  Widget _buildPlayerUI(bool isDragging) {
     return MusicPlayerWidget(
        audioPlayer: _audioPlayer,
        isRoomMusicPlaying: isRoomMusicPlaying,
        isDragging: isDragging,
        onTogglePlay: () => _audioPlayer.state == PlayerState.playing ? _audioPlayer.pause() : _audioPlayer.resume(),
        onClose: () => setState(() => isRoomMusicPlaying = false),
     );
  }
}
