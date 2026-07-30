import 'package:cloud_firestore/cloud_firestore.dart';

class FollowService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> toggleFollowUser(String targetUID, String myUID) async {
    if (myUID.isEmpty || targetUID.isEmpty || myUID == targetUID) {
      return false;
    }

    try {
      DocumentReference myDocRef = _db.collection('users').doc(myUID);
      DocumentReference targetDocRef = _db.collection('users').doc(targetUID);

      DocumentReference followCheckRef = myDocRef.collection('followingList').doc(targetUID);
      DocumentSnapshot followSnapshot = await followCheckRef.get();

      WriteBatch batch = _db.batch();

      if (followSnapshot.exists) {
        batch.delete(followCheckRef);
        batch.delete(targetDocRef.collection('followersList').doc(myUID));
        
        batch.update(myDocRef, {'following': FieldValue.increment(-1)});
        batch.update(targetDocRef, {'followers': FieldValue.increment(-1)});
        
        await batch.commit();
        return false;
      } else {
        batch.set(followCheckRef, {'followedAt': FieldValue.serverTimestamp()});
        batch.set(targetDocRef.collection('followersList').doc(myUID), {'followerAt': FieldValue.serverTimestamp()});
        
        batch.set(myDocRef, {'following': FieldValue.increment(1)}, SetOptions(merge: true));
        batch.set(targetDocRef, {'followers': FieldValue.increment(1)}, SetOptions(merge: true));
        
        await batch.commit();
        return true;
      }
    } catch (e) {
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