import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ১. জিমেইল ও পাসওয়ার্ড দিয়ে লগইন বা রেজিস্টার
  Future<User?> loginOrRegister(String email, String password) async {
    try {
      // প্রথমে লগইন করার চেষ্টা করবে
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      // যদি ইউজার খুঁজে না পায় অথবা ভুল পাসওয়ার্ড বলে (Firebase Web এ কোড আলাদা হতে পারে)
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        try {
          // নতুন অ্যাকাউন্ট তৈরি করবে
          UserCredential result = await _auth.createUserWithEmailAndPassword(
              email: email, password: password);
          
          // নতুন ইউজারের ডাটা ফায়ারস্টোরে সেভ করা
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

  // ২. ফায়ারস্টোরে ইউজারের তথ্য সেভ করা
  Future<void> _initializeUserData(User user) async {
    try {
      String uID = (100000 + Random().nextInt(900000)).toString();
      await _db.collection('users').doc(user.uid).set({
        'uID': uID,
        'name': user.email!.split('@')[0],
        'diamonds': 200,
        'xp': 0,
        'profilePic': 'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?auto=compress&cs=tinysrgb&w=200',
        'gender': 'পুরুষ',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge: true দিলে ডাটা হারাবে না
    } catch (e) {
      print("Firestore Error: $e");
    }
  }

  // ৩. লগআউট
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
