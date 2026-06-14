import 'package:cached_network_image/cached_network_image.dart';
import 'package:pagla_chat/data/romantic_gifts.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:pagla_chat/data/free_gifts.dart';
import 'package:pagla_chat/data/classic_gifts.dart';
import 'package:pagla_chat/data/luxury_gifts.dart';
import 'package:pagla_chat/data/pk_gifts.dart'; // নতুন ফাইলটি ইম্পোর্ট করলেন

class GiftBottomSheet extends StatefulWidget {
  final int diamondBalance;
  final List<dynamic> currentSeats;
  final int viewerCount;
  final Function(Map<String, dynamic> gift, int count, String target)
      onGiftSend;

  const GiftBottomSheet({
    super.key,
    required this.diamondBalance,
    required this.currentSeats,
    required this.onGiftSend,
    this.viewerCount = 0,
  });

  @override
  State<GiftBottomSheet> createState() => _GiftBottomSheetState();
}

class _GiftBottomSheetState extends State<GiftBottomSheet> {
  Map<String, dynamic>? selectedGift;
  int selectedCount = 1;
  String targetType = "Target";
  String? selectedTargetId;
  String? selectedTargetName;
  String? selectedTargetImage;
  final ScrollController _boxScrollController = ScrollController();
  bool isRandomBoxSelected = false; // বক্স সিলেক্ট হয়েছে কি না
  List<dynamic> randomGiftPool = []; // ৬টি গিফটের লিস্ট
  late List<Map<String, dynamic>> dynamicFreeGifts;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    DateTime expiryDate = DateTime.now().add(const Duration(days: 3));
    dynamicFreeGifts = freeGifts.map((g) {
      var map = Map<String, dynamic>.from(g);
      map['expiry'] = expiryDate;
      return map;
    }).toList();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          dynamicFreeGifts.removeWhere(
              (g) => (g['expiry'] as DateTime).isBefore(DateTime.now()));
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
    _boxScrollController.dispose();
  }

  void _showUserSelectionList() {
    // শুধুমাত্র যাদের uID আছে তাদের ফিল্টার করা (isOccupied চেক করার দরকার নেই যদি uID থাকে)
    List activeUsers = widget.currentSeats.where((s) {
      if (s == null) return false;

      // সিটের ভেতর uID বা userId বা uid আছে কি না তা দেখা হচ্ছে
      // কারণ সিটে ইউজার থাকলে অবশ্যই একটা আইডি থাকবে
      var userId = s['uID'] ?? s['userId'] ?? s['uid'];

      return userId != null && userId.toString().trim().isNotEmpty;
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(15),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // হ্যান্ডেল বার
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 15),
              const Text("Select User from Seats",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              activeUsers.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text("No users are currently on seats",
                          style: TextStyle(color: Colors.white54)),
                    )
                  : Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: activeUsers.length,
                        itemBuilder: (context, index) {
                          var seat = activeUsers[index];

                          // ডাটাবেজ কী (Key) অনুযায়ী ডাটা নেওয়া (মাল্টিপল অপশন চেক)
                          String uID = (seat['uID'] ??
                                  seat['userId'] ??
                                  seat['uid'] ??
                                  "")
                              .toString();
                          String name =
                              seat['name'] ?? seat['userName'] ?? "User";
                          String img = seat['profilePic'] ??
                              seat['image'] ??
                              seat['userImage'] ??
                              "";

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.white10,
                              backgroundImage:
                                  img.isNotEmpty ? NetworkImage(img) : null,
                              child: img.isEmpty
                                  ? const Icon(Icons.person,
                                      color: Colors.white24)
                                  : null,
                            ),
                            title: Text(name,
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text("ID: $uID",
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11)),
                            onTap: () {
                              setState(() {
                                selectedTargetId = uID;
                                selectedTargetName = name;
                                selectedTargetImage = img;
                                targetType = name;
                              });
                              Navigator.pop(context);
                            },
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

  @override
  Widget build(BuildContext context) {
    // 🎨 গিফটের টাইপ অনুযায়ী বডি কালার ঠিক করার লজিক
    Color getDynamicBodyColor() {
      if (selectedGift == null)
        return const Color.fromARGB(131, 4, 4, 122); // ডিফল্ট ডার্ক কালার

      bool isFree = selectedGift!['expiry'] != null;
      int price = (selectedGift!['price'] ?? 0);

      if (isFree)
        return Colors.green
            .withOpacity(0.08); // ফ্রি গিফটের জন্য হালকা সবুজ আভা
      if (price > 500)
        return Colors.purple
            .withOpacity(0.12); // লাক্সারি গিফটের জন্য বেগুনি আভা
      if (price > 100)
        return Colors.orange
            .withOpacity(0.08); // রোমান্টিক গিফটের জন্য কমলা আভা
      return Colors.pink.withOpacity(0.08); // ক্লাসিক গিফটের জন্য গোলাপী আভা
    }

    return DefaultTabController(
      length: 5,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400), // কালার পরিবর্তনের সময়
        height: 550,
        decoration: BoxDecoration(
          // এখানে সলিড কালারের বদলে গ্রেডিয়েন্ট দিলে আরও রয়্যাল লাগবে
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F0F1E), // উপরের ডার্ক বেস
              getDynamicBodyColor(), // নিচের ডাইনামিক আভা
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
                color: getDynamicBodyColor().withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            // উপরে একটা ছোট হ্যান্ডেল বারের মতো দিলে ভালো দেখাবে
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            _buildHeader(),
            _buildRandomBoxPreview(),
            _buildTargetSelector(),
            const TabBar(
              isScrollable: true,
              indicatorColor: Colors.pinkAccent,
              dividerColor: Colors.transparent,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelColor: Colors.white38,
              tabs: [
                Tab(text: "Free"),
                Tab(text: "Pk"),
                Tab(text: "Classic"),
                Tab(text: "Romantic"),
                Tab(text: "Luxury"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildGrid(dynamicFreeGifts, isFreeTab: true),
                  _buildGrid(pkGifts),
                  _buildGrid(classicGifts),
                  _buildGrid(romanticGifts),
                  _buildGrid(luxuryGifts),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ফায়ারবেস থেকে সরাসরি ডাইমন্ড আনার জন্য এই উইজেটটি ব্যবহার করুন
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 💎 ডাইমন্ড দেখানোর জন্য StreamBuilder
          StreamBuilder<QuerySnapshot>(
            // আপনার ডাটাবেস অনুযায়ী authUID দিয়ে সঠিক ইউজার ডকুমেন্ট খোঁজা হচ্ছে
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('authUID',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              int currentBalance = 0;

              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                // প্রথম যে ডকুমেন্ট পাওয়া যাবে (যেহেতু authUID ইউনিক)
                var userData =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;

                // আপনার ডাটাবেস অনুযায়ী ফিল্ডের নাম 'diamonds'
                currentBalance = userData['diamonds'] ?? 0;
              }

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    // ডাইমন্ড আইকন আপনি যেমন চেয়েছেন (💎)
                    const Text("💎", style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 5),
                    Text(
                      "$currentBalance",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),
          const Text(
            "Send Gift",
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Icon(Icons.history, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _buildTargetSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _targetChip("All Room", Icons.groups),
            _targetChip("All Mic", Icons.mic),
            _targetChip(selectedTargetName ?? "Target", Icons.person_add,
                isTargetMode: true, userImg: selectedTargetImage),
          ],
        ),
      ),
    );
  }

  Widget _targetChip(String label, IconData icon,
      {bool isTargetMode = false, String? userImg}) {
    bool isSelected =
        isTargetMode ? (targetType == "Target") : (targetType == label);
    return GestureDetector(
      onTap: () {
        if (isTargetMode) {
          _showUserSelectionList();
        } else {
          setState(() {
            targetType = label;
            selectedTargetId = label;
            selectedTargetName = null;
            selectedTargetImage = null;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.pinkAccent : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? Colors.white24 : Colors.transparent),
        ),
        child: Row(
          children: [
            if (userImg != null && userImg.isNotEmpty)
              CircleAvatar(radius: 8, backgroundImage: NetworkImage(userImg))
            else
              Icon(icon,
                  size: 16, color: isSelected ? Colors.white : Colors.white54),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildRandomBoxPreview() {
    if (!isRandomBoxSelected || randomGiftPool.isEmpty) {
      return const SizedBox.shrink();
    }

    // স্ক্রলিং লজিক একই থাকবে
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_boxScrollController.hasClients) {
        if (_boxScrollController.position.pixels >=
            _boxScrollController.position.maxScrollExtent) {
          _boxScrollController.jumpTo(0);
        }
        _boxScrollController.animateTo(
          _boxScrollController.position.pixels + 50,
          duration: const Duration(milliseconds: 200),
          curve: Curves.linear,
        );
      }
    });

    return Container(
      height: 75,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3), // গ্লাস ইফেক্টের জন্য ডার্ক টিন্ট
        borderRadius: BorderRadius.circular(25),
        border:
            Border.all(color: Colors.pinkAccent.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.pinkAccent.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1)
        ],
      ),
      child: ListView.builder(
        controller: _boxScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: randomGiftPool.length,
        itemBuilder: (context, index) {
          var gift = randomGiftPool[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            width: 55, // বল সাইজ সামান্য বাড়ানো হয়েছে
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.withOpacity(0.2), Colors.transparent],
              ),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: Container(
              margin: const EdgeInsets.all(3), // ইমেজের চারপাশ গ্লো করার জন্য
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black26,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: CachedNetworkImage(
                  imageUrl: gift['image'] ?? gift['icon'] ?? "",
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => const Icon(Icons.card_giftcard,
                      color: Colors.white24, size: 20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(List gifts, {bool isFreeTab = false}) {
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: gifts.length,
      itemBuilder: (context, index) {
        var gift = gifts[index];
        bool isSelected = selectedGift?['id'] == gift['id'];
        String giftPath =
            (gift["image"] ?? gift["icon"] ?? gift["url"] ?? "").toString();
        bool isJson = giftPath.toLowerCase().endsWith('.json');

        return GestureDetector(
          onTap: () {
            setState(() {
              // ১. পুরাতন সিলেক্ট লজিক (সব গিফটের জন্য কমন)
              selectedGift = gift;

              // ২. এখানে সব রেন্ডম বক্সের আইডিগুলো লিস্টে রাখুন
              // ভবিষ্যতে নতুন বক্স যোগ করলে শুধু এখানে আইডিটি কমা দিয়ে লিখে দেবেন
              List<String> randomBoxIds = [
                'random_box_id',
                'box_1_id',
                'box_2_id',
                'box_3_id',
                'box_4_id',
                'box_5_id',
                'box_6_id',
                'box_7_id',
                'box_8_id',
                'box_9_id',
                'box_10_id',
                'box_11_id',
                'box_12_id',
                'box_13_id',
                'box_14_id',
                'box_15_id',
                'box_16_id',
                'box_17_id',
                'box_18_id',
                'box_19_id',
              ];

              // ৩. চেক করছি গিফটটি কি এই লিস্টের কোনো বক্স কি না
              if (randomBoxIds.contains(gift['id'])) {
                isRandomBoxSelected = true;
                randomGiftPool = gift['gifts'] ?? []; // গিফট পুল সেট করছি
              } else {
                // যদি সাধারণ গিফট হয়
                isRandomBoxSelected = false;
                randomGiftPool = [];
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.pinkAccent.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                  color: isSelected ? Colors.pinkAccent : Colors.white10,
                  width: isSelected ? 2.0 : 1.5),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: Colors.pinkAccent.withOpacity(0.3),
                          blurRadius: 8)
                    ]
                  : null,
            ),
            child: ClipRRect(
              // ছবি যেন বর্ডারের বাইরে না যায়
              borderRadius: BorderRadius.circular(13),
              child: Stack(
                children: [
                  // ১. মূল ছবি (পুরো কার্ড জুড়ে থাকবে)
                  Positioned.fill(
                    child: isJson
                        ? Lottie.asset(giftPath,
                            repeat: true, fit: BoxFit.contain)
                        : CachedNetworkImage(
                            imageUrl: giftPath,
                            fit: BoxFit.cover,
                            errorWidget: (c, u, e) => const Icon(
                                Icons.card_giftcard,
                                color: Colors.white24),
                          ),
                  ),

                  // ২. নিচের টেক্সট বা ডাইমন্ড কাউন্ট (ছবির উপরে হালকা শ্যাডো সহ)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isFreeTab)
                            Text(_getRemainingTime(gift['expiry']),
                                style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold))
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("💎", style: TextStyle(fontSize: 9)),
                                const SizedBox(width: 2),
                                Text("${gift["price"]}",
                                    style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          ...[1, 10, 88, 100].map((count) => GestureDetector(
                onTap: () => setState(() => selectedCount = count),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selectedCount == count
                        ? Colors.pinkAccent
                        : Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  child: Text("$count",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              )),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              elevation: 5,
            ),
            onPressed: (selectedGift == null ||
                    (targetType == "Target" && selectedTargetId == null))
                ? null
                : _handleSendAction,
            child: const Text("SEND",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  void _handleSendAction() {
    Map<String, dynamic> giftToSend;

    // ১. রেন্ডম বক্স লজিক: রেন্ডম বক্স সিলেক্ট করা থাকলে পুল থেকে একটি গিফট বাছাই হবে
    if (isRandomBoxSelected && randomGiftPool.isNotEmpty) {
      final random = DateTime.now().millisecondsSinceEpoch;
      giftToSend = randomGiftPool[random % randomGiftPool.length];
    } else {
      // সাধারণ গিফট হলে সরাসরি সিলেক্টেড গিফটটি নেয়া হবে
      if (selectedGift == null) return;
      giftToSend = selectedGift!;
    }

    // ২. গিফট প্রাইস এবং ফ্রি চেক
    int unitPrice = (giftToSend['price'] ?? 0) as int;
    bool isFree = giftToSend['expiry'] != null;

    // ৩. মাল্টিপ্লায়ার ক্যালকুলেশন
    int multiplier = 1;
    if (targetType == "All Mic") {
      multiplier = widget.currentSeats.where((s) => s != null).length;
    } else if (targetType == "All Room") {
      multiplier = widget.viewerCount > 0 ? widget.viewerCount : 1;
    }

    int totalPrice = unitPrice * selectedCount * multiplier;

    // ৪. ডাইমন্ড ব্যালেন্স চেক
    if (!isFree && widget.diamondBalance < totalPrice) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Insufficient Diamonds! Need $totalPrice 💎",
              style: const TextStyle(color: Colors.white))));
      return;
    }

    // ৫. ফ্রি গিফট লিমিটেশন চেক
    if (isFree && targetType != "Target") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Free gifts can only be sent to a specific user!")));
      return;
    }

    // ৬. টার্গেট ভ্যালু সেট করা
    String finalTargetValue;
    if (targetType == "All Room" || targetType == "All Mic") {
      finalTargetValue = targetType;
    } else {
      finalTargetValue = selectedTargetName ?? "Target";
    }

    // ৭. গিফট পাঠানো
    widget.onGiftSend(giftToSend, selectedCount, finalTargetValue);

    // ৮. রিমুভাল লজিক (ফ্রি গিফট হলে লিস্ট থেকে সরানো)
    if (isFree) {
      setState(() {
        dynamicFreeGifts.removeWhere((g) => g['id'] == giftToSend['id']);
        selectedGift = null;
        isRandomBoxSelected = false; // রিসেট করা
      });
    }

    Navigator.pop(context);
  }

  // ✅ আপনার সেই হারানো টাইম লজিকটি এখানে যোগ করা হয়েছে
  String _getRemainingTime(DateTime expiry) {
    final difference = expiry.difference(DateTime.now());
    if (difference.isNegative) return "Expired";
    return "${difference.inDays}d ${difference.inHours % 24}h ${difference.inMinutes % 60}m";
  }
}
