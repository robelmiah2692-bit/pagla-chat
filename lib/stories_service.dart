import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as io; 

class StoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> uploadStory(String filePath, String text, {Uint8List? webFileBytes, bool isVideo = false}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String downloadUrl = "";

    try {
      // ১. ফাইল (ছবি বা ভিডিও) আপলোড লজিক
      if (webFileBytes != null || filePath.isNotEmpty) {
        String extension = isVideo ? '.mp4' : '.jpg';
        String folderName = isVideo ? 'stories/videos' : 'stories/images';
        String fileName = '$folderName/${DateTime.now().millisecondsSinceEpoch}$extension';
        Reference ref = _storage.ref().child(fileName);

        if (kIsWeb) {
          if (webFileBytes != null) {
            TaskSnapshot task = await ref.putData(webFileBytes);
            downloadUrl = await task.ref.getDownloadURL();
          }
        } else {
          io.File file = io.File(filePath);
          if (await file.exists()) {
            TaskSnapshot task = await ref.putFile(file);
            downloadUrl = await task.ref.getDownloadURL();
          }
        }
      }

      String actualName = "User";
      String actualProfilePic = "";
      String myCustomDocId = "";
      String actualFrameUrl = "";

      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();

      if (userQuery.docs.isNotEmpty) {
        var data = userQuery.docs.first.data();
        myCustomDocId = userQuery.docs.first.id;
        actualName = data['name'] ?? "User";
        actualProfilePic = data['profilePic'] ?? "";
        actualFrameUrl = data['activeFrameUrl'] ?? "";
      }

      // ৩. ডাটাবেসে স্টোরি সেভ (ভিডিও হলে videoUrl এবং ইমেজ হলে storyImage এ সেভ হবে)
      Map<String, dynamic> storyData = {
        'userId': myCustomDocId,
        'authUID': user.uid,
        'userName': actualName,
        'userImage': actualProfilePic,
        'activeFrameUrl': actualFrameUrl,
        'caption': text,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
      };

      if (isVideo) {
        storyData['videoUrl'] = downloadUrl;
        storyData['storyImage'] = ""; // ইমেজ খালি থাকবে
      } else {
        storyData['storyImage'] = downloadUrl;
        storyData['videoUrl'] = ""; // ভিডিও খালি থাকবে
      }

      await _firestore.collection('stories').add(storyData);

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