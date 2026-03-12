import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

class MarriageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String myUid = FirebaseAuth.instance.currentUser!.uid;

  // রিং পাঠানোর লজিক (জেন্ডার চেক-সহ)
  Future<String> sendMarriageRing(String partnerId, String myGender, String partnerGender) async {
    // ✅ শুধু পুরুষ-মহিলা জুটি হতে হবে
    if (myGender == partnerGender) {
      return "দুঃখিত! বিয়ে শুধুমাত্র বিপরীত লিঙ্গের ইউজারদের মধ্যে সম্ভব।";
    }

    try {
      await _db.collection('marriage_requests').doc(partnerId).set({
        'fromId': myUid,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      return "রিং পাঠানো হয়েছে! উত্তরের অপেক্ষায় থাকুন।";
    } catch (e) {
      return "ভুল হয়েছে: $e";
    }
  }

  // বিয়ে সম্পন্ন করার লজিক (Accept Ring)
  Future<void> completeMarriage(String partnerId, String partnerName, String partnerImg, String myName, String myImg) async {
    // দুইজনের ডাটাবেসেই বিয়ের ইনফো সেভ হবে
    var marriageData = {
      'husbandId': myUid, // লজিক অনুযায়ী আইডি সেট হবে
      'wifeId': partnerId,
      'partnerName': partnerName,
      'partnerImage': partnerImg,
      'ringType': 'Golden Ring',
      'marriedAt': FieldValue.serverTimestamp(),
    };

    await _db.collection('marriages').doc(myUid).set(marriageData);
    
    // পার্টনারের প্রোফাইলেও সেভ হবে
    await _db.collection('marriages').doc(partnerId).set({
      'partnerId': myUid,
      'partnerName': myName,
      'partnerImage': myImg,
      'marriedAt': FieldValue.serverTimestamp(),
    });
  }

  // ডিভোর্স লজিক (২০০০ ডায়মন্ড কাটবে)
  Future<String> processDivorce(String partnerId) async {
    const int divorceCost = 2000;
    
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(myUid).get();
      int currentDiamonds = userDoc['diamonds'] ?? 0;

      if (currentDiamonds < divorceCost) {
        return "পর্যাপ্ত ডায়মন্ড নেই! ২০০০ ডায়মন্ড প্রয়োজন।";
      }

      // ডায়মন্ড কেটে নেওয়া
      await _db.collection('users').doc(myUid).update({
        'diamonds': FieldValue.increment(-divorceCost)
      });

      // বিয়ের রেকর্ড মুছে ফেলা
      await _db.collection('marriages').doc(myUid).delete();
      await _db.collection('marriages').doc(partnerId).delete();

      return "বিচ্ছেদ সম্পন্ন হয়েছে।";
    } catch (e) {
      return "এরর: $e";
    }
  }
}
