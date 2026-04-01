/*import 'package:cloud_firestore/cloud_firestore.dart';

class VipService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// রিচার্জ করার পর এই ফাংশনটি কল করবেন
  static Future<void> addRechargeXP(String userId, int diamondAmount) async {
    // ২৫০ ডায়মন্ডে ১ XP
    int gainedXP = diamondAmount ~/ 250;

    if (gainedXP > 0) {
      // ২ মাস (৬০ দিন) মেয়াদ সেট করা
      int expiryDate = DateTime.now().add(const Duration(days: 60)).millisecondsSinceEpoch;

      await _firestore.collection('users').doc(userId).update({
        'xp': FieldValue.increment(gainedXP),
        'vipExpiry': expiryDate,
      });
    }
  }

  /// ইউজার বর্তমানে কোন লেভেলে আছে তা জানার জন্য
  static int calculateVipLevel(int xp, int expiry) {
    int currentTime = DateTime.now().millisecondsSinceEpoch;

    // যদি মেয়াদ শেষ হয়ে যায় তবে VIP ০ (সাধারণ ইউজার)
    if (currentTime > expiry) {
      return 0;
    }

    if (xp >= 35000) return 8;
    if (xp >= 30000) return 7;
    if (xp >= 25000) return 6;
    if (xp >= 20000) return 5;
    if (xp >= 13000) return 4;
    if (xp >= 9000)  return 3;
    if (xp >= 5000)  return 2;
    if (xp >= 2500)  return 1;
    
    return 0;
  }
}
