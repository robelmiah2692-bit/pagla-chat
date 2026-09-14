import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pagla_chat/profile_page.dart';


class TeamPanelChatRoom extends StatefulWidget {
  final String ownerDocId;
  final String panelName;

  const TeamPanelChatRoom({Key? key, required this.ownerDocId, required this.panelName}) : super(key: key);

  @override
  _TeamPanelChatRoomState createState() => _TeamPanelChatRoomState();
}

class _TeamPanelChatRoomState extends State<TeamPanelChatRoom> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    String text = _messageController.text.trim();
    if (text.isEmpty) return;

    String currentAuthUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentAuthUid.isEmpty) return;

    try {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(currentAuthUid).get();
      String userName = 'User';
      String profilePic = '';
      String uniqueId = currentAuthUid;

      if (userDoc.exists) {
        var data = userDoc.data()!;
        userName = data['name'] ?? data['userName'] ?? 'User';
        profilePic = data['profilePic'] ?? data['userImage'] ?? '';
        uniqueId = userDoc.id;
      } else {
        var query = await FirebaseFirestore.instance.collection('users').where('authUID', isEqualTo: currentAuthUid).limit(1).get();
        if (query.docs.isNotEmpty) {
          var data = query.docs.first.data();
          userName = data['name'] ?? data['userName'] ?? 'User';
          profilePic = data['profilePic'] ?? data['userImage'] ?? '';
          uniqueId = query.docs.first.id;
        }
      }

      await FirebaseFirestore.instance
          .collection('team_panels')
          .doc(widget.ownerDocId)
          .collection('chats')
          .add({
        'senderId': uniqueId,
        'senderName': userName,
        'senderPic': profilePic,
        'message': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // 👤 ইউজারের প্রোফাইলে যাওয়ার ফাংশন
  void _openUserProfile(String senderId) async {
    if (senderId.isEmpty) return;

    String finalIdToPass = senderId;
    try {
      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: senderId)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        finalIdToPass = userQuery.docs.first.data()['uID']?.toString() ??
            userQuery.docs.first.id;
      }
    } catch (e) {
      debugPrint("❌ প্রোফাইল আইডি লোড করতে ব্যর্থ: $e");
    }

    if (!mounted) return;

    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: finalIdToPass),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F1C2C), Color(0xFF4A154B), Color(0xFF1B2A4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('team_panels')
                  .doc(widget.ownerDocId)
                  .collection('chats')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Colors.amber));
                }

                var messages = snapshot.data!.docs;
                if (messages.isEmpty) {
                  return const Center(
                    child: Text("No messages yet. Start chatting!", style: TextStyle(color: Colors.white54)),
                  );
                }

                String currentAuthUid = FirebaseAuth.instance.currentUser?.uid ?? '';

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msgData = messages[index].data() as Map<String, dynamic>;
                    bool isMe = msgData['senderId'] == currentAuthUid || msgData['senderId'] == FirebaseAuth.instance.currentUser?.email;
                    String senderId = msgData['senderId'] ?? '';
                    String senderName = msgData['senderName'] ?? 'Member';
                    String senderPic = msgData['senderPic'] ?? '';
                    String messageText = msgData['message'] ?? '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.amber.withOpacity(0.2) : Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isMe ? Colors.amber.withOpacity(0.5) : Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              // 🖼️ প্রোফাইল পিকচারে ক্লিক করলে প্রোফাইল দেখাবে
                              GestureDetector(
                                onTap: () => _openUserProfile(senderId),
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundImage: senderPic.isNotEmpty ? CachedNetworkImageProvider(senderPic) as ImageProvider : null,
                                  child: senderPic.isEmpty ? const Icon(Icons.person, size: 15) : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  // ✍️ নামের ওপর ক্লিক করলে চ্যাট ইনপুটে `@senderName` মেনশন হয়ে যাবে
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _messageController.text = "@$senderName ";
                                        _messageController.selection = TextSelection.fromPosition(
                                          TextPosition(offset: _messageController.text.length),
                                        );
                                      });
                                    },
                                    child: Text(
                                      senderName,
                                      style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    messageText,
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.black45,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.amber,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black, size: 18),
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