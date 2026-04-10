import 'package:cloud_firestore/cloud_firestore.dart';

class GiftService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // সোলমেট গিফট এক্সেপ্ট করার লজিক
  Future<void> acceptSoulmateGift({
    required String myId,
    required String myName,
    required String myImg,
    required String friendId,
    required String friendName,
    required String friendImg,
  }) async {
    try {
      // একটি ব্যাচ তৈরি করছি যাতে দুটি অপারেশনই একসাথে হয়
      WriteBatch batch = _db.batch();

      // ১. আমার সোলমেট ডকুমেন্ট (Doc ID হিসেবে myId ব্যবহার করছি যাতে আমার একটাই সোলমেট থাকে)
      DocumentReference mySoulmateRef = _db.collection('soulmates').doc(myId);
      batch.set(mySoulmateRef, {
        'ownerId': myId,
        'partnerId': friendId,
        'partnerName': friendName,
        'partnerImage': friendImg,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ২. বন্ধুর সোলমেট ডকুমেন্ট
      DocumentReference friendSoulmateRef = _db.collection('soulmates').doc(friendId);
      batch.set(friendSoulmateRef, {
        'ownerId': friendId,
        'partnerId': myId,
        'partnerName': myName,
        'partnerImage': myImg,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ব্যাচটি সাবমিট করা
      await batch.commit();
      print("Soulmate successfully established!");

    } catch (e) {
      print("Error saving soulmate: $e");
      rethrow; // এররটি হ্যান্ডেল করার জন্য উপরের লেভেলে পাঠিয়ে দেওয়া
    }
  }
}
