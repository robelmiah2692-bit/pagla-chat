import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SoulmateService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String myAuthUid = FirebaseAuth.instance.currentUser!.uid;

  Future<String> breakRelation(String partnerId) async {
    const int breakupCost = 1500;

    try {
      QuerySnapshot userQuery = await _db.collection('users')
          .where('uid', isEqualTo: myAuthUid)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) return "ইউজার ডাটা পাওয়া যায়নি!";
      
      var userData = userQuery.docs.first.data() as Map<String, dynamic>;
      String mySixDigitUid = userData['uID'].toString();
      int myDiamonds = userData['diamonds'] ?? 0;

      if (myDiamonds < breakupCost) {
        return "Need 1500 Daimond।";
      }

      await _db.collection('soulmates').doc(mySixDigitUid).delete();
      
      if (partnerId.isNotEmpty) {
        await _db.collection('soulmates').doc(partnerId).delete();
      }

      await _db.collection('users').doc(mySixDigitUid).update({
        'diamonds': FieldValue.increment(-breakupCost)
      });

      return "SUCCESS";
    } catch (e) {
      return "Error: $e";
    }
  }
}

class SoulmateXpService {
  static Future<void> updateSoulmateXP(String senderUid, String receiverUid, int giftAmount) async {
    try {
      // 🎯 ৬০০ ডায়মন্ড খরচ হলে ১ এক্সপি যোগ হবে
      int calculatedXp = giftAmount ~/ 600;
      if (calculatedXp <= 0) return;

      // সেন্ডারের সোলমেট চেক
      var query = await FirebaseFirestore.instance
          .collection('soulmates')
          .where('ownerId', isEqualTo: senderUid)
          .where('partnerId', isEqualTo: receiverUid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        String docId = query.docs.first.id;
        await FirebaseFirestore.instance.collection('soulmates').doc(docId).update({
          'totalGift': FieldValue.increment(calculatedXp),
        });

        // রিসিভার বা পার্টনারের ডকুমেন্ট আপডেট
        var partnerQuery = await FirebaseFirestore.instance
            .collection('soulmates')
            .where('ownerId', isEqualTo: receiverUid)
            .where('partnerId', isEqualTo: senderUid)
            .limit(1)
            .get();

        if (partnerQuery.docs.isNotEmpty) {
          await FirebaseFirestore.instance.collection('soulmates').doc(partnerQuery.docs.first.id).update({
            'totalGift': FieldValue.increment(calculatedXp),
          });
        }
        print("✅ Soulmate XP Updated: +$calculatedXp");
      }
    } catch (e) {
      print("❌ Error updating Soulmate XP: $e");
    }
  }
}