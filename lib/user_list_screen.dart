import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart'; // ফ্রেমের জন্য
import 'package:pagla_chat/profile_page.dart';
import 'package:pagla_chat/services/follow_service.dart';


class UserListScreen extends StatefulWidget {
  final String title;
  final String userId;
  final String mySixDigitUID;

  const UserListScreen({super.key, required this.title, required this.userId, required this.mySixDigitUID});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  Widget build(BuildContext context) {
    String collectionPath = widget.title.toLowerCase() == "followers" ? "followersList" : "followingList";

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).collection(collectionPath).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
          if (snapshot.data!.docs.isEmpty) return Center(child: Text("কোনো ${widget.title} নেই", style: const TextStyle(color: Colors.white54)));

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              return UserCard(targetUid: snapshot.data!.docs[index].id, myUid: widget.mySixDigitUID);
            },
          );
        },
      ),
    );
  }
}

class UserCard extends StatefulWidget {
  final String targetUid;
  final String myUid;

  const UserCard({super.key, required this.targetUid, required this.myUid});

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    checkStatus();
  }

  void checkStatus() async {
    bool status = await FollowService().checkIfFollowing(widget.targetUid, widget.myUid);
    if (mounted) setState(() => isFollowing = status);
  }

  // প্রোফাইলে যাওয়ার লজিক
  void _onProfileTap(BuildContext context, String userId) async {
    String finalIdToPass = userId;
    try {
      var userQuery = await FirebaseFirestore.instance.collection('users').where('authUID', isEqualTo: userId).limit(1).get();
      if (userQuery.docs.isNotEmpty) {
        finalIdToPass = userQuery.docs.first.data()['uID']?.toString() ?? userId;
      }
    } catch (e) {}

    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userId: finalIdToPass)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.targetUid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var data = snapshot.data!.data() as Map<String, dynamic>;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ListTile(
            onTap: () => _onProfileTap(context, widget.targetUid),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(data['profilePic'] ?? "https://via.placeholder.com/150"),
                ),
                // ফ্রেম লজিক
                if (data['activeFrameUrl'] != null && data['activeFrameUrl'].toString().isNotEmpty)
                  Positioned.fill(
                    child: Transform.scale(
                      scale: 2.2,
                      child: IgnorePointer(
                        child: data['activeFrameUrl'].toString().contains('.json')
                            ? Lottie.network(data['activeFrameUrl'], fit: BoxFit.contain, errorBuilder: (c, e, s) => const SizedBox())
                            : Image.network(data['activeFrameUrl'], fit: BoxFit.contain, errorBuilder: (c, e, s) => const SizedBox()),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(data['name'] ?? "Unknown", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: ElevatedButton(
              onPressed: () async {
                bool newStatus = await FollowService().toggleFollowUser(widget.targetUid, widget.myUid);
                if (mounted) setState(() => isFollowing = newStatus);
              },
              style: ElevatedButton.styleFrom(backgroundColor: isFollowing ? Colors.blueGrey : Colors.pinkAccent),
              child: Text(isFollowing ? "Friend" : "Follow Back"),
            ),
          ),
        );
      },
    );
  }
}