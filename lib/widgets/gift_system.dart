import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pagla_chat/data/romantic_gifts.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:pagla_chat/data/free_gifts.dart';
import 'package:pagla_chat/data/classic_gifts.dart';
import 'package:pagla_chat/data/luxury_gifts.dart';
import 'package:pagla_chat/data/pk_gifts.dart';
import 'package:pagla_chat/mini_video_thumbnail_player.dart';

class GiftBottomSheet extends StatefulWidget {
  final String roomId;
  final int diamondBalance;
  final List<dynamic> currentSeats;
  final int viewerCount;
  final Function(Map<String, dynamic> gift, int count, String target)
      onGiftSend;

  const GiftBottomSheet({
    super.key,
    required this.roomId,
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
  bool isRandomBoxSelected = false;
  List<dynamic> randomGiftPool = [];
  late List<Map<String, dynamic>> dynamicFreeGifts;

  @override
  void initState() {
    super.initState();
    // টাইমার ও এক্সপায়ার লজিক বাদ দিয়ে শুধু ডাটা ইনিশিয়ালাইজ করা হলো
    dynamicFreeGifts = freeGifts.map((g) {
      return Map<String, dynamic>.from(g);
    }).toList();
  }

  @override
  void dispose() {
    _boxScrollController.dispose();
    super.dispose();
  }

  void _showUserSelectionList() {
    List activeUsers = widget.currentSeats.where((s) {
      if (s == null) return false;
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
    Color getDynamicBodyColor() {
      if (selectedGift == null) return const Color.fromARGB(131, 4, 4, 122);

      bool isFree = selectedGift!['price'] == null || (selectedGift!['price'] ?? 0) == 0;
      int price = (selectedGift!['price'] ?? 0);

      if (isFree) return Colors.green.withOpacity(0.08);
      if (price > 500) return Colors.purple.withOpacity(0.12);
      if (price > 100) return Colors.orange.withOpacity(0.08);
      return Colors.pink.withOpacity(0.08);
    }

    return DefaultTabController(
      length: 5,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 550,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F0F1E),
              getDynamicBodyColor(),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('authUID',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              int currentBalance = 0;

              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                var userData =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;
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
        color: Colors.black.withOpacity(0.3),
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
            width: 55,
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
              margin: const EdgeInsets.all(3),
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

        String giftPath = (gift["lottieUrl"] ??
                gift["image"] ??
                gift["icon"] ??
                gift["url"] ??
                "")
            .toString();
        bool isJson = giftPath.toLowerCase().endsWith('.json');
        bool isOnlineLottie = isJson &&
            (giftPath.startsWith('http://') || giftPath.startsWith('https://'));

        bool isVideoGift = gift.containsKey('videoUrl') &&
            gift['videoUrl'] != null &&
            gift['videoUrl'].toString().isNotEmpty;
        String videoUrl = isVideoGift ? gift['videoUrl'].toString() : '';

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedGift = gift;

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
                'box_20_id',
              ];

              if (randomBoxIds.contains(gift['id'])) {
                isRandomBoxSelected = true;
                randomGiftPool = gift['gifts'] ?? [];
              } else {
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
              borderRadius: BorderRadius.circular(13),
              child: Stack(
                children: [
                  // 🔥 অপ্টিমাইজড রেন্ডারিং: ইউজার ক্লিক করে সিলেক্ট করলে তবেই লটি/ভিডিও অ্যানিমেশন দেখাবে, নতুবা ক্যাশড ইমেজ দেখাবে যাতে হ্যাং না করে।
                  Positioned.fill(
                    child: isVideoGift
                        ? (isSelected
                            ? MiniVideoThumbnailPlayer(videoUrl: videoUrl)
                            : CachedNetworkImage(
                                imageUrl: gift['image'] ?? gift['icon'] ?? "",
                                fit: BoxFit.cover,
                                memCacheWidth: 150,
                                memCacheHeight: 150,
                                errorWidget: (c, u, e) => const Icon(
                                    Icons.card_giftcard,
                                    color: Colors.white24),
                              ))
                        : (isJson && isSelected
                            ? (isOnlineLottie
                                ? Lottie.network(giftPath,
                                    repeat: true,
                                    fit: BoxFit.contain,
                                    addRepaintBoundary: true)
                                : Lottie.asset(giftPath,
                                    repeat: true,
                                    fit: BoxFit.contain,
                                    addRepaintBoundary: true))
                            : CachedNetworkImage(
                                imageUrl: gift['image'] ?? gift['icon'] ?? giftPath,
                                fit: BoxFit.cover,
                                memCacheWidth: 150,
                                memCacheHeight: 150,
                                errorWidget: (c, u, e) => const Icon(
                                    Icons.card_giftcard,
                                    color: Colors.white24),
                              )),
                  ),
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
                            const Text("FREE",
                                style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold))
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("💎", style: TextStyle(fontSize: 9)),
                                const SizedBox(width: 2),
                                Text("${gift["price"] ?? 0}",
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

    if (isRandomBoxSelected && randomGiftPool.isNotEmpty) {
      final random = DateTime.now().millisecondsSinceEpoch;
      giftToSend = randomGiftPool[random % randomGiftPool.length];
    } else {
      if (selectedGift == null) return;
      giftToSend = selectedGift!;
    }

    int unitPrice = (giftToSend['price'] ?? 0) as int;
    bool isFree = giftToSend['price'] == null || (giftToSend['price'] ?? 0) == 0;

    int multiplier = 1;
    if (targetType == "All Mic") {
      multiplier = widget.currentSeats.where((s) => s != null).length;
    } else if (targetType == "All Room") {
      multiplier = widget.viewerCount > 0 ? widget.viewerCount : 1;
    }

    int totalPrice = unitPrice * selectedCount * multiplier;

    if (!isFree && widget.diamondBalance < totalPrice) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Insufficient Diamonds! Need $totalPrice 💎",
              style: const TextStyle(color: Colors.white))));
      return;
    }

    if (isFree && targetType != "Target") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Free gifts can only be sent to a specific user!")));
      return;
    }

    String finalTargetValue;
    if (targetType == "All Room" || targetType == "All Mic") {
      finalTargetValue = targetType;
    } else {
      finalTargetValue = selectedTargetName ?? "Target";
    }

    bool isVideoGift =
        giftToSend.containsKey('videoUrl') && giftToSend['videoUrl'] != null;

    widget.onGiftSend(giftToSend, selectedCount, finalTargetValue);

    if (isVideoGift) {
      sendRoomVideoGift(giftToSend['videoUrl']);
    }

    if (isFree) {
      setState(() {
        dynamicFreeGifts.removeWhere((g) => g['id'] == giftToSend['id']);
        selectedGift = null;
        isRandomBoxSelected = false;
      });
    }

    Navigator.pop(context);
  }

  void sendRoomVideoGift(String giftUrl) {
    String path = '${widget.roomId}/latestVideoGift';

    FirebaseDatabase.instance.ref(path).set({
      'url': giftUrl,
      'sendTime': ServerValue.timestamp,
    }).then((_) {
      FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
        'latestVideoGift': {
          'url': giftUrl,
          'sendTime': DateTime.now().millisecondsSinceEpoch,
        }
      });
    }).catchError((error) {});
  }
}