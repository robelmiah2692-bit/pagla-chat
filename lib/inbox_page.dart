import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_service.dart'; // ওপরের ফাইলটি ইম্পোর্ট করুন

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});
  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text("ইনবক্স", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.person_search, color: Colors.pinkAccent), onPressed: () {})],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(), // সব ইউজারদের লিস্ট
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index].data() as Map<String, dynamic>;
              if (users[index].id == _auth.currentUser?.uid) return const SizedBox.shrink();

              return _buildChatTile({
                "name": user['userName'] ?? "User",
                "id": users[index].id,
                "isOnline": user['isOnline'] ?? false,
                "currentRoom": user['currentRoom'] ?? "",
                "lastMsg": "মেসেজ করতে ক্লিক করুন...",
                "image": user['userImageURL'] ?? ""
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> friend) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: friend['image'].isNotEmpty ? NetworkImage(friend['image']) : null,
        child: friend['image'].isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(friend["name"], style: const TextStyle(color: Colors.white)),
      subtitle: Text(friend["lastMsg"], style: const TextStyle(color: Colors.white38, fontSize: 12)),
      onTap: () {
        // ক্লিক করলে চ্যাট বক্স খুলবে
        Navigator.push(context, MaterialPageRoute(builder: (context) => 
          IndividualChatPage(receiverId: friend['id'], receiverName: friend['name'])));
      },
    );
  }
}

// --- চ্যাট বক্স (মেসেজ আদান-প্রদান করার স্ক্রিন) ---
class IndividualChatPage extends StatelessWidget {
  final String receiverId;
  final String receiverName;
  IndividualChatPage({required this.receiverId, required this.receiverName});

  final TextEditingController _msgController = TextEditingController();
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(title: Text(receiverName), backgroundColor: Colors.pinkAccent),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _chatService.getMessages(FirebaseAuth.instance.currentUser!.uid, receiverId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) => Align(
                    alignment: docs[index]['senderId'] == FirebaseAuth.instance.currentUser!.uid ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(10), margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: Colors.pinkAccent.withOpacity(0.8), borderRadius: BorderRadius.circular(10)),
                      child: Text(docs[index]['message'], style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _msgController, style: const TextStyle(color: Colors.white))),
                IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: () {
                  _chatService.sendMessage(receiverId, _msgController.text);
                  _msgController.clear();
                })
              ],
            ),
          )
        ],
      ),
    );
  }
}
