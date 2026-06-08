import 'package:cloud_firestore/cloud_firestore.dart';

class GiftService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // সোলমেট গিফট এক্সেপ্ট করার লজিক (আপডেট করা)
  Future<void> acceptSoulmateGift({
    required String myId,         // রুম থেকে আসা আপনার লম্বা authUID
    required String myName,
    required String myImg,
    required String friendId,     // রুম থেকে আসা বন্ধুর লম্বা authUID
    required String friendName,
    required String friendImg,
  }) async {
    try {
      print("🚀 [GIFT SERVICE] সোলমেট অ্যারে প্রসেস শুরু হচ্ছে...");

      // ১. লম্বা authUID দিয়ে ৬ ডিজিটের uID খুঁজে বের করা (আপনার আগের লজিক)
      String my6DigitUID = await _getSixDigitId(myId);
      String friend6DigitUID = await _getSixDigitId(friendId);

      WriteBatch batch = _db.batch();

      // ২. নিজের 'soulmates' অ্যারেতে বন্ধুর আইডি যোগ করা
      DocumentReference myUserRef = _db.collection('users').doc(my6DigitUID);
      batch.update(myUserRef, {
        'soulmates': FieldValue.arrayUnion([friend6DigitUID]),
      });

      // ৩. বন্ধুর 'soulmates' অ্যারেতে নিজের আইডি যোগ করা
      DocumentReference friendUserRef = _db.collection('users').doc(friend6DigitUID);
      batch.update(friendUserRef, {
        'soulmates': FieldValue.arrayUnion([my6DigitUID]),
      });

      // ৪. সোলমেট রিকোয়েস্ট ডিলিট করা
      DocumentReference requestRef = _db.collection('soulmate_requests').doc(myId);
      batch.delete(requestRef);

      // ৫. ব্যাচ কমিট করা
      await batch.commit();

      // ৬. ৬টির বেশি হলে রিমুভ করার লিমিট চেক
      await _enforceSoulmateLimit(my6DigitUID);
      await _enforceSoulmateLimit(friend6DigitUID);

      print("✅ [GIFT SERVICE] সোলমেট সফলভাবে অ্যারেতে যোগ হয়েছে!");
    } catch (e) {
      print("❌ [GIFT SERVICE] এরর: $e");
      rethrow;
    }
  }

  // লম্বা আইডি থেকে ৬ ডিজিটের uID বের করার হেল্পার ফাংশন
  Future<String> _getSixDigitId(String authUid) async {
    var query = await _db.collection('users').where('userId', isEqualTo: authUid).get();
    if (query.docs.isEmpty) {
      query = await _db.collection('users').where('authUID', isEqualTo: authUid).get();
    }
    return query.docs.isNotEmpty ? query.docs.first.id : authUid;
  }

  // ৬টির বেশি সোলমেট আইডি হলে প্রথমটি রিমুভ করার ফাংশন
  Future<void> _enforceSoulmateLimit(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return;
    
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<dynamic> list = data['soulmates'] ?? [];
    
    if (list.length > 6) {
      await _db.collection('users').doc(uid).update({
        'soulmates': FieldValue.arrayRemove([list.first])
      });
    }
  }

  // রিকোয়েস্ট রিজেক্ট করার লজিক
  Future<void> rejectSoulmateRequest(String myId) async {
    try {
      await _db.collection('soulmate_requests').doc(myId).delete();
    } catch (e) {
      print("Error rejecting request: $e");
    }
  }
}