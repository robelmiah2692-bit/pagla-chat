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
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  String getChatRoomId() {
    List<String> ids = [currentUserId, widget.receiverId];
    ids.sort(); 
    return ids.join("_"); 
  }

  // ১. ওয়েবে সেফলি মেসেজ পাঠানোর ফাংশন
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || currentUserId.isEmpty) return;
    String message = _messageController.text.trim();
    _messageController.clear();

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      final String myPic = userDoc.data()?['imageURL'] ?? ''; 
      final String myName = userDoc.data()?['name'] ?? 'User';

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(getChatRoomId())
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'senderName': myName,
        'senderImage': myPic, 
        'receiverId': widget.receiverId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Web Send Error: $e");
    }
  }

  // ২. প্রিমিয়াম প্রোফাইল ডায়ালগ (Web Compatible)
  void _showProfile(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 150);
          
          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final String name = userData['name'] ?? 'User';
          final String pic = userData['imageURL'] ?? '';
          final bool isVIP = userData['isVIP'] ?? false;

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
                  radius: 50,
                  backgroundImage: NetworkImage(pic.isNotEmpty ? pic : 'https://ui-avatars.com/api/?name=$name'),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    if (isVIP) const Icon(Icons.verified, color: Colors.amber, size: 20),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statWidget("Followers", userData['followers'] ?? 0),
                    _statWidget("Following", userData['following'] ?? 0),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, shape: const StadiumBorder()),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Message Now"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statWidget(String label, dynamic count) {
    return Column(
      children: [
        Text(count.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: const Color(0xFF1E1E2F),
        elevation: 0,
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
                
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isMe = data['senderId'] == currentUserId;
                    final String senderPic = data['senderImage'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isMe) GestureDetector(
                            onTap: () => _showProfile(context, data['senderId']),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundImage: NetworkImage(senderPic.isNotEmpty ? senderPic : 'https://ui-avatars.com/api/?name=User'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.pinkAccent : const Color(0xFF1E1E2F),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(data['message'] ?? '', style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isMe) GestureDetector(
                            onTap: () => _showProfile(context, currentUserId),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundImage: NetworkImage(senderPic.isNotEmpty ? senderPic : 'https://ui-avatars.com/api/?name=Me'),
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
          // মডার্ন ওয়েব ইনপুট বক্স
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: "মেসেজ লিখুন...",
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF1E1E2F),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.small(
                  backgroundColor: Colors.pinkAccent,
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
