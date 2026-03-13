import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class GiftTransactionHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> processGiftTransaction({
    required String senderId,
    required String receiverId,
    required int totalPrice,
    required bool isFree,
    required String giftName,
  }) async {
    try {
      // আইডি চেক: আইডি না থাকলে ট্রানজ্যাকশন সম্ভব না
      if (receiverId.isEmpty || receiverId == "ALL") {
        debugPrint("Transaction Skipped: Receiver ID is empty or 'ALL'");
        return;
      }

      WriteBatch batch = _firestore.batch();

      // ১. যদি পেইড গিফট হয় (ফ্রি না হয়)
      if (!isFree && totalPrice > 0) {
        int userShare = (totalPrice * 0.40).floor(); // ৪০% গ্রহীতা পাবে
        int ownerShare = (totalPrice * 0.10).floor(); // ১০% মালিক পাবে

        // দাতার (Sender) ডায়মন্ড মাইনাস
        DocumentReference senderRef = _firestore.collection('users').doc(senderId);
        batch.update(senderRef, {
          'diamonds': FieldValue.increment(-totalPrice),
        });

        // গ্রহীতার (Receiver) ডায়মন্ড যোগ (৪০%)
        DocumentReference receiverRef = _firestore.collection('users').doc(receiverId);
        batch.update(receiverRef, {
          'diamonds': FieldValue.increment(userShare),
        });

        // এডমিন স্ট্যাটসে কমিশন রেকর্ড (১০%)
        DocumentReference adminRef = _firestore.collection('admin_stats').doc('revenue');
        batch.set(adminRef, {
          'ownerCommission': FieldValue.increment(ownerShare),
          'lastUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } 
      // ২. যদি ফ্রি গিফট হয় (আপনি যদি চান ফ্রি গিফটেও গ্রহীতা কিছু পাক)
      else if (isFree) {
        // ইচ্ছে করলে এখানে গ্রহীতাকে ১ ডায়মন্ড বোনাস দিতে পারেন
        // DocumentReference receiverRef = _firestore.collection('users').doc(receiverId);
        // batch.update(receiverRef, {'diamonds': FieldValue.increment(0)}); 
      }

      // ৩. গিফট লগ সেভ করা (ফ্রি বা পেইড সব সময় লগ হবে)
      DocumentReference logRef = _firestore.collection('gift_logs').doc();
      batch.set(logRef, {
        'senderId': senderId,
        'receiverId': receiverId,
        'giftName': giftName,
        'totalPrice': totalPrice,
        'isFree': isFree,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      debugPrint("Gift Transaction Successful: $giftName sent to $receiverId");

    } catch (e) {
      debugPrint("Gift Transaction Error: $e");
    }
  }
}
