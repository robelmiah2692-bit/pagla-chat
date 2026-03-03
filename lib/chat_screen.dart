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

  // মেসেজ পাঠানোর সময় সঠিক ছবি ও নাম পাঠানো
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || currentUserId.isEmpty) return;
    String message = _messageController.text.trim();
    _messageController.clear();

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      var userData = userDoc.data();
      
      // মাল্টিপল কী চেক করা হচ্ছে যাতে সঠিক ছবি পাওয়া যায়
      final String myPic = userData?['imageURL'] ?? userData?['profilePic'] ?? userData?['userImageURL'] ?? ''; 
      final String myName = userData?['name'] ?? 'User';

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
      print("Send Error: $e");
    }
  }

  // প্রোফাইল দেখানোর সময় রিয়েল ডাটা লোড করা
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
          final String pic = userData['imageURL'] ?? userData['profilePic'] ?? userData['userImageURL'] ?? '';
          final bool isVIP = userData['isVIP'] ?? false;
          final List followerList = userData['followerList'] ?? [];
          final bool isFollowing = followerList.contains(currentUserId);

          return Container(
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E2F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.pinkAccent,
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: const Color(0xFF0D0D1A),
                    backgroundImage: pic.isNotEmpty ? NetworkImage(pic) : null,
                    child: pic.isEmpty ? Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 30, color: Colors.white)) : null,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    if (isVIP) const Padding(padding: EdgeInsets.only(left: 5), child: Icon(Icons.verified, color: Colors.amber, size: 22)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statWidget("Followers", userData['followers'] ?? 0),
                    _statWidget("Following", userData['following'] ?? 0),
                  ],
                ),
                const SizedBox(height: 30),
                if (userId != currentUserId)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing ? Colors.grey : Colors.pinkAccent,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () => _toggleFollow(userId, isFollowing),
                    child: Text(isFollowing ? "Unfollow" : "Follow", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

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

  Widget _statWidget(String label, dynamic count) {
    return Column(
      children: [
        Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: Text(widget.receiverName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E2F),
        centerTitle: true,
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
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isMe = data['senderId'] == currentUserId;
                    final String senderPic = data['senderImage'] ?? '';
                    final String senderName = data['senderName'] ?? 'U';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) _chatAvatar(data['senderId'], senderPic, senderName),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.pinkAccent : const Color(0xFF1E1E2F),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(5),
                                  bottomRight: isMe ? const Radius.circular(5) : const Radius.circular(20),
                                ),
                              ),
                              child: Text(data['message'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (isMe) _chatAvatar(currentUserId, senderPic, senderName),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _inputSection(),
        ],
      ),
    );
  }

  Widget _chatAvatar(String uid, String url, String name) {
    return GestureDetector(
      onTap: () => _showProfile(context, uid),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white10,
        backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
        child: url.isEmpty 
          ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 12)) 
          : null,
      ),
    );
  }

  Widget _inputSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "মেসেজ লিখুন...",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF0D0D1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: Colors.pinkAccent,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
