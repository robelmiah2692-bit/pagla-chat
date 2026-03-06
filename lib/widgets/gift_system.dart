import 'package:flutter/material.dart';
import 'package:pagla_chat/services/database_service.dart';

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
  String targetType = "Selected User"; // All Room, All Mic, Selected User
final DatabaseService _dbService = DatabaseService();
  // ওস্তাদ, এখানে আপনার ১০টি ফ্রি গিফট এবং ডায়মন্ড গিফট লিস্ট
  final List<Map<String, dynamic>> allGifts = [
    {"id": "f1", "icon": "https://cdn-icons-png.flaticon.com/128/744/744502.png", "price": 0, "type": "free"},
    {"id": "f2", "icon": "https://cdn-icons-png.flaticon.com/128/2559/2559915.png", "price": 0, "type": "free"},
    {"id": "f3", "icon": "https://cdn-icons-png.flaticon.com/128/1041/1041888.png", "price": 0, "type": "free"},
    {"id": "f4", "icon": "https://cdn-icons-png.flaticon.com/128/1922/1922714.png", "price": 0, "type": "free"},
    {"id": "f5", "icon": "https://cdn-icons-png.flaticon.com/128/2164/2164589.png", "price": 0, "type": "free"},
    {"id": "c1", "icon": "https://cdn-icons-png.flaticon.com/128/1161/1161388.png", "price": 10, "type": "classic"},
    {"id": "c2", "icon": "https://cdn-icons-png.flaticon.com/128/9405/9405825.png", "price": 20, "type": "classic"},
    {"id": "r1", "icon": "https://cdn-icons-png.flaticon.com/128/4359/4359295.png", "price": 30, "type": "romantic"},
    {"id": "r2", "icon": "https://cdn-icons-png.flaticon.com/128/2904/2904973.png", "price": 50, "type": "romantic"},
    {"id": "l1", "icon": "https://cdn-icons-png.flaticon.com/128/1152/1152912.png", "price": 100, "type": "luxury"},
  ];

  @override
  Widget build(BuildContext context) {
    final freeGifts = allGifts.where((g) => g['type'] == 'free').toList();
    final classicGifts = allGifts.where((g) => g['type'] == 'classic').toList();
    final romanticGifts = allGifts.where((g) => g['type'] == 'romantic').toList();
    final luxuryGifts = allGifts.where((g) => g['type'] == 'luxury').toList();

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
                  _buildGrid(freeGifts), _buildGrid(classicGifts),
                  _buildGrid(romanticGifts), _buildGrid(luxuryGifts),
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
      onTap: () => setState(() => targetType = label),
      child: Container(
        margin: const EdgeInsets.only(right:10),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, shape: StadiumBorder()),
            onPressed: selectedGift == null ? null : () {
              widget.onGiftSend(selectedGift!, selectedCount, targetType);
              Navigator.pop(context);
            },
            child: const Text("SEND", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
