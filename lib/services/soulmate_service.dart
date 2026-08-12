import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SoulmateService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> breakRelation(String partnerId) async {
    const int breakupCost = 1500;

    try {
      // 🛠️ [FIX] সেফ কারেন্ট ইউজার চেক
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return "লগইন করা নেই!";

      QuerySnapshot userQuery = await _db.collection('users')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) return "ইউজার ডাটা পাওয়া যায়নি!";
      
      var userData = userQuery.docs.first.data() as Map<String, dynamic>;
      String mySixDigitUid = userData['uID'].toString();
      
      // 🛠️ [FIX] ডায়মন্ড স্ট্রিং বা ইন্টিজার যাই হোক না কেন সেফলি পার্স করা
      var diamondVal = userData['diamonds'];
      int myDiamonds = diamondVal is int 
          ? diamondVal 
          : int.tryParse(diamondVal?.toString() ?? "0") ?? 0;

      if (myDiamonds < breakupCost) {
        return "Need 1500 Diamond.";
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
      int calculatedXp = giftAmount ~/ 600;
      if (calculatedXp <= 0) return;

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
      }
    } catch (e) {
      // সাইলেন্টলি হ্যান্ডেল করা হলো
    }
  }
}