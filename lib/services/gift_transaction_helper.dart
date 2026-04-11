import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class GiftTransactionHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> processGiftTransaction({
    required String senderId,
    required String receiverId,
    required String roomId, // রুম আইডি লাগবে যাতে মালিককে খুঁজে পাওয়া যায়
    required int totalPrice,
    required bool isFree,
    required String giftName,
  }) async {
    try {
      if (receiverId.isEmpty || receiverId == "ALL") {
        debugPrint("Transaction Skipped: Receiver ID is empty or 'ALL'");
        return;
      }

      WriteBatch batch = _firestore.batch();

      // ১. যদি পেইড গিফট হয়
      if (!isFree && totalPrice > 0) {
        int userShare = (totalPrice * 0.40).floor();  // ৪০% গ্রহীতা পাবে
        int ownerShare = (totalPrice * 0.10).floor(); // ১০% রুমের মালিক পাবে

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

        // --- রুমের মালিকের কমিশন লজিক ---
        // প্রথমে রুমের ডাটা থেকে ownerId খুঁজে বের করা
        var roomDoc = await _firestore.collection('rooms').doc(roomId).get();
        if (roomDoc.exists) {
          String? ownerId = roomDoc.data()?['ownerId'];
          if (ownerId != null && ownerId.isNotEmpty) {
            DocumentReference ownerRef = _firestore.collection('users').doc(ownerId);
            batch.update(ownerRef, {
              'diamonds': FieldValue.increment(ownerShare),
            });
            debugPrint("Room Owner ($ownerId) received $ownerShare diamonds");
          }
        }
      } 
      
      // ২. গিফট লগ সেভ করা
      DocumentReference logRef = _firestore.collection('gift_logs').doc();
      batch.set(logRef, {
        'senderId': senderId,
        'receiverId': receiverId,
        'roomId': roomId,
        'giftName': giftName,
        'totalPrice': totalPrice,
        'isFree': isFree,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      debugPrint("Gift Transaction Successful: $giftName sent");

    } catch (e) {
      debugPrint("Gift Transaction Error: $e");
    }
  }
}
