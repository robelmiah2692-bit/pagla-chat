import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🚀 ফলো এবং আনফলো করার কোর লজিক (ডাটার রাস্তা সুরক্ষিত)
  Future<bool> toggleFollowUser(String targetUserId) async {
    final String myAuthId = _auth.currentUser?.uid ?? "";
    if (myAuthId.isEmpty || targetUserId.isEmpty) return false;
    if (myAuthId == targetUserId) return false; // নিজেকে ফলো করা যাবে না

    try {
      // ১. কারেন্ট ইউজারের 'users' ডকুমেন্ট রেফারেন্স
      DocumentReference myDocRef = _db.collection('users').doc(myAuthId);
      // ২. যাকে ফলো করা হচ্ছে (Target User) তার ডকুমেন্ট রেফারেন্স
      DocumentReference targetDocRef = _db.collection('users').doc(targetUserId);

      // ৩. অলরেডি ফলো করা আছে কিনা তা চেক করার জন্য সাব-কালেকশন রাস্তা
      DocumentReference followCheckRef = _db
          .collection('users')
          .doc(myAuthId)
          .collection('followingList')
          .doc(targetUserId);

      DocumentSnapshot followSnapshot = await followCheckRef.get();

      if (followSnapshot.exists) {
        // ❌ অলরেডি ফলো থাকলে -> আনফলো হবে
        WriteBatch batch = _db.batch();
        
        batch.delete(followCheckRef);
        batch.delete(_db.collection('users').doc(targetUserId).collection('followersList').doc(myAuthId));
        
        batch.update(myDocRef, {'following': FieldValue.increment(-1)});
        batch.update(targetDocRef, {'followers': FieldValue.increment(-1)});
        
        await batch.commit();
        return false; // বুঝাবে আনফলো হয়েছে
      } else {
        // ✅ ফলো না থাকলে -> নতুন ফলো হবে
        WriteBatch batch = _db.batch();
        
        batch.set(followCheckRef, {'followedAt': FieldValue.serverTimestamp()});
        batch.set(_db.collection('users').doc(targetUserId).collection('followersList').doc(myAuthId), {'followerAt': FieldValue.serverTimestamp()});
        
        batch.update(myDocRef, {'following': FieldValue.increment(1)});
        batch.update(targetDocRef, {'followers': FieldValue.increment(1)});
        
        await batch.commit();
        return true; // বুঝাবে ফলো হয়েছে
      }
    } catch (e) {
      print("फलो এরর: $e");
      return false;
    }
  }

  // 🔄 স্ক্রিন ওপেন হওয়ার সময় অলরেডি ফলো করা আছে কিনা তা চেক করার লজিক
  Future<bool> checkIfFollowing(String targetUserId) async {
    final String myAuthId = _auth.currentUser?.uid ?? "";
    if (myAuthId.isEmpty || targetUserId.isEmpty) return false;
    
    DocumentSnapshot doc = await _db
        .collection('users')
        .doc(myAuthId)
        .collection('followingList')
        .doc(targetUserId)
        .get();
        
    return doc.exists;
  }
}