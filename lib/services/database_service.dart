import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  // ১. রিয়েল-টাইম ইউজার ডাটা স্ট্রিম
  Stream<DocumentSnapshot> get userDataStream {
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid).snapshots();
  }

  // ২. ডায়মন্ড কাটার নিরাপদ পদ্ধতি (দাতার জন্য)
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

  // ৩. ডায়মন্ড যোগ করার নতুন পদ্ধতি (গ্রহীতার জন্য - এটি নতুন যোগ করা হলো)
  Future<void> addDiamondsToUser(String targetUid, int amount) async {
    try {
      await _db.collection('users').doc(targetUid).update({
        'diamonds': FieldValue.increment(amount),
      });
    } catch (e) {
      print("Error adding diamonds: $e");
    }
  }

  // ৪. প্রোফাইল আপডেট
  Future<void> updateProfileData(String field, dynamic value) async {
    if (uid != null) {
      await _db.collection('users').doc(uid).update({field: value});
    }
  }
}
