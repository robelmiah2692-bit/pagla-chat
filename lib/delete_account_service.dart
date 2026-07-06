import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteAccountService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // আইডি ডিলিট রিকোয়েস্ট (ডাটাবেসে ফ্ল্যাগ সেট করা)
  static Future<void> requestAccountDeletion(String uID) async {
    await _db.collection('users').doc(uID).update({
      'isDeleted': true, // ইউজার অ্যাপে ডিলিট দেখাবে কিন্তু ডাটাবেসে থাকবে
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  // রিকভারি লজিক (রিচার্জ করার পর অ্যাডমিন বা সিস্টেম এইটা কল করবে)
  static Future<void> recoverAccount(String uID) async {
    await _db.collection('users').doc(uID).update({
      'isDeleted': false,
      'deletedAt': FieldValue.delete(), // ফিল্ডটি মুছে ফেলা হবে
    });
  }
}