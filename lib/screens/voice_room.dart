import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

// হ্যান্ডলার ইম্পোর্ট (আপনার উইজেট ফোল্ডার থেকে)
import '../widgets/chat_input_bar.dart';
import '../widgets/gift_system.dart';
import '../widgets/music_player_widget.dart';

class VoiceRoom extends StatefulWidget {
  final String roomId; 
  const VoiceRoom({super.key, required this.roomId});

  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  // --- ১. স্টেট ভেরিয়েবলসমূহ (লোকাল ডাটা) ---
  bool isOwner = true; // এখন আপাতত আপনাকে ওনার হিসেবেই রাখা হয়েছে
  String displayUserID = "Hridoy"; // ওস্তাদ আপনার নাম
  String roomName = "পাগলা আড্ডা";
  
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
    // ২০টি সিট এবং কলিং ফিচার সেট করা হলো
    seats = List.generate(20, (index) => {
      "isOccupied": false,
      "userName": "",
      "userImage": "",
      "isVip": index < 5, 
      "status": "empty", 
    });
    
    // লোকাল ইউজার ডাটা লোড করার ফাংশন (ফায়ারবেস ছাড়া)
    _loadLocalUserData();
  }

  void _loadLocalUserData() async {
    // এখানে ভবিষ্যতে আপনি SharedPreferences থেকে নাম বা ছবি নিতে পারবেন
    setState(() {
      displayUserID = "Hridoy Owner"; 
      roomName = "পাগলা চ্যাট রুম";
    });
  }

  void sitOnSeat(int index) {
    if (seats[index]["isOccupied"] || seats[index]["status"] == "calling") return;
    
    setState(() {
      // আগের কোনো সিটে থাকলে তা খালি করা (ফিচার বজায় রাখা হয়েছে)
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

    // আপনার রিকোয়ারমেন্ট অনুযায়ী ৩ সেকেন্ড পর বসা (Calling Feature)
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          seats[index]["status"] = "occupied";
          seats[index]["userName"] = displayUserID;
          // রিয়েল টাইপ অবতারের লজিক (র‍্যান্ডম অবতার)
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
    const SizedBox(height: 45),
    
    // --- ১. রুম হেডার ও ইউজার কাউন্ট ---
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHeaderArea(), // আপনার আগের হেডার ফাংশন
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.greenAccent),
                const SizedBox(width: 4),
                Text("200", style: const TextStyle(color: Colors.white, fontSize: 12)), // ইউজার কাউন্ট
              ],
            ),
          ),
        ],
      ),
    ),

    // --- ২. প্রথম সারির উপরে অতিরিক্ত জায়গা (Empty Space for Viewers) ---
    const SizedBox(height: 30), // এখানে ইউজাররা সিট ছাড়াও থাকতে পারবে

    // --- ৩. সিট গ্রিড (VIP এবং জেনারেল সিট) ---
    Container(
      height: 360, // সিটগুলো বড় রাখার জন্য পর্যাপ্ত হাইট
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 10,
          childAspectRatio: 0.75,
        ),
        itemCount: seats.length, // ২০টি সিট
        itemBuilder: (context, index) {
          var seat = seats[index];
          bool isVip = index < 5; // প্রথম ৫টি VIP সিট
          bool isCalling = seat["status"] == "calling";

          return GestureDetector(
            onTap: () => sitOnSeat(index),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // VIP সিটের জন্য গোল্ডেন বর্ডার বা স্পেশাল কালার
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isVip 
                          ? Border.all(color: Colors.amber, width: 2) // VIP সিট বর্ডার
                          : null,
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: seat["isOccupied"] 
                          ? (isVip ? Colors.amber.shade700 : Colors.blueAccent) 
                          : Colors.white10,
                        backgroundImage: (seat["userImage"].toString().isNotEmpty) 
                          ? NetworkImage(seat["userImage"]) : null,
                        child: isCalling 
                          ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : (seat["isOccupied"] ? null : Icon(isVip ? Icons.stars : Icons.chair, size: 20, color: isVip ? Colors.amber : Colors.white24)),
                      ),
                    ),
                    // VIP ব্যাজ
                    if (isVip)
                      Positioned(
                        top: 0, right: 0,
                        child: Icon(Icons.workspace_premium, size: 14, color: Colors.amber),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  seat["userName"].isEmpty ? "${index + 1}" : seat["userName"],
                  style: TextStyle(
                    color: isVip ? Colors.amber : Colors.white, 
                    fontSize: 10,
                    fontWeight: isVip ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    ),

    // --- ৪. চ্যাট বক্স (অ্যাডজাস্টেড) ---
    Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: ListView.builder(
          reverse: true,
          itemCount: chatMessages.length,
          itemBuilder: (context, index) {
            final msg = chatMessages[chatMessages.length - 1 - index];
            return _buildMessageRow(msg);
          },
        ),
      ),
    ),

              // ইনপুট বার ও ইমোজি ফিচার
              ChatInputBar(
                controller: _messageController,
                onEmojiTap: () => _showMessage("ইমোজি পিকার আসছে..."),
                onMessageSend: (newMessage) {
                  setState(() => chatMessages.add(newMessage));
                },
              ),
            ],
          ),

          // মিউজিক প্লেয়ার ফিচার (Floating)
          if (isRoomMusicPlaying)
            Positioned(
              left: playerPosition.dx, top: playerPosition.dy,
              child: Draggable(
                feedback: MusicPlayerPage(audioPlayer: _audioPlayer, isDragging: true),
                onDragEnd: (details) => setState(() => playerPosition = details.offset),
                child: MusicPlayerPage(audioPlayer: _audioPlayer, isDragging: false),
              ),
            ),

          // গিফট এনিমেশন (Lottie)
          if (isGiftAnimating && currentGiftImage.isNotEmpty)
            Center(child: Lottie.network(currentGiftImage, width: 300)),
        ],
      ),
    );
  }

  Widget _buildHeaderArea() {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.amber,
        child: const Icon(Icons.person, color: Colors.white),
      ),
      title: Text(roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text("Room ID: ${widget.roomId}", style: const TextStyle(color: Colors.white54)),
      trailing: IconButton(
        icon: const Icon(Icons.card_giftcard, color: Colors.pinkAccent),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => GiftBottomSheet(
              diamondBalance: 5000,
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
      height: 260,
      child: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, 
          mainAxisSpacing: 10, 
          crossAxisSpacing: 10
        ),
        itemCount: seats.length,
        itemBuilder: (context, index) {
          var seat = seats[index];
          bool isCalling = seat["status"] == "calling";
          
          return GestureDetector(
            onTap: () => sitOnSeat(index),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: seat["isOccupied"] ? Colors.blueAccent : Colors.white10,
                  backgroundImage: (seat["userImage"].toString().isNotEmpty) 
                      ? NetworkImage(seat["userImage"]) : null,
                  child: isCalling 
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                      : (seat["isOccupied"] ? null : const Icon(Icons.chair, size: 18, color: Colors.white30)),
                ),
                const SizedBox(height: 4),
                Text(
                  seat["userName"].isEmpty ? "${index + 1}" : seat["userName"],
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                  overflow: TextOverflow.ellipsis,
                ),
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
          CircleAvatar(radius: 10, backgroundImage: NetworkImage(msg['userImage'] ?? 'https://via.placeholder.com/50')),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: "${msg['userName']}: ", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                  TextSpan(text: msg['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
