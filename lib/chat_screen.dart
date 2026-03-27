import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/voice_room.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final Map<String, dynamic>? receiverData;

  const ChatScreen({
    super.key, 
    required this.receiverId, 
    required this.receiverName, 
    this.receiverData
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  // চ্যাট রুম আইডি জেনারেট করা
  String getChatRoomId() {
    List<String> ids = [currentUserId, widget.receiverId];
    ids.sort(); 
    return ids.join("_"); 
  }

  // --- নতুন লজিক: ছবি ও ভিডিওর মেয়াদ চেক এবং কেনা ---
  void _handleMediaAction() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};

    DateTime now = DateTime.now();
    Timestamp? expiry = userData['media_expiry'];
    int diamonds = userData['diamonds'] ?? 0;

    // যদি মেয়াদ কেনা থাকে এবং সময় শেষ না হয়
    if (expiry != null && expiry.toDate().isAfter(now)) {
      _openGallery(); // ফিচার খোলা
    } else {
      _showPurchaseDialog(diamonds); // লক থাকলে কেনার অপশন
    }
  }

  void _showPurchaseDialog(int currentDiamonds) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        title: const Text("Unlock Media Feature", style: TextStyle(color: Colors.white)),
        content: Text(
          "Buy 1 month access to send Photos & Videos for 6,000 Diamonds.\n\nYour Balance: $currentDiamonds",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            onPressed: () async {
              if (currentDiamonds >= 6000) {
                DateTime expiryDate = DateTime.now().add(const Duration(days: 30));
                await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
                  'diamonds': FieldValue.increment(-6000),
                  'media_expiry': Timestamp.fromDate(expiryDate),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Media feature unlocked for 1 month!")));
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Not enough diamonds!")));
              }
            },
            child: const Text("Buy Now"),
          ),
        ],
      ),
    );
  }

  void _openGallery() {
    print("Gallery Opened"); // এখানে ইমেজ পিকার কোড বসবে
  }

  void _startVoiceNote() {
    print("Voice Message Recording..."); // এখানে ভয়েস লজিক বসবে
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || currentUserId.isEmpty) return;
    String message = _messageController.text.trim();
    _messageController.clear();

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      var userData = userDoc.data();
      
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
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Send Error: $e");
    }
  }

  // পুরাতন লাইভ বার ফিচার
  Widget _buildLiveRoomBar(Map<String, dynamic> data) {
    if (data['currentRoomId'] == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.pinkAccent, Colors.deepPurple]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.live_tv, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "${data['name']} is Live in: ${data['currentRoomName'] ?? 'Voice Room'}",
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.pinkAccent, shape: const StadiumBorder()),
            onPressed: () {
               // জয়েন লজিক
            }, 
            child: const Text("Join", style: TextStyle(fontSize: 11)),
          )
        ],
      ),
    );
  }

  // পুরাতন প্রোফাইল বটম শিট
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
        title: Text(widget.receiverName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2F),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          if (widget.receiverData != null) _buildLiveRoomBar(widget.receiverData!),
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
                                borderRadius: BorderRadius.circular(20),
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
        child: url.isEmpty ? Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)) : null,
      ),
    );
  }

  // --- ইনপুট সেকশন (নতুন বাটন সহ) ---
  Widget _inputSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        children: [
          // নতুন ভয়েস বাটন
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.cyanAccent),
            onPressed: _startVoiceNote,
          ),
          // নতুন ইমেজ/মিডিয়া বাটন (লজিক সহ)
          IconButton(
            icon: const Icon(Icons.image, color: Colors.pinkAccent),
            onPressed: _handleMediaAction,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF0D0D1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 5),
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
