import 'package:cloud_firestore/cloud_firestore.dart';

class FollowService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> toggleFollowUser(String targetUID, String myUID) async {
    print("DEBUG: প্রসেস শুরু - আমার আইডি: $myUID, টার্গেট আইডি: $targetUID");

    if (myUID.isEmpty || targetUID.isEmpty || myUID == targetUID) {
      print("DEBUG ERROR: আইডি খালি অথবা নিজের আইডিতে ক্লিক করেছেন");
      return false;
    }

    try {
      DocumentReference myDocRef = _db.collection('users').doc(myUID);
      DocumentReference targetDocRef = _db.collection('users').doc(targetUID);

      DocumentReference followCheckRef = myDocRef.collection('followingList').doc(targetUID);
      DocumentSnapshot followSnapshot = await followCheckRef.get();

      WriteBatch batch = _db.batch();

      if (followSnapshot.exists) {
        print("DEBUG: আনফলো করার সিদ্ধান্ত হয়েছে");
        batch.delete(followCheckRef);
        batch.delete(targetDocRef.collection('followersList').doc(myUID));
        
        batch.update(myDocRef, {'following': FieldValue.increment(-1)});
        batch.update(targetDocRef, {'followers': FieldValue.increment(-1)});
        
        await batch.commit();
        print("DEBUG: আনফলো সাকসেসফুল");
        return false;
      } else {
        print("DEBUG: ফলো করার সিদ্ধান্ত হয়েছে");
        batch.set(followCheckRef, {'followedAt': FieldValue.serverTimestamp()});
        batch.set(targetDocRef.collection('followersList').doc(myUID), {'followerAt': FieldValue.serverTimestamp()});
        
        batch.set(myDocRef, {'following': FieldValue.increment(1)}, SetOptions(merge: true));
        batch.set(targetDocRef, {'followers': FieldValue.increment(1)}, SetOptions(merge: true));
        
        await batch.commit();
        print("DEBUG: ফলো সাকসেসফুল");
        return true;
      }
    } catch (e) {
      print("❌ ডাটাবেজ আপডেট এরর (বিস্তারিত): $e");
      return false;
    }
  }

  Future<bool> checkIfFollowing(String targetUID, String myUID) async {
    if (myUID.isEmpty || targetUID.isEmpty) return false;
    
    DocumentSnapshot doc = await _db
        .collection('users')
        .doc(myUID)
        .collection('followingList')
        .doc(targetUID)
        .get();
        
    return doc.exists;
  }
}