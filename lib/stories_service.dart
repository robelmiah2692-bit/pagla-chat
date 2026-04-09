import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as io; 

class StoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> uploadStory(String imagePath, String text, {Uint8List? webImageBytes}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String downloadUrl = "";

    try {
      // ১. ছবি আপলোড লজিক
      if (webImageBytes != null || imagePath.isNotEmpty) {
        String fileName = 'stories/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference ref = _storage.ref().child(fileName);

        if (kIsWeb) {
          if (webImageBytes != null) {
            TaskSnapshot task = await ref.putData(webImageBytes);
            downloadUrl = await task.ref.getDownloadURL();
          }
        } else {
          io.File file = io.File(imagePath);
          if (await file.exists()) {
            TaskSnapshot task = await ref.putFile(file);
            downloadUrl = await task.ref.getDownloadURL();
          }
        }
      }

      // ২. প্রোফাইল ডাটা আনা (আপনার স্ক্রিনশট অনুযায়ী মিশন)
      // আপনার Firestore-এ ডকুমেন্ট আইডি হলো ৬ ডিজিটের, তাই সরাসরি user.uid দিয়ে পাওয়া যাবে না।
      // ইমেইল দিয়ে সার্চ করে ওই ৬ ডিজিটের ডকুমেন্ট থেকে নাম ও ছবি আনতে হবে।
      
      String actualName = "User";
      String actualProfilePic = "";
      String myCustomDocId = "";

      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();

      if (userQuery.docs.isNotEmpty) {
        var data = userQuery.docs.first.data();
        myCustomDocId = userQuery.docs.first.id; // এটা আপনার ৬ ডিজিটের আইডি (যেমন: 153530)
        actualName = data['name'] ?? "User";
        actualProfilePic = data['profilePic'] ?? "";
      }

      // ৩. ডাটাবেসে স্টোরি সেভ
      await _firestore.collection('stories').add({
        'userId': myCustomDocId, // এখানে ৬ ডিজিটের আইডি সেভ হবে
        'authUID': user.uid,     // চেনার সুবিধার জন্য অরিজিনাল Auth UID-ও রাখা হলো
        'userName': actualName, 
        'userImage': actualProfilePic, 
        'storyImage': downloadUrl,
        'caption': text,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [], 
      });

      debugPrint("Story Uploaded Successfully! ✅");
    } catch (e) {
      debugPrint("Upload Error: $e");
    }
  }

  Stream<QuerySnapshot> getStories() {
    return _firestore
        .collection('stories')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
