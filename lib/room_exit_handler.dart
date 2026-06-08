import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class RoomExitHandler {
  
  static Future<void> endRoom(String roomId) async {
    try {
      debugPrint("DEBUG: Attempting to end room using Batch: $roomId");
      final firestore = FirebaseFirestore.instance;
      WriteBatch batch = firestore.batch();
      DocumentReference roomRef = firestore.collection('rooms').doc(roomId);

      batch.update(roomRef, {
        'seats': [],
        'viewerList': [],
        'musicPlayer': {'url': '', 'status': 'stopped'},
        'chatList': [],
        'userCount': 0,
        'isActive': false,
        'isLocked': false,
      });

      var roomUsers = await roomRef.collection('users').get();
      for (var doc in roomUsers.docs) { batch.delete(doc.reference); }

      var chatMessages = await roomRef.collection('messages').get();
      debugPrint("DEBUG: Batch deleting ${chatMessages.docs.length} messages.");
      for (var msgDoc in chatMessages.docs) { batch.delete(msgDoc.reference); }
      
      await batch.commit();
      debugPrint("DEBUG: Room ended successfully!");
    } catch (e) {
      debugPrint("DEBUG ERROR: Failed to end room: $e");
    }
  }

  static Future<void> removeUserFromRoom(String roomId, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'usersInRoom': FieldValue.arrayRemove([userId.toString()])
      });
      debugPrint("DEBUG: User $userId removed.");
    } catch (e) {
      debugPrint("DEBUG ERROR: Remove failed: $e");
    }
  }

  static Future<bool> handleExit(String roomId, String currentUserId, List<String> adminList, String ownerId) async {
    try {
      var roomDoc = await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();
      
      // যদি রুম অলরেডি ডিলিট হয়ে গিয়ে থাকে, তবুও আমরা true রিটার্ন করবো যাতে ইউজার বের হতে পারে
      if (!roomDoc.exists) {
        debugPrint("DEBUG: Room doc not found, allowing exit...");
        return true; 
      }

      String currentUidStr = currentUserId.toString();
      String ownerIdStr = ownerId.toString();
      List<String> adminIdsStr = adminList.map((e) => e.toString()).toList();

      bool isMeAdminOrOwner = (currentUidStr == ownerIdStr || adminIdsStr.contains(currentUidStr));

      if (isMeAdminOrOwner) {
        List<dynamic> usersInRoom = roomDoc.data()?['usersInRoom'] ?? [];
        
        bool anyOtherAdminOrOwnerLeft = usersInRoom.any((uid) {
          String uidStr = uid.toString();
          return uidStr != currentUidStr && (uidStr == ownerIdStr || adminIdsStr.contains(uidStr));
        });

        if (!anyOtherAdminOrOwnerLeft) {
          debugPrint("DEBUG: Ending room as last Admin/Owner...");
          await endRoom(roomId);
        } else {
          debugPrint("DEBUG: Other admin/owner present. Just removing self.");
          await removeUserFromRoom(roomId, currentUidStr);
        }
      } else {
        debugPrint("DEBUG: Regular user $currentUidStr leaving.");
        await removeUserFromRoom(roomId, currentUidStr);
      }
      return true; // সব ঠিক থাকলে true
    } catch (e) {
      debugPrint("DEBUG ERROR: $e");
      return true; // এরর হলেও ইউজারকে আটকে রাখবে না, বের করে দেবে
    }
  }
}