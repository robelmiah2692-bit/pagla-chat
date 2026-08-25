import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class RoomImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  static Future<void> pickAndSendImage({
    required String roomId,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      File file = File(image.path);
      String fileName = 'room_chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Firebase Storage-এ আপলোড
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('room_chat_images')
          .child(roomId)
          .child(fileName);

      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // ইউজারের তথ্য ফেচ করা
      final currentUser = FirebaseAuth.instance.currentUser;
      final String authUID = currentUser?.uid ?? "";

      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: authUID)
          .limit(1)
          .get();

      String finalName = currentUser?.displayName ?? "User";
      String finalImage = currentUser?.photoURL ?? "";
      String finalSenderId = authUID;

      if (userQuery.docs.isNotEmpty) {
        var uData = userQuery.docs.first.data();
        finalName = uData['name'] ?? finalName;
        finalImage = uData['profilePic'] ?? finalImage;
        finalSenderId = userQuery.docs.first.id;
      }

      // ফায়ারস্টোরে মেসেজ হিসেবে সেভ করা (টাইপ image)
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .add({
        'userName': finalName,
        'profilePic': finalImage,
        'text': '', // টেক্সট খালি থাকতে পারে
        'imageUrl': downloadUrl, // ইমেজ লিংক
        'type': 'image',
        'senderId': finalSenderId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("⚠️ Error uploading room chat image: $e");
    }
  }
}