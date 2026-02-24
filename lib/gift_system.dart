import 'package:flutter/material.dart';

class GiftBottomSheet extends StatelessWidget {
  const GiftBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Container(
        height: 450, // গিফট বক্সের উচ্চতা
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E), // ডার্ক ব্যাকগ্রাউন্ড
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
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
            Expanded(
              child: TabBarView(
                children: [
                  _buildGiftGrid("free"),     // পাগলা/ফ্রি গিফট
                  _buildGiftGrid("classic"),  // পুরাতন ১৫টি সস্তা গিফট
                  _buildGiftGrid("romantic"), // এনিমেশন গিফট
                  _buildGiftGrid("luxury"),   // রিং, কার্ড, হার্ট
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // এটি একটি কমন গ্রিড ডিজাইন যা সব ট্যাবে গিফট দেখাবে
  Widget _buildGiftGrid(String category) {
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // এক লাইনে ৪টি গিফট
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      itemCount: 8, // আপাতত টেস্টের জন্য ৮টি করে দিলাম
      itemBuilder: (context, index) {
        return Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.card_giftcard, color: Colors.greenAccent), // এখানে আপনার গিফট ইমেজ হবে
              ),
            ),
            const Text("Gift Name", style: TextStyle(color: Colors.white, fontSize: 10)),
            const Text("10 💎", style: TextStyle(color: Colors.yellow, fontSize: 10)),
          ],
        );
      },
    );
  }
}
