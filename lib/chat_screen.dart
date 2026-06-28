import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pagla_chat/profile_page.dart';
import 'package:pagla_chat/widgets/room_settings_handler.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import 'screens/voice_room.dart';
import 'package:flutter/foundation.dart'; // এই লাইনটি যোগ করুন
import 'chat_actions.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final Map<String, dynamic>? receiverData;

  const ChatScreen(
      {super.key,
      required this.receiverId,
      required this.receiverName,
      this.receiverData});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Map<String, dynamic>? _repliedMessage;
  bool _isRecording = false;
  String currentSixDigitId = "";
  // ব্লক স্ট্যাটাস চেক করার জন্য একটি বুলিয়ান
  bool isBlocked = false;
  List myBlockedUsers = [];

  @override
  void initState() {
    super.initState();
    // ১. অ্যাপ ওপেন হওয়ার সাথে সাথেই এই ইনিশিয়েলাইজেশন শুরু হবে
    _initializeChat();
  }

// এটি অবশ্যই Future<void> হতে হবে যাতে await করা যায়
  Future<void> _initializeChat() async {
    // ২. আইডি লোড হওয়া পর্যন্ত অপেক্ষা করুন
    await _getMySixDigitId();

    print("INIT: Current ID is now: $currentSixDigitId");

    // ৩. আইডি আসার পর ব্লক লিস্ট লোড করুন
    _loadBlockedList();
  }

  void _loadBlockedList() {
    if (currentSixDigitId.isEmpty) {
      print("Error: আইডি পাওয়া যায়নি, ব্লক লিস্ট লোড হবে না।");
      return;
    }

    FirebaseFirestore.instance
        .collection('users')
        .doc(currentSixDigitId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          myBlockedUsers = List.from(data['blockedUsers'] ?? []);
          isBlocked = myBlockedUsers.contains(widget.receiverId);
          print("ব্লক লিস্ট সফলভাবে আপডেট হয়েছে: $myBlockedUsers");
        });
      }
    });
  }

// এই ফাংশনটিও Future<void> করে দিয়েছি যাতে await কাজ করে
  Future<void> _getMySixDigitId() async {
    final String authUID = FirebaseAuth.instance.currentUser?.uid ?? "";

    // যদি authUID খালি থাকে তবে আর সামনে আগাবে না
    if (authUID.isEmpty) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('authUID', isEqualTo: authUID)
        .limit(1)
        .get();

    if (userDoc.docs.isNotEmpty) {
      setState(() {
        // ডাটাবেজ থেকে আপনার uID ভেরিয়েবলে সেট করা হচ্ছে
        currentSixDigitId = userDoc.docs.first.data()['uID']?.toString() ?? "";
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String getChatRoomId() {
    // যদি রিসিভার অফিশিয়াল আইডি হয়, তবে ফিক্সড ফরম্যাট রিটার্ন করবে
    if (widget.receiverId == "paglachat_official") {
      return "paglachat_official_$currentSixDigitId";
    }

    // সাধারণ ইউজারদের জন্য আপনার আগের সর্টিং লজিক ঠিক থাকবে
    List<String> ids = [currentSixDigitId, widget.receiverId];
    ids.sort();
    return ids.join("_");
  }

  // --- মিডিয়া অ্যাকশন (ডায়মন্ড ও এক্সপায়ারি চেক) ---
  void _handleMediaAction() async {
    String? authUID = FirebaseAuth.instance.currentUser?.uid;
    if (authUID == null) return;

    // ১. Firestore-এ ৬ ডিজিটের আইডি খুঁজে বের করা (authUID ব্যবহার করে)
    // কারণ আপনার Firestore-এ authUID ফিল্ডটি আছে
    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('authUID', isEqualTo: authUID)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      debugPrint("User document not found!");
      return;
    }

    // ২. ডকুমেন্টের আইডি (যা ৬ ডিজিটের) পাওয়া গেল
    String sixDigitUID = userQuery.docs.first.id;
    final userData = userQuery.docs.first.data();

    DateTime now = DateTime.now();
    Timestamp? expiry = userData['media_expiry'];
    int diamonds = userData['diamonds'] ?? 0;

    if (expiry != null && expiry.toDate().isAfter(now)) {
      _showMediaOptions();
    } else {
      // ৩. এখন ৬ ডিজিটের আইডি পাঠানো হচ্ছে
      _showPurchaseDialog(diamonds, sixDigitUID);
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromARGB(152, 84, 84, 244),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image,
                color: Color.fromARGB(200, 112, 248, 109)),
            title:
                const Text("Send Image", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _pickMedia(ImageSource.gallery, isVideo: false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam, color: Colors.cyanAccent),
            title:
                const Text("Send Video", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _pickMedia(ImageSource.gallery, isVideo: true);
            },
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
      Reference ref =
          FirebaseStorage.instance.ref().child('chat_media').child(fileName);
      await ref.putFile(file);
      String url = await ref.getDownloadURL();
      _sendDataMessage(url, type, null);
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
        final path =
            '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone permission denied!")),
      );
    }
  }

 // ১. মেসেজ পাঠানোর ফাংশন (টাইপ সেফ)
void _sendDataMessage(String content, String type, Map<String, dynamic>? replyData) async {
  if (content.isEmpty) return;

  try {
    final String authUID = FirebaseAuth.instance.currentUser?.uid ?? "";

    // ইউজার ডকুমেন্ট খুঁজে বের করা
    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('authUID', isEqualTo: authUID)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      debugPrint("User profile not found in Firestore!");
      return;
    }

    final userData = userQuery.docs.first.data();
    final String mySixDigitId = userData['uID']?.toString() ?? '0';
    final String myEmail = userData['email'] ?? '';
    final String myName = userData['name'] ?? 'User';
    final String myPic = userData['profilepic'] ?? userData['profilePic'] ?? '';

    // ইউনিক চ্যাট রুম আইডি তৈরি
    String roomId;
    if (widget.receiverId == "paglachat_official") {
      roomId = "paglachat_official_$mySixDigitId";
    } else {
      List<String> ids = [mySixDigitId, widget.receiverId];
      ids.sort();
      roomId = ids.join("_");
    }

    // মেসেজ পাঠানো
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .add({
      'senderId': authUID,
      'senderuID': mySixDigitId,
      'senderEmail': myEmail,
      'senderName': myName,
      'senderImage': myPic,
      'receiverId': widget.receiverId,
      'message': content,
      'type': type,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
      
      // রিপ্লাই ডাটা পাঠানো
      'repliedMessage': replyData != null ? (replyData['message'] ?? "") : null,
      'repliedBy': replyData != null ? (replyData['senderName'] ?? "User") : null,
    });

    debugPrint("Message Sent to Room: $roomId");
  } catch (e) {
    debugPrint("Send Error: $e");
  }
}

// ২. সেন্ড বাটন ক্লিক ফাংশন
void _sendMessage() async {
  String text = _messageController.text.trim();
  if (text.isEmpty) return;

  // লোকাল কপি তৈরি
  final Map<String, dynamic>? tempReply = _repliedMessage;

  // এখন আর লাল দাগ থাকার কথা নয়
   _sendDataMessage(text, "text", tempReply);

  _messageController.clear();
  setState(() {
    _repliedMessage = null;
  });
}

  void _showPurchaseDialog(int currentDiamonds, String myUID) {
    // myUID হলো ইউজারের ৬ ডিজিটের ইউনিক আইডি
    if (myUID.isEmpty) {
      debugPrint("Error: User ID is empty");
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(146, 129, 219, 241),
        title: const Text("Unlock Media Feature",
            style: TextStyle(color: Colors.white)),
        content: Text(
            "Buy 1 month access for 15,000 Diamonds.\nYour Balance: $currentDiamonds",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(107, 238, 57, 117)),
            onPressed: () async {
              if (currentDiamonds >= 15000) {
                try {
                  DateTime expiryDate =
                      DateTime.now().add(const Duration(days: 30));

                  // এখানে সরাসরি ৬ ডিজিটের uID ব্যবহার করে আপডেট করা হচ্ছে
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(myUID) // আউথ আইডি নয়, এখানে ৬ ডিজিটের uID কাজ করবে
                      .update({
                    'diamonds': FieldValue.increment(-15000),
                    'media_expiry': Timestamp.fromDate(expiryDate),
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    _showMediaOptions();
                  }
                } catch (e) {
                  debugPrint("Error purchasing media: $e");
                }
              } else {
                debugPrint("Not enough diamonds");
                // আপনি এখানে একটি SnackBar দেখাতে পারেন
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
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null)
          return const SizedBox.shrink();

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String? roomId = userData['currentRoomId'];
        String roomName = userData['currentRoomName'] ?? 'Voice Room';

        if (roomId == null || roomId.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color.fromARGB(131, 242, 92, 142), Colors.deepPurple]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const Icon(Icons.live_tv, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                  child: Text("${widget.receiverName} is Live in: $roomName",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.pinkAccent,
                    shape: const StadiumBorder()),
                onPressed: () async {
                  // লক চেক করার লজিক
                  var roomDoc = await FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(roomId)
                      .get();
                  if (!roomDoc.exists) return;

                  var data = roomDoc.data() as Map<String, dynamic>;
                  bool isLocked = data['isLocked'] ?? false;
                  String password = data['password'] ?? "";
                  String ownerId = data['ownerId'] ?? "";

                  // এখানে আপনার অ্যাপের মালিকানা চেক (uID)
                  String myUID = FirebaseAuth.instance.currentUser?.uid ?? "";

                  if (isLocked && ownerId != myUID) {
                    // লক থাকলে পাসওয়ার্ড চাইবে
                    RoomSettingsHandler.showJoinPasswordDialog(
                        context, roomId, password, () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => VoiceRoom(roomId: roomId)));
                    });
                  } else {
                    // লক না থাকলে বা মালিক হলে সরাসরি ঢুকবে
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => VoiceRoom(roomId: roomId)));
                  }
                },
                child: const Text("Join", style: TextStyle(fontSize: 11)),
              )
            ],
          ),
        );
      },
    );
  }

  void _onProfileTap(BuildContext context, String userId) async {
    // ১. ভিউয়ার লিস্টের মতো করে ৬-ডিজিটের সঠিক uID খুঁজে বের করার লজিক
    String finalIdToPass = userId;

    try {
      // সরাসরি users কালেকশনে কুয়েরি করা হচ্ছে
      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: userId)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        // ৬-ডিজিটের ছোট uID ফিল্ডটি রিড করা হচ্ছে
        finalIdToPass =
            userQuery.docs.first.data()['uID']?.toString() ?? userId;
      }
    } catch (e) {}

    // ২. পুরনো ModalBottomSheet মুছে ফেলে সরাসরি ProfilePage-এ নেভিগেট করা
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: finalIdToPass),
      ),
    );
  }

  Widget _statWidget(String label, dynamic count) {
    return Column(children: [
      Text(count.toString(),
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // পুরো ব্যাকগ্রাউন্ডে নিয়ন ভাইব দেওয়ার জন্য Container ব্যবহার করা হয়েছে
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E), // ডার্ক নেভি
              Color(0xFF16213E), // গভীর পার্পল শেড
              Color(0xFF0D0D1A), // একদম নিচে কালো
            ],
          ),
        ),
        child: Column(
          children: [
            // অ্যাপবার অংশ
            AppBar(
              title: Text(widget.receiverName,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                // এই PopupMenuButton টি নতুন করে বসবে
                PopupMenuButton<String>(
                  color: const Color(0xFF1E1E2F),
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  onSelected: (value) async {
                    String roomId =
                        getChatRoomId(); // আপনার তৈরি করা চ্যাট রুম আইডি
                    if (value == 'block') {
                      await ChatActions.blockUser(context, currentSixDigitId,
                          widget.receiverId, roomId);
                      setState(() => isBlocked = true);
                      _loadBlockedList();
                    } else if (value == 'unblock') {
                      await ChatActions.unblockUser(context, currentSixDigitId,
                          widget.receiverId, roomId);
                      setState(() => isBlocked = false);
                      _loadBlockedList();
                    } else if (value == 'report') {
                      ChatActions.reportUser(
                          context, currentSixDigitId, widget.receiverId);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: isBlocked ? 'unblock' : 'block',
                      child: Text(isBlocked ? "Unblock User" : "Block User",
                          style: TextStyle(
                              color: isBlocked
                                  ? Colors.greenAccent
                                  : Colors.redAccent)),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Text("Report User",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),

            _buildLiveRoomBar(),

            Expanded(
              child: Stack(
                children: [
                  // ব্যাকগ্রাউন্ডে হালকা একটি লাভ রিয়েকশন ইফেক্ট (আপনার ছবির থিম অনুযায়ী)
                  Positioned(
                    bottom: 100,
                    right: -50,
                    child: Opacity(
                      opacity: 0.03,
                      child: Icon(Icons.favorite,
                          size: 400, color: Colors.pinkAccent),
                    ),
                  ),

                  StreamBuilder<QuerySnapshot>(
                    // বর্তমান সিক্স ডিজিট আইডি লোড না হওয়া পর্যন্ত ওয়েট করবে
                    stream: currentSixDigitId.isEmpty
                        ? const Stream.empty()
                        : FirebaseFirestore.instance
                            .collection('chats')
                            .doc(getChatRoomId())
                            .collection('messages')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (currentSixDigitId.isEmpty)
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Colors.pinkAccent));
                      if (!snapshot.hasData)
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Colors.cyanAccent));

                      final docs = snapshot.data!.docs;
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;

                          // প্রিন্ট দিয়ে দেখুন কোন আইডি মেসেজ পাঠাচ্ছে
                          print("Message from: ${data['senderuID']}");

                          // ১. আইডি স্ট্রিং এ কনভার্ট করুন (যাতে টাইপ এরর না হয়)
                          String senderId = data['senderuID']?.toString() ?? "";

                          // ২. ব্লকড ইউজার চেক করুন
                          bool isBlockedNow = myBlockedUsers.contains(senderId);

                          // ৩. যদি ব্লক থাকে, তবে সাথে সাথে হাইড করুন
                          if (isBlockedNow) {
                            return const SizedBox.shrink();
                          }

                          // ৪. ব্লক না থাকলে মেসেজ দেখান
                          final bool isMe = data['senderId'] ==
                              FirebaseAuth.instance.currentUser?.uid;
                          return _buildMessageBubble(data, isMe);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // ইনপুট সেকশনকে একটু গ্লাসি লুক দেওয়া হয়েছে
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2F).withOpacity(0.9),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(25)),
                border: Border.all(color: Colors.white10),
              ),
              child: _inputSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    String type = data['type'] ?? 'text';
    String msg = data['message'] ?? data['text'] ?? '';
    bool isRead = data['isRead'] ?? false;

    // রিপ্লাই করা মেসেজ থাকলে সেটি দেখার লজিক (ডাটাবেস থেকে আসলে)
    String? repliedTo = data['repliedMessage'];

    bool isOfficial =
        data['senderId'] == 'paglachat_official' || type == 'system_msg';
    bool finalIsMe = isMe && !isOfficial;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment:
            finalIsMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!finalIsMe)
            _chatAvatar(data['senderId'] ?? 'paglachat_official',
                data['senderImage'] ?? '', data['senderName'] ?? 'Official'),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  finalIsMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // এখানে লং প্রেস লজিক আপডেট করা হলো
                GestureDetector(
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF1E1E2F),
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading:
                                const Icon(Icons.reply, color: Colors.white),
                            title: const Text("Reply",
                                style: TextStyle(color: Colors.white)),
                            onTap: () {
                              setState(() => _repliedMessage = data);
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading:
                                const Icon(Icons.copy, color: Colors.white),
                            title: const Text("Copy Text",
                                style: TextStyle(color: Colors.white)),
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: msg));
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Copied!")));
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  onTap:
                      type != 'text' ? () => _downloadMedia(msg, type) : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: finalIsMe
                          ? const Color.fromARGB(171, 241, 97, 145)
                          : isOfficial
                              ? const Color(0xFF251F3D)
                              : const Color(0xFF1E1E2F),
                      borderRadius: BorderRadius.circular(15),
                      border: isOfficial
                          ? Border.all(
                              color: Colors.amberAccent.withOpacity(0.4),
                              width: 1)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // রিপ্লাইড মেসেজ দেখানোর লজিক
                        if (data['repliedMessage'] != null &&
                            data['repliedMessage'].toString().isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  finalIsMe ? Colors.black12 : Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                              border: const Border(
                                  left: BorderSide(
                                      color: Colors.pinkAccent, width: 3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['repliedBy'] != null
                                      ? "Replying to ${data['repliedBy']}:"
                                      : "Replying to:",
                                  style: const TextStyle(
                                      color: Colors.pinkAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  data['repliedMessage'] ?? "",
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        // আসল মেসেজ কন্টেন্ট
                        _buildTypeContent(type, msg),
                      ],
                    ),
                  ),
                ),
                if (data['timestamp'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Text(
                      DateFormat('dd MMM, hh:mm a')
                          .format((data['timestamp'] as Timestamp).toDate()),
                      style: const TextStyle(
                          color: Colors.white30,
                          fontSize: 10,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                if (finalIsMe)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 4),
                    child: Icon(Icons.done_all,
                        size: 14,
                        color: isRead ? Colors.greenAccent : Colors.white60),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (finalIsMe)
            _chatAvatar(currentUserId, data['senderImage'] ?? '',
                data['senderName'] ?? 'U'),
        ],
      ),
    );
  }

  Widget _buildTypeContent(String type, String msg) {
    if (type == 'image') {
      return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(msg, width: 200));
    } else if (type == 'video') {
      return const Column(
        children: [
          Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
          Text("Video Message",
              style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      );
    } else if (type == 'audio') {
      return InkWell(
        onTap: () => _audioPlayer.play(UrlSource(msg)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.play_arrow, color: Colors.white),
          Text(" Play Voice", style: TextStyle(color: Colors.white))
        ]),
      );
    }
    return Text(msg, style: const TextStyle(color: Colors.white, fontSize: 16));
  }

  Future<void> _downloadMedia(String url, String type) async {
    try {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Downloading...")));

      // ১. ফাইলটি ডাউনলোড করার জন্য HttpClient ব্যবহার করছি
      final HttpClient httpClient = HttpClient();
      final HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
      final HttpClientResponse response = await request.close();

      // ২. ডাউনলোড করা ডাটা বাইট আকারে পড়া
      final Uint8List bytes =
          await consolidateHttpClientResponseBytes(response);

      // ৩. টেম্পোরারি ফাইল পাথ তৈরি করা
      final dir = await getTemporaryDirectory();
      final String extension = type == 'image' ? 'jpg' : 'mp4';
      final file = File(
          '${dir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.$extension');

      // ৪. ফাইলটি সেভ করা
      await file.writeAsBytes(bytes);

      // ৫. গ্যালারিতে সেভ করা
      if (type == 'image') {
        await Gal.putImage(file.path);
      } else {
        await Gal.putVideo(file.path);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("${type == 'image' ? 'Image' : 'Video'} Saved!")));
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Save failed: $e")));
      }
    }
  }

  Widget _chatAvatar(String uID, String url, String name) {
    // 🔥 ফিক্স: আইডি যদি অফিশিয়াল হয়, তবে ফায়ারবেস চেক ছাড়াই সরাসরি গিটহাবের রয়্যাল লোগো দেখাবে
    if (uID == 'paglachat_official' || name == 'Official') {
      const String officialPic =
          "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/favicon.png";
      return GestureDetector(
        onTap: () =>
            _onProfileTap(context, uID), // এখানে নতুন ফাংশনটি কল করা হলো
        child: const CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(officialPic),
        ),
      );
    }

    // --- সাধারণ ইউজারদের জন্য আপনার আগের লজিক একদম হুবহু ১00% এক থাকবে ---
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uID).snapshots(),
      builder: (context, snapshot) {
        bool isLive = false;
        if (snapshot.hasData && snapshot.data?.data() != null) {
          var d = snapshot.data!.data() as Map<String, dynamic>;
          isLive = d['currentRoomId'] != null &&
              d['currentRoomId'].toString().isNotEmpty;
        }

        return GestureDetector(
          onTap: () => _onProfileTap(context, uID),
          child: Stack(
            children: [
              CircleAvatar(
                  radius: 20,
                  backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
                  child: url.isEmpty
                      ? Text(name.isNotEmpty ? name[0] : 'U')
                      : null),
              if (isLive)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _inputSection() {
    if (isBlocked) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: const Text(
          "You have blocked this user.",
          style:
              TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
      );
    }

    // নিচে পরিবর্তনগুলো দেখুন:
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 5), // ভার্টিকাল প্যাডিং একটু কমিয়েছি
      decoration: const BoxDecoration(
          color: Color(0xFF1E1E2F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(
        // এখানে Column ব্যবহার করেছি যাতে রিপ্লাই প্রিভিউ ওপরে থাকে
        mainAxisSize: MainAxisSize.min,
        children: [
          // রিপ্লাই প্রিভিউ বক্স
          if (_repliedMessage != null)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Replying to: ${_repliedMessage!['message']}",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, size: 18, color: Colors.white),
                    onPressed: () => setState(() => _repliedMessage = null),
                  )
                ],
              ),
            ),

          // মূল ইনপুট রো (আগের কোড)
          Row(
            children: [
              IconButton(
                  icon: Icon(Icons.mic,
                      color: _isRecording ? Colors.red : Colors.cyanAccent),
                  onPressed: _startVoiceNote),
              IconButton(
                  icon: const Icon(Icons.image,
                      color: Color.fromARGB(255, 119, 245, 103)),
                  onPressed: _handleMediaAction),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText:
                        _isRecording ? "Recording..." : "Type a message...",
                    filled: true,
                    fillColor: const Color(0xFF0D0D1A),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              CircleAvatar(
                  backgroundColor: Colors.pinkAccent,
                  child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage)),
            ],
          ),
        ],
      ),
    );
  }
}
