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
      return "ভুল হয়েছে: $e";
    }
  }

  // 🎉 বিয়ে সম্পন্ন করার লজিক (Accept Ring)
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

    // ১. নিজের ম্যারেজ ডাটাবেস আপডেট (লম্বা UID ডকুমেন্টে সেট হচ্ছে, ক্র্যাশ করবে না)
    DocumentReference myMarriageRef = _db.collection('marriages').doc(myAuthUID);
    batch.set(myMarriageRef, {
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
    print("✅ বিয়ের রেকর্ড সফলভাবে দুইজনের প্রোফাইলে সেভ হয়েছে!");
  }

  // 🔴 রিজেক্ট লজিক (রিকোয়েস্ট কালেকশন থেকে মুছে ফেলা)
  Future<void> rejectMarriageRequest(String myAuthUID) async {
    await _db.collection('marriage_requests').doc(myAuthUID).delete();
  }

  // 💔 ডিভোর্স লজিক (২০০০ ডায়মন্ড কেটে রেকর্ড ডিলিট করা)
  Future<String> processDivorce(String partnerAuthUID) async {
    const int divorceCost = 2000;
    
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(currentAuthUID).get();
      int currentDiamonds = userDoc['diamonds'] ?? 0;

      if (currentDiamonds < divorceCost) {
        return "পর্যাপ্ত ডায়মন্ড নেই! ২০০০ ডায়মন্ড প্রয়োজন।";
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
      return "এরর: $e";
    }
  }
}