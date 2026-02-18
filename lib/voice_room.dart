import 'package:flutter/material.dart';
import 'dart:async';
// গ্যালারি থেকে ছবি নিতে এই প্যাকেজটি পরে লাগবে: image_picker

class VoiceRoom extends StatefulWidget {
  const VoiceRoom({super.key});

  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
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

  // ৪. গিফট বক্স ডিজাইন (৩০টি আইটেম সহ)
  void _showGiftBox() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          height: 450,
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              // ডাইমন্ড ব্যালেন্স ও টাইটেল
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                    child: Text("💎 ব্যালেন্স: $diamondBalance", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ),
                  const Text("গিফট বক্স", style: TextStyle(color: Colors.white, fontSize: 16)),
                  const Icon(Icons.history, color: Colors.white38),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),
              
              // ৩০টি গিফটের গ্রিড
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, 
                    mainAxisSpacing: 10, 
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.8
                  ),
                  itemCount: gifts.length,
                  itemBuilder: (context, index) {
                    var gift = gifts[index];
                    return GestureDetector(
                      onTap: () => _sendGift(gift),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(gift["icon"], height: 45), // গিফটের বড় আইকন
                            const SizedBox(height: 5),
                            Text("💎 ${gift["price"]}", style: const TextStyle(color: Colors.amber, fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ৫. স্ক্রিনের ওপর গিফট এনিমেশন লেয়ার
  Widget _buildGiftOverlay() {
    if (!isGiftAnimating) return const SizedBox();

    return Center(
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 800),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // আপনার চাহিদা মতো দামী গিফট বড়, কম দামী ছোট
                  Image.network(
                    currentGiftImage, 
                    height: isFullScreenBinding ? 380 : 180, 
                  ),
                  const SizedBox(height: 10),
                  // গিফট দাতা ও গ্রহীতার নাম (অটোমেটিক)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    decoration: BoxDecoration(color: Colors.pinkAccent, borderRadius: BorderRadius.circular(20)),
                    child: const Text("ইউজার 🎁 সিট ১", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  // --- ১. ভেরিয়েবলসমূহ ---
  bool isLocked = false; 
  int diamondBalance = 1000; 
  String roomWallpaper = ""; 
  String roomName = "পাগলা রুম";
  int followerCount = 150;
  bool isFollowing = false;
  
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
    if (seats[index]["isVip"]) {
      bool userHasVipBadge = false; // এটি পরে ইউজার প্রোফাইল থেকে আসবে
      if (!userHasVipBadge) {
        _showMessage("এটি VIP সিট! আপনি বসতে পারবেন না।");
        return;
      }
    }
    setState(() {
      seats[index]["isOccupied"] = true;
      seats[index]["userName"] = "ইউজার ${index+1}";
    });
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
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
          
          // তোমার সিট গ্রিড
          _buildSeatGrid(), 

          // --- এইখানে নতুন কোডটুকু বসবে ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              reverse: true, // নতুন মেসেজ নিচে দেখাবে
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                // উল্টো করে দেখাচ্ছি যেন লেটেস্ট মেসেজ নিচে থাকে
                final msg = chatMessages[chatMessages.length - 1 - index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    "ইউজার: $msg",
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                );
              },
            ),
          ),
          // ---------------------------------

          _buildChatAndControls(), 
        ],
      ),
    ),
  );
}
  
  // --- ৩. উইজেটসমূহ (ডিজাইন) ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          const CircleAvatar(radius: 25, backgroundColor: Colors.white10, child: Icon(Icons.person, color: Colors.pinkAccent)), 
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("ID: 556677 | Follower: $followerCount", style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          // ফলো বাটন
          IconButton(
            onPressed: () => setState(() => isFollowing = !isFollowing),
            icon: Icon(isFollowing ? Icons.check_circle : Icons.add_circle, color: Colors.pinkAccent)
          ),
          // লক বাটন
          IconButton(onPressed: toggleLock, icon: Icon(isLocked ? Icons.lock : Icons.lock_open, color: Colors.amber)), 
          // ওয়ালপেপার মেনু
          PopupMenuButton<int>(
            icon: const Icon(Icons.wallpaper, color: Colors.cyanAccent),
            onSelected: (val) => val == 20 ? setWallpaper(20, "২৪ ঘন্টা") : setWallpaper(600, "১ মাস"),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 20, child: Text("২৪ ঘন্টা (২০💎)")),
              const PopupMenuItem(value: 600, child: Text("১ মাস (৬০০💎)")),
            ],
          ),
        ],
      ),
    );
  }

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

                    // ইমোজি পপ-আপ
                    if (seat["emoji"].isNotEmpty)
                      Positioned(
                        top: -15,
                        child: Text(seat["emoji"], style: const TextStyle(fontSize: 25)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
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
        IconButton(onPressed: () => _showEmojiPicker(), icon: const Icon(Icons.emoji_emotions, color: Colors.amber)),
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
              setState(() {
                chatMessages.add(_messageController.text); // লিস্টে মেসেজ যোগ হবে
                _messageController.clear(); // বক্স খালি হয়ে যাবে
              });
            }
          }, 
          icon: const Icon(Icons.send, color: Colors.blueAccent)
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.videogame_asset, color: Colors.blueAccent)), 
        IconButton(onPressed: _showGiftBox, icon: const Icon(Icons.card_giftcard, color: Colors.pinkAccent)), 
      ],
    ),
  );
}

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) => GridView.count(
        crossAxisCount: 6,
        children: ["🤔","🤫","🫣","🤭","😭","😏","👏","🥱","😡"].map((e) => IconButton(
          onPressed: () {
            showEmojiOnSeat(0, e); // ধরে নিচ্ছি ইউজার ১ নম্বর সিটে আছে
            Navigator.pop(context);
          },
          icon: Text(e, style: const TextStyle(fontSize: 24)),
        )).toList(),
      ),
    );
  }

  void showEmojiOnSeat(int seatIndex, String emoji) {
    setState(() => seats[seatIndex]["emoji"] = emoji);
    Timer(const Duration(seconds: 3), () => setState(() => seats[seatIndex]["emoji"] = ""));
  }
}
