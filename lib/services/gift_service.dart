import 'package:cloud_firestore/cloud_firestore.dart';

class GiftService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // সোলমেট গিফট এক্সেপ্ট করার লজিক
  Future<void> acceptSoulmateGift(String myId, String myName, String myImg, String friendId, String friendName, String friendImg) async {
    try {
      // ১. আমার সোলমেট হিসেবে বন্ধুকে সেভ করা (আমার প্রোফাইলে শো করার জন্য)
      await _db.collection('soulmates').add({
        'ownerId': myId,
        'partnerId': friendId,
        'partnerName': friendName,
        'partnerImage': friendImg,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ২. বন্ধুর সোলমেট হিসেবে আমাকে সেভ করা (বন্ধুর প্রোফাইলে শো করার জন্য)
      await _db.collection('soulmates').add({
        'ownerId': friendId,
        'partnerId': myId,
        'partnerName': myName,
        'partnerImage': myImg,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
    } catch (e) {
      print("Error saving soulmate: $e");
    }
  }
}
