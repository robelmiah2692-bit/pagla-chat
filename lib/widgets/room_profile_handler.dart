import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RoomProfileHandler {
  // ১. ইমেজ পিকার লজিক
  static Future<void> pickRoomImage({
    required Function(String) onImagePicked,
    required Function(String) showMessage,
  }) async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      onImagePicked(image.path);
      showMessage("রুম প্রোফাইল আপডেট হয়েছে!");
    }
  }

  // ২. রুমের নাম এডিট করার পপ-আপ
  static void editRoomName({
    required BuildContext context,
    required String currentName,
    required Function(String) onNameSaved,
  }) {
    TextEditingController nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        title: const Text("রুমের নাম পরিবর্তন", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "নতুন নাম লিখুন",
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("বাতিল", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              onNameSaved(nameController.text);
              Navigator.pop(context);
            },
            child: const Text("সেভ", style: TextStyle(color: Colors.pinkAccent)),
          ),
        ],
      ),
    );
  }
}
