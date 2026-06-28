import 'package:flutter/material.dart';

class UserBadgeWidget extends StatelessWidget {
  final String gender;
  final String age;

  const UserBadgeWidget({super.key, required this.gender, required this.age});

  @override
  Widget build(BuildContext context) {
    // জেন্ডারকে ছোট হাতের করে নিচ্ছি যাতে 'Male' বা 'Female' সব সাপোর্ট করে
    String normalizedGender = gender.toLowerCase();
    
    // চেক করছি জেন্ডার কি male কি না
    final bool isMale = normalizedGender == 'male';
    final Color badgeColor = isMale ? Colors.blueAccent : Colors.pinkAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.6), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMale ? Icons.male : Icons.female,
            color: badgeColor,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            age,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}