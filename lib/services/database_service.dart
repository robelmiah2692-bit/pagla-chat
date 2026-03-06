import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 🔥 এই নিচের লাইনটি ছিল না, তাই এরর আসছিল
import '../models/user_model.dart'; 

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  // ১. রিয়েল-টাইম ইউজার ডাটা স্ট্রিম
  Stream<UserModel> get userData {
    if (uid == null) {
      throw Exception("ইউজার লগইন করা নেই!");
    }
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) {
        throw Exception("ইউজার ডাটা পাওয়া যায়নি!");
      }
      return UserModel.fromMap(snap.data() as Map<String, dynamic>, snap.id);
    });
  }

  // ২. ডায়মন্ড কাটার নিরাপদ পদ্ধতি
  Future<bool> useDiamonds(int amount) async {
    if (uid == null) return false;
    try {
      return await _db.runTransaction((transaction) async {
        DocumentReference userRef = _db.collection('users').doc(uid);
        DocumentSnapshot snapshot = await transaction.get(userRef);

        if (!snapshot.exists) return false;

        int currentDiamonds = (snapshot.data() as Map<String, dynamic>)['diamonds'] ?? 0;
        int newDiamonds = currentDiamonds - amount;

        if (newDiamonds >= 0) {
          transaction.update(userRef, {'diamonds': newDiamonds});
          return true; 
        }
        return false; 
      });
    } catch (e) {
      print("Error using diamonds: $e");
      return false;
    }
  }

  // ৩. প্রোফাইল আপডেট
  Future<void> updateProfileData(String field, dynamic value) async {
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({field: value});
  }
}
