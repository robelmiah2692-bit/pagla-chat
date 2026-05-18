import 'package:cloud_firestore/cloud_firestore.dart';

class GiftService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // সোলমেট গিফট এক্সেপ্ট করার লজিক (সংশোধিত ও ফিক্সড)
  Future<void> acceptSoulmateGift({
    required String myId,
    required String myName,
    required String myImg,
    required String friendId,
    required String friendName,
    required String friendImg,
  }) async {
    try {
      WriteBatch batch = _db.batch();

      // ১. আমার সোলমেট ডকুমেন্ট (আমার আইডিতে সেভ হবে)
      DocumentReference mySoulmateRef = _db.collection('soulmates').doc(myId);
      batch.set(mySoulmateRef, {
        'ownerId': myId,          // 🔥 প্রোফাইলের Where কুয়েরির জন্য এটি বাধ্যতামূলক
        'partnerId': friendId,
        'partnerName': friendName,
        'partnerImage': friendImg,
        'status': 'active',
        'totalGift': 0,           // লেভেল লজিকের জন্য ডিফল্ট ০ পয়েন্ট
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ২. বন্ধুর সোলমেট ডকুমেন্ট (বন্ধুর আইডিতে আমার তথ্য সেভ হবে)
      DocumentReference friendSoulmateRef = _db.collection('soulmates').doc(friendId);
      batch.set(friendSoulmateRef, {
        'ownerId': friendId,        // 🔥 প্রোফাইলের Where কুয়েরির জন্য এটি বাধ্যতামূলক
        'partnerId': myId,
        'partnerName': myName,
        'partnerImage': myImg,
        'status': 'active',
        'totalGift': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ৩. আপনার ইউজার প্রোফাইল আপডেট
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

      // ৫. সোলমেট রিকোয়েস্টটি এক্সেপ্ট হওয়ার পর ডিলিট করা
      DocumentReference requestRef = _db.collection('soulmate_requests').doc(myId);
      batch.delete(requestRef);

      await batch.commit();
      print("Soulmate successfully established and profile updated!");
    } catch (e) {
      print("Error saving soulmate: $e");
      rethrow; 
    }
  }

  // রিকোয়েস্ট রিজেক্ট করার লজিক
  Future<void> rejectSoulmateRequest(String myId) async {
    try {
      await _db.collection('soulmate_requests').doc(myId).delete();
      print("Soulmate request rejected.");
    } catch (e) {
      print("Error rejecting request: $e");
    }
  }
}