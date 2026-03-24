import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ১. জিমেইল, পাসওয়ার্ড এবং জেন্ডার দিয়ে লগইন বা রেজিস্টার
  // ✅ এখানে 'gender' প্যারামিটার যোগ করা হয়েছে যাতে ইউজারের পছন্দ সেভ করা যায়
  Future<User?> loginOrRegister(String email, String password, String gender) async {
    try {
      // প্রথমে লগইন করার চেষ্টা করবে
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      // যদি ইউজার নতুন হয়, তবেই রেজিস্ট্রেশন করবে
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
        try {
          UserCredential result = await _auth.createUserWithEmailAndPassword(
              email: email, password: password);
          
          // ✅ নতুন আইডি খোলার সময় ইউজারের সিলেক্ট করা জেন্ডার ডাটাবেসে পাঠানো হচ্ছে
          await _initializeUserData(result.user!, gender);
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

  // ২. পাসওয়ার্ড ভুলে গেলে জিমেইলে রিসেট লিঙ্ক পাঠানো (Forget Password)
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ৩. ফায়ারস্টোরে ইউজারের তথ্য সেভ করা
  Future<void> _initializeUserData(User user, String selectedGender) async {
    try {
      // ৬ ডিজিটের ইউনিক ইউজার আইডি (যেমন: ১৫৪৩২১)
      String uID = (100000 + Random().nextInt(900000)).toString();
      
      // ✅ জেন্ডার অনুযায়ী একটি ডিফল্ট প্রোফাইল পিকচার সেট করা (ঐচ্ছিক)
      String defaultPic = selectedGender == 'মহিলা' 
          ? 'https://cdn-icons-png.flaticon.com/512/6997/6997674.png' 
          : 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';
      
      await _db.collection('users').doc(user.uid).set({
        'uID': uID,
        'uid': user.uid,
        'name': user.email!.split('@')[0],
        'email': user.email,
        'diamonds': 200,
        'xp': 0,
        'profilePic': defaultPic,
        'gender': selectedGender, // ✅ এখানে এখন ইউজারের সিলেক্ট করা জেন্ডার সেভ হবে
        'fcmToken': '', 
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
