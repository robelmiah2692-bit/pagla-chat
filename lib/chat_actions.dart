import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatActions {
  // ব্লক করার সাথে একটি সিস্টেম মেসেজ পাঠানো
  static Future<void> blockUser(BuildContext context, String currentUserId, String receiverId, String roomId) async {
    try {
      print("BLOCK ACTION: Initiating block for user: $receiverId by: $currentUserId");
      
      // SetOptions(merge: true) নিশ্চিত করবে ফিল্ড না থাকলে তৈরি হবে
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).set({
        'blockedUsers': FieldValue.arrayUnion([receiverId])
      }, SetOptions(merge: true));
      
      print("BLOCK ACTION: Firestore update successful.");
      
      await _sendSystemMessage(roomId, "You have blocked $receiverId");
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User Blocked")));
      }
    } catch (e) {
      print("BLOCK ACTION ERROR: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // আনব্লক করার লজিক
  static Future<void> unblockUser(BuildContext context, String currentUserId, String receiverId, String roomId) async {
    try {
      print("UNBLOCK ACTION: Initiating unblock for user: $receiverId by: $currentUserId");
      
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).set({
        'blockedUsers': FieldValue.arrayRemove([receiverId])
      }, SetOptions(merge: true));
      
      print("UNBLOCK ACTION: Firestore update successful.");
      
      await _sendSystemMessage(roomId, "You have unblocked $receiverId");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User Unblocked")));
      }
    } catch (e) {
      print("UNBLOCK ACTION ERROR: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // চ্যাট রুমে সিস্টেম মেসেজ পাঠানো
  static Future<void> _sendSystemMessage(String roomId, String message) async {
    try {
      await FirebaseFirestore.instance.collection('chats').doc(roomId).collection('messages').add({
        'senderId': 'paglachat_official',
        'message': message,
        'type': 'system_msg',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("SYSTEM MESSAGE: Message sent successfully to room: $roomId");
    } catch (e) {
      print("SYSTEM MESSAGE ERROR: $e");
    }
  }

  // রিপোর্ট ইউজার
  static Future<void> reportUser(BuildContext context, String currentUserId, String receiverId) async {
    try {
      print("REPORT ACTION: Reporting user: $receiverId");
      await FirebaseFirestore.instance.collection('reports').add({
        'reporter': currentUserId,
        'reportedUser': receiverId,
        'reason': 'Inappropriate behavior',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("REPORT ACTION: Report saved successfully.");
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User Reported")));
      }
    } catch (e) {
      print("REPORT ACTION ERROR: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error reporting: $e")));
      }
    }
  }
}