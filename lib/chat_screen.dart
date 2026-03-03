import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile_dialog.dart'; // নতুন ডায়ালগ ফাইলটি ইমপোর্ট করলাম

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

  // চ্যাট রুম আইডি বানানোর সঠিক লজিক
  String getChatRoomId() {
    List<String> ids = [currentUserId, widget.receiverId];
    ids.sort(); 
    return ids.join("_"); 
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String message = _messageController.text.trim();
    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(getChatRoomId())
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: Text(widget.receiverName, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2F),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(getChatRoomId())
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index];
                    bool isMe = data['senderId'] == currentUserId;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // অন্যের মেসেজ হলে বামে ছবি দেখাবে
                          if (!isMe)
                            GestureDetector(
                              onTap: () => showUserProfile(context, data['senderId']),
                              child: const CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage('https://via.placeholder.com/150'), // পরে আমরা রিয়েল অবতার বসাবো
                              ),
                            ),
                          
                          const SizedBox(width: 8),

                          Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.pinkAccent : Colors.grey[800],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(15),
                                topRight: const Radius.circular(15),
                                bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
                                bottomRight: isMe ? Radius.zero : const Radius.circular(15),
                              ),
                            ),
                            child: Text(
                              data['message'], 
                              style: const TextStyle(color: Colors.white)
                            ),
                          ),

                          const SizedBox(width: 8),

                          // নিজের মেসেজ হলে ডানে ছবি দেখাবে
                          if (isMe)
                            GestureDetector(
                              onTap: () => showUserProfile(context, currentUserId),
                              child: const CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "মেসেজ লিখুন...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1E1E2F),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.pinkAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
