import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SoulmateService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String myUid = FirebaseAuth.instance.currentUser!.uid;

  // ১০০০ ডায়মন্ড কেটে সম্পর্ক ছিন্ন করার লজিক
  Future<String> breakRelation() async {
    const int breakupCost = 1000; // আপনার রিকোয়ারমেন্ট অনুযায়ী ১০০০ ডায়মন্ড

    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(myUid).get();
      int myDiamonds = userDoc['diamonds'] ?? 0;

      if (myDiamonds < breakupCost) {
        return "পর্যাপ্ত ডায়মন্ড নেই! সম্পর্ক ছিন্ন করতে ১০০০ ডায়মন্ড লাগবে।";
      }

      // রিলেশন ডাটা চেক
      var soulDoc = await _db.collection('soulmates').doc(myUid).get();
      if (!soulDoc.exists) return "কোনো সম্পর্ক খুঁজে পাওয়া যায়নি।";

      String partnerUid = soulDoc['partnerId'];

      // দুইজনের ডাটাবেস থেকে রিমুভ (অটোমেটিক কার্ড খালি হয়ে যাবে)
      await _db.collection('soulmates').doc(myUid).delete();
      await _db.collection('soulmates').doc(partnerUid).delete();

      // ডায়মন্ড কেটে নেওয়া
      await _db.collection('users').doc(myUid).update({
        'diamonds': FieldValue.increment(-breakupCost)
      });

      return "সাফল্যের সাথে সম্পর্ক ছিন্ন হয়েছে।";
    } catch (e) {
      return "এরর: $e";
    }
  }
}
