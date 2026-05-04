import 'package:cloud_firestore/cloud_firestore.dart';

class GiftService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // সোলমেট গিফট এক্সেপ্ট করার লজিক (সম্পূর্ণ ও সংশোধিত)
  Future<void> acceptSoulmateGift({
    required String myId,
    required String myName,
    required String myImg,
    required String friendId,
    required String friendName,
    required String friendImg,
  }) async {
    try {
      // একটি ব্যাচ তৈরি করছি যাতে সবগুলো অপারেশন একসাথে হয় (Atomic Operation)
      WriteBatch batch = _db.batch();

      // ১. আমার সোলমেট ডকুমেন্ট (soulmates কালেকশনে আমার আইডিতে সেভ হবে)
      DocumentReference mySoulmateRef = _db.collection('soulmates').doc(myId);
      batch.set(mySoulmateRef, {
        'ownerId': myId,
        'partnerId': friendId,
        'partnerName': friendName,
        'partnerImage': friendImg,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ২. বন্ধুর সোলমেট ডকুমেন্ট (soulmates কালেকশনে তার আইডিতে আমার তথ্য সেভ হবে)
      DocumentReference friendSoulmateRef = _db.collection('soulmates').doc(friendId);
      batch.set(friendSoulmateRef, {
        'ownerId': friendId,
        'partnerId': myId,
        'partnerName': myName,
        'partnerImage': myImg,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ৩. আপনার (সেন্ডার/রিসিভার) ইউজার প্রোফাইল আপডেট
      DocumentReference myUserRef = _db.collection('users').doc(myId);
      batch.update(myUserRef, {
        'hasSoulmate': true,
        'soulmateId': friendId,
      });

      // ৪. বন্ধুর ইউজার প্রোফাইল আপডেট
      DocumentReference friendUserRef = _db.collection('users').doc(friendId);
      batch.update(friendUserRef, {
        'hasSoulmate': true,
        'soulmateId': myId,
      });

      // ৫. সোলমেট রিকোয়েস্টটি এক্সেপ্ট হওয়ার পর সেটি ডিলিট করে দেওয়া
      // (যেহেতু রিকোয়েস্টটি রিসিভারের আইডিতে জমা ছিল)
      DocumentReference requestRef = _db.collection('soulmate_requests').doc(myId);
      batch.delete(requestRef);

      // ব্যাচটি সাবমিট করা
      await batch.commit();
      print("Soulmate successfully established and profile updated!");

    } catch (e) {
      print("Error saving soulmate: $e");
      rethrow; 
    }
  }

  // রিকোয়েস্ট রিজেক্ট করার লজিক (যদি প্রয়োজন হয়)
  Future<void> rejectSoulmateRequest(String myId) async {
    try {
      await _db.collection('soulmate_requests').doc(myId).delete();
      print("Soulmate request rejected.");
    } catch (e) {
      print("Error rejecting request: $e");
    }
  }
}