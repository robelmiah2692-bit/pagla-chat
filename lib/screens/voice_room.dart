import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

// হ্যান্ডলার ইম্পোর্ট
import '../widgets/chat_input_bar.dart';
import '../widgets/gift_system.dart';
import '../widgets/music_player_widget.dart';

// যে ফাইলগুলো এরর দিচ্ছে সেগুলো যদি Widget না হয় তবে সরাসরি Widget হিসেবে ব্যবহার করা যাবে না
// তাই আপাতত কোডটি নিরাপদ রাখা হয়েছে

class VoiceRoom extends StatefulWidget {
  final String roomId; 
  const VoiceRoom({super.key, required this.roomId});

  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  // --- ১. স্টেট ভেরিয়েবলসমূহ (ফিচার অক্ষুণ্ণ রাখা হয়েছে) ---
  bool isOwner = false;
  String displayUserID = "";
  String displayRoomID = "";
  bool isMicOn = true; 
  int diamondBalance = 1000; 
  String roomName = "পাগলা রুম";
  String roomImageURL = "";

  final TextEditingController _messageController = TextEditingController();
  List<Map<String, String>> chatMessages = [];
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  Offset playerPosition = const Offset(20, 100);
  bool isRoomMusicPlaying = false;

  bool isGiftAnimating = false;
  String currentGiftImage = ""; // গিফট এনিমেশনের জন্য

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
          isOwner = (displayRoomID == widget.roomId); // মালিক চিনে নেওয়া
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

    // ৩ সেকেন্ড কলিং সিস্টেম (আপনার রিকোয়ারমেন্ট)
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          seats[index]["status"] = "occupied";
          seats[index]["userName"] = displayUserID;
          // রিয়েল টাইপ অবতারের লজিক
          seats[index]["userImage"] = "https://api.dicebear.com/7.x/avataaars/svg?seed=$displayUserID"; 
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 40),
              _buildHeaderArea(), // প্রোফাইল এরিয়া
              _buildSeatGrid(),   // সিট গ্রিড এরিয়া (কলিং ফিচারসহ)
              
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: chatMessages.length,
                  itemBuilder: (context, index) {
                    final msg = chatMessages[chatMessages.length - 1 - index];
                    return ListTile(
                      leading: CircleAvatar(radius: 12, backgroundImage: NetworkImage(msg['userImage'] ?? '')),
                      title: Text("${msg['userName']}: ${msg['text']}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                    );
                  },
                ),
              ),

              ChatInputBar(
                controller: _messageController,
                onEmojiTap: () {
                  // এরর এড়াতে ইমোজি পিকার আপাতত মেসেজ দেয়, আপনি ইমোজি হ্যান্ডলার ঠিক করলে এটি বদলে দেব
                  _showMessage("ইমোজি ফিচার লোড হচ্ছে...");
                },
                onMessageSend: (newMessage) {
                  setState(() => chatMessages.add(newMessage));
                },
              ),
            ],
          ),

          // মিউজিক প্লেয়ার ফিচার
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

          // গিফট এনিমেশন (সরাসরি কোড দিয়ে করা হয়েছে যাতে এরর না আসে)
          if (isGiftAnimating && currentGiftImage.isNotEmpty)
            Center(
              child: Lottie.network(currentGiftImage, width: 300),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderArea() {
    return ListTile(
      leading: CircleAvatar(backgroundColor: isOwner ? Colors.amber : Colors.blue, child: const Icon(Icons.person)),
      title: Text(roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text("ID: ${widget.roomId}", style: const TextStyle(color: Colors.white54)),
      trailing: IconButton(
        icon: const Icon(Icons.card_giftcard, color: Colors.pinkAccent),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => GiftBottomSheet(
              diamondBalance: diamondBalance,
              onGiftSend: (gift, count, target) {
                setState(() {
                  currentGiftImage = gift["icon"];
                  isGiftAnimating = true;
                });
                Timer(const Duration(seconds: 4), () => setState(() => isGiftAnimating = false));
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeatGrid() {
    return Container(
      height: 250,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10),
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
                  child: seat["status"] == "calling" ? const CircularProgressIndicator(strokeWidth: 2) : (seat["isOccupied"] ? null : const Icon(Icons.chair, color: Colors.white24)),
                ),
                Text(seat["userName"].isEmpty ? "${index+1}" : seat["userName"], style: const TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
