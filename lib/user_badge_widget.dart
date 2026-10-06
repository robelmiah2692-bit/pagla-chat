import 'package:flutter/material.dart';

class UserBadgeWidget extends StatelessWidget {
  final String gender;
  final String age; // এখানে "25 yrs" বা শুধু সংখ্যা আসতে পারে

  const UserBadgeWidget({super.key, required this.gender, required this.age});

  @override
  Widget build(BuildContext context) {
    // জেন্ডারকে ছোট হাতের করে নিচ্ছি
    String normalizedGender = gender.toLowerCase();
    final bool isMale = normalizedGender == 'male';
    final Color badgeColor = isMale ? Colors.blueAccent : Colors.pinkAccent;

    // গিটহাব থেকে দেওয়া ব্যাজ ফ্রেমের লিংক
    const String badgeFrameUrl = 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/activelavel/yarbadge.webp';

    // age স্ট্রিং থেকে সংখ্যা এবং "yrs" আলাদা করে নেওয়া
    String ageNumber = age.replaceAll(RegExp(r'[^0-9]'), ''); 
    if (ageNumber.isEmpty) ageNumber = age; 

    return Stack(
      alignment: Alignment.center,
      children: [
        // 🌟 ১. ব্যাকগ্রাউন্ডে আপনার গিটহাবের ব্যাজ ফ্রেম (অন্যান্য লেভেলের মতো ৪০x৪০ সাইজ করা হলো)
        SizedBox(
          width: 40,
          height: 40,
          child: Image.network(
            badgeFrameUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
        ),

        // 🌟 ২. ফ্রেমের ভেতরে উপরে জেন্ডার এবং নিচে বয়স ও yrs
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // জেন্ডার আইকন
            Icon(
              isMale ? Icons.male : Icons.female,
              color: badgeColor,
              size: 11,
            ),
            const SizedBox(height: 0.5),
            // বয়সের সংখ্যা
            Text(
              ageNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            // "yrs" লেখাটি ঠিক নিচের লাইনে
            const Text(
              'yrs',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 7,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}