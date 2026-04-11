import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ১. রিয়েল-টাইম ইউজার ডাটা স্ট্রিম (ইমেইল দিয়ে ৬-ডিজিটের uID খুঁজে ডাটা আনা)
  Stream<DocumentSnapshot?> get userDataStream {
    final User? user = _auth.currentUser;
    if (user == null || user.email == null) return const Stream.empty();

    // আপনার স্ক্রিনশট অনুযায়ী ইমেইল দিয়ে সঠিক ইউজার ডকুমেন্ট (uID) খুঁজে বের করা
    return _db
        .collection('users')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null);
  }

  // ২. ডায়মন্ড কাটার নিরাপদ পদ্ধতি (দাতার জন্য)
  Future<bool> useDiamonds(int amount) async {
    final User? user = _auth.currentUser;
    if (user == null || user.email == null) return false;

    try {
      // প্রথমে ইমেইল দিয়ে ইউজারের ৬-ডিজিটের uID ডকুমেন্টটি খুঁজে বের করতে হবে
      final query = await _db
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return false;
      
      DocumentReference userRef = query.docs.first.reference;

      return await _db.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return false;

        var data = snapshot.data() as Map<String, dynamic>;
        // আপনার স্ক্রিনশট অনুযায়ী ফিল্ডের নাম 'diamonds'
        int currentDiamonds = (data['diamonds'] ?? 0).toInt();

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

  // ৩. ডায়মন্ড যোগ করার পদ্ধতি (গ্রহীতার জন্য - ৬-ডিজিটের uID ব্যবহার করে)
  Future<void> addDiamondsToUser(String targetUID, int amount) async {
    try {
      // targetUID হলো ইউজারের সেই ৬-ডিজিটের আইডি (যেমন: 970321)
      await _db.collection('users').doc(targetUID).update({
        'diamonds': FieldValue.increment(amount),
      });
      print("✅ Diamonds added to uID: $targetUID");
    } catch (e) {
      print("❌ Error adding diamonds: $e");
    }
  }

  // ৪. প্রোফাইল আপডেট (যেমন: নাম বা ছবি পরিবর্তন)
  Future<void> updateProfileData(String field, dynamic value) async {
    final User? user = _auth.currentUser;
    if (user == null || user.email == null) return;

    try {
      final query = await _db
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        // স্ক্রিনশট অনুযায়ী 'name' অথবা 'profilePic' ফিল্ড আপডেট হবে
        await query.docs.first.reference.update({field: value});
        print("✅ Profile field '$field' updated for uID: ${query.docs.first.id}");
      }
    } catch (e) {
      print("❌ Update Profile Error: $e");
    }
  }
}
