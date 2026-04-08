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
  // 🔥 ফিক্স: AppData.myID (৬-ডিজিটের আইডি) ব্যবহার করা সবচেয়ে নিরাপদ
  final String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        height: 600,
        decoration: const BoxDecoration(
          // আপনার স্ক্রিনশট অনুযায়ী প্রিমিয়াম লাইট ব্লু কালার
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
                  color: Color(0xFF1A1A2E), // লিস্টের ভেতরটা ডার্ক রাখা হয়েছে ক্লারিটির জন্য
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
        
        // ⚔️ চোর জবাই: শুধু ownerId অথবা uID (৬-ডিজিটের আইডি) চেক হবে
        String actualOwnerId = roomData['ownerId'] ?? roomData['uID'] ?? widget.ownerId;
        
        List<dynamic> followers = List.from(roomData['followers'] ?? []);
        
        // ⚔️ চোর জবাই: 'adminList' বাদ দিয়ে শুধু 'admins' (অ্যারে) ব্যবহার হবে
        List<dynamic> admins = List.from(roomData['admins'] ?? []);

        if (actualOwnerId.isNotEmpty && !followers.contains(actualOwnerId)) {
          followers.add(actualOwnerId);
        }

        // সর্টিং: মালিক সবার উপরে
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
            String targetUid = followers[index];
            bool isTargetOwner = (targetUid == actualOwnerId);
            bool isTargetAdmin = admins.contains(targetUid);

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(targetUid).get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const SizedBox();
                var userData = userSnap.data?.data() as Map<String, dynamic>?;
                
                String name = userData?['name'] ?? "পাগলা ইউজার"; 
                String photo = userData?['profilePic'] ?? "";

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
                  trailing: _shouldShowMenu(myUid, actualOwnerId, targetUid, isTargetOwner, isTargetAdmin, admins) 
                      ? IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white54),
                          onPressed: () => _showAdminOptions(targetUid, isTargetAdmin, actualOwnerId),
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

        String actualOwnerId = data['ownerId'] ?? data['uID'] ?? widget.ownerId;
        List kickedUsers = data['kickedUsers'] ?? [];
        List admins = data['admins'] ?? [];

        if (kickedUsers.isEmpty) return const Center(child: Text("কেউ কিক লিস্টে নেই", style: TextStyle(color: Colors.white38)));

        return ListView.builder(
          itemCount: kickedUsers.length,
          itemBuilder: (context, index) {
            String targetUid = kickedUsers[index];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(targetUid).get(),
              builder: (context, userSnap) {
                var userData = userSnap.data?.data() as Map<String, dynamic>?;
                
                String name = userData?['name'] ?? "User";
                String photo = userData?['profilePic'] ?? "";

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  title: Text(name, style: const TextStyle(color: Colors.white)),
                  trailing: (myUid == actualOwnerId || admins.contains(myUid)) 
                    ? IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.greenAccent),
                        onPressed: () => _unKickUser(targetUid),
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
    if (me == target) return false;
    // এখানে 'me' কে অবশ্যই ৬-ডিজিটের আইডি হতে হবে যদি ডাটাবেসের owner আইডি ৬-ডিজিটের হয়
    if (me == owner) return true;
    if (admins.contains(me) && !isTargetOwner && !isTargetAdmin) return true;
    return false;
  }

  Widget _buildBadge(bool isOwner, bool isAdmin) {
    if (isOwner) return const Text("👑 Room Owner", style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold));
    if (isAdmin) return const Text("🛡️ Admin", style: TextStyle(color: Colors.blueAccent, fontSize: 12));
    return const Text("Follower", style: TextStyle(color: Colors.white54, fontSize: 12));
  }

  void _showAdminOptions(String targetUid, bool isTargetAdmin, String actualOwnerId) {
    bool iAmOwner = (myUid == actualOwnerId);

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
                _toggleAdmin(targetUid, isTargetAdmin);
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ⚔️ চোর জবাই ফিক্স: শুধুমাত্র 'admins' অ্যারে আপডেট হবে
  void _toggleAdmin(String targetUid, bool isAdmin) {
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'admins': isAdmin 
          ? FieldValue.arrayRemove([targetUid]) 
          : FieldValue.arrayUnion([targetUid]),
    });
  }

  void _kickUser(String targetUid) {
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'followers': FieldValue.arrayRemove([targetUid]),
      'kickedUsers': FieldValue.arrayUnion([targetUid])
    });
  }

  void _unKickUser(String targetUid) {
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'kickedUsers': FieldValue.arrayRemove([targetUid])
    });
  }
}
