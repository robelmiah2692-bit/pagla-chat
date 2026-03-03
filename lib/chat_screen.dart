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

    // ইউজারের রিয়েল প্রোফাইল ডাটাবেস থেকে ছবি নেওয়া
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

  // প্রিমিয়াম লুকের প্রোফাইল কার্ড (গ্লাস ইফেক্ট)
  void _showProfile(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2F).withOpacity(0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: Colors.white10, width: 0.5),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            var userData = snapshot.data!.data() as Map<String, dynamic>;
            String pic = userData['imageURL'] ?? '';
            bool isVIP = userData['isVIP'] ?? false;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.pinkAccent,
                      child: CircleAvatar(
                        radius: 61,
                        backgroundImage: NetworkImage(pic.isNotEmpty ? pic : 'https://via.placeholder.com/150'),
                      ),
                    ),
                    if (isVIP) 
                      const Positioned(bottom: 5, right: 5, child: Icon(Icons.verified, color: Colors.amber, size: 35)),
                  ],
                ),
                const SizedBox(height: 15),
                Text(userData['name'] ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCol("Followers", userData['followers'] ?? 0),
                    _buildStatCol("Following", userData['following'] ?? 0),
                  ],
                ),
                const SizedBox(height: 35),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {
                          // এখানে ফলো করার কোড বসবে
                        }, 
                        child: const Text("Follow", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, int count) {
    return Column(
      children: [
        Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E2F),
        title: Text(widget.receiverName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                  padding: const EdgeInsets.all(15),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index];
                    bool isMe = data['senderId'] == currentUserId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isMe) GestureDetector(
                            onTap: () => _showProfile(context, data['senderId']),
                            child: CircleAvatar(radius: 22, backgroundImage: NetworkImage(data['senderImage'] ?? 'https://via.placeholder.com/150')),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.pinkAccent : const Color(0xFF1E1E2F),
                              borderRadius: BorderRadius.circular(25).copyWith(
                                bottomLeft: isMe ? const Radius.circular(25) : const Radius.circular(5),
                                bottomRight: isMe ? const Radius.circular(5) : const Radius.circular(25),
                              ),
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
                              ],
                            ),
                            child: Text(data['message'], style: const TextStyle(color: Colors.white, fontSize: 15.5)),
                          ),
                          const SizedBox(width: 12),
                          if (isMe) GestureDetector(
                            onTap: () => _showProfile(context, currentUserId),
                            child: CircleAvatar(radius: 22, backgroundImage: NetworkImage(data['senderImage'] ?? 'https://via.placeholder.com/150')),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // মডার্ন ইনপুট ফিল্ড
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E2F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Write a message...",
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF0D0D1A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(color: Colors.pinkAccent, shape: BoxShape.circle),
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 22), onPressed: _sendMessage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
