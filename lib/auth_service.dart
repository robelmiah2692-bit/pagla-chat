import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '25052070011-ernp28c3e48cqvuupm9gq28q560u5po6.apps.googleusercontent.com',
  );

  // ইউজার ডাটাবেসে আছে কি না তা চেক করার মেথড
  Future<bool> isUserRegistered(String email) async {
    var doc = await _db.collection('users').where('email', isEqualTo: email).get();
    return doc.docs.isNotEmpty;
  }

  // ২. নতুন লজিক: ইউজার ডিলিটেড কি না চেক করার জন্য
  Future<bool> isUserDeleted(String email) async {
    var doc = await _db.collection('users')
        .where('email', isEqualTo: email)
        .where('isDeleted', isEqualTo: true) // শুধুমাত্র ডিলিট হওয়া ইউজারদের খুঁজবে
        .get();
    return doc.docs.isNotEmpty;
  }
  
  // গুগল লগইন
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, 
        idToken: googleAuth.idToken,
      );
      
      UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}