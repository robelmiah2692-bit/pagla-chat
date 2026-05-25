import 'package:cloud_firestore/cloud_firestore.dart';

class SoulmateXpService {
  static Future<void> updateSoulmateXP(String senderSixDigitUid, String receiverSixDigitUid, int giftAmount) async {
    try {
      // ৬০০ ডায়মন্ডে ১ XP (totalGift) লজিক
      int calculatedXp = giftAmount ~/ 600;
      if (calculatedXp <= 0) return;

      final firestore = FirebaseFirestore.instance;

      // সেন্ডারের সোলমেট ডকুমেন্ট আপডেট
      var senderDoc = await firestore.collection('soulmates').doc(senderSixDigitUid).get();
      if (senderDoc.exists) {
        await firestore.collection('soulmates').doc(senderSixDigitUid).update({
          'totalGift': FieldValue.increment(calculatedXp),
        });
      }

      // রিসিভারের সোলমেট ডকুমেন্ট আপডেট
      var partnerDoc = await firestore.collection('soulmates').doc(receiverSixDigitUid).get();
      if (partnerDoc.exists) {
        await firestore.collection('soulmates').doc(receiverSixDigitUid).update({
          'totalGift': FieldValue.increment(calculatedXp),
        });
      }
    } catch (e) {
      print("❌ Error updating Soulmate XP: $e");
    }
  }
}