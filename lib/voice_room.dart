import 'music_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io'; // এটি আপনার প্রোফাইল পিকের জন্য দরকার
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';      // গান বাজানোর জন্য
import 'package:shared_preferences/shared_preferences.dart'; // গান সেভ রাখার জন্য
import 'package:path_provider/path_provider.dart';   // ফোনের স্টোরেজ লোকেশন পাওয়ার জন্য
import 'gift_system.dart';
import 'package:lottie/lottie.dart';

class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});

  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
 bool isOwner = false;
String displayUserID = "";
String displayRoomID = "";
int activeEmojiSeatIndex = -1; 
String currentLottieEmojiUrl = "";
  
void checkOwnership() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      setState(() {
        displayUserID = doc['uID'] ?? "";
        displayRoomID = doc['roomID'] ?? "";
        
        // এখানে widget.roomId এর বদলে নিচের মতো চেক করুন
        // আপনার widget এ আইডি যে নামে আছে সেটা দিন (সাধারণত roomId বা roomID)
        isOwner = (displayRoomID == (widget as dynamic).roomId); 
      });
    }
  }
}
  // ১. মেসেজ ইনপুট করার জন্য কন্ট্রোলার
final TextEditingController _messageController = TextEditingController();

// ২. চ্যাট মেসেজগুলো জমা রাখার জন্য লিস্ট
List<String> chatMessages = [];
  // --- গিফট বক্সের জন্য প্রয়োজনীয় ডাটা ও লজিক ---

  // ১. গিফট এনিমেশন কন্ট্রোল করার ভেরিয়েবল
  bool isGiftAnimating = false;
  String currentGiftImage = "";
  bool isFullScreenBinding = false; // দামি গিফটের জন্য

  // ২. গিফট লিস্ট (৩০টি আইটেম - আপনি পরে ছবি পাল্টাতে পারবেন)
  final List<Map<String, dynamic>> gifts = List.generate(30, (index) => {
    "id": index + 1,
    "name": "Gift ${index + 1}",
    "price": (index + 1) * 50, // বিভিন্ন দাম (৫০, ১০০, ১৫০...)
    "icon": "https://cdn-icons-png.flaticon.com/512/3135/3135715.png", // বক্সের ছোট ছবি
    "isVipGift": (index + 1) * 50 >= 500 ? true : false, // ৫০০ ডাইমন্ডের বেশি হলে ফুল স্ক্রিন
  });

  // ৩. গিফট সেন্ড করার মেইন ফাংশন
  void _sendGift(Map<String, dynamic> gift) {
    if (diamondBalance < gift["price"]) {
      Navigator.pop(context);
      _showMessage("পর্যাপ্ত ডাইমন্ড নেই! 💎");
      return;
    }

    Navigator.pop(context); // গিফট বক্স বন্ধ হবে
    setState(() {
      final TextEditingController _messageController = TextEditingController(); 
      List<String> chatMessages = []; // মেসেজ জমা রাখার জন্য
      diamondBalance -= gift["price"] as int; // ডাইমন্ড কেটে নেওয়া হলো
      currentGiftImage = gift["icon"]; // এখানে আপনার বড় এনিমেশন ছবির লিঙ্ক হবে
      isFullScreenBinding = gift["isVipGift"]; // বড় না ছোট গিফট তা চেক
      isGiftAnimating = true;
    });

    // ৫ সেকেন্ড পর স্ক্রিন থেকে গিফট চলে যাবে
    Timer(const Duration(seconds: 5), () {
      setState(() {
        isGiftAnimating = false;
      });
    });
  }

// ৪. নতুন ক্যাটাগরিযুক্ত গিফট বক্স কল
  void _showGiftBox() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => GiftBottomSheet(
      diamondBalance: diamondBalance,
      // এখানে gift, count এবং target—এই ৩টি জিনিসই পাঠাতে হবে
      onGiftSend: (gift, count, target) {
        _sendGift(gift); // এখানে আপনার গিফট পাঠানোর মেইন লজিক
      },
    ),
  );
}

  // --- ১. ভেরিয়েবলসমূহ ---
  bool isLocked = false; 
  bool isMicOn = true; 
  int diamondBalance = 1000; 
  String roomWallpaper = ""; 
  String roomName = "পাগলা রুম";
  int followerCount = 0;
  bool isFollowing = false;
  String roomImageURL = ""; // গ্যালারি থেকে নেওয়া রুমের ছবির জন্য
  // মেইন রুম স্ক্রিনের ভেতরে এই ভেরিয়েবলগুলো নিন
List<String> savedMusicPaths = [];
// এই ৩টি লাইন নতুন যোগ করুন
Offset playerPosition = Offset(20, 100); // প্লেয়ারের পজিশন সেভ রাখার জন্য
bool isRoomMusicPlaying = false;         // রুমে গান বাজছে কি না বোঝার জন্য
String currentSongName = "";             // বর্তমানে যে গানটি বাজছে তার নাম
  int currentPlayingIndex = -1;
final AudioPlayer _audioPlayer = AudioPlayer();

// গান সেভ করার ফাংশন
Future<void> saveMusicToStorage(List<String> paths) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('my_music', paths);
}

// অ্যাপ খোলার সময় গান লোড করার ফাংশন
Future<void> loadSavedMusic() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    savedMusicPaths = prefs.getStringList('my_music') ?? [];
  });
}
  
  // ১৫টি সিটের ডাটা
  List<Map<String, dynamic>> seats = List.generate(20, (index) => {
    "isOccupied": false,
    "userName": "",
    "userImage": "",
    "isVip": index < 5 ? true : false, 
    "isMuted": false,
    "emoji": "",
  });

  // --- ২. ফাংশনসমূহ (অ্যাকশন রেডি) ---

  // রুম লক সিস্টেম (৩০০ ডাইমন্ড চেক সহ)
  void toggleLock() {
    if (!isLocked) {
      if (diamondBalance >= 300) {
        setState(() {
          isLocked = true;
          diamondBalance -= 300;
        });
        _showMessage("রুম ২৪ ঘন্টার জন্য লক করা হলো! (-৩০০💎)");
      } else {
        _showMessage("লক করতে ৩০০ ডাইমন্ড লাগবে!");
      }
    } else {
      setState(() => isLocked = false);
    }
  }

  // ওয়ালপেপার সেট করা (ডাইমন্ড লজিক সহ)
  void setWallpaper(int price, String duration) {
    if (diamondBalance >= price) {
      setState(() {
        diamondBalance -= price;
        // এখানে গ্যালারি ওপেন করার কোড আসবে
        roomWallpaper = "https://images.unsplash.com/photo-1519681393784-d120267933ba"; 
      });
      _showMessage("$duration ওয়ালপেপার সেট হয়েছে!");
    } else {
      _showMessage("পর্যাপ্ত ডাইমন্ড নেই!");
    }
  }

  // সিটে বসার লজিক (VIP চেক)
  void sitOnSeat(int index) {
  // ১. চেক: সিট যদি আগে থেকে বুক থাকে তবে কিছু হবে না
  if (seats[index]["isOccupied"]) return;

  // ২. চেক: ভিআইপি সিট হলে ভিআইপি ব্যাজ আছে কি না দেখবে (আপনার অরিজিনাল কোড)
  if (seats[index]["isVip"]) {
    bool userHasVipBadge = true; // VIP লেভেল ১ এর জন্য এটি true
    if (!userHasVipBadge) {
      _showMessage("এটি VIP সিট! আপনি বসতে পারবেন না।");
      return;
    }
  }

  setState(() {
    // ৩. নতুন ফিক্স: ইউজার আগে অন্য কোনো সিটে থাকলে তাকে সেখান থেকে নামিয়ে দাও
    for (int i = 0; i < seats.length; i++) {
      if (seats[i]["userName"] == (displayUserID.isNotEmpty ? displayUserID : "ইউজার ${i + 1}")) {
        seats[i]["isOccupied"] = false;
        seats[i]["userName"] = "";
        seats[i]["userImage"] = "";
      }
    }

    // ৪. অ্যাকশন: ক্লিক করার সাথে সাথে বর্তমান সিটে কলিং শুরু হবে
    seats[index]["userName"] = "Calling..."; 
    seats[index]["isOccupied"] = true; 
  });

  // ৫. রেজাল্ট: ৩ সেকেন্ড পর প্রোফাইল ডাটা বসবে
  Timer(const Duration(seconds: 3), () {
    if (mounted) {
      setState(() {
        seats[index]["userName"] = displayUserID.isNotEmpty ? displayUserID : "ইউজার ${index + 1}";
        seats[index]["userImage"] = ""; // প্রোফাইল পিকের জন্য খালি রাখলাম
      });
    }
  });
}

void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ১. ব্যাকগ্রাউন্ড ওয়ালপেপার এবং মেইন লেআউট
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
                _buildHeader(), // রুম হেডার (এখানেই সেটিংস থাকবে)
                
                // ২. সিট গ্রিড (এটি উপরে ফিক্সড থাকবে)
                _buildSeatGrid(), 
                
                const SizedBox(height: 10),

                // ৩. চ্যাট এরিয়া: মেসেজ সিটের নিচ দিয়ে স্ক্রল হবে
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    reverse: true, // নতুন মেসেজ নিচে দেখাবে
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      // চ্যাট লিস্ট থেকে ডাটা নিয়ে ছবি ও নামসহ দেখানো
                      final msgData = chatMessages[chatMessages.length - 1 - index];
                      return _buildMessageRow(msgData); 
                    },
                  ),
                ),
                
                // ৪. কন্ট্রোল এরিয়া (ইনপুট বক্স ও মাইক বাটন)
                _buildChatAndControls(), 
              ],
            ), // Column শেষ
          ), // Container শেষ
        ],
      ), // Stack শেষ
    );
  }

    // --- আপনার ভাসমান মিউজিক প্লেয়ার (Stack এর ভেতরে) ---
    if (isRoomMusicPlaying)
      Positioned(
        left: playerPosition.dx,
        top: playerPosition.dy,
        child: Draggable(
          feedback: _buildPlayerUI(true), 
          childWhenDragging: Container(), 
          onDragEnd: (details) {
            setState(() {
              // স্ট্যাটাস বার আর অ্যাপ বারের জন্য ৫০ পিক্সেল মাইনাস করা হয়েছে
              playerPosition = Offset(details.offset.dx, details.offset.dy - 50); 
            });
          },
          child: _buildPlayerUI(false),
        ),
      ),
    // গিফট এনিমেশন লেয়ার (সবার উপরে)
    _buildGiftOverlay(),

    ], // Stack children শেষ
   ), // Stack শেষ
  ); // Scaffold শেষ
} // build ফাংশন শেষ  
  // --- ৩. উইজেটসমূহ (ডিজাইন) ---
  Widget _buildHeader() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Row(
      children: [
        // ১. রুম প্রোফাইল ছবি (আপনার গ্যালারি ফিচারের সাথে)
        GestureDetector(
          onTap: _pickRoomImage, 
          child: CircleAvatar(
            radius: 25, 
            backgroundColor: Colors.white10, 
            backgroundImage: roomImageURL.isNotEmpty ? FileImage(File(roomImageURL)) : null,
            child: roomImageURL.isEmpty ? const Icon(Icons.person, color: Colors.pinkAccent) : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ২. রুমের নাম (ক্লিক করলে এডিট হবে)
              GestureDetector(
                onTap: _editRoomName,
                child: Text(roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              // ৫. রুম আইডি এবং ফলোয়ার কাউন্ট
              Text("ID: $displayRoomID | Follower: $followerCount", style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
        
        // ৩. ফলো বাটন (সংখ্যা বাড়ানো/কমানো সহ)
        IconButton(
          onPressed: () {
            setState(() {
              isFollowing = !isFollowing;
              isFollowing ? followerCount++ : followerCount--;
            });
          },
          icon: Icon(isFollowing ? Icons.check_circle : Icons.add_circle, color: Colors.pinkAccent)
        ),

        // ৪. ফলোয়ার লিস্ট বাটন (নতুন যোগ করা)
        IconButton(
          onPressed: _showFollowerList, 
          icon: const Icon(Icons.people, color: Colors.white70)
        ),
       
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => _showRoomSettings(context),
        ), 

      ], // <--- এই ব্র্যাকেটটা মিসিং ছিল (Row শেষ)
    ), // <--- এইটা মিসিং ছিল (Padding শেষ)
  ); // <--- এইটা মিসিং ছিল (return শেষ)
} // <--- এইটা সবচাইতে জরুরি ছিল (_buildHeader ফাংশন শেষ)

  // ৩. ১৫টি সিটের গ্রিড (পুরাতন লজিক + নতুন ডিজাইন)
  Widget _buildSeatGrid() {
    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, 
          mainAxisSpacing: 22, // নামের জন্য গ্যাপ বাড়ানো হয়েছে
          crossAxisSpacing: 10,
          childAspectRatio: 0.7, // ইউজার নেম ও ছবি সুন্দর দেখানোর জন্য
        ),
        itemCount: 20,
        itemBuilder: (context, index) {
          var seat = seats[index];
          return GestureDetector(
            onTap: () => sitOnSeat(index),
            onLongPress: () {
              // পুরাতন ফিচারের লজিক ঠিক রাখা হয়েছে: রুম ওনার বা এডমিন অপশন
              if (seat["isOccupied"]) {
                _showAdminMenu(index);
              }
            },
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // গোল ফ্রেম ও প্রোফাইল ছবি
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: seat["isVip"] ? Colors.amber : Colors.white12,
                          width: 2,
                        ),
                        image: seat["isOccupied"] && seat["userImage"] != ""
                            ? DecorationImage(
                                image: NetworkImage(seat["userImage"]),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: seat["isVip"] 
                            ? Colors.amber.withOpacity(0.1) 
                            : Colors.white10,
                      ),
                      child: !seat["isOccupied"]
                          ? Icon(
                              Icons.chair_rounded, 
                              color: seat["isVip"] ? Colors.amber : Colors.white24, 
                              size: 24,
                            )
                          : null,
                    ),
                    
                    // ভিআইপি স্টার
                    if (seat["isVip"])
                     const Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(Icons.stars, size: 14, color: Colors.amber),
                      ),

                    // মাইক স্ট্যাটাস ইন্ডিকেটর
                  if (seat["isOccupied"])
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black54, // আইকনটি যাতে স্পষ্ট দেখা যায়
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          seat["isMuted"] ? Icons.mic_off : Icons.mic_rounded,
                          size: 12,
                          color: seat["isMuted"] ? Colors.redAccent : Colors.greenAccent,
                        ),
                      ),
                    ),
                    
                // ইমোজি পপ-আপ (নিজের সিটে দেখানোর জন্য Positioned.fill যুক্ত)
                    if (activeEmojiSeatIndex == index && currentLottieEmojiUrl.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Lottie.network(
                            currentLottieEmojiUrl,
                            width: 80,
                            height: 80,
                            repeat: false,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(),
                          ),
                        ),
                      ),
                ], // এইটা Stack এর children শেষ
              ),
              // নামের জায়গা: খালি থাকলে সংখ্যা/VIP, কেউ বসলে তার নাম
                Text(
                  seat["isOccupied"] ? seat["userName"] : (seat["isVip"] ? "VIP" : "${index + 1}"),
                  style: TextStyle(
                    color: seat["isOccupied"] ? Colors.white : Colors.white38,
                    fontSize: 10,
                    fontWeight: seat["isOccupied"] ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAdminMenu(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(leading: const Icon(Icons.mic_off), title: const Text("মিউট করুন"), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.exit_to_app, color: Colors.red), title: const Text("কিক দিন"), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.verified_user), title: const Text("এডমিন দিন"), onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildChatAndControls() {
  return Container(
    padding: const EdgeInsets.all(10),
    color: Colors.black45,
    child: Row(
      children: [
        IconButton(onPressed: () => _showEmojiPicker(0), icon: const Icon(Icons.emoji_emotions, color: Colors.amber)),
        Expanded(
          child: TextField(
            controller: _messageController, // কন্ট্রোলারটি এখানে বসলো
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "মেসেজ লিখুন...", 
              border: InputBorder.none, 
              hintStyle: TextStyle(color: Colors.white24)
            ),
          )
        ),
        // সেন্ড বাটন - এখানে ক্লিক করলে মেসেজ স্ক্রিনে যাবে
        IconButton(
          onPressed: () {
            if (_messageController.text.isNotEmpty) {
              // ১. বর্তমান ইউজারের তথ্য নেওয়া
              final user = FirebaseAuth.instance.currentUser;

              setState(() {
                // ২. এখানে শুধু টেক্সট না পাঠিয়ে, নাম ও ছবিসহ ম্যাপ পাঠাচ্ছি
                chatMessages.add({
                  'userName': user?.displayName ?? "User", // ডাটাবেসের নাম
                  'userImage': user?.photoURL ?? "https://picsum.photos/100", // প্রোফাইল পিক
                  'text': _messageController.text, // আপনার লিখা মেসেজ
                });
                
                _messageController.clear(); // বক্স খালি হয়ে যাবে
              });
            }
          }, 
          icon: const Icon(Icons.send, color: Colors.blueAccent)
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.videogame_asset, color: Colors.blueAccent)), 
        IconButton(
          onPressed: () {
            setState(() {
              // ১. নিজের মাইক বাটন অন/অফ করা
              isMicOn = !isMicOn;
              
              // ২. আপনি যে সিটে বসে আছেন সেই সিটের ইনডেক্স খুঁজে বের করা
              int mySeatIndex = seats.indexWhere((s) => s["userName"] == displayUserID);
              
              // ৩. যদি আপনি সিটে থাকেন, তবে ঐ সিটের মাইক আইকনও আপডেট করা
              if (mySeatIndex != -1) {
                seats[mySeatIndex]["isMuted"] = !isMicOn; 
              }
            });
          },
          icon: Icon(
            isMicOn ? Icons.mic : Icons.mic_off, 
            color: isMicOn ? Colors.blueAccent : Colors.redAccent
          ),
        ),
       // ১. মিউজিক পেজে যাওয়া এবং সেখান থেকে ডাটা নিয়ে আসা
       IconButton(
          onPressed: () async {   
            final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MusicPlayerPage()),
              );

              // ২. যদি ইউজার কোনো গান সিলেক্ট করে ব্যাক আসে
              if (result != null && result is Map) {
                setState(() {
                  currentSongName = result['name'] ?? "Unknown"; // গানের নাম সেট
                  isRoomMusicPlaying = true; // ড্র্যাগেবল বার চালু
                });

                // ৩. গানটি বাজানো শুরু করা
                try {
                  await _audioPlayer.stop(); // আগের গান বন্ধ
                  await _audioPlayer.play(DeviceFileSource(result['path'])); // নতুন গান প্লে
                } catch (e) {
                  print("গান বাজাতে সমস্যা হয়েছে: $e");
                }
              }

              // ৪. ব্যাক করার পর লিস্ট আপডেট রাখা
              final prefs = await SharedPreferences.getInstance();
              final List<String> songs = prefs.getStringList('my_music') ?? [];
              
              setState(() {
                savedMusicPaths = songs;
              });
            },
            icon: const Icon(
              Icons.music_note, 
              color: Colors.greenAccent, 
              size: 28,
            ),
          ),
        IconButton(onPressed: _showGiftBox, icon: const Icon(Icons.card_giftcard, color: Colors.pinkAccent)), 
      ],
    ),
  );
}
  
} // <--- এই একটি মাত্র ব্র্যাকেট দিয়ে পুরো ফাইল শেষ হবে
