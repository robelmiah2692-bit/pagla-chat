import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SoulmateService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> breakRelation(String partnerId) async {
    const int breakupCost = 50000;

    try {
      // 🛠️ সেফ কারেন্ট ইউজার চেক
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return "লগইন করা নেই!";

      // ১. কারেন্ট ইউজারের ফায়ারস্টোর ডকুমেন্ট খুঁজে বের করা
      QuerySnapshot userQuery = await _db
          .collection('users')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      DocumentSnapshot myUserDoc;
      if (userQuery.docs.isNotEmpty) {
        myUserDoc = userQuery.docs.first;
      } else {
        myUserDoc = await _db.collection('users').doc(user.uid).get();
        if (!myUserDoc.exists) return "ইউজার ডাটা পাওয়া যায়নি!";
      }

      String myDocId = myUserDoc.id;
      var userData = myUserDoc.data() as Map<String, dynamic>;

      String mySixDigitUid = userData['uID']?.toString() ?? '';
      String myAuthUid = user.uid;

      // ২. ডায়মন্ড ব্যালেন্স চেক করা
      var diamondVal = userData['diamonds'];
      int myDiamonds = diamondVal is int
          ? diamondVal
          : int.tryParse(diamondVal?.toString() ?? "0") ?? 0;

      if (myDiamonds < breakupCost) {
        return "Need 50000 Diamond.";
      }

      // ৩. রাইট ব্যাচ (WriteBatch) শুরু করা
      WriteBatch batch = _db.batch();

      // ✅ নিজের একাউন্ট থেকে ডায়মন্ড কাটা এবং soulmates অ্যারে থেকে পার্টনার আইডি রিমুভ করা
      DocumentReference myUserRef = _db.collection('users').doc(myDocId);
      batch.update(myUserRef, {
        'diamonds': FieldValue.increment(-breakupCost),
        'soulmates': FieldValue.arrayRemove([partnerId]),
      });

      // ✅ পার্টনারের একাউন্টের soulmates অ্যারে থেকেও নিজের আইডি রিমুভ করা
      if (partnerId.isNotEmpty) {
        DocumentReference partnerRef = _db.collection('users').doc(partnerId);
        DocumentSnapshot partnerDoc = await partnerRef.get();

        if (partnerDoc.exists) {
          batch.update(partnerRef, {
            'soulmates': FieldValue.arrayRemove([mySixDigitUid, myAuthUid, myDocId]),
          });
        } else {
          // partnerId টি যদি ডিরেক্ট doc ID না হয়ে uID বা uid হয়
          QuerySnapshot partnerQuery = await _db
              .collection('users')
              .where('uID', isEqualTo: partnerId)
              .limit(1)
              .get();

          if (partnerQuery.docs.isEmpty) {
            partnerQuery = await _db
                .collection('users')
                .where('uid', isEqualTo: partnerId)
                .limit(1)
                .get();
          }

          if (partnerQuery.docs.isNotEmpty) {
            DocumentReference foundPartnerRef = partnerQuery.docs.first.reference;
            batch.update(foundPartnerRef, {
              'soulmates': FieldValue.arrayRemove([mySixDigitUid, myAuthUid, myDocId]),
            });
          }
        }

        // পুরানো লজিক অনুযায়ী 'soulmates' কালেকশন থেকে ডকুমেন্ট ডিলিট
        batch.delete(_db.collection('soulmates').doc(mySixDigitUid));
        batch.delete(_db.collection('soulmates').doc(partnerId));
      }

      // ব্যাচ এক্সিকিউট করা
      await batch.commit();

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
          'soulmateTotalGift': FieldValue.increment(calculatedXp),
        });

        var partnerQuery = await FirebaseFirestore.instance
            .collection('soulmates')
            .where('ownerId', isEqualTo: receiverUid)
            .where('partnerId', isEqualTo: senderUid)
            .limit(1)
            .get();

        if (partnerQuery.docs.isNotEmpty) {
          await FirebaseFirestore.instance.collection('soulmates').doc(partnerQuery.docs.first.id).update({
            'soulmateTotalGift': FieldValue.increment(calculatedXp),
          });
        }
      }
    } catch (e) {
      // সাইলেন্টলি হ্যান্ডেল করা হলো
    }
  }
}