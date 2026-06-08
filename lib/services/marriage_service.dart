import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarriageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String currentAuthUID = FirebaseAuth.instance.currentUser!.uid;

  // 💍 বিপরীত লিঙ্গ ভ্যালিডেশন-সহ পেন্ডিং রিং রিকোয়েস্ট পাঠানোর মেথড
  Future<String> sendMarriageRing({
    required String receiverAuthUID,
    required String senderDocID,
    required String senderAuthUID,
    required String senderName,
    required String senderImgUrl,
    required String ringName,
    required String ringIconUrl,
    required String myGender,
    required String partnerGender,
  }) async {
    if (myGender != "Unknown" && partnerGender != "Unknown" && 
        myGender.trim().toLowerCase() == partnerGender.trim().toLowerCase()) {
      return "দুঃখিত! বিয়ে শুধুমাত্র বিপরীত লিঙ্গের ইউজারদের মধ্যে সম্ভব।❌";
    }

    try {
      DocumentSnapshot myMarriageCheck = await _db.collection('marriages').doc(senderAuthUID).get();
      if (myMarriageCheck.exists) {
        return "আপনি অলরেডি বিবাহিত! নতুন কাউকে রিং পাঠাতে হলে আগে ডিভোর্স করতে হবে। ❌";
      }

      DocumentSnapshot receiverMarriageCheck = await _db.collection('marriages').doc(receiverAuthUID).get();
      if (receiverMarriageCheck.exists) {
        return "উক্ত ইউজারটি অলরেডি বিবাহিত! উনি সিঙ্গেল না হওয়া পর্যন্ত রিং পাঠানো যাবে না। ❌";
      }

      await _db.collection('marriage_requests').doc(receiverAuthUID).set({
        'fromId': senderDocID,
        'fromAuthUID': senderAuthUID,
        'fromName': senderName,
        'fromImg': senderImgUrl,
        'ringName': ringName,
        'ringIcon': ringIconUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', 
      });
      return "SUCCESS";
    } catch (e) {
      return "eror: $e";
    }
  }

  // 🎉 বিয়ে সম্পন্ন করার লজিক (Accept Ring) - [পুরান লজিক + ইউজার ফিল্ড সিঙ্ক]
  Future<void> completeMarriage({
    required String myId,
    required String myAuthUID,
    required String myName,
    required String myImg,
    required String friendId,
    required String friendAuthUID,
    required String friendName,
    required String friendImg,
    required String ringName,
    required String ringIcon,
  }) async {
    WriteBatch batch = _db.batch();

    // ১. marriages কালেকশনে ডাটা সেভ
    DocumentReference myMarriageRef = _db.collection('marriages').doc(myAuthUID);
    batch.set(myMarriageRef, {
      'marriageId': myAuthUID,
      'myAuthUID': myAuthUID,
      'myName': myName,
      'myImage': myImg,
      'profilePic': myImg,
      'name': myName,
      'partnerId': friendId,
      'partnerAuthUID': friendAuthUID,
      'partnerName': friendName,
      'partnerImage': friendImg,
      'ringName': ringName,
      'ringIcon': ringIcon,
      'marriedAt': FieldValue.serverTimestamp(),
    });

    DocumentReference partnerMarriageRef = _db.collection('marriages').doc(friendAuthUID);
    batch.set(partnerMarriageRef, {
      'marriageId': friendAuthUID,
      'myAuthUID': friendAuthUID,
      'myName': friendName,
      'myImage': friendImg,
      'profilePic': friendImg,
      'name': friendName,
      'partnerId': myId,
      'partnerAuthUID': myAuthUID,
      'partnerName': myName,
      'partnerImage': myImg,
      'ringName': ringName,
      'ringIcon': ringIcon,
      'marriedAt': FieldValue.serverTimestamp(),
    });

    // ২. [NEW] ইউজারের নিজস্ব ডাটায় ম্যারেজ স্ট্যাটাস আপডেট
    batch.update(_db.collection('users').doc(myId), {
      'isMarried': true,
      'partnerUid': friendAuthUID,
    });

    batch.update(_db.collection('users').doc(friendId), {
      'isMarried': true,
      'partnerUid': myAuthUID,
    });

    // ৩. পেন্ডিং রিকোয়েস্ট ডিলিট
    batch.delete(_db.collection('marriage_requests').doc(myAuthUID));

    await batch.commit();
  }

  // 🔴 রিজেক্ট লজিক
  Future<void> rejectMarriageRequest(String myAuthUID) async {
    await _db.collection('marriage_requests').doc(myAuthUID).delete();
  }

  // 💔 ডিভোর্স লজিক (ইউজার ডাটা থেকে স্ট্যাটাস মুছে ফেলাসহ)
  Future<String> processDivorce(String myId, String partnerId, String partnerAuthUID) async {
    try {
      WriteBatch batch = _db.batch();

      // ১. ম্যারেজ রেকর্ড মুছে ফেলা
      batch.delete(_db.collection('marriages').doc(currentAuthUID));
      batch.delete(_db.collection('marriages').doc(partnerAuthUID));

      // ২. [NEW] ইউজার ডাটা থেকে ম্যারেজ স্ট্যাটাস মুছে ফেলা
      batch.update(_db.collection('users').doc(myId), {
        'isMarried': FieldValue.delete(),
        'partnerUid': FieldValue.delete(),
      });

      batch.update(_db.collection('users').doc(partnerId), {
        'isMarried': FieldValue.delete(),
        'partnerUid': FieldValue.delete(),
      });

      await batch.commit();
      return "SUCCESS";
    } catch (e) {
      return "eror: $e";
    }
  }
}