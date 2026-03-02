import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// সঠিক পাথ ব্যবহার করে ইম্পোর্ট করুন
import 'services/chat_service.dart'; 

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
        backgroundColor: Colors.transparent, 
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search, color: Colors.pinkAccent), 
            onPressed: () {}
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(), 
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // [FIX] snapshot.data!.docs এর টাইপ এখানে অটো হ্যান্ডেল হবে
          var users = snapshot.data!.docs;
          
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index].data() as Map<String, dynamic>;
              
              // নিজের আইডি লিস্টে হাইড করে রাখা
              if (users[index].id == _auth.currentUser?.uid) return const SizedBox.shrink();

              return _buildChatTile({
                "name": user['name'] ?? user['userName'] ?? "User",
                "id": users[index].id,
                "isOnline": user['isOnline'] ?? false,
                "currentRoom": user['currentRoom'] ?? "",
                "lastMsg": "মেসেজ করতে ক্লিক করুন...",
                "image": user['profilePic'] ?? user['userImageURL'] ?? ""
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
        backgroundImage: (friend['image'] != null && friend['image'].isNotEmpty) 
            ? NetworkImage(friend['image']) 
            : null,
        child: (friend['image'] == null || friend['image'].isEmpty) 
            ? const Icon(Icons.person) 
            : null,
      ),
      title: Text(friend["name"], style: const TextStyle(color: Colors.white)),
      subtitle: Text(friend["lastMsg"], style: const TextStyle(color: Colors.white38, fontSize: 12)),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => 
          IndividualChatPage(receiverId: friend['id'], receiverName: friend['name'])));
      },
    );
  }
}

// --- চ্যাট বক্স স্ক্রিন ---
class IndividualChatPage extends StatelessWidget {
  final String receiverId;
  final String receiverName;
  IndividualChatPage({super.key, required this.receiverId, required this.receiverName});

  final TextEditingController _msgController = TextEditingController();
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: Text(receiverName), 
        backgroundColor: Colors.pinkAccent
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(FirebaseAuth.instance.currentUser!.uid, receiverId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                
                // [FIX] .docs এরর কাটাতে টাইপ কাস্টিং করা হয়েছে
                var docs = snapshot.data!.docs;
                
                return ListView.builder(
                  reverse: false, // মেসেজ নিচে থেকে উপরে দেখানোর জন্য
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == FirebaseAuth.instance.currentUser!.uid;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10), 
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.pinkAccent : Colors.grey[800], 
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: Text(data['message'] ?? "", style: const TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController, 
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "মেসেজ লিখুন...",
                      hintStyle: TextStyle(color: Colors.white38)
                    ),
                  )
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.pinkAccent), 
                  onPressed: () {
                    if (_msgController.text.trim().isNotEmpty) {
                      _chatService.sendMessage(receiverId, _msgController.text.trim());
                      _msgController.clear();
                    }
                  }
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
