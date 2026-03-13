import 'package:flutter/material.dart';
import 'package:pagla_chat/services/database_service.dart';
import 'package:pagla_chat/services/gift_logic_helper.dart';

// আপনার তৈরি করা ৪টি আলাদা গিফট ফাইল ইমপোর্ট করা হলো
import 'package:pagla_chat/data/free_gifts.dart';
import 'package:pagla_chat/data/classic_gifts.dart';
import 'package:pagla_chat/data/romantic_gifts.dart';
import 'package:pagla_chat/data/luxury_gifts.dart';

class GiftBottomSheet extends StatefulWidget {
  final int diamondBalance;
  final Function(Map<String, dynamic> gift, int count, String target) onGiftSend;

  const GiftBottomSheet({
    super.key,
    required this.diamondBalance,
    required this.onGiftSend,
  });

  @override
  State<GiftBottomSheet> createState() => _GiftBottomSheetState();
}

class _GiftBottomSheetState extends State<GiftBottomSheet> {
  Map<String, dynamic>? selectedGift;
  int selectedCount = 1;
  String targetType = "Selected User"; 
  final DatabaseService _dbService = DatabaseService();

  // ৪টি ফাইল থেকে সব গিফটকে এখানে একত্রিত করা হয়েছে
  late final List<Map<String, dynamic>> allGifts = [
    ...freeGifts,
    ...classicGifts,
    ...romanticGifts,
    ...luxuryGifts,
  ];

  @override
  Widget build(BuildContext context) {
    // ক্যাটাগরি অনুযায়ী ফিল্টার
    final freeList = allGifts.where((g) => g['type'] == 'free').toList();
    final classicList = allGifts.where((g) => g['type'] == 'classic').toList();
    final romanticList = allGifts.where((g) => g['type'] == 'romantic').toList();
    final luxuryList = allGifts.where((g) => g['type'] == 'luxury').toList();

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
                  _buildGrid(freeList), _buildGrid(classicList),
                  _buildGrid(romanticList), _buildGrid(luxuryList),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // --- হেল্পার উইজেটস (আপনার আগের কোড অনুযায়ী) ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("💎 Balance: ${widget.diamondBalance}", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
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
    bool isSelected = targetType == label;
    return GestureDetector(
      onTap: () {
        if (label == "Target") {
          // গিফট লজিক হেল্পার থেকে টার্গেট সিলেক্টর ওপেন হবে
          GiftLogicHelper.showTargetSelector(
            context: context,
            micUsers: GiftLogicHelper.getAllMicUsers([]), // এখানে আপনার বর্তমান সিট লিস্ট পাঠাতে হবে
            onSelected: (uid, name) {
              setState(() => targetType = name);
            },
          );
        } else {
          setState(() => targetType = label);
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.85),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, shape: const StadiumBorder()),
            onPressed: selectedGift == null ? null : _handleSendAction,
            child: const Text("SEND", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- স্পেশাল গিফট লজিক ---
  void _handleSendAction() {
    int totalPrice = (selectedGift!['price'] as int) * selectedCount;
    
    // ১. যদি গিফট টাইপ 'free' হয়, তবে ডায়মন্ড কাটবে না (যত দামই হোক)
    if (selectedGift!['type'] == 'free') {
      widget.onGiftSend(selectedGift!, selectedCount, targetType);
      Navigator.pop(context);
    } 
    // ২. পেইড গিফট হলে ব্যালেন্স চেক করবে
    else if (widget.diamondBalance >= totalPrice) {
      widget.onGiftSend(selectedGift!, selectedCount, targetType);
      Navigator.pop(context);
    } 
    // ৩. ব্যালেন্স না থাকলে রিচার্জ অপশন বা মেসেজ দেখাবে
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Insufficient Diamonds! Please recharge."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
