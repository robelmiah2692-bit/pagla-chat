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

  // চ্যাট রুম আইডি তৈরির লজিক
  String getChatRoomId() {
    List<String> ids = [currentUserId, widget.receiverId];
    ids.sort(); 
    return ids.join("_"); 
  }

  // ১. মেসেজ পাঠানোর সময় ইউজারের ডাটাবেস থেকে ছবি ও নাম পাঠানো
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    String message = _messageController.text.trim();
    _messageController.clear();

    // ইউজারের রিয়েল প্রোফাইল ডাটা (imageURL) ফায়ারস্টোর থেকে আনা
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
      'senderImage': myPic, // এই লাইনের মাধ্যমেই চ্যাটে রিয়েল পিক যাবে
      'receiverId': widget.receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ২. রিয়েল প্রোফাইল দেখার ফাংশন (ফলো ও ভিআইপি ব্যাজ সহ)
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
          String pic = userData['imageURL'] ?? '';
          bool isVIP = userData['isVIP'] ?? false;
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
                CircleAvatar(
                  radius: 55, 
                  backgroundImage: NetworkImage(pic.isNotEmpty ? pic : 'https://via.placeholder.com/150'),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    if (isVIP) const Padding(padding: EdgeInsets.only(left: 5), child: Icon(Icons.verified, color: Colors.gold, size: 22)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statCol("Followers", userData['followers'] ?? 0),
                    _statCol("Following", userData['following'] ?? 0),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (userId != currentUserId)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: isFollowing ? Colors.grey : Colors.pinkAccent, shape: const StadiumBorder()),
                        onPressed: () => _toggleFollow(userId, isFollowing),
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
        }
      ),
    );
  }

  // ৩. ফলো লজিক যা ডাটাবেসে রিয়েল টাইমে কাজ করবে
  void _toggleFollow(String targetUid, bool isFollowing) async {
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
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: Text(widget.receiverName, style: const TextStyle(color: Colors.white)),
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
                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index];
                    bool isMe = data['senderId'] == currentUserId;
                    String senderPic = data['senderImage'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isMe) GestureDetector(
                            onTap: () => _showProfile(context, data['senderId']),
                            child: CircleAvatar(
                              radius: 18, 
                              backgroundImage: NetworkImage(senderPic.isNotEmpty ? senderPic : 'https://via.placeholder.com/150'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.pinkAccent : Colors.grey[800],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(data['message'], style: const TextStyle(color: Colors.white, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isMe) GestureDetector(
                            onTap: () => _showProfile(context, currentUserId),
                            child: CircleAvatar(
                              radius: 18, 
                              backgroundImage: NetworkImage(senderPic.isNotEmpty ? senderPic : 'https://via.placeholder.com/150'),
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
          // ইনপুট বক্স
          Padding(
            padding: const EdgeInsets.all(12),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent, size: 28), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
