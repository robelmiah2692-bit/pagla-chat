import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ১. ইমেইল ও পাসওয়ার্ড দিয়ে লগইন বা একাউন্ট খোলা
  // এখান থেকে জেন্ডার এবং আইডি জেনারেশন লজিক সম্পূর্ণ বাদ দেওয়া হয়েছে।
  Future<User?> loginOrRegister(String email, String password) async {
    try {
      // প্রথমে সাইন-ইন করার চেষ্টা করবে
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      // যদি ইউজার না থাকে, তবে নতুন একাউন্ট তৈরি করবে
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
        try {
          UserCredential result = await _auth.createUserWithEmailAndPassword(
              email: email, password: password);
          return result.user;
        } catch (innerError) {
          return null;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ২. ফায়ারবেস চেক লজিক: ইউনিক আইডি আছে কি নেই তা খোঁজা
  // এটি আপনার ৬-ডিজিটের ইউনিক আইডি দিয়ে ডাটাবেসে ইউজারকে খুঁজবে
  Future<bool> checkUserExistsByUID(String authUID) async {
    try {
      // 'users' কালেকশনে 'uid' (Firebase Auth ID) দিয়ে সার্চ করবে
      var query = await _db.collection('users')
          .where('uid', isEqualTo: authUID)
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty; // ডাটা থাকলে true, না থাকলে false
    } catch (e) {
      return false;
    }
  }

  // ৩. পাসওয়ার্ড রিসেট (Forget Password)
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ৪. লগআউট
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
