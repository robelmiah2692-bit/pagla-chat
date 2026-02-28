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
import 'floating_room_tools.dart'; // আপনার তৈরি করা নতুন ফাইলটি চেনানো
import 'gift_rank_dialog.dart';
import 'top_room_leaderboard.dart';

class VoiceRoom extends StatefulWidget {
  final String roomId; 
  const VoiceRoom({super.key, required this.roomId});

  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  bool isOwner = true; 
  String displayUserID = "Owner"; // মালিক শনাক্তকরণ
  String roomName = "পাগলা চ্যাট রুম";
  int followerCount = 0;
  String roomProfileImage = '';
  bool isFollowed = false; // ফলো বাটন চেক করার জন্য
  List<Map<String, dynamic>> viewersList = []; // ভিউয়ার লিস্টের জন্য
  int activeEmojiSeatIndex = -1; // কোন সিটে ইমোজি উড়বে তা মনে রাখার জন্য
  bool isRoomLocked = false; // রুম কি লক নাকি আনলক তা এখানে সেভ থাকবে
  String roomWallpaperPath = ''; // ওয়ালপেপার ছবির পাথ রাখার জন্য
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

  bool isCountingGifts = false;
  int remainingSeconds = 900; // ১৫ মিনিট = ৯০০ সেকেন্ড
  Timer? giftTimer;

  void _startGiftCounting() {
    if (isCountingGifts) return; // অলরেডি চালু থাকলে আর হবে না

    setState(() {
      isCountingGifts = true;
      remainingSeconds = 900; 
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("💎 ১৫ মিনিটের গিফট কাউন্টডাউন শুরু হয়েছে!"))
    );

    giftTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() => isCountingGifts = false);
        _showWinnerPopup(); // ১৫ মিনিট শেষ হলে উইনার দেখাবে
      }
    });
  }
  void _showWinnerPopup() {
    // এখানে আপনার সেই আলাদা ফাইলের (gift_rank_dialog.dart) কোড কল হবে
    print("Time Up! Show Top Winners");
  }

  void _showWinnerPopup() {
    // ১. সিট থেকে সব ইউজারদের গিফট অনুযায়ী সাজানো (Sorting)
    List<Map<String, dynamic>> seatData = List.from(seats);
    seatData.sort((a, b) => b['giftCount'].compareTo(a['giftCount']));

    // ২. শুধুমাত্র যারা গিফট পেয়েছে এবং সিটে আছে তাদের ফিল্টার করা
    List<Map<String, dynamic>> topWinners = [];
    for (var s in seatData) {
      if (s['giftCount'] > 0 && s['isOccupied']) {
        topWinners.add({
          "name": s['userName'],
          "avatar": s['userImage'],
          "gifts": s['giftCount']
        });
      }
      if (topWinners.length == 2) break; // শুধু টপ ২ জনকে নিবে
    }

    // ৩. পপ-আপ দেখানো
    if (topWinners.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => GiftRankDialog(winners: topWinners),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("কেউ গিফট পায়নি, তাই উইনার নেই!"))
      );
    }
  }
  
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
    // ১. নিজের সিটে ক্লিক করলে লিভ (Leave) নেওয়ার অপশন আসবে
    if (currentSeatIndex == index) {
      _showLeaveConfirmation(index);
      return;
    }

    // ২. রুম লক থাকলে বা সিট খালি না থাকলে বসতে পারবে না
    if (isRoomLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("রুম এখন লক আছে!"))
      );
      return;
    }

    if (seats[index]["isOccupied"] || seats[index]["status"] == "calling") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("এই সিটটি খালি নেই!"))
      );
      return;
    }

    // ৩. সিটে বসার প্রক্রিয়া শুরু (Calling phase)
    setState(() {
      // আগের কোনো সিটে বসে থাকলে সেটি আগে খালি করে দেওয়া
      for (var seat in seats) {
        if (seat["userName"] == displayUserID) {
          seat["isOccupied"] = false;
          seat["userName"] = "";
          seat["status"] = "empty";
          seat["isMicOn"] = false;
        }
      }
      
      // নতুন সিটে কলিং স্টেট সেট করা
      seats[index]["status"] = "calling";
      seats[index]["userName"] = "Calling...";
      seats[index]["isOccupied"] = true;
    });

    // ৪. ৩ সেকেন্ড পর সিটে কনফার্ম হওয়া (Final Step)
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          seats[index]["status"] = "occupied";
          seats[index]["userName"] = displayUserID;
          // আপনার রিয়েল অবতারের ইমেজ বসানো
          seats[index]["userImage"] = "https://api.dicebear.com/7.x/avataaars/svg?seed=$displayUserID";
          
          // --- আগের মেইন ফিচারগুলো সচল রাখা ---
          seats[index]["isMicOn"] = true; // সিটের ওপর মাইক সবুজ দেখাবে
          isMicOn = true;               // নিচের মেইন বাটন সবুজ হবে
          currentSeatIndex = index;     // অ্যাপ এখন জানবে আপনি এই সিটে আছেন
        });
      }
    });
  }

  void _showLeaveConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("সিট ছেড়ে দিন", style: TextStyle(color: Colors.white)),
        content: const Text("আপনি কি সিট থেকে নামতে চান?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("না")),
          TextButton(
            onPressed: () {
              setState(() {
                // সিট খালি করা কিন্তু ইউজার রুমেই থাকবে (ভিউয়ার লিস্টে)
                seats[index]["isOccupied"] = false;
                seats[index]["userName"] = "";
                seats[index]["status"] = "empty";
                seats[index]["isMicOn"] = false;
                
                currentSeatIndex = -1; // এখন আপনি ভিউয়ার
                isMicOn = false;      // মাইক অফ
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

          // ২. এইখানে ভাসমান বাটনগুলো যোগ করুন (Column-এর নিচে থাকায় এটি সবার ওপরে ভাসবে)
          FloatingRoomTools(
            onGiftCountStart: () {
              // এখানে ১৫ মিনিটের টাইমার শুরু করার ফাংশনটি কল হবে
              _startGiftCounting(); 
            },
          ),
        ],
      ),
    );
  } 
         
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
               // ৩. ফলো (+) বাটন - টিক মার্ক এবং কালার চেঞ্জ হবে
                GestureDetector(
                  onTap: () {
                    if (!isFollowed) {
                      setState(() {
                        followerCount++;
                        isFollowed = true;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isFollowed ? Colors.green : Colors.blueAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(
                      isFollowed ? Icons.check : Icons.add,
                      color: Colors.white,
                      size: 14,
                    ),
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
          IconButton(
            padding: EdgeInsets.zero,
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 300), // কালার চেঞ্জ হবে স্মুথলি
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                // সিটে না থাকলে কালো, অন থাকলে উজ্জ্বল সবুজ, অফ থাকলে হালকা লাল
                color: currentSeatIndex == -1 
                    ? Colors.black54 
                    : (isMicOn ? Colors.greenAccent.withOpacity(0.25) : Colors.redAccent.withOpacity(0.15)),
                shape: BoxShape.circle,
                boxShadow: [
                  if (currentSeatIndex != -1 && isMicOn)
                    BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)
                ],
                border: Border.all(
                  color: currentSeatIndex == -1 
                      ? Colors.grey.withOpacity(0.5) 
                      : (isMicOn ? Colors.greenAccent : Colors.redAccent),
                  width: 2,
                ),
              ),
              child: Icon(
                currentSeatIndex == -1 
                    ? Icons.mic_off_rounded 
                    : (isMicOn ? Icons.mic : Icons.mic_off),
                color: currentSeatIndex == -1 
                    ? Colors.grey 
                    : (isMicOn ? Colors.greenAccent : Colors.redAccent),
                size: 24,
              ),
            ),
            onPressed: () {
              if (currentSeatIndex == -1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("আগে সিটে বসুন, তারপর মাইক খুলুন!"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                setState(() {
                  // ১. মেইন মাইক স্টেট পরিবর্তন
                  isMicOn = !isMicOn; 
                  
                  // ২. আপনার বসা সিটের ভেতরের ডাটা আপডেট (যাতে সিটের কোণার আইকন বদলায়)
                  seats[currentSeatIndex]["isMicOn"] = isMicOn; 
                });
              }
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
        // ১. লাইভ ভিউয়ার কাউন্টার (viewersList এর সাইজ অনুযায়ী)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "👀 ${viewersList.length}", 
            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        
        // ২. ভিউয়ার অবতার লিস্ট
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: viewersList.length,
            itemBuilder: (context, index) {
              // ভিউয়ারের ডাটা থেকে ছবি নেওয়া
              String avatarUrl = viewersList[index]['avatar'] ?? "https://api.dicebear.com/7.x/avataaars/svg?seed=$index";
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white10,
                  // রিয়েল টাইপ অবতার লোড হবে
                  backgroundImage: NetworkImage(avatarUrl),
                ),
              );
            },
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
              // সিটে দীর্ঘক্ষণ চেপে ধরলে ইমোজি সিলেক্ট করার অপশন
              EmojiHandler.showPicker(
                context: context,
                seatIndex: index,
                onEmojiSelected: (i, url) {
                  setState(() { 
                    currentGiftImage = url; 
                    isGiftAnimating = true; 
                    // ইমোজিটা আপনার (ইউজারের) নিজের সিটে দেখানোর জন্য
                    activeEmojiSeatIndex = currentSeatIndex; 
                  });
                  Timer(const Duration(seconds: 3), () => setState(() => isGiftAnimating = false));
                },
              );
            },
            onTap: () {
              sitOnSeat(index);
              // আপনি যখন সিটে বসবেন, তখন আপনার ইনডেক্স সেভ হবে
              setState(() {
                currentSeatIndex = index;
              });
            },
            child: Column(
              children: [
                // স্ট্যাক ব্যবহার করা হয়েছে যাতে ইমোজি সিটের ওপর ভাসে
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: seat["isOccupied"] ? Colors.blueAccent : Colors.white10,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          border: isVip ? Border.all(color: Colors.amber, width: 2) : null
                        ),
                        child: Center(
                          child: seat["status"] == "calling" 
                            ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                            : (seat["isOccupied"] ? null : Icon(isVip ? Icons.stars : Icons.chair, color: isVip ? Colors.amber : Colors.white24, size: 20)),
                        ),
                      ),
                    ),

                    // --- এই অংশটি ইমোজিকে আপনার সিটের ওপরে চালাবে ---
                    if (isGiftAnimating && currentSeatIndex == index)
                      Positioned(
                        top: -40, // সিটের ঠিক ওপরে
                        child: Lottie.network(
                          currentGiftImage,
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                        ),
                      ),
                  ],
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
      isLocked: isRoomLocked, 
      
      // ১. লক-আনলক লজিক
      onToggleLock: () {
        setState(() {
          isRoomLocked = !isRoomLocked;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isRoomLocked ? "রুম লক করা হয়েছে 🔒" : "রুম আনলক করা হয়েছে 🔓"))
        );
      }, 
      
      // ২. ওয়ালপেপার সেট লজিক
      onSetWallpaper: (path, display) {
        setState(() {
          roomWallpaperPath = path; // গ্যালারির ছবির পাথ সেভ হবে
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ওয়ালপেপার পরিবর্তন সফল! ✨"))
        );
      }, 
      
      // ৩. মিনিমাইজ লজিক (লাইভ সার্ভিসসহ)
      onMinimize: () async {
        Navigator.pop(context); // সেটিংস প্যানেল বন্ধ হবে
        
        final service = FlutterBackgroundService();
        bool isRunning = await service.isRunning();
        if (!isRunning) {
          await service.startService(); // সার্ভিস চালু হবে
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("রুম মিনিমাইজ করা হয়েছে। নোটিফিকেশন চেক করুন। 📥"))
        );
      },

      // ৪. এক্সিট লজিক (পুরো রুম বন্ধ করবে)
      onExit: () {
        // লাইভ সার্ভিস বন্ধ করা
        FlutterBackgroundService().invoke("stopService"); 
        _audioPlayer.stop(); // মিউজিক বন্ধ

        Navigator.pop(context); // ১. সেটিংস প্যানেল বন্ধ করবে
        Navigator.pop(context); // ২. ভয়েস রুম থেকে বের হয়ে হোমে যাবে
        
        print("Room Exited Successfully");
      }
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
