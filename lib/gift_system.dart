import 'package:flutter/material.dart';

class GiftBottomSheet extends StatelessWidget {
  final int diamondBalance;
  final List gifts;
  final Function(Map) onGiftSend;

  const GiftBottomSheet({
    super.key,
    required this.diamondBalance,
    required this.gifts,
    required this.onGiftSend,
  });

  @override
  Widget build(BuildContext context) {
    // আপনার লিস্ট থেকে ক্যাটাগরি অনুযায়ী ভাগ করা
    final freeGifts = gifts.where((g) => g['price'] == 0).toList();
    final classicGifts = gifts.where((g) => g['price'] > 0 && g['price'] <= 50).toList();
    final romanticGifts = gifts.where((g) => (g['type'] ?? '') == 'romantic').toList();
    final luxuryGifts = gifts.where((g) => (g['type'] ?? '') == 'luxury').toList();

    return DefaultTabController(
      length: 4,
      child: Container(
        height: 500,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            // ব্যালেন্স বার
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                    child: Text("💎 ব্যালেন্স: $diamondBalance", 
                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ),
                  const Text("উপহার চয়ন করুন", style: TextStyle(color: Colors.white, fontSize: 16)),
                  const Icon(Icons.history, color: Colors.white38),
                ],
              ),
            ),
            
            // আপনার পছন্দের ৪টি নাম
            const TabBar(
              isScrollable: true,
              indicatorColor: Colors.greenAccent,
              labelColor: Colors.greenAccent,
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(text: "Free Gift"),
                Tab(text: "Classic Gift"),
                Tab(text: "Romantic Gift"),
                Tab(text: "Luxury Heart"),
              ],
            ),
            const Divider(color: Colors.white10),

            Expanded(
              child: TabBarView(
                children: [
                  _buildGrid(context, freeGifts),
                  _buildGrid(context, classicGifts),
                  _buildGrid(context, romanticGifts),
                  _buildGrid(context, luxuryGifts),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List filteredGifts) {
    if (filteredGifts.isEmpty) {
      return const Center(child: Text("এই ক্যাটাগরিতে কোনো গিফট নেই", style: TextStyle(color: Colors.white24)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: filteredGifts.length,
      itemBuilder: (context, index) {
        var gift = filteredGifts[index];
        return GestureDetector(
          onTap: () {
            onGiftSend(gift);
            Navigator.pop(context); 
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(gift["icon"], height: 45, errorBuilder: (c, e, s) => const Icon(Icons.card_giftcard, color: Colors.white24)),
                const SizedBox(height: 5),
                Text("💎 ${gift["price"]}", style: const TextStyle(color: Colors.amber, fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }
}
