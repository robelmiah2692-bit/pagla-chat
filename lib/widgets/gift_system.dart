import 'package:flutter/material.dart';
import 'package:pagla_chat/services/database_service.dart';
import 'package:pagla_chat/services/gift_logic_helper.dart';

// ডাটা ফাইল ইমপোর্ট
import 'package:pagla_chat/data/free_gifts.dart';
import 'package:pagla_chat/data/classic_gifts.dart';
import 'package:pagla_chat/data/romantic_gifts.dart';
import 'package:pagla_chat/data/luxury_gifts.dart';

class GiftBottomSheet extends StatefulWidget {
  final int diamondBalance;
  final List<dynamic> currentSeats; // সিটের ইউজারদের জন্য
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
  String targetType = "Selected User"; 
  String? selectedTargetId; // টার্গেট ইউজারের আইডি রাখার জন্য

  // ফ্রি গিফট একবার সেন্ড হলে রিমুভ করার জন্য এই লিস্টটি ব্যবহার হবে
  late List<Map<String, dynamic>> dynamicFreeGifts;

  @override
  void initState() {
    super.initState();
    // শুরুতেই সব ফ্রি গিফট কপি করে নেওয়া হলো
    dynamicFreeGifts = List.from(freeGifts);
  }

  @override
  Widget build(BuildContext context) {
    // সব গিফটকে ক্যাটাগরি অনুযায়ী লিস্ট করা
    final classicList = classicGifts;
    final romanticList = romanticGifts;
    final luxuryList = luxuryGifts;

    return DefaultTabController(
      length: 4,
      child: Container(
        height: 550,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
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
                  _buildGrid(dynamicFreeGifts), // ফ্রি গিফট এখন ডাইনামিক লিস্ট থেকে আসবে
                  _buildGrid(classicList),
                  _buildGrid(romanticList),
                  _buildGrid(luxuryList),
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
          Text("💎 Balance: ${widget.diamondBalance}", 
            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          const Text("Select Gift", style: TextStyle(color: Colors.white, fontSize: 16)),
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
    bool isSelected = (label == "Target" && targetType != "All Room" && targetType != "All Mic" && targetType != "Selected User") 
                    || targetType == label;
    
    return GestureDetector(
      onTap: () {
        if (label == "Target") {
          final micUsers = GiftLogicHelper.getAllMicUsers(widget.currentSeats);
          GiftLogicHelper.showTargetSelector(
            context: context,
            micUsers: micUsers,
            onSelected: (uid, name) {
              setState(() {
                targetType = name;
                selectedTargetId = uid;
              });
            },
          );
        } else {
          setState(() {
            targetType = label;
            selectedTargetId = null;
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

  Widget _buildGrid(List gifts) {
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, 
        childAspectRatio: 0.85
      ),
      itemCount: gifts.length,
      itemBuilder: (context, index) {
        var gift = gifts[index];
        bool isSelected = selectedGift?['id'] == gift['id'];
        return GestureDetector(
          onTap: () => setState(() => selectedGift = gift),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.pinkAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSelected ? Colors.pinkAccent : Colors.white10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(gift["icon"], height: 40),
                Text("💎 ${gift["price"]}", style: const TextStyle(color: Colors.amber, fontSize: 10)),
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
      color: Colors.white.withOpacity(0.02),
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
              child: Text("x$count", style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          )),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent, 
              shape: const StadiumBorder()
            ),
            onPressed: selectedGift == null ? null : _handleSendAction,
            child: const Text("SEND", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleSendAction() {
    int unitPrice = selectedGift!['price'] as int;
    int totalPrice = unitPrice * selectedCount;
    bool isFree = selectedGift!['type'] == 'free';

    // ১. ব্যালেন্স চেক (ফ্রি হলে চেক করবে না)
    if (!isFree && widget.diamondBalance < totalPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient Diamonds!"), backgroundColor: Colors.redAccent)
      );
      return;
    }

    // ২. লজিক অনুযায়ী ভাগাভাগির হিসাব
    final split = GiftLogicHelper.calculateSplit(totalPrice);

    // ৩. মেইন ফাংশনে ডাটা পাঠানো
    widget.onGiftSend({
      ...selectedGift!,
      'userShare': split['userShare'],      // ইউজার পাবে ৪০%
      'ownerShare': split['ownerShare'],    // মালিক পাবে ১০%
      'isFree': isFree,
      'targetId': selectedTargetId,
    }, selectedCount, targetType);

    // ৪. ফ্রি গিফট হলে লিস্ট থেকে সরিয়ে ফেলা
    if (isFree) {
      setState(() {
        dynamicFreeGifts.removeWhere((g) => g['id'] == selectedGift!['id']);
        selectedGift = null; // সিলেকশন ক্লিয়ার
      });
    }

    Navigator.pop(context);
  }
}
