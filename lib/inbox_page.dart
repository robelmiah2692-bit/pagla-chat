import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'chat_screen.dart';
import 'screens/voice_room.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});
  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

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
          const Text("Inbox", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                hintText: "Search by User ID...",
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));

        var users = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = (data['name'] ?? "").toString().toLowerCase();
          
          // এখানে সার্চের জন্য সব ধরণের আইডি চেক করা হচ্ছে
          String customId = (data['uID'] ?? data['userId'] ?? data['uid'] ?? "").toString().toLowerCase();
          
          return name.contains(_searchQuery.toLowerCase()) || customId.contains(_searchQuery.toLowerCase());
        }).toList();

        // Paglachat Official মেসেজ প্রায়োরিটি
        users.sort((a, b) {
          var aData = a.data() as Map<String, dynamic>;
          var bData = b.data() as Map<String, dynamic>;
          String aId = (aData['uID'] ?? aData['userId'] ?? "").toString();
          if (aId == "paglachat_official") return -1;
          return 1;
        });

        return ListView.builder(
          itemCount: users.length,
          padding: const EdgeInsets.all(10),
          itemBuilder: (context, index) {
            var userData = users[index].data() as Map<String, dynamic>;
            String userId = users[index].id;
            if (userId == currentUserId) return const SizedBox.shrink();

            return _buildGlassChatTile(userData, userId);
          },
        );
      },
    );
  }

  Widget _buildGlassChatTile(Map<String, dynamic> userData, String userId) {
    // আইডি দেখানোর সময় সব ধরণের সম্ভাবনা (uID, userId, uid) চেক করা হচ্ছে
    String displayId = (userData['uID'] ?? userData['userId'] ?? userData['uid'] ?? "N/A").toString();
    
    String name = userData['name'] ?? "User";
    String image = userData['profilePic'] ?? userData['imageURL'] ?? "";
    bool isLive = userData['currentRoomId'] != null;

    List<String> chatIds = [currentUserId, userId];
    chatIds.sort();
    String chatId = chatIds.join("_");

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
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (context) => ChatScreen(receiverId: userId, receiverName: name, receiverData: userData),
              )),
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

// আপনার ChatScreen-এ ব্যবহারের জন্য আলাদা ফাংশন
Widget _buildLiveRoomBar(BuildContext context, Map<String, dynamic> receiverData) {
  if (receiverData['currentRoomId'] == null) return const SizedBox.shrink();
  
  return Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Colors.pinkAccent, Colors.deepPurple]),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        const Icon(Icons.live_tv, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "${receiverData['name']} is Live in: ${receiverData['currentRoomName'] ?? 'Voice Room'}",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.pinkAccent, shape: const StadiumBorder()),
          onPressed: () {
             Navigator.push(context, MaterialPageRoute(builder: (context) => VoiceRoom(roomId: receiverData['currentRoomId'])));
          }, 
          child: const Text("Join"),
        )
      ],
    ),
  );
}
