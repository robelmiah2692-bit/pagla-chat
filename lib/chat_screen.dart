import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({super.key, required this.receiverId, required this.receiverName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  String getChatRoomId() {
    List<String> ids = [currentUserId, widget.receiverId];
    ids.sort(); 
    return ids.join("_"); 
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    String message = _messageController.text.trim();
    _messageController.clear();

    var userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    String myPic = userDoc.data()?['imageURL'] ?? ''; 

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(getChatRoomId())
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'senderImage': myPic, 
      'receiverId': widget.receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _showProfile(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 100);
          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E2F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(userData['imageURL'] ?? 'https://via.placeholder.com/150'),
                ),
                const SizedBox(height: 10),
                Text(userData['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text("Followers: ${userData['followers'] ?? 0}", style: const TextStyle(color: Colors.white70)),
                    Text("Following: ${userData['following'] ?? 0}", style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(title: Text(widget.receiverName), backgroundColor: const Color(0xFF1E1E2F)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(getChatRoomId()).collection('messages').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index];
                    bool isMe = data['senderId'] == currentUserId;
                    return ListTile(
                      leading: isMe ? null : GestureDetector(
                        onTap: () => _showProfile(context, data['senderId']),
                        child: CircleAvatar(backgroundImage: NetworkImage(data['senderImage'] ?? '')),
                      ),
                      trailing: isMe ? GestureDetector(
                        onTap: () => _showProfile(context, currentUserId),
                        child: CircleAvatar(backgroundImage: NetworkImage(data['senderImage'] ?? '')),
                      ) : null,
                      title: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: isMe ? Colors.pinkAccent : Colors.grey[800], borderRadius: BorderRadius.circular(10)),
                          child: Text(data['message'], style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          TextField(controller: _messageController, decoration: InputDecoration(suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage))),
        ],
      ),
    );
  }
}
