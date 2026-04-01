/*import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lottie/lottie.dart'; 
import 'package:pagla_chat/services/gift_logic_helper.dart';

import 'package:pagla_chat/data/free_gifts.dart';
import 'package:pagla_chat/data/classic_gifts.dart';
import 'package:pagla_chat/data/romantic_gifts.dart';
import 'package:pagla_chat/data/luxury_gifts.dart';

class GiftBottomSheet extends StatefulWidget {
  final int diamondBalance;
  final List<dynamic> currentSeats; 
  final int viewerCount; // ভিউয়ার সংখ্যা জানার জন্য (All Room এর জন্য দরকার)
  final Function(Map<String, dynamic> gift, int count, String target) onGiftSend;

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
  String? selectedTargetName; // ইউজারের নাম দেখানোর জন্য
  
  late List<Map<String, dynamic>> dynamicFreeGifts;
  Timer? _timer; 

  @override
  void initState() {
    super.initState();
    // ✅ ৩ দিনের (৭২ ঘণ্টা) ফ্রি গিফট লজিক
    DateTime expiryDate = DateTime.now().add(const Duration(days: 3));
    dynamicFreeGifts = freeGifts.map((g) {
      var map = Map<String, dynamic>.from(g);
      map['expiry'] = expiryDate; 
      return map;
    }).toList();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          dynamicFreeGifts.removeWhere((g) => 
            (g['expiry'] as DateTime).isBefore(DateTime.now())
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showUserSelectionList() {
    // অ্যাক্টিভ ইউজার ফিল্টারিং
    List activeUsers = widget.currentSeats.where((s) => s != null && (s['uID'] != null || s['uid'] != null)).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select User", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white10),
              activeUsers.isEmpty 
                ? const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("No users on seats", style: TextStyle(color: Colors.white54)),
                  )
                : Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: activeUsers.length,
                      itemBuilder: (context, index) {
                        var seat = activeUsers[index];
                        String uID = (seat['uID'] ?? seat['uid'] ?? "").toString();
                        String name = seat['name'] ?? "User";
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(seat['image'] ?? seat['profilePic'] ?? "https://via.placeholder.com/150"),
                          ),
                          title: Text(name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text("ID: $uID", style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          onTap: () {
                            setState(() {
                              selectedTargetId = uID;
                              selectedTargetName = name;
                              targetType = "Target"; 
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
    return DefaultTabController(
      length: 4,
      child: Container(
        height: 550,
        decoration: const BoxDecoration(
          color: Color(0xFF0F0F1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            _buildHeader(),
            _buildTargetSelector(),
            const TabBar(
              isScrollable: true,
              indicatorColor: Colors.pinkAccent,
              tabs: [
                Tab(text: "Free"), Tab(text: "Classic"),
                Tab(text: "Romantic"), Tab(text: "Luxury"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildGrid(dynamicFreeGifts, isFreeTab: true),
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
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("💎 Balance: ${widget.diamondBalance}", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          const Text("Send Gift", style: TextStyle(color: Colors.white, fontSize: 16)),
          const Icon(Icons.history, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _buildTargetSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Row(
        children: [
          _targetChip("All Room", Icons.groups),
          _targetChip("All Mic", Icons.mic),
          // যদি টার্গেট সিলেক্ট করা থাকে তবে তার নাম দেখাবে
          _targetChip(selectedTargetName ?? "Target", Icons.person_pin_circle, isTargetMode: true),
        ],
      ),
    );
  }

  Widget _targetChip(String label, IconData icon, {bool isTargetMode = false}) {
    bool isSelected = isTargetMode ? (targetType == "Target") : (targetType == label);
    return GestureDetector(
      onTap: () {
        if (isTargetMode) {
          _showUserSelectionList();
        } else {
          setState(() {
            targetType = label;
            selectedTargetId = label;
            selectedTargetName = null;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pinkAccent : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.white54),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List gifts, {bool isFreeTab = false}) {
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, 
        childAspectRatio: 0.75,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: gifts.length,
      itemBuilder: (context, index) {
        var gift = gifts[index];
        bool isSelected = selectedGift?['id'] == gift['id'];
        
        String giftPath = (gift["image"] ?? gift["icon"] ?? gift["url"] ?? gift["png"] ?? "").toString();
        bool isJson = giftPath.toLowerCase().endsWith('.json');

        return GestureDetector(
          onTap: () => setState(() => selectedGift = gift),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.pinkAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSelected ? Colors.pinkAccent : Colors.white10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 45, width: 45,
                  child: isJson 
                      ? Lottie.asset(giftPath, repeat: true, fit: BoxFit.contain)
                      : Image.network(giftPath, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.card_giftcard, color: Colors.white24)),
                ),
                const SizedBox(height: 5),
                if (isFreeTab) 
                  Text(_getRemainingTime(gift['expiry']), style: const TextStyle(color: Colors.greenAccent, fontSize: 7, fontWeight: FontWeight.bold))
                else
                  Text("💎 ${gift["price"]}", style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.white10,
      child: Row(
        children: [
          ...[1, 10, 88, 100].map((count) => GestureDetector(
            onTap: () => setState(() => selectedCount = count),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selectedCount == count ? Colors.pinkAccent : Colors.white10,
                shape: BoxShape.circle,
              ),
              child: Text("x$count", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          )),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, shape: const StadiumBorder()),
            onPressed: (selectedGift == null || (targetType == "Target" && selectedTargetId == null)) ? null : _handleSendAction,
            child: const Text("SEND", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleSendAction() {
    int unitPrice = (selectedGift!['price'] ?? 0) as int;
    bool isFree = selectedGift!['expiry'] != null;
    
    // ✅ ডায়মন্ড ক্যালকুলেশন লজিক
    int multiplier = 1;
    if (targetType == "All Mic") {
      multiplier = widget.currentSeats.where((s) => s != null).length;
    } else if (targetType == "All Room") {
      multiplier = widget.viewerCount > 0 ? widget.viewerCount : 1;
    }
    
    int totalPrice = unitPrice * selectedCount * multiplier;

    if (!isFree && widget.diamondBalance < totalPrice) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Insufficient Diamonds! Need $totalPrice 💎")));
      return;
    }

    // ফ্রি গিফট হলে শুধুমাত্র ১ জনকে দেওয়া যাবে ( multiplier = 1)
    if (isFree && targetType != "Target") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Free gifts can only be sent to a specific user!")));
        return;
    }

    widget.onGiftSend(selectedGift!, selectedCount, selectedTargetId ?? targetType);

    if (isFree) {
      setState(() {
        dynamicFreeGifts.removeWhere((g) => g['id'] == selectedGift!['id']);
        selectedGift = null;
      });
    }
    Navigator.pop(context);
  }

  String _getRemainingTime(DateTime expiry) {
    final difference = expiry.difference(DateTime.now());
    if (difference.isNegative) return "Expired";
    return "${difference.inDays}d ${difference.inHours % 24}h ${difference.inMinutes % 60}m";
  }
}
