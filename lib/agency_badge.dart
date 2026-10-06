import 'package:flutter/material.dart';

class AgencyBadgeWidget extends StatelessWidget {
  final bool isAgent;
  final String imageUrl;

  const AgencyBadgeWidget({
    super.key,
    required this.isAgent,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAgent) {
      return const SizedBox.shrink();
    }

    // কোনো ব্যাকগ্রাউন্ড বা বর্ডার ছাড়াই সরাসরি ইমেজ সাইজ রিটার্ন করা হলো
    return SizedBox(
      width: 32, 
      height: 18, 
      child: Image.network(
        imageUrl,
        fit: BoxFit.fill, // ইমেজটি টেনে পুরো সাইজ পূর্ণ করবে
        filterQuality: FilterQuality.high, // ইমেজ শার্প দেখানোর জন্য
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) => 
            const Icon(
              Icons.business_center, 
              color: Color.fromARGB(255, 112, 212, 248), 
              size: 18,
            ),
      ),
    );
  }
}