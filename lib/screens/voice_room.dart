import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';

// আপনার সেই ৮টি আলাদা ফাইল
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
  bool isOwner = true; 
  String displayUserID = "Hridoy Owner"; // মালিক শনাক্তকরণ
  String roomName = "পাগলা চ্যাট রুম";
  int followerCount = 0;
  
// মিউজিক ও কন্ট্রোল ভেরিয়েবল
  bool isRoomMusicPlaying = false; // এখানে অলরেডি আপনার কোডে ছিল, তাও চেক করে নিন
  Offset playerPosition = const Offset(20, 100);
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _messageController = TextEditingController();
  
  // সিট ও মাইক কন্ট্রোল (যেগুলো আগের এরর দূর করবে)
  int currentSeatIndex = -1; 
  bool isMicOn = false;
  String currentPlayingMusicName = "No music playing";
  
  List<Map<String, String>> chatMessages = [];
  bool isGiftAnimating = false;
  String currentGiftImage = "";
 
  late List<Map<String, dynamic>> seats;

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
    });
  }

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
              _buildTopNavBar(), // এখানে ফলো বাটন যুক্ত করা হয়েছে
              _buildViewerArea(),
              _buildSeatGridArea(),
              
              // চ্যাট মেসেজ এরিয়া (এখন Expanded যাতে কিবোর্ড আসলে মানিয়ে নেয়)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

              // নিচের কন্ট্রোল বার (মেসেজ বক্স + ৪টি বাটন)
              _buildBottomActionArea(),
            ],
          ),

          if (isRoomMusicPlaying)
            Positioned(
              left: playerPosition.dx,
              top: playerPosition.dy,
              child: Draggable(
                // ১. টানার সময় প্লেয়ারটি যেমন দেখাবে
                feedback: _buildFloatingPlayer(isDragging: true),
                // ২. টানা শেষ হলে নতুন জায়গায় সেট হবে
                onDragEnd: (details) {
                  setState(() {
                    playerPosition = details.offset;
                  });
                },
                // ৩. সাধারণ অবস্থায় প্লেয়ারটি যেমন দেখাবে
                child: _buildFloatingPlayer(isDragging: false),
              ),
            ),

          if (isGiftAnimating)
            Center(child: Lottie.network(currentGiftImage, width: 300)),
        ],
      ),
    );
  }

  // --- নতুন টপ নেভিগেশন বার (ফলো বাটনসহ) ---
  Widget _buildTopNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // ১. প্রোফাইল পিকচার সেকশন (গ্যালারি থেকে ছবি সেভ হবে)
          GestureDetector(
            onTap: () {
              RoomProfileHandler.pickRoomImage(
                onImagePicked: (path) {
                  setState(() {
                    roomProfileImage = path; // গ্যালারির ছবির পাথ এখানে সেভ হচ্ছে
                  });
                },
                showMessage: (msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))),
              );
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.amber,
              // যদি ছবি থাকে তবে সেটা দেখাবে, না থাকলে ক্যামেরা আইকন
              backgroundImage: roomProfileImage.isNotEmpty 
                  ? FileImage(File(roomProfileImage)) 
                  : null,
              child: roomProfileImage.isEmpty 
                  ? const Icon(Icons.camera_alt, size: 18, color: Colors.white) 
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // ২. নাম পরিবর্তন সেকশন (নামের ওপর ক্লিক করলে পপ-আপ আসবে)
                    GestureDetector(
                      onTap: () {
                        RoomProfileHandler.editRoomName(
                          context: context,
                          currentName: roomName,
                          onNameSaved: (newName) {
                            setState(() {
                              roomName = newName; // নতুন নাম সেভ হচ্ছে
                            });
                          },
                        );
                      },
                      child: Text(
                        roomName, 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                      ),
                    ),
                    const SizedBox(width: 5),
                    // ৩. ফলো (+) বাটন (ফলোয়ার কাউন্টিং হবে)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          followerCount++; // ক্লিক করলে ফলোয়ার ১ বাড়বে
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
                // ফলোয়ার সংখ্যা এখানে লাইভ আপডেট হবে
                Text("ID: ${widget.roomId} | $followerCount ফলোয়ার", 
                  style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          // আপনার বাকি বাটনগুলো এখানে থাকবে...
          IconButton(icon: const Icon(Icons.group, color: Colors.blueAccent), onPressed: () => _showFollowers()),
          IconButton(icon: const Icon(Icons.settings, color: Colors.white70), onPressed: () => _showSettings()),
        ],
      ),
    );
  }

  // --- চ্যাট বক্সের নিচের মেইন একশন বার ---
  Widget _buildBottomActionArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: Colors.black26,
      child: Row(
        children: [
          // ১. চ্যাট ইনপুট বক্স ও ইমোজি হ্যান্ডলার
          Expanded(
            child: ChatInputBar(
              controller: _messageController,
              onEmojiTap: () {
                EmojiHandler.showPicker(
                  context: context,
                  seatIndex: -1,
                  onEmojiSelected: (index, url) {
                    setState(() {
                      currentGiftImage = url;
                      isGiftAnimating = true;
                    });
                    Timer(const Duration(seconds: 3),
                        () => setState(() => isGiftAnimating = false));
                  },
                );
              },
              onMessageSend: (newMessage) {
                setState(() => chatMessages.add(newMessage));
              },
            ),
          ),
          const SizedBox(width: 8),

          // ২. মাইক কন্ট্রোল বাটন
          _buildSmallIconButton(
            isMicOn ? Icons.mic : Icons.mic_off,
            isMicOn ? Colors.greenAccent : Colors.white,
            () {
              if (currentSeatIndex == -1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("কথা বলতে আগে সিটে বসুন!")),
                );
                return;
              }
              setState(() {
                isMicOn = !isMicOn;
                seats[currentSeatIndex]['isMicOn'] = isMicOn;
              });
            },
          ),

          // ৩. গেম বাটন
          _buildSmallIconButton(Icons.videogame_asset, Colors.orange, () {
            // গেম লজিক এখানে
          }),

          // ৪. মিউজিক স্টোর বাটন (নতুন যোগ করা মিউজিক লজিক)
          _buildSmallIconButton(Icons.music_note, Colors.cyanAccent, () async {
            final result = await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: const MusicPlayerPage(),
              ),
            );

            if (result != null && result is Map) {
              try {
                await _audioPlayer.stop();
                await _audioPlayer.play(DeviceFileSource(result['path']));
                setState(() {
                  isRoomMusicPlaying = true;
                });
              } catch (e) {
                print("Error playing music: $e");
              }
            }
          }),

          // ৫. গিফট বাটন
          _buildSmallIconButton(Icons.card_giftcard, Colors.pinkAccent, () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => GiftBottomSheet(
                diamondBalance: 500,
                onGiftSend: (gift, count, target) => print("Gift Sent"),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ফ্লোটিং প্লেয়ার ফাংশন (এটি নিচের আলাদা ফাংশন হিসেবে থাকবে)
  Widget _buildFloatingPlayer({required bool isDragging}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: Colors.greenAccent.withOpacity(0.5), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 8, spreadRadius: 1)
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.music_note, color: Colors.greenAccent, size: 22),
            GestureDetector(
              onTap: () async {
                if (_audioPlayer.state == PlayerState.playing) {
                  await _audioPlayer.pause();
                } else {
                  await _audioPlayer.resume();
                }
                setState(() {});
              },
              child: Icon(
                _audioPlayer.state == PlayerState.playing
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: Colors.white,
                size: 32,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  isRoomMusicPlaying = false;
                  _audioPlayer.stop();
                });
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    color: Colors.redAccent, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildViewerArea() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const SizedBox(width: 15),
          const Text("👀 200", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 10),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(radius: 12, backgroundImage: NetworkImage("https://api.dicebear.com/7.x/avataaars/svg?seed=$index")),
              ),
            ),
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
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.7,
        ),
        itemCount: 15,
        itemBuilder: (context, index) {
          var seat = seats[index];
          bool isVip = seat["isVip"];
          return GestureDetector(
            onLongPress: () {
              // সিটে দীর্ঘক্ষণ চেপে ধরলে ইমোজি ওই সিটে যাবে (index পাওয়া যাচ্ছে)
              EmojiHandler.showPicker(
                context: context,
                seatIndex: index,
                onEmojiSelected: (i, url) {
                  setState(() { currentGiftImage = url; isGiftAnimating = true; });
                  Timer(const Duration(seconds: 3), () => setState(() => isGiftAnimating = false));
                },
              );
            },
            onTap: () => sitOnSeat(index),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: seat["isOccupied"] ? Colors.blueAccent : Colors.white10,
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: isVip ? Border.all(color: Colors.amber, width: 2) : null),
                    child: Center(
                      child: seat["status"] == "calling" 
                        ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        : (seat["isOccupied"] ? null : Icon(isVip ? Icons.stars : Icons.chair, color: isVip ? Colors.amber : Colors.white24, size: 20)),
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
          Text("${msg['userName']}: ", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
          Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  void _showSettings() {
    RoomSettingsHandler.showSettings(
      context: context, 
      isLocked: false, 
      onToggleLock: () {}, 
      onSetWallpaper: (p, d) {}, 
      onExit: () {}
    );
  }

  void _showFollowers() {
    FollowerListHandler.show(context, followerCount);
  }

  Widget _buildControlButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white10,
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
