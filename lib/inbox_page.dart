import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'chat_screen.dart';
import 'screens/voice_room.dart'; // পাথ প্রয়োজন অনুযায়ী ঠিক করে নিন

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});
  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // মেসেজ সিন (isRead) করার ফাংশন
  void _markAsRead(String chatId) async {
    try {
      var unreadMessages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      debugPrint("Read Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildSearchBar(),
              Expanded(child: _buildUserList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Inbox",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.pinkAccent),
            onPressed: () {},
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Search by Name or ID...",
                hintStyle: TextStyle(color: Colors.white24),
                prefixIcon: Icon(Icons.search, color: Colors.cyanAccent),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
        }

        var users = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = (data['name'] ?? "").toString().toLowerCase();
          String customId = (data['uID'] ?? "").toString().toLowerCase();
          return name.contains(_searchQuery.toLowerCase()) || customId.contains(_searchQuery.toLowerCase());
        }).toList();

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getSortedUserStream(users),
          builder: (context, sortedSnapshot) {
            if (!sortedSnapshot.hasData) return const SizedBox.shrink();
            final sortedList = sortedSnapshot.data!;

            return ListView.builder(
              itemCount: sortedList.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (context, index) {
                var userData = sortedList[index]['data'] as Map<String, dynamic>;
                String userId = sortedList[index]['id'];
                String chatId = sortedList[index]['chatId'];

                if (userId == currentUserId) return const SizedBox.shrink();
                return _buildGlassChatTile(userData, userId, chatId);
              },
            );
          },
        );
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _getSortedUserStream(List<QueryDocumentSnapshot> users) {
    return Stream.fromFuture(Future.wait(users.map((user) async {
      String userId = user.id;
      var userData = user.data() as Map<String, dynamic>;
      String uID = (userData['uID'] ?? "").toString();
      
      String chatId;
      
      // অফিসিয়াল মেসেজের জন্য আপনার ডেটাবেস স্ট্রাকচার অনুযায়ী আইডি তৈরি
      if (uID == "paglachat_official") {
        chatId = "paglachat_official_$currentUserId"; 
      } else {
        List<String> ids = [currentUserId, userId];
        ids.sort();
        chatId = ids.join("_");
      }

      var lastMsg = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      Timestamp lastTs = lastMsg.docs.isNotEmpty
          ? (lastMsg.docs.first['timestamp'] as Timestamp? ?? Timestamp.now())
          : Timestamp.fromMillisecondsSinceEpoch(0);

      return {
        'id': userId,
        'data': userData,
        'chatId': chatId,
        'lastTs': lastTs
      };
    }))).map((list) {
      list.sort((a, b) {
        final Map<String, dynamic> aData = a['data'] as Map<String, dynamic>;
        final Map<String, dynamic> bData = b['data'] as Map<String, dynamic>;

        String aUID = (aData['uID'] ?? "").toString();
        String bUID = (bData['uID'] ?? "").toString();

        // Official অ্যাকাউন্ট সবসময় উপরে থাকবে
        if (aUID == "paglachat_official") return -1;
        if (bUID == "paglachat_official") return 1;

        // বাকিরা শেষ মেসেজ অনুযায়ী সর্ট হবে
        return (b['lastTs'] as Timestamp).compareTo(a['lastTs'] as Timestamp);
      });
      return list;
    });
  }

  Widget _buildGlassChatTile(Map<String, dynamic> userData, String userId, String chatId) {
    String displayId = (userData['uID'] ?? "N/A").toString();
    String name = userData['name'] ?? "User";
    String image = userData['profilePic'] ?? "";
    bool isLive = userData['currentRoomId'] != null && userData['currentRoomId'].toString().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: ListTile(
              onTap: () {
                _markAsRead(chatId);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ChatScreen(receiverId: userId, receiverName: name, receiverData: userData),
                ));
              },
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                    backgroundColor: Colors.white10,
                    child: image.isEmpty ? Text(name[0], style: const TextStyle(color: Colors.white)) : null,
                  ),
                  if (userData['isOnline'] == true)
                    Positioned(bottom: 2, right: 2, child: Container(height: 12, width: 12, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)))),
                ],
              ),
              title: Row(
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  if (isLive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(5)),
                      child: const Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ]
                ],
              ),
              subtitle: Text("ID: $displayId", style: const TextStyle(color: Colors.white38, fontSize: 12)),
              trailing: _buildUnreadCounter(chatId),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadCounter(String chatId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.pinkAccent, shape: BoxShape.circle),
            child: Text("${snapshot.data!.docs.length}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          );
        }
        return const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14);
      },
    );
  }
}
