import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:io';
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
  
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;

  @override
  void dispose() {
    _messageController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // দুই ইউজারের আইডি দিয়ে একটি ইউনিক রুম আইডি তৈরি করা
  String getChatRoomId() {
    List<String> ids = [currentUserId, widget.receiverId];
    ids.sort(); 
    return ids.join("_"); 
  }

  // --- মিডিয়া অ্যাকশন (ডায়মন্ড চেক) ---
  void _handleMediaAction() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};

    DateTime now = DateTime.now();
    Timestamp? expiry = userData['media_expiry'];
    int diamonds = userData['diamonds'] ?? 0;

    if (expiry != null && expiry.toDate().isAfter(now)) {
      _showMediaOptions();
    } else {
      _showPurchaseDialog(diamonds);
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image, color: Colors.pinkAccent),
            title: const Text("Send Image", style: TextStyle(color: Colors.white)),
            onTap: () { Navigator.pop(context); _pickMedia(ImageSource.gallery, isVideo: false); },
          ),
          ListTile(
            leading: const Icon(Icons.videocam, color: Colors.cyanAccent),
            title: const Text("Send Video", style: TextStyle(color: Colors.white)),
            onTap: () { Navigator.pop(context); _pickMedia(ImageSource.gallery, isVideo: true); },
          ),
        ],
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source, {required bool isVideo}) async {
    final XFile? file = isVideo 
        ? await _picker.pickVideo(source: source) 
        : await _picker.pickImage(source: source, imageQuality: 70);

    if (file != null) {
      _uploadToFirebase(File(file.path), isVideo ? "video" : "image");
    }
  }

  Future<void> _uploadToFirebase(File file, String type) async {
    try {
      String fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}';
      Reference ref = FirebaseStorage.instance.ref().child('chat_media').child(fileName);
      await ref.putFile(file);
      String url = await ref.getDownloadURL();
      _sendDataMessage(url, type);
    } catch (e) {
      debugPrint("Upload Error: $e");
    }
  }

  void _startVoiceNote() async {
    if (await _audioRecorder.hasPermission()) {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() => _isRecording = false);
        if (path != null) {
          _uploadToFirebase(File(path), "audio");
        }
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone permission denied!")),
      );
    }
  }

  // মেসেজ পাঠানোর মূল লজিক (সংশোধিত)
  void _sendDataMessage(String content, String type) async {
    if (content.isEmpty) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      var userData = userDoc.data();
      
      // আপনার ডাটাবেস অনুযায়ী ফিল্ড নেম সংশোধিত
      final String myPic = userData?['profilePic'] ?? userData?['profilePic'] ?? ''; 
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
        'message': content,
        'type': type,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Send Error: $e");
    }
  }

  void _sendMessage() {
    String text = _messageController.text.trim();
    if (text.isEmpty) return;
    _sendDataMessage(text, "text");
    _messageController.clear();
  }

  void _showPurchaseDialog(int currentDiamonds) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        title: const Text("Unlock Media Feature", style: TextStyle(color: Colors.white)),
        content: Text("Buy 1 month access for 6,000 Diamonds.\nYour Balance: $currentDiamonds", style: const TextStyle(color: Colors.white70)),
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
                _showMediaOptions();
              }
            },
            child: const Text("Buy Now"),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRoomBar() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.receiverId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) return const SizedBox.shrink();
        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String? roomId = userData['currentRoomId'];
        String roomName = userData['currentRoomName'] ?? 'Voice Room';

        if (roomId == null || roomId.isEmpty) return const SizedBox.shrink();

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
              Expanded(child: Text("${widget.receiverName} is Live in: $roomName", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.pinkAccent, shape: const StadiumBorder()),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => VoiceRoom(roomId: roomId)));
                }, 
                child: const Text("Join", style: TextStyle(fontSize: 11)),
              )
            ],
          ),
        );
      },
    );
  }

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
          final String pic = userData['profilePic'] ?? userData['profilePic'] ?? '';
          final bool isVIP = userData['isVIP'] ?? false;
          final bool isFollowing = (userData['followerList'] ?? []).contains(currentUserId);

          return Container(
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(color: Color(0xFF1E1E2F), borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 55, backgroundColor: Colors.pinkAccent, child: CircleAvatar(radius: 52, backgroundImage: pic.isNotEmpty ? NetworkImage(pic) : null)),
                const SizedBox(height: 15),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  if (isVIP) const Icon(Icons.verified, color: Colors.amber, size: 22),
                ]),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _statWidget("Followers", userData['followers'] ?? 0),
                  _statWidget("Following", userData['following'] ?? 0),
                ]),
                const SizedBox(height: 30),
                if (userId != currentUserId)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: isFollowing ? Colors.grey : Colors.pinkAccent, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: () => _toggleFollow(userId, isFollowing),
                    child: Text(isFollowing ? "Unfollow" : "Follow", style: const TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _toggleFollow(String targetuID, bool isFollowing) async {
    var myRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);
    var targetRef = FirebaseFirestore.instance.collection('users').doc(targetuID);
    if (isFollowing) {
      await targetRef.update({'followers': FieldValue.increment(-1), 'followerList': FieldValue.arrayRemove([currentUserId])});
      await myRef.update({'following': FieldValue.increment(-1)});
    } else {
      await targetRef.update({'followers': FieldValue.increment(1), 'followerList': FieldValue.arrayUnion([currentUserId])});
      await myRef.update({'following': FieldValue.increment(1)});
    }
  }

  Widget _statWidget(String label, dynamic count) {
    return Column(children: [
      Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildLiveRoomBar(),
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
                  padding: const EdgeInsets.all(15),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isMe = data['senderId'] == currentUserId;
                    return _buildMessageBubble(data, isMe);
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

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    String type = data['type'] ?? 'text';
    String msg = data['message'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _chatAvatar(data['senderId'], data['senderImage'] ?? '', data['senderName'] ?? 'U'),
          const SizedBox(width: 10),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _downloadMedia(msg, type),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? Colors.pinkAccent : const Color(0xFF1E1E2F),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: _buildTypeContent(type, msg),
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (isMe) _chatAvatar(currentUserId, data['senderImage'] ?? '', data['senderName'] ?? 'U'),
        ],
      ),
    );
  }

  Widget _buildTypeContent(String type, String msg) {
    if (type == 'image') {
      return ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(msg, width: 200));
    } else if (type == 'video') {
      return const Column(
        children: [
          Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
          Text("Video Message", style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      );
    } else if (type == 'audio') {
      return InkWell(
        onTap: () => _audioPlayer.play(UrlSource(msg)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.play_arrow, color: Colors.white), Text(" Play Voice", style: TextStyle(color: Colors.white))]),
      );
    }
    return Text(msg, style: const TextStyle(color: Colors.white, fontSize: 16));
  }

  void _downloadMedia(String url, String type) async {
  try {
    if (type == 'image') {
      // ইমেজের জন্য
      await Gal.putImage(url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image Saved to Gallery!")),
      );
    } else if (type == 'video') {
      // ভিডিওর জন্য
      await Gal.putVideo(url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video Saved to Gallery!")),
      );
    }
  } catch (e) {
    // কোনো এরর হলে
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Save failed: $e")),
    );
  }
}

  Widget _chatAvatar(String uID, String url, String name) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uID).snapshots(),
      builder: (context, snapshot) {
        bool isLive = false;
        if (snapshot.hasData && snapshot.data?.data() != null) {
          var d = snapshot.data!.data() as Map<String, dynamic>;
          isLive = d['currentRoomId'] != null && d['currentRoomId'].toString().isNotEmpty;
        }

        return GestureDetector(
          onTap: () => _showProfile(context, uID),
          child: Stack(
            // clipBehavior: Clip.none, // কিছু ভার্সনে এরর দিলে এটি কমেন্ট করতে পারেন
            children: [
              CircleAvatar(radius: 20, backgroundImage: url.isNotEmpty ? NetworkImage(url) : null, child: url.isEmpty ? Text(name[0]) : null),
              if (isLive)
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _inputSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: const BoxDecoration(color: Color(0xFF1E1E2F), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.mic, color: _isRecording ? Colors.red : Colors.cyanAccent), onPressed: _startVoiceNote),
          IconButton(icon: const Icon(Icons.image, color: Colors.pinkAccent), onPressed: _handleMediaAction),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _isRecording ? "Recording..." : "Type a message...",
                filled: true, fillColor: const Color(0xFF0D0D1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 5),
          CircleAvatar(
            backgroundColor: Colors.pinkAccent, 
            child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage)
          ),
        ],
      ),
    );
  }
}
