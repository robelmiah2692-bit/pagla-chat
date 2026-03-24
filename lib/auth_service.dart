import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ১. জিমেইল ও পাসওয়ার্ড দিয়ে লগইন বা রেজিস্টার
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
          await _initializeUserData(result.user!);
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

  // ✅ ২. পাসওয়ার্ড ভুলে গেলে জিমেইলে রিসেট লিঙ্ক পাঠানো (Forget Password)
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ৩. ফায়ারস্টোরে ইউজারের তথ্য সেভ করা
  Future<void> _initializeUserData(User user) async {
    try {
      // ৬ ডিজিটের ইউনিক ইউজার আইডি
      String uID = (100000 + Random().nextInt(900000)).toString();
      
      await _db.collection('users').doc(user.uid).set({
        'uID': uID,
        'uid': user.uid, // অরিজিনাল ফায়ারবেস ইউআইডি
        'name': user.email!.split('@')[0],
        'email': user.email,
        'diamonds': 200,
        'xp': 0,
        'profilePic': 'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?auto=compress&cs=tinysrgb&w=200',
        'gender': 'পুরুষ',
        'fcmToken': '', // নোটিফিকেশনের জন্য খালি টোকেন ইনিশিয়ালাইজ করা
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Firestore Error: $e");
    }
  }

  // ৪. লগআউট
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
