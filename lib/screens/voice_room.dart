import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

// সব হ্যান্ডলার ইম্পোর্ট
import '../widgets/chat_input_bar.dart';
import '../widgets/emoji_handler.dart';
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
  // --- স্টেট ভেরিয়েবল ---
  bool isOwner = false;
  String displayUserID = "";
  String displayRoomID = "";
  bool isMicOn = true; 
  int diamondBalance = 1000; 
  String roomWallpaper = ""; 
  String roomName = "পাগলা রুম";
  String roomImageURL = "";

  final TextEditingController _messageController = TextEditingController();
  List<Map<String, String>> chatMessages = [];
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  Offset playerPosition = const Offset(20, 100);
  bool isRoomMusicPlaying = false;

  bool isGiftAnimating = false;
  String currentGiftImage = "";
  bool isFullScreenBinding = false;

  late List<Map<String, dynamic>> seats;

  @override
  void initState() {
    super.initState();
    // ২০টি সিট এবং কলিং সিস্টেম ফিচার
    seats = List.generate(20, (index) => {
      "isOccupied": false,
      "userName": "",
      "userImage": "",
      "isVip": index < 5, 
      "status": "empty", 
    });
    checkOwnership();
  }

  void checkOwnership() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          displayUserID = doc['uID'] ?? "Hridoy";
          displayRoomID = doc['roomID'] ?? "";
          isOwner = (displayRoomID == widget.roomId); // ওনার আইডেন্টিফিকেশন
        });
      }
    }
  }

  void sitOnSeat(int index) {
    if (seats[index]["isOccupied"] || seats[index]["status"] == "calling") return;
    
    setState(() {
      seats[index]["status"] = "calling";
      seats[index]["userName"] = "Calling...";
      seats[index]["isOccupied"] = true;
    });

    // ৩ সেকেন্ড কলিং এর পর বসা
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          seats[index]["status"] = "occupied";
          seats[index]["userName"] = displayUserID;
          // রিয়েল টাইপ অবতার অবতার লজিক
          seats[index]["userImage"] = "https://api.dicebear.com/7.x/avataaars/svg?seed=$displayUserID"; 
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ব্যাকগ্রাউন্ড ফিচার
          Container(
            color: const Color(0xFF0F0F1E),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // ১. রুম প্রোফাইল ফিচার
                _buildHeaderArea(),

                // ২. সিট গ্রিড ফিচার (Calling & Seats)
                _buildSeatGrid(),

                // ৩. চ্যাট লিস্ট ফিচার
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = chatMessages[chatMessages.length - 1 - index];
                      return _buildMessageRow(msg);
                    },
                  ),
                ),

                // ৪. চ্যাট ইনপুট ও ইমোজি ফিচার
                ChatInputBar(
                  controller: _messageController,
                  onEmojiTap: () {
                    showModalBottomSheet(context: context, builder: (c) => EmojiHandler());
                  },
                  onMessageSend: (newMessage) {
                    setState(() => chatMessages.add(newMessage));
                  },
                ),
              ],
            ),
          ),

          // ৫. মিউজিক প্লেয়ার ফিচার (Floating)
          if (isRoomMusicPlaying)
            Positioned(
              left: playerPosition.dx,
              top: playerPosition.dy,
              child: Draggable(
                feedback: MusicPlayerPage(audioPlayer: _audioPlayer, isDragging: true),
                onDragEnd: (details) => setState(() => playerPosition = details.offset),
                child: MusicPlayerPage(audioPlayer: _audioPlayer, isDragging: false),
              ),
            ),

          // ৬. গিফট এনিমেশন ওভারলে ফিচার
          if (isGiftAnimating) 
            GiftOverlayHandler(isGiftAnimating: isGiftAnimating),
        ],
      ),
    );
  }

  Widget _buildHeaderArea() {
    // এখানে আপনার RoomProfileHandler কল করা হয়েছে
    // যেহেতু আপনার ফাইলে কনস্ট্রাক্টর এরর দিচ্ছে, তাই আমরা এভাবে কল করছি
    try {
      return RoomProfileHandler(); 
    } catch (e) {
      // ব্যাকআপ হেডার যদি উইজেট এরর দেয়
      return ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(roomName, style: const TextStyle(color: Colors.white)),
        trailing: IconButton(onPressed: _showGiftBox, icon: const Icon(Icons.card_giftcard, color: Colors.pink)),
      );
    }
  }

  Widget _buildSeatGrid() {
    return Container(
      height: 280,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
        itemCount: seats.length,
        itemBuilder: (context, index) {
          var seat = seats[index];
          return GestureDetector(
            onTap: () => sitOnSeat(index),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: seat["isOccupied"] ? Colors.blue : Colors.white10,
                  backgroundImage: seat["userImage"].isNotEmpty ? NetworkImage(seat["userImage"]) : null,
                  child: seat["status"] == "calling" ? const CircularProgressIndicator() : (seat["isOccupied"] ? null : const Icon(Icons.chair)),
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
    return ListTile(
      leading: CircleAvatar(radius: 12, backgroundImage: NetworkImage(msg['userImage'] ?? '')),
      title: Text("${msg['userName']}: ${msg['text']}", style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}
