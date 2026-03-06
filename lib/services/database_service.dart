import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  // ১. রিয়েল-টাইম ইউজার ডাটা স্ট্রিম (Map হিসেবে, যাতে UserModel এর ঝামেলা না থাকে)
  Stream<DocumentSnapshot> get userDataStream {
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid).snapshots();
  }

  // ২. ডায়মন্ড কাটার নিরাপদ পদ্ধতি (এটি আপনার গিফট সিস্টেমের জন্য)
  Future<bool> useDiamonds(int amount) async {
    if (uid == null) return false;
    try {
      return await _db.runTransaction((transaction) async {
        DocumentReference userRef = _db.collection('users').doc(uid!);
        DocumentSnapshot snapshot = await transaction.get(userRef);

        if (!snapshot.exists) return false;

        var data = snapshot.data() as Map<String, dynamic>;
        int currentDiamonds = data['diamonds'] ?? 0;

        if (currentDiamonds >= amount) {
          transaction.update(userRef, {'diamonds': currentDiamonds - amount});
          return true;
        }
        return false;
      });
    } catch (e) {
      print("Transaction Error: $e");
      return false;
    }
  }

  // ৩. প্রোফাইল আপডেট (নাম বা ছবি বদলানো)
  Future<void> updateProfileData(String field, dynamic value) async {
    if (uid != null) {
      await _db.collection('users').doc(uid).update({field: value});
    }
  }
}
