import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1️⃣ রুমের সব ডাটা (নাম, ছবি, লক, ওয়ালপেপার, ফলোয়ার) সেভ রাখা
  Future<void> updateRoomFullData({
    required String roomId,
    required String roomName,
    required String roomImage,
    required bool isLocked,
    required String wallpaper,
    required int followers,
    required int totalDiamonds,
  }) async {
    String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) return;

    try {
      await _firestore.collection('rooms').doc(roomId).set({
        'roomId': roomId,
        'roomName': roomName,
        'roomImage': roomImage,
        'isLocked': isLocked,
        'wallpaper': wallpaper,
        'followerCount': followers,
        'totalDiamonds': totalDiamonds,
        'adminId': uid,
        'isLive': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print("✅ Room Full Data Synced!");
    } catch (e) {
      print("❌ Room Update Error: $e");
    }
  }

  // 2️⃣ সিটে বসার পর প্রোফাইল নাম ও ছবি রিয়েল-টাইম সেভ করা
  Future<void> updateSeatData({
    required String roomId,
    required int seatIndex,
    required String uName,
    required String uImage,
    required bool isOccupied,
  }) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'seats.$seatIndex': {
          'userName': uName,
          'userImage': uImage,
          'isOccupied': isOccupied,
          'uid': _auth.currentUser?.uid,
          'at': DateTime.now().toIso8601String(),
        }
      });
      print("✅ Seat $seatIndex updated with profile!");
    } catch (e) {
      print("❌ Seat Update Error: $e");
    }
  }

  // 3️⃣ ইউজার প্রোফাইল থেকে ডায়মন্ড চেক করার জন্য Stream (অটো আপডেট)
  Stream<DocumentSnapshot> getUserDiamonds() {
    String uid = _auth.currentUser?.uid ?? "";
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // 4️⃣ গিফট লজিক (প্রোফাইল থেকে ডায়মন্ড কাটা ও রুমের ডায়মন্ডে প্লাস করা)
  Future<bool> sendGift({
    required String roomId,
    required int giftValue,
    required String receiverId,
  }) async {
    String senderUid = _auth.currentUser?.uid ?? "";
    if (senderUid.isEmpty) return false;

    try {
      // ইউজারের প্রোফাইল থেকে ব্যালেন্স চেক
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(senderUid).get();
      int currentBalance = (userDoc.data() as Map<String, dynamic>)['diamonds'] ?? 0;

      if (currentBalance >= giftValue) {
        // ক) সেন্ডারের প্রোফাইল থেকে ডায়মন্ড মাইনাস (-) করা
        await _firestore.collection('users').doc(senderUid).update({
          'diamonds': FieldValue.increment(-giftValue),
        });

        // খ) রুমের টোটাল ডায়মন্ডে প্লাস (+) করা (টপ রুম র‍্যাঙ্কিংয়ের জন্য)
        await _firestore.collection('rooms').doc(roomId).update({
          'totalDiamonds': FieldValue.increment(giftValue),
        });

        // গ) রিসিভারের ইনকামে যোগ করা (যদি থাকে)
        if (receiverId.isNotEmpty) {
          await _firestore.collection('users').doc(receiverId).update({
            'receivedDiamonds': FieldValue.increment(giftValue),
          });
        }
        
        print("✅ গিফট সফল! ডায়মন্ড অটো +/- হয়েছে।");
        return true;
      } else {
        print("❌ পর্যাপ্ত ডায়মন্ড নেই!");
        return false;
      }
    } catch (e) {
      print("❌ গিফট এরর: $e");
      return false;
    }
  }

  // 5️⃣ রুম থেকে বের হলে ডাটা ক্লিন
  Future<void> leaveRoom(String roomId) async {
    String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).update({
      'currentRoomId': "",
    });
  }
}
