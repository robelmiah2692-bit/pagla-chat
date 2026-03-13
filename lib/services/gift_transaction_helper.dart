import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class GiftTransactionHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> processGiftTransaction({
    required String senderId,
    required String receiverId,
    required int totalPrice,
    required Map<String, int> split,
    required bool isFree,
    required String giftName,
  }) async {
    try {
      // যদি ফ্রি গিফট না হয় তবেই ব্যালেন্স কাটবে
      if (!isFree && totalPrice > 0) {
        
        WriteBatch batch = _firestore.batch();

        // ১. দাতার আইডি থেকে ডায়মন্ড মাইনাস করা
        DocumentReference senderRef = _firestore.collection('users').doc(senderId);
        batch.update(senderRef, {
          'diamonds': FieldValue.increment(-totalPrice),
        });

        // ২. গ্রহীতার আইডিতে ৪০% ডায়মন্ড যোগ করা
        DocumentReference receiverRef = _firestore.collection('users').doc(receiverId);
        batch.update(receiverRef, {
          'diamonds': FieldValue.increment(split['userShare'] ?? 0),
        });

        // ৩. এডমিন স্ট্যাটসে ১০% কমিশন রেকর্ড করা
        DocumentReference adminRef = _firestore.collection('admin_stats').doc('revenue');
        batch.set(adminRef, {
          'ownerCommission': FieldValue.increment(split['ownerShare'] ?? 0),
          'lastUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // ৪. গিফট লগ তৈরি করা
        DocumentReference logRef = _firestore.collection('gift_logs').doc();
        batch.set(logRef, {
          'senderId': senderId,
          'receiverId': receiverId,
          'giftName': giftName,
          'totalPrice': totalPrice,
          'isFree': isFree,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // সব কাজ একসাথে সাবমিট করা
        await batch.commit();
      }
    } catch (e) {
      debugPrint("Error in Gift Transaction: $e");
    }
  }
}
