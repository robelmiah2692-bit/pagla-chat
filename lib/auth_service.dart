import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ১. জিমেইল ও পাসওয়ার্ড দিয়ে নতুন অ্যাকাউন্ট বা লগইন করা
  Future<User?> loginOrRegister(String email, String password) async {
    try {
      // প্রথমে লগইন করার চেষ্টা করবে
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // ইউজার না থাকলে নতুন অ্যাকাউন্ট তৈরি করবে
        UserCredential result = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        
        // নতুন ইউজারের জন্য ডাটাবেসে ডিফল্ট ডাটা সেভ করা
        await _initializeUserData(result.user!);
        return result.user;
      }
      return null;
    }
  }

  // ২. ফায়রবেস ডাটাবেসে (Firestore) ইউজারের তথ্য সেভ করা
  Future<void> _initializeUserData(User user) async {
    String uID = (100000 + Random().nextInt(900000)).toString();
    await _db.collection('users').doc(user.uid).set({
      'uID': uID,
      'name': user.email!.split('@')[0], // জিমেইলের প্রথম অংশ নাম হিসেবে
      'diamonds': 200, // নতুন ইউজারকে ২০০ ডায়মন্ড ফ্রি
      'xp': 0,
      'profilePic': 'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?auto=compress&cs=tinysrgb&w=200',
      'gender': 'পুরুষ',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ৩. লগআউট করা
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
