import 'package:pagla_chat/data/romantic_gifts.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lottie/lottie.dart'; 
import 'package:pagla_chat/services/gift_logic_helper.dart';

import 'package:pagla_chat/data/free_gifts.dart';
import 'package:pagla_chat/data/classic_gifts.dart';
import 'package:pagla_chat/data/luxury_gifts.dart';

class GiftBottomSheet extends StatefulWidget {
  final int diamondBalance;
  final List<dynamic> currentSeats; 
  final int viewerCount;
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
  String? selectedTargetName; 
  String? selectedTargetImage; 
  
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

  // ✅ ফিক্সড ইউজার সিলেকশন লজিক (Firebase uID অনুযায়ী)
  void _showUserSelectionList() {
    // সিটে থাকা ইউজারদের ফিল্টার করা - স্ক্রিনশট অনুযায়ী 'uID' চেক করা হচ্ছে
    List activeUsers = widget.currentSeats.where((s) {
      if (s == null) return false;
      return s['uID'] != null || s['uid'] != null || s['userId'] != null;
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F1E), 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select User from Seats", 
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              activeUsers.isEmpty 
                ? const Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Text("No users are currently on seats", style: TextStyle(color: Colors.white54)),
                  )
                : Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: activeUsers.length,
                      itemBuilder: (context, index) {
                        var seat = activeUsers[index];
                        
                        // Firebase key 'uID' এবং 'profilePic' এর সাথে ম্যাচ করা হয়েছে
                        String uID = (seat['uID'] ?? seat['uid'] ?? seat['userId'] ?? "").toString();
                        String name = seat['name'] ?? seat['userName'] ?? "User ${index + 1}";
                        String img = seat['profilePic'] ?? seat['image'] ?? seat['userImage'] ?? "";

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white10,
                            backgroundImage: img.isNotEmpty ? NetworkImage(img) : null,
                            child: img.isEmpty ? const Icon(Icons.person, color: Colors.white24) : null,
                          ),
                          title: Text(name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text("ID: $uID", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          onTap: () {
                            setState(() {
                              selectedTargetId = uID;
                              selectedTargetName = name;
                              selectedTargetImage = img;
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
          color: Color(0xFF07070F), 
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(color: Colors.white10, blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            _buildHeader(),
            _buildTargetSelector(),
            const TabBar(
              isScrollable: true,
              indicatorColor: Colors.pinkAccent,
              dividerColor: Colors.transparent,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelColor: Colors.white38,
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                const Icon(Icons.diamond, color: Colors.amber, size: 16),
                const SizedBox(width: 5),
                Text("${widget.diamondBalance}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Text("Send Gift", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
            _targetChip(selectedTargetName ?? "Target", Icons.person_add, isTargetMode: true, userImg: selectedTargetImage),
          ],
        ),
      ),
    );
  }

  Widget _targetChip(String label, IconData icon, {bool isTargetMode = false, String? userImg}) {
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
            selectedTargetImage = null;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pinkAccent : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.white24 : Colors.transparent),
        ),
        child: Row(
          children: [
            if (userImg != null && userImg.isNotEmpty)
              CircleAvatar(radius: 8, backgroundImage: NetworkImage(userImg))
            else
              Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.white54),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
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
        childAspectRatio: 0.8,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: gifts.length,
      itemBuilder: (context, index) {
        var gift = gifts[index];
        bool isSelected = selectedGift?['id'] == gift['id'];
        String giftPath = (gift["image"] ?? gift["icon"] ?? gift["url"] ?? "").toString();
        bool isJson = giftPath.toLowerCase().endsWith('.json');

        return GestureDetector(
          onTap: () => setState(() => selectedGift = gift),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? Colors.pinkAccent.withOpacity(0.15) : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSelected ? Colors.pinkAccent : Colors.white10, width: 1.5),
              boxShadow: isSelected ? [BoxShadow(color: Colors.pinkAccent.withOpacity(0.3), blurRadius: 8)] : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 48, width: 48,
                  child: isJson 
                      ? Lottie.asset(giftPath, repeat: true, fit: BoxFit.contain)
                      : Image.network(giftPath, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.card_giftcard, color: Colors.white24)),
                ),
                const SizedBox(height: 6),
                if (isFreeTab) 
                  Text(_getRemainingTime(gift['expiry']), style: const TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold))
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.diamond, color: Colors.amber, size: 10),
                      const SizedBox(width: 2),
                      Text("${gift["price"]}", style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
              ],
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
                color: selectedCount == count ? Colors.pinkAccent : Colors.white10,
                shape: BoxShape.circle,
              ),
              child: Text("$count", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          )),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent, 
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 5,
            ),
            onPressed: (selectedGift == null || (targetType == "Target" && selectedTargetId == null)) ? null : _handleSendAction,
            child: const Text("SEND", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  void _handleSendAction() {
    int unitPrice = (selectedGift!['price'] ?? 0) as int;
    bool isFree = selectedGift!['expiry'] != null;
    
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
        content: Text("Insufficient Diamonds! Need $totalPrice 💎", style: const TextStyle(color: Colors.white))));
      return;
    }

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
