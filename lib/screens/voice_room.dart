import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';

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
  // --- স্টেট ভেরিয়েবল ---
  bool isOwner = true; 
  String displayUserID = "Hridoy Owner"; 
  String roomName = "পাগলা চ্যাট রুম";
  int followerCount = 1200;
  
  bool isRoomMusicPlaying = false;
  Offset playerPosition = const Offset(20, 100);
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _messageController = TextEditingController();
  
  List<Map<String, String>> chatMessages = [];
  bool isGiftAnimating = false;
  String currentGiftImage = "";
  
  late List<Map<String, dynamic>> seats;

  @override
  void initState() {
    super.initState();
    // আপনার রিকোয়ারমেন্ট অনুযায়ী ১৫টি সিট (৫টি VIP + ১০টি সাধারণ)
    seats = List.generate(15, (index) => {
      "isOccupied": false,
      "userName": "",
      "userImage": "",
      "isVip": index < 5, 
      "status": "empty", 
    });
  }

  // --- সিটে বসার ৩ সেকেন্ডের কলিং লজিক ---
  void sitOnSeat(int index) {
    if (seats[index]["isOccupied"] || seats[index]["status"] == "calling") return;
    
    setState(() {
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

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          seats[index]["status"] = "occupied";
          seats[index]["userName"] = displayUserID;
          seats[index]["userImage"] = "https://api.dicebear.com/7.x/avataaars/svg?seed=$displayUserID"; 
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      resizeToAvoidBottomInset: true, 
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 40),
              
              // ১. রুম প্রোফাইল ও বাটন এরিয়া (সব বাটন ক্লিয়ার করা হলো)
              _buildTopNavBar(),

              // ৫. ভিউয়ার এরিয়া (সিট না নিয়ে যারা উপরে বসে থাকবে)
              _buildViewerArea(),

              // ৬. ১৫টি বড় সিট (৫টি VIP)
              _buildSeatGridArea(),

              // ৭. চ্যাট স্টোরেজ (সিটের নিচেই থাকবে, উপরে উঠবে না)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(15),
                  ),
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

              // ৮, ৯. নিচের বার (ইমোজি, সেন্ড, মাইক, গেইম, গিফট)
              ChatInputBar(
                controller: _messageController,
                onEmojiTap: () { /* ইমোজি হ্যান্ডলার কল করুন */ },
                onMessageSend: (newMessage) {
                  setState(() => chatMessages.add(newMessage));
                },
                // এখানে আপনার অন্যান্য বাটনগুলো (মাইক, গেইম) যুক্ত আছে
              ),
            ],
          ),

          // মিউজিক প্লেয়ার (ভাসমান)
          if (isRoomMusicPlaying)
            Positioned(
              left: playerPosition.dx, top: playerPosition.dy,
              child: Draggable(
                feedback: MusicPlayerPage(audioPlayer: _audioPlayer, isDragging: true),
                onDragEnd: (details) => setState(() => playerPosition = details.offset),
                child: MusicPlayerPage(audioPlayer: _audioPlayer, isDragging: false),
              ),
            ),

          if (isGiftAnimating)
            Center(child: Lottie.network(currentGiftImage, width: 300)),
        ],
      ),
    );
  }

  // --- উপরের বাটন ও প্রোফাইল সেকশন ---
  Widget _buildTopNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RoomProfileHandler())),
            child: CircleAvatar(radius: 20, backgroundColor: Colors.amber, child: const Icon(Icons.camera_alt, size: 18)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text("ID: ${widget.roomId} | $followerCount ফলোয়ার", style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          // বাটনগুলো
          IconButton(icon: const Icon(Icons.add_circle, color: Colors.greenAccent), onPressed: () => setState(() => followerCount++)),
          IconButton(icon: const Icon(Icons.group, color: Colors.blueAccent), onPressed: () => _showFollowers()),
          IconButton(icon: const Icon(Icons.settings, color: Colors.white70), onPressed: () => _showSettings()),
        ],
      ),
    );
  }

  // --- ভিউয়ার এরিয়া (সিট ছাড়া ইউজার) ---
  Widget _buildViewerArea() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 15),
          const Text("👀 200", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(radius: 15, backgroundImage: NetworkImage("https://api.dicebear.com/7.x/avataaars/svg?seed=$index")),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ১৫টি সিটের গ্রিড ---
  Widget _buildSeatGridArea() {
    return Container(
      height: 280, // ১৫ সিটের জন্য অ্যাডজাস্ট করা হাইট
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 15,
          crossAxisSpacing: 10,
          childAspectRatio: 0.7,
        ),
        itemCount: 15,
        itemBuilder: (context, index) {
          var seat = seats[index];
          bool isVip = seat["isVip"];
          return GestureDetector(
            onTap: () => sitOnSeat(index),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 26, // সিট সাইজ বড় করা হয়েছে
                  backgroundColor: seat["isOccupied"] ? Colors.blueAccent : Colors.white10,
                  backgroundImage: seat["userImage"].isNotEmpty ? NetworkImage(seat["userImage"]) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isVip ? Border.all(color: Colors.amber, width: 2) : null,
                    ),
                    child: Center(
                      child: seat["status"] == "calling" 
                        ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        : (seat["isOccupied"] ? null : Icon(isVip ? Icons.stars : Icons.chair, color: isVip ? Colors.amber : Colors.white24)),
                    ),
                  ),
                ),
                Text("${index + 1}", style: TextStyle(color: isVip ? Colors.amber : Colors.white54, fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageRow(Map<String, String> msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Wrap(
        children: [
          Text("${msg['userName']}: ", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
          Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => const RoomSettingsHandler());
  }

  void _showFollowers() {
    showModalBottomSheet(context: context, builder: (context) => const FollowerListHandler());
  }
}
