import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void showUserProfile(BuildContext context, String userId) {
  final String myUid = FirebaseAuth.instance.currentUser!.uid;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        
        var data = snapshot.data!.data() as Map<String, dynamic>;
        
        // ফলোয়ার লিস্ট চেক করা (আপনি ফলো করেছেন কি না)
        List followerList = data['followerList'] ?? [];
        bool isFollowing = followerList.contains(myUid);

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E2F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // প্রোফাইল পিকচার ও ভিআইপি ব্যাজ
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(data['imageURL'] ?? 'https://via.placeholder.com/150'),
                  ),
                  if (data['isVIP'] == true)
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber, width: 3),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // নাম এবং প্রিমিয়াম/ভিআইপি ব্যাজ
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(data['name'] ?? 'ইউজার', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  if (data['isVIP'] == true) const Icon(Icons.verified, color: Colors.gold, size: 22),
                  if (data['hasPremiumCard'] == true) const Icon(Icons.star, color: Colors.blueAccent, size: 20),
                ],
              ),
              const SizedBox(height: 15),

              // ফলোয়ার ও ফলোইং স্ট্যাট
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat("Followers", data['followers'] ?? 0),
                  _buildStat("Following", data['following'] ?? 0),
                ],
              ),
              const SizedBox(height: 20),

              // ফলো ও মেসেজ বাটন
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // নিজের প্রোফাইল না হলে ফলো বাটন দেখাবে
                  if (myUid != userId)
                    ElevatedButton(
                      onPressed: () => _handleFollow(myUid, userId, isFollowing),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing ? Colors.grey : Colors.pinkAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(isFollowing ? "Unfollow" : "Follow"),
                    ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("Message"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

// আসল ফলো লজিক যা ডাটাবেসে কাউন্ট করবে
void _handleFollow(String myUid, String targetUid, bool isFollowing) async {
  DocumentReference myRef = FirebaseFirestore.instance.collection('users').doc(myUid);
  DocumentReference targetRef = FirebaseFirestore.instance.collection('users').doc(targetUid);

  if (isFollowing) {
    // আনফলো করলে
    await targetRef.update({
      'followers': FieldValue.increment(-1),
      'followerList': FieldValue.arrayRemove([myUid])
    });
    await myRef.update({'following': FieldValue.increment(-1)});
  } else {
    // ফলো করলে
    await targetRef.update({
      'followers': FieldValue.increment(1),
      'followerList': FieldValue.arrayUnion([myUid])
    });
    await myRef.update({'following': FieldValue.increment(1)});
  }
}

Widget _buildStat(String label, int count) {
  return Column(
    children: [
      Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white54)),
    ],
  );
}
