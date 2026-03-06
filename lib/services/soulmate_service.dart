import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SoulmateService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String myUid = FirebaseAuth.instance.currentUser!.uid;

  // ১০০০ ডায়মন্ড কেটে সম্পর্ক ছিন্ন করার লজিক
  // ✅ এখানে (String partnerId) যোগ করা হয়েছে যাতে প্রোফাইল পেজ থেকে পাঠানো আইডিটি গ্রহণ করতে পারে
  Future<String> breakRelation(String partnerId) async {
    const int breakupCost = 1000; 

    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(myUid).get();
      int myDiamonds = userDoc['diamonds'] ?? 0;

      if (myDiamonds < breakupCost) {
        return "পর্যাপ্ত ডায়মন্ড নেই! সম্পর্ক ছিন্ন করতে ১০০০ ডায়মন্ড লাগবে।";
      }

      // দুইজনের ডাটাবেস থেকে রিমুভ (অটোমেটিক কার্ড খালি হয়ে যাবে)
      // আমরা সরাসরি প্রোফাইল পেজ থেকে আসা partnerId ব্যবহার করছি
      await _db.collection('soulmates').doc(myUid).delete();
      await _db.collection('soulmates').doc(partnerId).delete();

      // ডায়মন্ড কেটে নেওয়া
      await _db.collection('users').doc(myUid).update({
        'diamonds': FieldValue.increment(-breakupCost)
      });

      return "সাফল্যের সাথে সম্পর্ক ছিন্ন হয়েছে।";
    } catch (e) {
      return "এরর: $e";
    }
  }
}
