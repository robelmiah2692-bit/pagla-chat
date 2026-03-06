import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  // ১. রিয়েল-টাইম ইউজার ডাটা স্ট্রিম (হোম ও প্রোফাইলের জন্য)
  Stream<UserModel> get userData {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      return UserModel.fromMap(snap.data() as Map<String, dynamic>, snap.id);
    });
  }

  // ২. ডায়মন্ড কাটার নিরাপদ পদ্ধতি (হ্যাকিং রোধে Transaction)
  Future<bool> useDiamonds(int amount) async {
    try {
      return await _db.runTransaction((transaction) async {
        DocumentReference postRef = _db.collection('users').doc(uid);
        DocumentSnapshot snapshot = await transaction.get(postRef);

        int newDiamonds = (snapshot.get('diamonds') ?? 0) - amount;
        if (newDiamonds >= 0) {
          transaction.update(postRef, {'diamonds': newDiamonds});
          return true; // সফল
        }
        return false; // ডায়মন্ড কম
      });
    } catch (e) {
      return false;
    }
  }

  // ৩. প্রোফাইল আপডেট (নাম বা ছবি বদলানো)
  Future<void> updateProfileData(String field, dynamic value) async {
    await _db.collection('users').doc(uid).update({field: value});
  }
}
