import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ফায়ারবেস থেকে ইউজারের ডাটা রিয়েল-টাইমে দেখা (Stream)
  Stream<DocumentSnapshot> getUserStream() {
    String uID = _auth.currentUser!.uid;
    return _db.collection('users').doc(uID).snapshots();
  }

  // ডাটা আপডেট করা (যেমন ডায়মন্ড বাড়লে বা কমলে)
  Future<void> updateDiamonds(int newAmount) async {
    String uID = _auth.currentUser!.uid;
    await _db.collection('users').doc(uID).update({'diamonds': newAmount});
  }
}

