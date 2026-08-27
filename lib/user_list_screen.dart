import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart'; // ফ্রেমের জন্য
import 'package:pagla_chat/profile_page.dart';
import 'package:pagla_chat/services/follow_service.dart';

class UserListScreen extends StatefulWidget {
  final String title;
  final String userId;
  final String mySixDigitUID;

  const UserListScreen(
      {super.key,
      required this.title,
      required this.userId,
      required this.mySixDigitUID});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  Widget build(BuildContext context) {
    String collectionPath = widget.title.toLowerCase() == "followers"
        ? "followersList"
        : "followingList";

    return Scaffold(
      backgroundColor:
          const Color(0xFF190033), // সেটিংস পেজের সাথে সামঞ্জস্যপূর্ণ বেস কালার
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(color: Colors.cyanAccent)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: Container(
        decoration: const BoxDecoration(
          // সেটিংস পেজের হুবহু প্রিমিয়াম ব্লু ও পার্পল গ্রেডিয়েন্ট
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00B4DB), // Bright Cyan Blue
              Color(0xFF0083B0), // Mid Blue tone
              Color(0xFF4A00E0), // Deep Purple gradient match
              Color(0xFF190033), // Rich dark purple-blue base
            ],
          ),
        ),
        child: Stack(
          children: [
            // ব্যাকগ্রাউন্ডে তারার ঝিকিমিকি ইফেক্ট
            ...List.generate(
              15,
              (index) => Positioned(
                top: (index * 50.0) % 500,
                left: (index * 80.0) % 380,
                child: Icon(
                  Icons.star,
                  size: index % 3 == 0 ? 12 : 6,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection(collectionPath)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Colors.cyanAccent));
                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text("কোনো ${widget.title} নেই",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    return UserCard(
                        targetUid: snapshot.data!.docs[index].id,
                        myUid: widget.mySixDigitUID);
                  },
                );
              },
            ),
          ],
        ),
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
    bool status =
        await FollowService().checkIfFollowing(widget.targetUid, widget.myUid);
    if (mounted) setState(() => isFollowing = status);
  }

  // প্রোফাইলে যাওয়ার লজিক
  void _onProfileTap(BuildContext context, String userId) async {
    String finalIdToPass = userId;
    try {
      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: userId)
          .limit(1)
          .get();
      if (userQuery.docs.isNotEmpty) {
        finalIdToPass =
            userQuery.docs.first.data()['uID']?.toString() ?? userId;
      }
    } catch (e) {}

    if (!context.mounted) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProfilePage(userId: finalIdToPass)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.targetUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var data = snapshot.data!.data() as Map<String, dynamic>;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            // সেটিংস পেজের মতো গ্লাস ইফেক্ট কার্ড ডিজাইন
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
              )
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: () => _onProfileTap(context, widget.targetUid),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white24,
                  backgroundImage: NetworkImage(
                      data['profilePic'] ?? "https://via.placeholder.com/150"),
                ),
                // ফ্রেম লজিক অপরিবর্তিত রাখা হয়েছে
                if (data['activeFrameUrl'] != null &&
                    data['activeFrameUrl'].toString().isNotEmpty)
                  Positioned.fill(
                    child: Transform.scale(
                      scale: 2.2,
                      child: IgnorePointer(
                        child: data['activeFrameUrl']
                                .toString()
                                .contains('.json')
                            ? Lottie.network(data['activeFrameUrl'],
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const SizedBox())
                            : Image.network(data['activeFrameUrl'],
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const SizedBox()),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(data['name'] ?? "Unknown",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: ElevatedButton(
              onPressed: () async {
                bool newStatus = await FollowService()
                    .toggleFollowUser(widget.targetUid, widget.myUid);
                if (mounted) setState(() => isFollowing = newStatus);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isFollowing ? Colors.blueGrey : Colors.pinkAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isFollowing ? "Friend" : "Follow Back"),
            ),
          ),
        );
      },
    );
  }
}
