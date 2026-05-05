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
  // 🔥 ফিক্স: ৬-ডিজিটের ID লোড করার জন্য ভেরিয়েবল
  String myuID = "";

  @override
  void initState() {
    super.initState();
    _fetchMyCustomID();
  }

  // ফায়ারবেস অথ আইডি দিয়ে আপনার ৬-ডিজিটের কাস্টম uID খুঁজে বের করা
  Future<void> _fetchMyCustomID() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: user.uid)
          .limit(1)
          .get();
      
      if (userDoc.docs.isNotEmpty && mounted) {
        setState(() {
          myuID = userDoc.docs.first.data()['uID']?.toString() ?? "";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        height: 600,
        decoration: const BoxDecoration(
          color: Color(0xFF87CEEB), 
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const TabBar(
              indicatorColor: Colors.pinkAccent,
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.black45,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: "Followers"),
                Tab(text: "Kick List"),
              ],
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A2E), 
                ),
                child: TabBarView(
                  children: [
                    _buildFollowerList(),
                    _buildKickList(),
                  ],
                ),
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
        if (!snapshot.data!.exists) return const Center(child: Text("রুম পাওয়া যায়নি", style: TextStyle(color: Colors.white54)));

        var roomData = snapshot.data!.data() as Map<String, dynamic>;
        String actualOwnerId = roomData['uID']?.toString() ?? roomData['ownerId']?.toString() ?? widget.ownerId;
        
        List<dynamic> followers = List.from(roomData['followers'] ?? []);
        List<dynamic> admins = List.from(roomData['admins'] ?? []);

        if (actualOwnerId.isNotEmpty && !followers.contains(actualOwnerId)) {
          followers.add(actualOwnerId);
        }

        followers.sort((a, b) {
          if (a.toString() == actualOwnerId) return -1;
          if (b.toString() == actualOwnerId) return 1;
          bool aIsAdmin = admins.contains(a);
          bool bIsAdmin = admins.contains(b);
          if (aIsAdmin && !bIsAdmin) return -1;
          if (!aIsAdmin && bIsAdmin) return 1;
          return 0;
        });

        return ListView.builder(
          itemCount: followers.length,
          itemBuilder: (context, index) {
            String targetuID = followers[index].toString();
            bool isTargetOwner = (targetuID == actualOwnerId);
            bool isTargetAdmin = admins.contains(targetuID);

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(targetuID).get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const SizedBox();
                var userData = userSnap.data?.data() as Map<String, dynamic>?;
                
                String name = userData?['name'] ?? "ইউজার $targetuID"; 
                String photo = userData?['profilepic'] ?? userData?['profilePic'] ?? "";

                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[900],
                        backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                        child: photo.isEmpty ? const Icon(Icons.person, color: Colors.white54) : null,
                      ),
                      if (isTargetOwner)
                        const Positioned(right: -2, bottom: -2, child: Icon(Icons.stars, color: Colors.amber, size: 18)),
                    ],
                  ),
                  title: Text(name, style: TextStyle(color: isTargetOwner ? Colors.amber : Colors.white, fontWeight: isTargetOwner ? FontWeight.bold : FontWeight.normal)),
                  subtitle: _buildBadge(isTargetOwner, isTargetAdmin),
                  trailing: _shouldShowMenu(myuID, actualOwnerId, targetuID, isTargetOwner, isTargetAdmin, admins) 
                      ? IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white54),
                          onPressed: () => _showAdminOptions(targetuID, isTargetAdmin, actualOwnerId),
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

  Widget _buildKickList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox();

        String actualOwnerId = data['uID']?.toString() ?? data['ownerId']?.toString() ?? widget.ownerId;
        List kickedUsers = data['kickedUsers'] ?? [];
        List admins = data['admins'] ?? [];

        if (kickedUsers.isEmpty) return const Center(child: Text("কেউ কিক লিস্টে নেই", style: TextStyle(color: Colors.white38)));

        return ListView.builder(
          itemCount: kickedUsers.length,
          itemBuilder: (context, index) {
            String targetuID = kickedUsers[index].toString();
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(targetuID).get(),
              builder: (context, userSnap) {
                var userData = userSnap.data?.data() as Map<String, dynamic>?;
                String name = userData?['name'] ?? "User $targetuID";
                String photo = userData?['profilepic'] ?? userData?['profilePic'] ?? "";

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  title: Text(name, style: const TextStyle(color: Colors.white)),
                  trailing: (myuID == actualOwnerId || admins.contains(myuID)) 
                    ? IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.greenAccent),
                        onPressed: () => _unKickUser(targetuID),
                      ) : null,
                );
              },
            );
          },
        );
      },
    );
  }

  bool _shouldShowMenu(String me, String owner, String target, bool isTargetOwner, bool isTargetAdmin, List admins) {
    if (me.isEmpty || me == target) return false;
    if (me == owner) return true;
    if (admins.contains(me) && !isTargetOwner && !isTargetAdmin) return true;
    return false;
  }

  Widget _buildBadge(bool isOwner, bool isAdmin) {
    if (isOwner) return const Text("👑 Room Owner", style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold));
    if (isAdmin) return const Text("🛡️ Admin", style: TextStyle(color: Colors.blueAccent, fontSize: 12));
    return const Text("Follower", style: TextStyle(color: Colors.white54, fontSize: 12));
  }

  void _showAdminOptions(String targetuID, bool isTargetAdmin, String actualOwnerId) {
    bool iAmOwner = (myuID == actualOwnerId);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          if (iAmOwner)
            ListTile(
              leading: Icon(isTargetAdmin ? Icons.remove_moderator : Icons.add_moderator, color: Colors.blue),
              title: Text(isTargetAdmin ? "Remove Admin" : "Make Admin", style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _toggleAdmin(targetuID, isTargetAdmin);
              },
            ),
          ListTile(
            leading: const Icon(Icons.gavel, color: Colors.red),
            title: const Text("Kick User", style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _kickUser(targetuID);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _toggleAdmin(String targetuID, bool isAdmin) {
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'admins': isAdmin 
          ? FieldValue.arrayRemove([targetuID]) 
          : FieldValue.arrayUnion([targetuID]),
    });
  }

  void _kickUser(String targetuID) {
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'followers': FieldValue.arrayRemove([targetuID]),
      'kickedUsers': FieldValue.arrayUnion([targetuID])
    });
  }

  void _unKickUser(String targetuID) {
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'kickedUsers': FieldValue.arrayRemove([targetuID])
    });
  }
}