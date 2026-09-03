import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pagla_chat/full_screen_image_viewer.dart';
import 'package:pagla_chat/profile_page.dart';
import 'package:pagla_chat/services/call_handler.dart';
import 'package:pagla_chat/services/call_screen.dart';
import 'package:pagla_chat/video_player_screen.dart';
import 'package:pagla_chat/widgets/room_settings_handler.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart' hide Source;
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
  StreamSubscription? _blockedListSubscription;
  // ব্লক স্ট্যাটাস চেক করার জন্য একটি বুলিয়ান
  bool isBlocked = false;
  List myBlockedUsers = [];

  Timer? _recordTimer;
  int _recordDuration = 0;
  bool _isPlayingAudio = false;
  String? _playingAudioUrl;
  int _currentAudioPosition = 0;
  int _totalAudioDuration = 0;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // অ্যাপ ওপেন হওয়ার সাথে সাথেই ইনিশিয়েলাইজেশন শুরু হবে
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // আইডি লোড হওয়া পর্যন্ত অপেক্ষা করুন
    await _getMySixDigitId();

    // আইডি লোড হওয়ার পর চেক করুন এবং রিসেট কল করুন
    if (currentSixDigitId.isNotEmpty) {
      _loadBlockedList();

      // চ্যাট আইডি এবং রিসেট ফাংশন এখানে কল করুন
      String chatId = getChatRoomId();

      await _resetUnreadCount(chatId); // এখানে await যোগ করুন
    } else {
      // যদি আইডি না পায়, তবে পুনরায় চেষ্টা করুন
      Future.delayed(const Duration(milliseconds: 500), _initializeChat);
    }
  }

  Future<void> _resetUnreadCount(String chatId) async {
    if (chatId.isEmpty || chatId.contains("null")) return;

    try {
      DocumentReference chatRef =
          FirebaseFirestore.instance.collection('chats').doc(chatId);

      // Transaction ব্যবহার করছি কারণ এটি সার্ভার থেকে লেটেস্ট ডাটা নিশ্চিত করে
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(chatRef);

        if (!snapshot.exists) return;

        // ১. মেসেজ রিড হিসেবে মার্ক করা
        var unreadMessages = await chatRef
            .collection('messages')
            .where('isRead', isEqualTo: false)
            .get();

        for (var doc in unreadMessages.docs) {
          if (doc.data()['senderuID'] != currentSixDigitId) {
            transaction.update(doc.reference, {'isRead': true});
          }
        }

        // ২. নিজের আইডির কাউন্ট ০ করা
        transaction.update(chatRef, {'unReadCount_$currentSixDigitId': 0});
      });
    } catch (e) {}
  }

  // ৩. _loadBlockedList ফাংশনটিকে এভাবে আপডেট করুন
  void _loadBlockedList() {
    if (currentSixDigitId.isEmpty) {
      return;
    }

    // আগের কোনো লিসেনার চালু থাকলে তা আগে ক্যানসেল করে নেওয়া ভালো
    _blockedListSubscription?.cancel();

    _blockedListSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(currentSixDigitId)
        .snapshots()
        .listen((doc) {
      // অত্যন্ত গুরুত্বপূর্ণ: স্ক্রিন ডিসপোজ হয়ে গেলে আর কোড এক্সিকিউট হবে না
      if (!mounted) return;

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          myBlockedUsers = List.from(data['blockedUsers'] ?? []);
          isBlocked = myBlockedUsers.contains(widget.receiverId);
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
    _blockedListSubscription?.cancel();

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

  Future<void> shareRoomInChat(String roomId, String targetUserId,
      String roomName, BuildContext context) async {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    List<String> ids = [currentUserId, targetUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    Map<String, dynamic> roomMessage = {
      'senderId': currentUserId,
      'receiverId': targetUserId,
      'message': "Join my room: $roomName",
      'type': 'room_invite', // এটি খুব গুরুত্বপূর্ণ
      'roomId': roomId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    // ১. মেসেজ পাঠানো
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(roomMessage);

    // ২. চ্যাট লিস্টে দেখানোর জন্য চ্যাট ডকুমেন্টে আপডেট করা
    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
      'lastMessage':
          "Room Invitation: $roomName", // চ্যাট লিস্টে এই টেক্সট দেখাবে
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'type': 'room_invite', // লিস্টে টাইপ চেক করার জন্য
    }, SetOptions(merge: true));
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

  // 🔥 মিডিয়া আপলোডের সময় লোডিং এবং প্রোগ্রেস দেখানোর ব্যবস্থা
  Future<void> _uploadToFirebase(File file, String type) async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      String fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}';
      Reference ref =
          FirebaseStorage.instance.ref().child('chat_media').child(fileName);

      UploadTask uploadTask = ref.putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();
      _sendDataMessage(url, type, null);
    } catch (e) {
      debugPrint("Upload Error: $e");
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  void _startVoiceNote() async {
    if (await _audioRecorder.hasPermission()) {
      if (_isRecording) {
        _recordTimer?.cancel();
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _recordDuration = 0;
        });
        if (path != null) {
          _uploadToFirebase(File(path), "audio");
        }
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });

        // রেকর্ডিংয়ের মিনিট-সেকেন্ড কাউন্ট করার জন্য টাইমার
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration++;
          });
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone permission denied!")),
      );
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ১. মেসেজ পাঠানোর ফাংশন (টাইপ সেফ)
  // ১. মেসেজ পাঠানোর ফাংশন (টাইপ সেফ)
  void _sendDataMessage(
      String content, String type, Map<String, dynamic>? replyData) async {
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
        return;
      }

      final userData = userQuery.docs.first.data();
      final String mySixDigitId = userData['uID']?.toString() ?? '0';
      final String myEmail = userData['email'] ?? '';
      final String myName = userData['name'] ?? 'User';
      final String myPic =
          userData['profilepic'] ?? userData['profilePic'] ?? '';

      // ইউনিক চ্যাট রুম আইডি তৈরি
      String roomId;
      if (widget.receiverId == "paglachat_official") {
        roomId = "paglachat_official_$mySixDigitId";
      } else {
        List<String> ids = [mySixDigitId, widget.receiverId];
        ids.sort();
        roomId = ids.join("_");
      }

      // চ্যাটের ভেতর রিয়েল মেসেজ পাঠানো (এখানে অরিজিনাল কন্টেন্ট বা লিংকই সেভ হবে)
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
        'repliedMessage':
            replyData != null ? (replyData['message'] ?? "") : null,
        'repliedBy':
            replyData != null ? (replyData['senderName'] ?? "User") : null,
      });

      // 🔥 নোটিফিকেশন বা চ্যাট লিস্টের প্রিভিউয়ের জন্য লাস্ট মেসেজ টেক্সট ঠিক করা
      String displayLastMessage = content;
      if (type == 'image') {
        displayLastMessage = '📷 Sent an image';
      } else if (type == 'video') {
        displayLastMessage = '🎥 Sent a video';
      } else if (type == 'audio') {
        displayLastMessage = '🎤 Sent a voice message';
      }

      // লাস্ট মেসেজ আপডেট করা
      await FirebaseFirestore.instance.collection('chats').doc(roomId).set({
        'lastMessage':
            displayLastMessage, // এখানে লিংকের বদলে সুন্দর টেক্সট সেভ হবে
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        // রিসিভারের আইডির জন্য কাউন্ট বাড়ান, সেন্ডারের জন্য নয়
        'unReadCount_${widget.receiverId}': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Send message error: $e");
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
                } catch (e) {}
              } else {
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

// 🔥 লং প্রেস করলে গ্যালারিতে সেভ করার জন্য পপআপ ডায়ালগ
  void _showSaveDialog(String url, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        title: Text("Save ${type == 'image' ? 'Image' : 'Video'}?",
            style: const TextStyle(color: Colors.white)),
        content: Text(
            "Do you want to download and save this ${type == 'image' ? 'image' : 'video'} to your gallery?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadMedia(url, type);
            },
            child:
                const Text("Save", style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
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
      // পুরো ব্যাকগ্রাউন্ড এবং অ্যাপবার জুড়ে ছবির মতো ভার্টিক্যাল লাইট বিম ও গ্লোয়িং লাভ ইফেক্ট থিম
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(
                  0xFF261007), // ওপরের অংশে উজ্জ্বল ডার্ক ব্রাউন ও গোল্ডেন গ্লো
              Color(0xFF140804), // মিডল ডিপ কপার টোন
              Color(0xFF050201), // একদম নিচে গাঢ় ব্ল্যাক-ব্রাউন
            ],
          ),
        ),
        child: Stack(
          children: [
            // ১. ছবির মতো ওপর থেকে নেমে আসা ভার্টিক্যাল লাইট বিম ও গ্লোয়িং লাভ ইফেক্টের ব্যাকগ্রাউন্ড লেয়ার
            Positioned.fill(
              child: CustomPaint(
                painter: _LoveLightRaysPainter(),
              ),
            ),

            // ২. মূল চ্যাট ইন্টারফেস ও অ্যাপবার অংশ
            Column(
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
                    // রঙিন কলিং বাটন (VIP চেক লজিক সহ)
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amberAccent,
                              Colors.deepOrangeAccent,
                              Colors.orange
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call,
                            color: Colors.white, size: 18),
                      ),
                      onPressed: () async {
                        // ১. ফায়ারস্টোর থেকে বর্তমান ইউজারের (কলার) ডাটা ফেচ করা
                        var myDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentSixDigitId)
                            .get();

                        var myData = myDoc.data();
                        if (myData == null) return;

                        // 🛑 [শুধুমাত্র কলারের ভিআইপি স্ট্যাটাস চেক করা হচ্ছে]
                        int vipXp = myData['vip_xp'] ?? myData['xp'] ?? 0;
                        int vipExpiry = myData['vipExpiry'] ?? 0;
                        int currentTime = DateTime.now().millisecondsSinceEpoch;

                        int vipLevel = 0;
                        if (!(vipExpiry != 0 && currentTime > vipExpiry)) {
                          if (vipXp >= 35000) {
                            vipLevel = 8;
                          } else if (vipXp >= 30000) {
                            vipLevel = 7;
                          } else if (vipXp >= 25000) {
                            vipLevel = 6;
                          } else if (vipXp >= 20000) {
                            vipLevel = 5;
                          } else if (vipXp >= 13000) {
                            vipLevel = 4;
                          } else if (vipXp >= 9000) {
                            vipLevel = 3;
                          } else if (vipXp >= 5000) {
                            vipLevel = 2;
                          } else if (vipXp >= 2500) {
                            vipLevel = 1;
                          }
                        }

                        // যদি কলার ভিআইপি না হয় (vipLevel == 0), তবে কল করতে পারবে না
                        if (vipLevel <= 0) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Only VIP users can make calls"),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                          return;
                        }

                        String myName = myData['name'] ?? '';
                        String myPic = myData['profilePic'] ?? '';

                        // ২. ফায়ারস্টোর থেকে রিসিভারের ডাটা ফেচ করা
                        var receiverDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.receiverId)
                            .get();

                        String receiverName =
                            receiverDoc.data()?['name'] ?? widget.receiverName;
                        String receiverPic =
                            receiverDoc.data()?['profilePic'] ?? '';

                        String callChannelId = getChatRoomId();

                        // ৩. কল হ্যান্ডলার কল করা
                        if (context.mounted) {
                          await CallHandler.makeCall(
                            context: context,
                            myId: currentSixDigitId,
                            myName: myName,
                            myPic: myPic,
                            receiverId: widget.receiverId,
                            receiverName: receiverName,
                            receiverPic: receiverPic,
                            channelId: callChannelId,
                          );
                        }
                      },
                    ),

                    // ব্লক, আনব্লক ও রিপোর্ট অপশন সম্বলিত PopupMenuButton
                    PopupMenuButton<String>(
                      color: const Color(0xFF22110B),
                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                      onSelected: (value) async {
                        String roomId = getChatRoomId();
                        if (value == 'block') {
                          await ChatActions.blockUser(context,
                              currentSixDigitId, widget.receiverId, roomId);
                          setState(() => isBlocked = true);
                          _loadBlockedList();
                        } else if (value == 'unblock') {
                          await ChatActions.unblockUser(context,
                              currentSixDigitId, widget.receiverId, roomId);
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
                                      : Colors.amberAccent)),
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

                // লাইভ রুম বার (যদি থাকে)
                _buildLiveRoomBar(),

                // চ্যাট ম্যাসেজ লিস্ট সেকশন
                Expanded(
                  child: Stack(
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: currentSixDigitId.isEmpty
                            ? const Stream.empty()
                            : FirebaseFirestore.instance
                                .collection('chats')
                                .doc(getChatRoomId())
                                .collection('messages')
                                .orderBy('timestamp', descending: true)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (currentSixDigitId.isEmpty) {
                            return const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.amberAccent));
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.orangeAccent));
                          }

                          final docs = snapshot.data!.docs;
                          return ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;

                              data['docId'] = doc.id;

                              String senderId =
                                  data['senderuID']?.toString() ?? "";
                              bool isBlockedNow =
                                  myBlockedUsers.contains(senderId);

                              if (isBlockedNow) {
                                return const SizedBox.shrink();
                              }

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

                // ইনপুট সেকশন
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF22110B).withOpacity(0.9),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(25)),
                    border: Border.all(color: const Color.fromARGB(31, 245, 186, 22)),
                  ),
                  child: _inputSection(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
  if (data['type'] == 'room_invite') {
    String rName = data['roomName'] ?? "Voice Room";
    String rImage = data['roomImage'] ?? 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/room_default.png';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VoiceRoom(roomId: data['roomId']),
              ),
            );
          },
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    rImage,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.meeting_room, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  rName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  "Tap to join voice room",
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                          ListTile(
                            leading: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            title: const Text("Delete Message",
                                style: TextStyle(color: Colors.redAccent)),
                            onTap: () async {
                              Navigator.pop(context);
                              try {
                                String messageDocId = data['docId'] ?? '';
                                if (messageDocId.isNotEmpty) {
                                  await FirebaseFirestore.instance
                                      .collection('chats')
                                      .doc(getChatRoomId())
                                      .collection('messages')
                                      .doc(messageDocId)
                                      .delete();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Message deleted")));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Failed: Message ID not found")));
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text("Failed to delete: $e")));
                              }
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
      return GestureDetector(
        onTap: () {
          // সিঙ্গেল ট্যাপে ফুলস্ক্রিন ইমেজ ভিউ ওপেন হবে
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenImageViewer(imageUrl: msg),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: msg,
            width: 200,
            fit: BoxFit.cover,
            placeholder: (context, url) => const SizedBox(
              width: 50,
              height: 50,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.white70,
                ),
              ),
            ),
            errorWidget: (context, error, stackTrace) => const Icon(
              Icons.broken_image,
              color: Colors.white24,
              size: 40,
            ),
          ),
        ),
      );
    } else if (type == 'video') {
      return GestureDetector(
        onTap: () {
          // সিঙ্গেল ট্যাপে ভিডিও প্লেয়ার বা ফুলস্ক্রিন পেজে রিডাইরেক্ট হবে
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(videoUrl: msg),
            ),
          );
        },
        child: Container(
          width: 200,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.play_circle_fill, color: Colors.cyanAccent, size: 50),
              Positioned(
                bottom: 8,
                child: Text("Tap to Play Video",
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ),
            ],
          ),
        ),
      );
    } else if (type == 'audio') {
      bool isPlayingThis = _isPlayingAudio && _playingAudioUrl == msg;

      return InkWell(
        onTap: () async {
          if (isPlayingThis) {
            await _audioPlayer.stop();
            _positionSub?.cancel();
            _durationSub?.cancel();
            setState(() {
              _isPlayingAudio = false;
              _playingAudioUrl = null;
              _currentAudioPosition = 0;
              _totalAudioDuration = 0;
            });
          } else {
            await _audioPlayer.stop();
            _positionSub?.cancel();
            _durationSub?.cancel();

            setState(() {
              _isPlayingAudio = true;
              _playingAudioUrl = msg;
              _currentAudioPosition = 0;
              _totalAudioDuration = 0;
            });

            await _audioPlayer.play(UrlSource(msg));

            _durationSub = _audioPlayer.onDurationChanged.listen((duration) {
              if (mounted) {
                setState(() {
                  _totalAudioDuration = duration.inSeconds;
                });
              }
            });

            _positionSub = _audioPlayer.onPositionChanged.listen((position) {
              if (mounted) {
                setState(() {
                  _currentAudioPosition = position.inSeconds;
                });
              }
            });

            _audioPlayer.onPlayerComplete.listen((event) {
              if (mounted) {
                _positionSub?.cancel();
                _durationSub?.cancel();
                setState(() {
                  _isPlayingAudio = false;
                  _playingAudioUrl = null;
                  _currentAudioPosition = 0;
                  _totalAudioDuration = 0;
                });
              }
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPlayingThis
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                color: Colors.cyanAccent,
                size: 28,
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                height: 20,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    bool isPassed = false;
                    if (isPlayingThis && _totalAudioDuration > 0) {
                      int activeIndex =
                          ((_currentAudioPosition / _totalAudioDuration) * 10)
                              .floor();
                      isPassed = index <= activeIndex;
                    }
                    return Container(
                      width: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: isPassed ? Colors.cyanAccent : Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isPlayingThis
                    ? "${_formatDuration(_currentAudioPosition)} / ${_formatDuration(_totalAudioDuration)}"
                    : "Voice Message",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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

      // ২. ডাউনলোড করা ডাটা বাইট আকারে পড়া
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
          color: Color(0xFF1E1E2F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔥 আপলোড প্রোগ্রেস বারটি এখানে ইনপুট বক্সের ঠিক ওপরে বসবে
          if (_isUploading)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.cyanAccent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.cyanAccent),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text("${(_uploadProgress * 100).toStringAsFixed(0)}%",
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),

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

          // 🎙️ রেকর্ডিং চলার সময় প্রিভিউ এবং রানিং সেকেন্ড অ্যানিমেশন বক্স
          if (_isRecording)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D1A),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.redAccent, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    _formatDuration(_recordDuration),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: SizedBox(
                      height: 20,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 15,
                        itemBuilder: (context, index) {
                          // রেকর্ডিংয়ের সময় সেকেন্ডের সাথে ওয়েভফর্ম এগোবে
                          bool isActive = index <= (_recordDuration % 15);
                          return Container(
                            width: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color:
                                  isActive ? Colors.cyanAccent : Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const Text("Recording...",
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),

          // মূল ইনপুট রো
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
                    hintText: "Type a message...",
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
// ছবির মতো ভার্টিক্যাল লাইট বিম এবং ঝুলন্ত লাভ শেপ আঁকার জন্য কাস্টম পেইন্টার
class _LoveLightRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final raysColors = [
      Colors.orange.withOpacity(0.08),
      Colors.amber.withOpacity(0.12),
      Colors.deepOrange.withOpacity(0.05),
      Colors.transparent,
    ];

    for (double i = 0; i < size.width; i += 35) {
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: raysColors,
      ).createShader(Rect.fromLTWH(i, 0, 25, size.height));

      canvas.drawRect(Rect.fromLTWH(i, 0, 18, size.height * 0.75), paint);
    }

    final heartPaint = Paint()
      ..color = Colors.amberAccent.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.orangeAccent.withOpacity(0.2)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    var heartsData = [
      Offset(size.width * 0.2, size.height * 0.15),
      Offset(size.width * 0.45, size.height * 0.28),
      Offset(size.width * 0.75, size.height * 0.20),
      Offset(size.width * 0.3, size.height * 0.45),
      Offset(size.width * 0.85, size.height * 0.40),
    ];

    for (var center in heartsData) {
      canvas.drawLine(Offset(center.dx, 0), center, linePaint);

      Path path = Path();
      double sizeFactor = center.dy * 0.08 + 8;
      path.moveTo(center.dx, center.dy + sizeFactor * 0.4);
      path.cubicTo(
        center.dx - sizeFactor, center.dy - sizeFactor * 0.6,
        center.dx - sizeFactor * 0.5, center.dy - sizeFactor * 1.2,
        center.dx, center.dy - sizeFactor * 0.4,
      );
      path.cubicTo(
        center.dx + sizeFactor * 0.5, center.dy - sizeFactor * 1.2,
        center.dx + sizeFactor, center.dy - sizeFactor * 0.6,
        center.dx, center.dy + sizeFactor * 0.4,
      );
      path.close();

      canvas.drawPath(path, heartPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}