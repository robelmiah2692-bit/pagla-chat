import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SoulmateService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String myuID = FirebaseAuth.instance.currentUser!.uid;

  // ১০০০ ডায়মন্ড কেটে সম্পর্ক ছিন্ন করার লজিক (ডাটা রাস্তা প্রটেক্টেড)
  Future<String> breakRelation(String partnerId) async {
    const int breakupCost = 1500; 

    try {
      // ১. ইউজারের ডায়মন্ড চেক করা
      DocumentSnapshot userDoc = await _db.collection('users').doc(myuID).get();
      if (!userDoc.exists) return "ইউজার ডাটা পাওয়া যায়নি!";
      
      int myDiamonds = userDoc['diamonds'] ?? 0;

      if (myDiamonds < breakupCost) {
        return "Need 1500 Daimond।";
      }

      // ২. [ডাটা প্রোটেকশন রাস্তা ফিক্স]: 
      // দুইজনের মূল কালেকশন অথবা সাব-কালেকশন থেকে সোলমেট জোড়া রিমুভ করা হচ্ছে
      // আপনার ডাটাবেজ আর্কিটেকচার অনুযায়ী ডকুমেন্ট ডিলিট করা হচ্ছে
      await _db.collection('soulmates').doc(myuID).delete();
      if (partnerId.isNotEmpty) {
        await _db.collection('soulmates').doc(partnerId).delete();
      }

      // ৩. সফলভাবে ডায়মন্ড কেটে অ্যাকাউন্ট আপডেট করা
      await _db.collection('users').doc(myuID).update({
        'diamonds': FieldValue.increment(-breakupCost)
      });

      return "SUCCESS"; // সফল মেসেজ রিটার্ন
    } catch (e) {
      return "eror: $e";
    }
  }
}