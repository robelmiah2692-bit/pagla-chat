import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lottie/lottie.dart'; // লটি এনিমেশন ইমপোর্ট
import 'package:pagla_chat/services/gift_logic_helper.dart';

// ডাটা ফাইল ইমপোর্ট
import 'package:pagla_chat/data/free_gifts.dart';
import 'package:pagla_chat/data/classic_gifts.dart';
import 'package:pagla_chat/data/romantic_gifts.dart';
import 'package:pagla_chat/data/luxury_gifts.dart';

class GiftBottomSheet extends StatefulWidget {
  final int diamondBalance;
  final List<dynamic> currentSeats; 
  final Function(Map<String, dynamic> gift, int count, String target) onGiftSend;

  const GiftBottomSheet({
    super.key,
    required this.diamondBalance,
    required this.currentSeats,
    required this.onGiftSend,
  });

  @override
  State<GiftBottomSheet> createState() => _GiftBottomSheetState();
}

class _GiftBottomSheetState extends State<GiftBottomSheet> {
  Map<String, dynamic>? selectedGift;
  int selectedCount = 1;
  String targetType = "Target"; 
  String? selectedTargetId; 
  
  late List<Map<String, dynamic>> dynamicFreeGifts;
  Timer? _timer; 

  @override
  void initState() {
    super.initState();
    // ফ্রি গিফট সেটআপ (টাইম আটকে থাকবে না, প্রতি সেকেন্ডে আপডেট হবে)
    DateTime expiryDate = DateTime.now().add(const Duration(hours: 2, minutes: 23));
    dynamicFreeGifts = freeGifts.map((g) {
      var map = Map<String, dynamic>.from(g);
      map['expiry'] = expiryDate; 
      return map;
    }).toList();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // সময় শেষ হলে ফ্রি গিফট অটোমেটিক রিমুভ হবে
          dynamicFreeGifts.removeWhere((g) => 
            (g['expiry'] as DateTime).difference(DateTime.now()).isNegative
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

  // --- রুমে থাকা ইউজার লিস্ট দেখানোর ডায়ালগ ---
  void _showUserSelectionList() {
    // শুধু যাদের UID আছে এবং যারা একটিভ তাদের লিস্ট
    List activeUsers = widget.currentSeats.where((s) => s != null && s['uid'] != null).toList();

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
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(seat['image'] ?? seat['profilePic'] ?? "https://via.placeholder.com/150"),
                          ),
                          title: Text(seat['name'] ?? "User", style: const TextStyle(color: Colors.white)),
                          subtitle: Text("ID: ${seat['uID'] ?? seat['uid'] ?? 'N/A'}", style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          onTap: () {
                            setState(() {
                              selectedTargetId = seat['uid'];
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
          _targetChip("Target", Icons.person_pin_circle),
        ],
      ),
    );
  }

  Widget _targetChip(String label, IconData icon) {
    bool isSelected = targetType == label;
    return GestureDetector(
      onTap: () {
        if (label == "Target") {
          _showUserSelectionList();
        } else {
          setState(() {
            targetType = label;
            selectedTargetId = label; 
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
        
        // ইমেজ হ্যান্ডলিং: JSON (Lottie), Network, অথবা Asset
        String giftPath = (gift["image"] ?? gift["icon"] ?? gift["url"] ?? gift["png"] ?? "").toString();
        bool isJson = giftPath.toLowerCase().endsWith('.json');
        bool isNetwork = giftPath.startsWith('http');

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
                  child: giftPath.isEmpty 
                    ? const Icon(Icons.card_giftcard, color: Colors.white24)
                    : isJson 
                      ? Lottie.asset(giftPath, repeat: true, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.error))
                      : isNetwork 
                        ? Image.network(giftPath, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.broken_image))
                        : Image.asset(giftPath, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)),
                ),
                const SizedBox(height: 5),
                if (isFreeTab) 
                  Text(_getRemainingTime(gift['expiry']), style: const TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold))
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
    int totalPrice = unitPrice * selectedCount;
    bool isFree = selectedGift!['expiry'] != null;

    if (!isFree && widget.diamondBalance < totalPrice) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Insufficient Diamonds!")));
      return;
    }

    // সার্ভারে বা মেইন পেজে ডাটা পাঠানো (সেখানে ৫ সেকেন্ডের টাইমার সেট করতে হবে)
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
    final now = DateTime.now();
    final difference = expiry.difference(now);
    if (difference.isNegative) return "Expired";
    
    int hours = difference.inHours;
    int minutes = difference.inMinutes % 60;
    int seconds = difference.inSeconds % 60;
    
    return "${hours}h ${minutes}m ${seconds}s";
  }
}
