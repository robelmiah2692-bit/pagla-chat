import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarriageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String currentAuthUID = FirebaseAuth.instance.currentUser!.uid;

  // 💍 বিপরীত লিঙ্গ ভ্যালিডেশন-সহ পেন্ডিং রিং রিকোয়েস্ট পাঠানোর মেথড (fromAuthUID ফিক্সড)
  Future<String> sendMarriageRing({
    required String receiverAuthUID, // রিসিভারের লম্বা ফায়ারবেস UID
    required String senderDocID,     // আপনার ৬ ডিজিটের uID
    required String senderAuthUID,    // 🔥 আপনার লম্বা authUID
    required String senderName,
    required String senderImgUrl,
    required String ringName,
    required String ringIconUrl,
    required String myGender,
    required String partnerGender,
  }) async {
    // ❌ একই লিঙ্গের জুটি হলে বিয়ে বা রিং পাঠানো যাবে না
    if (myGender != "Unknown" && partnerGender != "Unknown" && 
        myGender.trim().toLowerCase() == partnerGender.trim().toLowerCase()) {
      return "দুঃখিত! বিয়ে শুধুমাত্র বিপরীত লিঙ্গের ইউজারদের মধ্যে সম্ভব। ❌";
    }

    try {
      // ❌ নতুন লজিক: চেক করা হচ্ছে আপনি নিজে অলরেডি বিবাহিত কিনা
      DocumentSnapshot myMarriageCheck = await _db.collection('marriages').doc(senderAuthUID).get();
      if (myMarriageCheck.exists) {
        return "আপনি অলরেডি বিবাহিত! নতুন কাউকে রিং পাঠাতে হলে আগে ডিভোর্স করতে হবে। ❌";
      }

      // ❌ নতুন লজিক: চেক করা হচ্ছে রিসিভার অলরেডি বিবাহিত কিনা
      DocumentSnapshot receiverMarriageCheck = await _db.collection('marriages').doc(receiverAuthUID).get();
      if (receiverMarriageCheck.exists) {
        return "উক্ত ইউজারটি অলরেডি বিবাহিত! উনি সিঙ্গেল না হওয়া পর্যন্ত রিং পাঠানো যাবে না। ❌";
      }

      // রিসিভারের লম্বা আইডির ডকুমেন্টে 'pending' রিকোয়েস্ট তৈরি হবে
      await _db.collection('marriage_requests').doc(receiverAuthUID).set({
        'fromId': senderDocID, // ৬ ডিজিটের uID
        'fromAuthUID': senderAuthUID, // 🔥 ফিক্স: আপনার নিজের লম্বা আইডি সেভ হলো যা এক্সেপ্ট করতে লাগবে!
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

  // 🎉 বিয়ে সম্পন্ন করার লজিক (Accept Ring) - [পুরাতন প্যারামিটার ১০০% অক্ষত রাখা হয়েছে]
  Future<void> completeMarriage({
    required String myId,          // নিজের ৬ ডিজিটের uID
    required String myAuthUID,     // নিজের লম্বা authUID
    required String myName,
    required String myImg,
    required String friendId,      // পার্টনারের ৬ ডিজিটের uID
    required String friendAuthUID,  // পার্টনারের লম্বা authUID
    required String friendName,
    required String friendImg,
    required String ringName,
    required String ringIcon,
  }) async {
    WriteBatch batch = _db.batch();

    // ১. নিজের ম্যারেজ ডাটাবেস আপডেট (বটমশিটের জন্য নিজের নাম ও ইমেজসহ ডকে সেভ হচ্ছে)
    DocumentReference myMarriageRef = _db.collection('marriages').doc(myAuthUID);
    batch.set(myMarriageRef, {
      'myAuthUID': myAuthUID,
      'myName': myName,
      'myImage': myImg,
      'partnerId': friendId,          // ৬ ডিজিটের আইডি
      'partnerAuthUID': friendAuthUID, // লম্বা আইডি
      'partnerName': friendName,
      'partnerImage': friendImg,
      'ringName': ringName,
      'ringIcon': ringIcon,
      'marriedAt': FieldValue.serverTimestamp(),
    });

    // ২. পার্টনারের ম্যারেজ ডাটাবেস আপডেট
    DocumentReference partnerMarriageRef = _db.collection('marriages').doc(friendAuthUID);
    batch.set(partnerMarriageRef, {
      'myAuthUID': friendAuthUID,
      'myName': friendName,
      'myImage': friendImg,
      'partnerId': myId,              // ৬ ডিজিটের আইডি
      'partnerAuthUID': myAuthUID,     // লম্বা আইডি
      'partnerName': myName,
      'partnerImage': myImg,
      'ringName': ringName,
      'ringIcon': ringIcon,
      'marriedAt': FieldValue.serverTimestamp(),
    });

    // ৩. সোলমেটের মতো পেন্ডিং রিকোয়েস্ট ডকুমেন্টটি ডিলিট করে দেওয়া (যাতে পপ-আপ চলে যায়)
    DocumentReference requestRef = _db.collection('marriage_requests').doc(myAuthUID);
    batch.delete(requestRef);

    await batch.commit();
    print("✅ Marrige complited!");
  }

  // 🔴 রিজেক্ট লজিক (রিকোয়েস্ট কালেকশন থেকে মুছে ফেলা)
  Future<void> rejectMarriageRequest(String myAuthUID) async {
    await _db.collection('marriage_requests').doc(myAuthUID).delete();
  }

  // 💔 ডিভোর্স লজিক (২০০০ ডায়মন্ড কেটে রেকর্ড ডিলিট করা)
  Future<String> processDivorce(String partnerAuthUID) async {
    const int divorceCost = 3000;
    
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(currentAuthUID).get();
      int currentDiamonds = userDoc['diamonds'] ?? 0;

      if (currentDiamonds < divorceCost) {
        return "need 3000 Diamond।";
      }

      WriteBatch batch = _db.batch();

      // ডায়মন্ড কেটে নেওয়া
      DocumentReference userRef = _db.collection('users').doc(currentAuthUID);
      batch.update(userRef, {
        'diamonds': FieldValue.increment(-divorceCost)
      });

      // দুইজনের বিয়ের রেকর্ড মুছে ফেলা
      batch.delete(_db.collection('marriages').doc(currentAuthUID));
      batch.delete(_db.collection('marriages').doc(partnerAuthUID));

      await batch.commit();
      return "SUCCESS";
    } catch (e) {
      return "eror: $e";
    }
  }
}