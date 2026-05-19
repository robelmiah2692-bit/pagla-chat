import 'package:cloud_firestore/cloud_firestore.dart';

class GiftService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // সোলমেট গিফট এক্সেপ্ট করার লজিক (৬ ডিজিটের uID ও ডায়নামিক ডকুমেন্ট ফিক্সড)
  Future<void> acceptSoulmateGift({
    required String myId,         // রুম থেকে আসা আপনার লম্বা authUID
    required String myName,
    required String myImg,
    required String friendId,     // রুম থেকে আসা বন্ধুর লম্বা authUID
    required String friendName,
    required String friendImg,
  }) async {
    try {
      print("🚀 [GIFT SERVICE] প্রসেস শুরু - লম্বা আইডি দিয়ে ৬ ডিজিটের uID খোঁজা হচ্ছে...");

      // 🔍 ১. লম্বা authUID দিয়ে নিজের ৬ ডিজিটের uID খুঁজে বের করা
      String my6DigitUID = "";
      var myQuery = await _db.collection('users').where('userId', isEqualTo: myId).get();
      if (myQuery.docs.isEmpty) {
        // যদি userId ফিল্ডে না পায়, তবে authUID ফিল্ড দিয়ে খুঁজবে
        myQuery = await _db.collection('users').where('authUID', isEqualTo: myId).get();
      }
      if (myQuery.docs.isNotEmpty) {
        my6DigitUID = myQuery.docs.first.id; // ডকুমেন্টের আসল আইডি (৬ ডিজিটের uID)
      } else {
        my6DigitUID = myId; // ব্যাকআপ
      }

      // 🔍 ২. লম্বা authUID দিয়ে বন্ধুর ৬ ডিজিটের uID খুঁজে বের করা
      String friend6DigitUID = "";
      var friendQuery = await _db.collection('users').where('userId', isEqualTo: friendId).get();
      if (friendQuery.docs.isEmpty) {
        friendQuery = await _db.collection('users').where('authUID', isEqualTo: friendId).get();
      }
      if (friendQuery.docs.isNotEmpty) {
        friend6DigitUID = friendQuery.docs.first.id; // ডকুমেন্টের আসল আইডি (৬ ডিজিটের uID)
      } else {
        friend6DigitUID = friendId; // ব্যাকআপ
      }

      print("🎯 [GIFT SERVICE] আইডি ম্যাপিং সফল! আমার ৬ ডিজিটের ID: $my6DigitUID, বন্ধুর ৬ ডিজিটের ID: $friend6DigitUID");

      WriteBatch batch = _db.batch();

      // ৩. আমার সোলমেট ডকুমেন্ট (৬ ডিজিটের uID দিয়ে সেভ হবে)
      DocumentReference mySoulmateRef = _db.collection('soulmates').doc(my6DigitUID);
      batch.set(mySoulmateRef, {
        'ownerId': my6DigitUID,          // ৬ ডিজিটের uID
        'partnerId': friend6DigitUID,    // ৬ ডিজিটের uID
        'partnerName': friendName,
        'partnerImage': friendImg,
        'status': 'active',
        'totalGift': 0,           
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ৪. বন্ধুর সোলমেট ডকুমেন্ট
      DocumentReference friendSoulmateRef = _db.collection('soulmates').doc(friend6DigitUID);
      batch.set(friendSoulmateRef, {
        'ownerId': friend6DigitUID,        
        'partnerId': my6DigitUID,
        'partnerName': myName,
        'partnerImage': myImg,
        'status': 'active',
        'totalGift': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ৫. আপনার ইউজার প্রোফাইল আপডেট (৬ ডিজিটের ডকুমেন্টে সেট/মার্জ হবে, তাই ক্র্যাশ করবে না)
      DocumentReference myUserRef = _db.collection('users').doc(my6DigitUID);
      batch.set(myUserRef, {
        'hasSoulmate': true,
        'soulmateId': friend6DigitUID,
      }, SetOptions(merge: true));

      // ৬. বন্ধুর ইউজার প্রোফাইল আপডেট
      DocumentReference friendUserRef = _db.collection('users').doc(friend6DigitUID);
      batch.set(friendUserRef, {
        'hasSoulmate': true,
        'soulmateId': my6DigitUID,
      }, SetOptions(merge: true));

      // 🔴 ৭. পেন্ডিং সোলমেট রিকোয়েস্টটি ডিলিট করা (রিকোয়েস্ট লিসেনার লম্বা authUID দিয়ে চলে)
      DocumentReference requestRef = _db.collection('soulmate_requests').doc(myId);
      batch.delete(requestRef);

      // ব্যাচ সাবমিট
      await batch.commit();
      print("✅ [GIFT SERVICE] সোলমেট সফলভাবে সেট হয়েছে এবং ৬ ডিজিটের প্রোফাইল আপডেট হয়েছে!");
    } catch (e) {
      print("❌ [GIFT SERVICE] এরর এসেছে: $e");
      rethrow; 
    }
  }

  // রিকোয়েস্ট রিজেক্ট করার লজিক (লম্বা authUID দিয়ে রিকোয়েস্ট ডিলিট হবে)
  Future<void> rejectSoulmateRequest(String myId) async {
    try {
      await _db.collection('soulmate_requests').doc(myId).delete();
      print("Soulmate request rejected.");
    } catch (e) {
      print("Error rejecting request: $e");
    }
  }
}