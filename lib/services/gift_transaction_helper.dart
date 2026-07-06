import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
// RoomLevelHelper ফাইলটি ইমপোর্ট করুন (আপনার প্রজেক্টের পাথ অনুযায়ী)
import 'package:pagla_chat/RoomLevelHelper.dart'; 

class GiftTransactionHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> processGiftTransaction({
    required String senderId,
    required String receiverId,
    required String roomId,
    String senderImage = "", 
    String receiverImage = "", 
    required int totalPrice,
    required bool isFree,
    required String giftName,
  }) async {
    try {
      if (senderId.isEmpty || receiverId.isEmpty) {
        debugPrint("Transaction Cancelled: Sender or Receiver ID is missing.");
        return;
      }

      WriteBatch batch = _firestore.batch();

      if (!isFree && totalPrice > 0) {
        // ১. দাতার (Sender) ডায়মন্ড মাইনাস
        DocumentReference senderRef = _firestore.collection('users').doc(senderId);
        batch.update(senderRef, {'diamonds': FieldValue.increment(-totalPrice)});

        // ২. রিসিভার পাবে ২০%
        if (receiverId != "All Room" && receiverId != "All Mic") {
          int userShare = (totalPrice * 0.20).floor();
          DocumentReference receiverRef = _firestore.collection('users').doc(receiverId);
          batch.update(receiverRef, {'diamonds': FieldValue.increment(userShare)});
        }

        // ৩. রুমের মালিক পাবে ৩%
        var roomDoc = await _firestore.collection('rooms').doc(roomId).get();
        if (roomDoc.exists) {
          int ownerShare = (totalPrice * 0.03).floor();
          String? ownerId = roomDoc.data()?['ownerId'];
          if (ownerId != null && ownerId.isNotEmpty) {
            DocumentReference ownerRef = _firestore.collection('users').doc(ownerId);
            batch.update(ownerRef, {'diamonds': FieldValue.increment(ownerShare)});
          }
        }
      }

      // ৪. গিফট লগ সেভ করা
      DocumentReference logRef = _firestore.collection('gift_logs').doc();
      batch.set(logRef, {
        'senderId': senderId,
        'receiverId': receiverId,
        'roomId': roomId,
        'senderImage': senderImage,
        'receiverImage': receiverImage,
        'giftName': giftName,
        'totalPrice': totalPrice,
        'isFree': isFree,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // ৫. ব্যাচ কমিট করা
      await batch.commit();
      debugPrint("Transaction successful: Receiver 20%, Owner 3%");

      // ৬. গিফট ট্রাঞ্জেকশন সফল হওয়ার পর রুমের XP আপডেট করা
      if (!isFree && totalPrice > 0) {
        await RoomLevelHelper.addXpToRoom(roomId, totalPrice);
        debugPrint("XP updated successfully for room: $roomId");
      }
      
    } catch (e) {
      debugPrint("Transaction Error: $e");
      rethrow; 
    }
  }
}