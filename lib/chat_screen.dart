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
    String myName = userDoc.data()?['name'] ?? 'User';

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
  }

  // রিয়েল প্রোফাইল কার্ড (রিয়েল ডাটা ও ফলো বাটন সহ)
  void _showProfile(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
          
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String name = userData['name'] ?? 'ইউজার';
          String pic = userData['imageURL'] ?? 'https://via.placeholder.com/150';
          bool isVIP = userData['isVIP'] ?? false;
          bool hasPremium = userData['hasPremiumCard'] ?? false;
          List followerList = userData['followerList'] ?? [];
          bool isFollowing = followerList.contains(currentUserId);

          return Container(
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E2F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(radius: 50, backgroundImage: NetworkImage(pic)),
                    if (isVIP) Container(width: 110, height: 110, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.amber, width: 3))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    if (isVIP) const Icon(Icons.verified, color: Colors.gold, size: 22),
                    if (hasPremium) const Icon(Icons.star, color: Colors.blueAccent, size: 20),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statCol("Followers", userData['followers'] ?? 0),
                    _statCol("Following", userData['following'] ?? 0),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (userId != currentUserId)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: isFollowing ? Colors.grey : Colors.pinkAccent, shape: const StadiumBorder()),
                        onPressed: () => _handleFollow(userId, isFollowing),
                        child: Text(isFollowing ? "Unfollow" : "Follow"),
                      ),
                    const SizedBox(width: 15),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, shape: const StadiumBorder()),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Message"),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleFollow(String targetUid, bool isFollowing) async {
    var myRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);
    var targetRef = FirebaseFirestore.instance.collection('users').doc(targetUid);
    if (isFollowing) {
      await targetRef.update({'followers': FieldValue.increment(-1), 'followerList': FieldValue.arrayRemove([currentUserId])});
      await myRef.update({'following': FieldValue.increment(-1)});
    } else {
      await targetRef.update({'followers': FieldValue.increment(1), 'followerList': FieldValue.arrayUnion([currentUserId])});
      await myRef.update({'following': FieldValue.increment(1)});
    }
  }

  Widget _statCol(String label, int count) {
    return Column(children: [
      Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
    ]);
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
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isMe) GestureDetector(
                            onTap: () => _showProfile(context, data['senderId']),
                            child: CircleAvatar(radius: 18, backgroundImage: NetworkImage(data['senderImage'] ?? 'https://via.placeholder.com/150')),
                          ),
                          const SizedBox(width: 8),
                          Flexible(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isMe ? Colors.pinkAccent : Colors.grey[800], borderRadius: BorderRadius.circular(15)), child: Text(data['message'], style: const TextStyle(color: Colors.white)))),
                          const SizedBox(width: 8),
                          if (isMe) GestureDetector(
                            onTap: () => _showProfile(context, currentUserId),
                            child: CircleAvatar(radius: 18, backgroundImage: NetworkImage(data['senderImage'] ?? 'https://via.placeholder.com/150')),
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
                Expanded(child: TextField(controller: _messageController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "মেসেজ...", filled: true, fillColor: const Color(0xFF1E1E2F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))),
                IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
