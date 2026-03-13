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

  // --- ফলোয়ার লিস্ট তৈরির লজিক ---
  Widget _buildFollowerList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var roomData = snapshot.data!.data() as Map<String, dynamic>;
        List followers = roomData['followers'] ?? [];
        List admins = roomData['admins'] ?? [];

        // ফলোয়ারদের র‍্যাঙ্ক অনুযায়ী সাজানো (Owner > Admin > Others)
        followers.sort((a, b) {
          if (a == widget.ownerId) return -1;
          if (b == widget.ownerId) return 1;
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
            bool isOwner = uid == widget.ownerId;
            bool isAdmin = admins.contains(uid);

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const ListTile();
                var userData = userSnap.data!.data() as Map<String, dynamic>;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(userData['photoUrl'] ?? ""),
                  ),
                  title: Text(userData['name'] ?? "User", style: const TextStyle(color: Colors.white)),
                  subtitle: _buildBadge(isOwner, isAdmin),
                  trailing: (myUid == widget.ownerId && uid != myUid) 
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
    if (isOwner) return const Text("👑 Owner", style: TextStyle(color: Colors.amber, fontSize: 12));
    if (isAdmin) return const Text("🛡️ Admin", style: TextStyle(color: Colors.blueAccent, fontSize: 12));
    return const Text("Follower", style: TextStyle(color: Colors.white54, fontSize: 12));
  }

  // --- ওনারের জন্য কন্ট্রোল মেনু ---
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

  // --- কিক লিস্ট তৈরির লজিক ---
  Widget _buildKickList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        List kickedUsers = (snapshot.data!.data() as Map<String, dynamic>)['kickedUsers'] ?? [];

        if (kickedUsers.isEmpty) return const Center(child: Text("No one is kicked", style: TextStyle(color: Colors.white38)));

        return ListView.builder(
          itemCount: kickedUsers.length,
          itemBuilder: (context, index) {
            String uid = kickedUsers[index];
            return ListTile(
              title: Text(uid, style: const TextStyle(color: Colors.white)),
              trailing: ElevatedButton(
                onPressed: () => _unKickUser(uid),
                child: const Text("Unkick"),
              ),
            );
          },
        );
      },
    );
  }

  // --- ডাটাবেস ফাংশনসমূহ ---
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
