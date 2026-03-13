import 'package:cloud_firestore/cloud_firestore.dart';

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
      // ১. যদি ফ্রি গিফট না হয়, তবেই ডায়মন্ডের হিসাব হবে
      if (!isFree) {
        // দাতার (Sender) ডায়মন্ড মাইনাস করা
        await _firestore.collection('users').doc(senderId).update({
          'diamonds': FieldValue.increment(-totalPrice),
        });

        // গ্রহীতার (Receiver) ডায়মন্ড যোগ করা (৪০%)
        await _firestore.collection('users').doc(receiverId).update({
          'diamonds': FieldValue.increment(split['userShare']!),
        });

        // মালিকের (Owner) ডায়মন্ড যোগ করা (১০%) - আপনি চাইলে এটি একটি আলাদা কালেকশনেও রাখতে পারেন
        await _firestore.collection('admin_stats').doc('revenue').update({
          'ownerCommission': FieldValue.increment(split['ownerShare']!),
        });
      }

      // ২. গিফট হিস্ট্রি সেভ করা (ঐচ্ছিক কিন্তু জরুরি)
      await _firestore.collection('gift_logs').add({
        'senderId': senderId,
        'receiverId': receiverId,
        'giftName': giftName,
        'amount': totalPrice,
        'isFree': isFree,
        'timestamp': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print("Error in Gift Transaction: $e");
    }
  }
}
