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
      return "দুঃখিত! বিয়ে শুধুমাত্র বিপরীত লিঙ্গের ইউজারদের মধ্যে সম্ভব。❌";
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
        return "উক্ত ইউজারটি অলরেডি বিবাহিত! উনি সিঙ্গেল না হওয়া পর্যন্ত রিং পাঠানো যাবে না। ❌";
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

  // 🎉 বিয়ে সম্পন্ন করার লজিক (Accept Ring) - [ফিল্ড ট্র্যাকিং ১০০% ফিক্সড করা হয়েছে]
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
      'marriageId': myAuthUID,       // 🆔 ডকুমেন্টের নিজস্ব আইডি ট্র্যাক করার জন্য সেভ করা হলো
      'myAuthUID': myAuthUID,
      'myName': myName,
      'myImage': myImg,
      'profilePic': myImg,           // ব্যাকআপ ফিল্ড হিসেবে প্রোফাইল পিকচার ট্র্যাক করা হলো
      'name': myName,                // ব্যাকআপ ফিল্ড হিসেবে নাম ট্র্যাক করা হলো
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
      'marriageId': friendAuthUID,   // 🆔 পার্টনারের ডকুমেন্টের আইডি
      'myAuthUID': friendAuthUID,
      'myName': friendName,
      'myImage': friendImg,
      'profilePic': friendImg,
      'name': friendName,
      'partnerId': myId,              // ৬ ডিজিটের আইডি
      'partnerAuthUID': myAuthUID,     // লম্বা আইডি
      'partnerName': myName,
      'partnerImage': myImg,
      'ringName': ringName,
      'ringIcon': ringIcon,
      'marriedAt': FieldValue.serverTimestamp(),
    });

    // ৩. পেন্ডিং রিকোয়েস্ট документটি ডিলিট করে দেওয়া (যাতে পপ-আপ চলে যায়)
    DocumentReference requestRef = _db.collection('marriage_requests').doc(myAuthUID);
    batch.delete(requestRef);

    await batch.commit();
    print("✅ Marrige completed and fields synced!");
  }

  // 🔴 রিজেক্ট লজিক (রিকোয়েস্ট কালেকশন থেকে মুছে ফেলা)
  Future<void> rejectMarriageRequest(String myAuthUID) async {
    await _db.collection('marriage_requests').doc(myAuthUID).delete();
  }

  // 💔 ডিভোর্স লজিক (লাল দাগ ফিক্সড এবং ইউআই ট্রানজেকশনের সাথে এলাইন করা হয়েছে)
  Future<String> processDivorce(String partnerAuthUID) async {
    try {
      WriteBatch batch = _db.batch();

      // দুইজনের বিয়ের রেকর্ড সম্পূর্ণ মুছে ফেলা
      batch.delete(_db.collection('marriages').doc(currentAuthUID));
      
      if (partnerAuthUID.isNotEmpty) {
        batch.delete(_db.collection('marriages').doc(partnerAuthUID));
      }

      await batch.commit();
      return "SUCCESS";
    } catch (e) {
      return "eror: $e";
    }
  }
}
