import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // বর্তমান লগইন করা ইউজারের লম্বা uid সংগ্রহ করা হচ্ছে
  final String? authUid = FirebaseAuth.instance.currentUser?.uid;

  // ১. রিয়েল-টাইম ইউজার ডাটা স্ট্রিম (আপনার স্ক্রিনশট অনুযায়ী 'users' কালেকশন থেকে)
  Stream<DocumentSnapshot> get userDataStream {
    if (authUid == null) return const Stream.empty();
    // আপনার স্ক্রিনশটে 'users' কালেকশনের ডকুমেন্ট আইডি হলো এই লম্বা uid
    return _db.collection('users').doc(authUid).snapshots();
  }

  // ২. ডায়মন্ড কাটার নিরাপদ পদ্ধতি (দাতার জন্য)
  Future<bool> useDiamonds(int amount) async {
    if (authUid == null) return false;
    try {
      return await _db.runTransaction((transaction) async {
        DocumentReference userRef = _db.collection('users').doc(authUid!);
        DocumentSnapshot snapshot = await transaction.get(userRef);

        if (!snapshot.exists) return false;

        var data = snapshot.data() as Map<String, dynamic>;
        // আপনার স্ক্রিনশটে ডায়মন্ডের ফিল্ড নাম 'diamonds' (int64)
        int currentDiamonds = data['diamonds'] ?? 0;

        if (currentDiamonds >= amount) {
          transaction.update(userRef, {'diamonds': currentDiamonds - amount});
          return true;
        }
        return false;
      });
    } catch (e) {
      print("❌ Transaction Error: $e");
      return false;
    }
  }

  // ৩. ডায়মন্ড যোগ করার পদ্ধতি (গ্রহীতার জন্য)
  Future<void> addDiamondsToUser(String targetAuthUid, int amount) async {
    try {
      // targetAuthUid হলো সেই ইউজারের লম্বা আইডি যার কাছে ডায়মন্ড যাবে
      await _db.collection('users').doc(targetAuthUid).update({
        'diamonds': FieldValue.increment(amount),
      });
      print("✅ Diamonds added successfully to: $targetAuthUid");
    } catch (e) {
      print("❌ Error adding diamonds: $e");
    }
  }

  // ৪. প্রোফাইল আপডেট (যেমন: নাম বা ছবি পরিবর্তন)
  Future<void> updateProfileData(String field, dynamic value) async {
    if (authUid != null) {
      // স্ক্রিনশট অনুযায়ী এখানে 'name' অথবা 'profilePic' ফিল্ড আপডেট হবে
      await _db.collection('users').doc(authUid).update({field: value});
      print("✅ Profile field '$field' updated.");
    }
  }
}
