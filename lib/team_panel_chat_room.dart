import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // গ্যালারি থেকে ছবি নেওয়ার জন্য
import 'package:pagla_chat/full_screen_image_viewer.dart';
import 'package:pagla_chat/profile_page.dart';

// আপনি যে ফুলস্ক্রিন ইমেজ ভিউয়ার ফাইলটি দিয়েছেন সেটির ইম্পোর্ট (প্রয়োজন অনুযায়ী পাথ ঠিক করে নিতে পারেন)
// import 'full_screen_image_viewer.dart'; 

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
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  // 📝 টেক্সট মেসেজ পাঠানোর ফাংশন
  void _sendMessage() async {
    String text = _messageController.text.trim();
    if (text.isEmpty) return;

    _sendMessageToFirestore(messageText: text, isImage: false);
  }

  // 🖼️ গ্যালারি থেকে ছবি সিলেক্ট করে চ্যাটে পাঠানোর ফাংশন
  void _sendImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // কোয়ালিটি অপ্টিমাইজ করার জন্য
      );

      if (image == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      File imageFile = File(image.path);
      
      // বিঃদ্রঃ আপনার প্রজেক্টে যদি ফায়ারবেস স্টোরেজ (Firebase Storage) বা অন্য কোনো ইমেজ হোস্টিং ব্যবহার করা থাকে, 
      // তবে এখানে imageFile আপলোড করে তার URL নিয়ে নিতে হবে। উদাহরণস্বরূপ নিচের লোকাল পাথ বা স্টোরেজ লিংক ব্যবহার করতে পারেন:
      // ফায়ারবেস স্টোরেজে আপলোড করার কোড এখানে যুক্ত করতে হবে। 
      // সাময়িকভাবে লোকাল ফাইল পাথ বা স্টোরেজ URL-এর মাধ্যমে হ্যান্ডেল করার লজিক:
      
      // উদাহরণস্বরূপ স্টোরেজ আপলোড করার পর প্রাপ্ত URL:
      String imageUrl = imageFile.path; // প্রোডাকশনে এখানে Firebase Storage URL বসবে।

      await _sendMessageToFirestore(messageText: imageUrl, isImage: true);
    } catch (e) {
      debugPrint("Error picking/sending image: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  // ফায়ারস্টোরে মেসেজ বা ইমেজ সেভ করার কমন ফাংশন
  Future<void> _sendMessageToFirestore({required String messageText, required bool isImage}) async {
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
        'message': messageText,
        'isImage': isImage, // ইমেজ নাকি টেক্সট তা ট্র্যাক করার জন্য
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!isImage) {
        _messageController.clear();
      }

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

  // 👤 ইউজারের প্রোফাইলে যাওয়ার ফাংশন
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
                    String messageText = msgData['message'] ?? '';
                    bool isImageMsg = msgData['isImage'] ?? false;

                    // রিয়েল-টাইমে ইউজারের বর্তমান প্রোফাইল পিকচার দেখানোর জন্য senderId দিয়ে users কালেকশন স্ট্রিম করা হচ্ছে
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(senderId).snapshots(),
                      builder: (context, userSnapshot) {
                        String liveSenderPic = '';
                        if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                          var uData = userSnapshot.data!.data() as Map<String, dynamic>?;
                          liveSenderPic = uData?['profilePic'] ?? uData?['userImage'] ?? msgData['senderPic'] ?? '';
                        } else {
                          liveSenderPic = msgData['senderPic'] ?? '';
                        }

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
                                  // 🖼️ প্রোফাইল পিকচারে ক্লিক করলে প্রোফাইল দেখাবে (রিয়েল-টাইম ছবি সহ)
                                  GestureDetector(
                                    onTap: () => _openUserProfile(senderId),
                                    child: CircleAvatar(
                                      radius: 15,
                                      backgroundImage: liveSenderPic.isNotEmpty ? CachedNetworkImageProvider(liveSenderPic) as ImageProvider : null,
                                      child: liveSenderPic.isEmpty ? const Icon(Icons.person, size: 15) : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      // ✍️ নামের ওপর ক্লিক করলে চ্যাট ইনপুটে `@senderName` মেনশন হয়ে যাবে
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
                                      const SizedBox(height: 4),
                                      
                                      // যদি মেসেজটি ইমেজ হয় তবে ইমেজ দেখাবে এবং ক্লিক করলে FullScreenImageViewer কল করবে
                                      isImageMsg
                                          ? GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => FullScreenImageViewer(imageUrl: messageText),
                                                  ),
                                                );
                                              },
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: messageText.startsWith('http')
                                                    ? CachedNetworkImage(
                                                        imageUrl: messageText,
                                                        width: 150,
                                                        height: 150,
                                                        fit: BoxFit.cover,
                                                        placeholder: (context, url) => const SizedBox(
                                                          width: 150,
                                                          height: 150,
                                                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                        ),
                                                        errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
                                                      )
                                                    : Image.file(
                                                        File(messageText),
                                                        width: 150,
                                                        height: 150,
                                                        fit: BoxFit.cover,
                                                      ),
                                              ),
                                            )
                                          : Text(
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
                );
              },
            ),
          ),
          
          // আপলোড লোডিং ইন্ডিকেটর
          if (_isUploadingImage)
            const Padding(
              padding: EdgeInsets.all(4.0),
              child: LinearProgressIndicator(color: Colors.amber),
            ),

          // চ্যাট ইনপুট এবং গ্যালারি বাটন
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // গ্যালারি থেকে ছবি পাঠানোর বাটন
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.amberAccent),
                  onPressed: _sendImageFromGallery,
                  tooltip: "Send Image",
                ),
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