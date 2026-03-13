import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomFollowerSheet extends StatefulWidget {
  final String roomId;
  final String ownerId;

  const RoomFollowerSheet({super.key, required this.roomId, required this.ownerId});

  @override
  State<RoomFollowerSheet> createState() => _RoomFollowerSheetState();
}

class _RoomFollowerSheetState extends State<RoomFollowerSheet> {
  final String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        height: 600,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const TabBar(
              indicatorColor: Colors.pinkAccent,
              tabs: [
                Tab(text: "Followers"),
                Tab(text: "Kick List"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildFollowerList(),
                  _buildKickList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowerList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (!snapshot.data!.exists) return const Center(child: Text("রুম পাওয়া যায়নি", style: TextStyle(color: Colors.white54)));

        var roomData = snapshot.data!.data() as Map<String, dynamic>;
        
        // ১. ডাটাবেস থেকে ওনার আইডি নিশ্চিত করা
        String actualOwnerId = roomData['ownerId'] ?? roomData['owner'] ?? widget.ownerId;
        
        List<dynamic> followers = List.from(roomData['followers'] ?? []);
        List<dynamic> admins = List.from(roomData['admins'] ?? []);

        // ২. ওনার যদি লিস্টে না থাকে, তবে তাকে লিস্টে যুক্ত করা
        if (actualOwnerId.isNotEmpty && !followers.contains(actualOwnerId)) {
          followers.add(actualOwnerId);
        }

        // ৩. র‍্যাঙ্ক অনুযায়ী সাজানো: ওনার (👑) সবার উপরে
        followers.sort((a, b) {
          if (a == actualOwnerId) return -1;
          if (b == actualOwnerId) return 1;
          bool aIsAdmin = admins.contains(a);
          bool bIsAdmin = admins.contains(b);
          if (aIsAdmin && !bIsAdmin) return -1;
          if (!aIsAdmin && bIsAdmin) return 1;
          return 0;
        });

        return ListView.builder(
          itemCount: followers.length,
          itemBuilder: (context, index) {
            String uid = followers[index];
            bool isOwner = (uid == actualOwnerId);
            bool isAdmin = admins.contains(uid);

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const ListTile();
                var userData = userSnap.data?.data() as Map<String, dynamic>?;
                
                String name = userData?['name'] ?? "User";
                String photo = userData?['photoUrl'] ?? "https://via.placeholder.com/150";

                return ListTile(
                  leading: CircleAvatar(backgroundImage: NetworkImage(photo)),
                  title: Text(name, style: const TextStyle(color: Colors.white)),
                  subtitle: _buildBadge(isOwner, isAdmin),
                  trailing: (myUid == actualOwnerId && uid != myUid) 
                      ? IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white54),
                          onPressed: () => _showAdminOptions(uid, isAdmin),
                        ) 
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBadge(bool isOwner, bool isAdmin) {
    if (isOwner) return const Text("👑 Owner", style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold));
    if (isAdmin) return const Text("🛡️ Admin", style: TextStyle(color: Colors.blueAccent, fontSize: 12));
    return const Text("Follower", style: TextStyle(color: Colors.white54, fontSize: 12));
  }

  void _showAdminOptions(String targetUid, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(isAdmin ? Icons.remove_moderator : Icons.add_moderator, color: Colors.blue),
            title: Text(isAdmin ? "Remove Admin" : "Make Admin", style: const TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _toggleAdmin(targetUid, isAdmin);
            },
          ),
          ListTile(
            leading: const Icon(Icons.gavel, color: Colors.red),
            title: const Text("Kick User", style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _kickUser(targetUid);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKickList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var data = snapshot.data!.data() as Map<String, dynamic>?;
        List kickedUsers = data?['kickedUsers'] ?? [];

        if (kickedUsers.isEmpty) return const Center(child: Text("কেউ কিক লিস্টে নেই", style: TextStyle(color: Colors.white38)));

        return ListView.builder(
          itemCount: kickedUsers.length,
          itemBuilder: (context, index) {
            String uid = kickedUsers[index];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
              builder: (context, userSnap) {
                var userData = userSnap.data?.data() as Map<String, dynamic>?;
                String name = userData?['name'] ?? uid;
                String photo = userData?['photoUrl'] ?? "https://via.placeholder.com/150";

                return ListTile(
                  leading: CircleAvatar(radius: 15, backgroundImage: NetworkImage(photo)),
                  title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent, 
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: (myUid == widget.ownerId || (data?['admins'] ?? []).contains(myUid)) 
                      ? () => _unKickUser(uid) : null,
                    child: const Text("Unkick", style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _toggleAdmin(String uid, bool isAdmin) {
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'admins': isAdmin ? FieldValue.arrayRemove([uid]) : FieldValue.arrayUnion([uid])
    });
  }

  void _kickUser(String uid) {
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'followers': FieldValue.arrayRemove([uid]),
      'kickedUsers': FieldValue.arrayUnion([uid])
    });
  }

  void _unKickUser(String uid) {
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'kickedUsers': FieldValue.arrayRemove([uid])
    });
  }
}
