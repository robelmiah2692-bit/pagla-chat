import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class DiamondGridItem extends StatelessWidget {
  final String display;
  final String price;
  final VoidCallback onTap;

  const DiamondGridItem({
    Key? key,
    required this.display,
    required this.price,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // এখানে আপনার ডিজাইনের লিংক বসান
    const String designUrl = "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/daimondprice.png";

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.shade700, width: 2), // গোল্ডেন বর্ডার
          image: const DecorationImage(
            image: CachedNetworkImageProvider(designUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.diamond, color: Colors.blueAccent, size: 26),
            const SizedBox(height: 5),
            Text(display, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            Text(price, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}