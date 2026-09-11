import 'package:cloud_firestore/cloud_firestore.dart';

class SoulmateXpService {
  static Future<void> updateSoulmateXP(String senderSixDigitUid, String receiverSixDigitUid, int giftAmount) async {
    try {
      int calculatedXp = giftAmount ~/ 600;
      
      if (calculatedXp <= 0) {
        return;
      }

      final firestore = FirebaseFirestore.instance;

      var senderDoc = await firestore.collection('users').doc(senderSixDigitUid).get();
      
      if (!senderDoc.exists) {
        return;
      }

      List<dynamic> senderSoulmates = senderDoc.data()?['soulmates'] ?? [];

      if (senderSoulmates.contains(receiverSixDigitUid)) {
        await firestore.collection('users').doc(senderSixDigitUid).update({
          'soulmateTotalGift': FieldValue.increment(calculatedXp),
        });

        await firestore.collection('users').doc(receiverSixDigitUid).update({
          'soulmateTotalGift': FieldValue.increment(calculatedXp),
        });
      }
    } catch (e) {
      // সাইলেন্টলি হ্যান্ডেল করা হলো
    }
  }
}