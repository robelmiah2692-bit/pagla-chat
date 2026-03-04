import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // স্টোরি আপলোড
  Future<void> uploadStory(String imagePath) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('stories').add({
      'userId': user.uid,
      'userName': user.displayName ?? "অজানা ইউজার",
      'userImage': user.photoURL ?? "",
      'storyImage': imagePath,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // স্টোরি রিড (orderBy আপাতত অফ করে দিলাম যেন সাথে সাথে দেখা যায়)
  Stream<QuerySnapshot> getStories() {
    return _firestore.collection('stories').snapshots();
  }
}
