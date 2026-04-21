import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ১. ইমেইল ও পাসওয়ার্ড দিয়ে লগইন বা একাউন্ট খোলা
  Future<User?> loginOrRegister(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
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

  // ২. ফায়ারবেস চেক লজিক: ইউনিক আইডি আছে কি নেই তা খোঁজা
  // (Bengali Comment: এখানে এখন আপনার ৬-ডিজিটের ইউনিক uID দিয়ে ডাটা খুঁজবে)
  Future<bool> checkUserExistsByuID(String uniqueID) async {
    try {
      // (Bengali Comment: 'users' কালেকশনে 'uID' ফিল্ড দিয়ে সার্চ করা হচ্ছে)
      var query = await _db.collection('users')
          .where('uID', isEqualTo: uniqueID) 
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty; 
    } catch (e) {
      return false;
    }
  }

  // ৩. পাসওয়ার্ড রিসেট (Forget Password)
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
