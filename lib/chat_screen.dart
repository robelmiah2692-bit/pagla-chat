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
  bool _isRecording = false;
  String currentSixDigitId = "";

  @override
  void initState() {
    super.initState();
    _getMySixDigitId(); // অ্যাপ ওপেন হওয়ার সাথে সাথে আপনার আইডি লোড হবে
  }

// আপনার নিজের ৬-ডিজিটের uID খুঁজে বের করার ফাংশন
  void _getMySixDigitId() async {
    final String authUID = FirebaseAuth.instance.currentUser?.uid ?? "";

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('authUID', isEqualTo: authUID)
        .limit(1)
        .get();

    if (userDoc.docs.isNotEmpty) {
      setState(() {
        // ডাটাবেজ থেকে আপনার uID ভেরিয়েবলে সেট করা হচ্ছে
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
    // এখানে ডাটাবেস থেকে ইউজারের বর্তমান অবস্থা চেক করা হচ্ছে
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
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

  void _sendDataMessage(String content, String type) async {
    if (content.isEmpty) return;

    try {
      final String authUID = FirebaseAuth.instance.currentUser?.uid ?? "";

      // ১. আপনার লম্বা Auth UID দিয়ে ইউজার ডকুমেন্ট খুঁজে বের করা
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: authUID)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        debugPrint("User profile not found in Firestore!");
        return;
      }

      // ২. নিজের ৬-ডিজিটের uID এবং অন্যান্য তথ্য সংগ্রহ করা
      final userData = userQuery.docs.first.data();
      final String mySixDigitId = userData['uID']?.toString() ?? '0';
      final String myEmail = userData['email'] ?? '';
      final String myName = userData['name'] ?? 'User';
      final String myPic =
          userData['profilepic'] ?? userData['profilePic'] ?? '';

      // ৩. ইউনিক চ্যাট রুম আইডি তৈরি (শুধুমাত্র ৬-ডিজিটের আইডি ব্যবহার করে)
      String roomId;
      if (widget.receiverId == "paglachat_official") {
        roomId = "paglachat_official_$mySixDigitId";
      } else {
        List<String> ids = [mySixDigitId, widget.receiverId];
        ids.sort();
        roomId = ids.join("_");
      }
      // ৪. মেসেজ পাঠানো
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(roomId) // ৬-ডিজিট ভিত্তিক রুম আইডি
          .collection('messages')
          .add({
        'senderId': authUID, // লম্বা আইডি (ভবিষ্যৎ রেফারেন্সের জন্য রাখা ভালো)
        'senderuID': mySixDigitId, // আপনার ৬-ডিজিটের আইডি
        'senderEmail': myEmail,
        'senderName': myName,
        'senderImage': myPic,
        'receiverId': widget.receiverId, // রিসিভারের ৬-ডিজিটের আইডি
        'message': content,
        'type': type,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint("Message Sent to Room: $roomId");
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
        backgroundColor: const Color.fromARGB(146, 129, 219, 241),
        title: const Text("Unlock Media Feature",
            style: TextStyle(color: Colors.white)),
        content: Text(
            "Buy 1 month access for 6,000 Diamonds.\nYour Balance: $currentDiamonds",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(107, 238, 57, 117)),
            onPressed: () async {
              if (currentDiamonds >= 6000) {
                DateTime expiryDate =
                    DateTime.now().add(const Duration(days: 30));
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUserId)
                    .update({
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
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => VoiceRoom(roomId: roomId)));
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
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 150);
          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final String name =
              userData['name'] ?? userData['userName'] ?? 'User';
          final String pic =
              userData['profilePic'] ?? userData['userImage'] ?? '';
          final bool isVIP = userData['isVIP'] ?? false;
          final bool isFollowing =
              (userData['followerList'] ?? []).contains(currentUserId);

          return Container(
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
                color: Color(0xFF1E1E2F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                    radius: 55,
                    backgroundColor: const Color.fromARGB(108, 237, 91, 140),
                    child: CircleAvatar(
                        radius: 52,
                        backgroundImage:
                            pic.isNotEmpty ? NetworkImage(pic) : null)),
                const SizedBox(height: 15),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  if (isVIP)
                    const Icon(Icons.verified, color: Colors.amber, size: 22),
                ]),
                const SizedBox(height: 20),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statWidget("Followers", userData['followers'] ?? 0),
                      _statWidget("Following", userData['following'] ?? 0),
                    ]),
                const SizedBox(height: 30),
                if (userId != currentUserId)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isFollowing ? Colors.grey : Colors.pinkAccent,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))),
                    onPressed: () => _toggleFollow(userId, isFollowing),
                    child: Text(isFollowing ? "Unfollow" : "Follow",
                        style: const TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _toggleFollow(String targetuID, bool isFollowing) async {
    var myRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);
    var targetRef =
        FirebaseFirestore.instance.collection('users').doc(targetuID);
    if (isFollowing) {
      await targetRef.update({
        'followers': FieldValue.increment(-1),
        'followerList': FieldValue.arrayRemove([currentUserId])
      });
      await myRef.update({'following': FieldValue.increment(-1)});
    } else {
      await targetRef.update({
        'followers': FieldValue.increment(1),
        'followerList': FieldValue.arrayUnion([currentUserId])
      });
      await myRef.update({'following': FieldValue.increment(1)});
    }
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
              backgroundColor:
                  Colors.transparent, // ব্যাকগ্রাউন্ডের সাথে মিশিয়ে দেওয়া হয়েছে
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                    onPressed: () {}),
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
                          // লম্বা আইডি দিয়ে চেক করা হচ্ছে কে পাঠিয়েছে
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
  
  // 🔥 ফিক্স ১: ডাটাবেসে 'message' না থাকলে যেন 'text' ফিল্ড থেকে রিচার্জের লেখাটা নেয়
  String msg = data['message'] ?? data['text'] ?? ''; 

  // 🔥 ফিক্স ২: অফিশিয়াল মেসেজ যেন ভুল করে আপনার নিজের (isMe) বাবলের ভেতরে না ঢুকে যায়
  bool isOfficial = data['senderId'] == 'paglachat_official' || type == 'system_msg';
  bool finalIsMe = isMe && !isOfficial;

  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Row(
      mainAxisAlignment:
          finalIsMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // বাম পাশের অবতার (যদি নিজের মেসেজ না হয়)
        if (!finalIsMe)
          _chatAvatar(
              data['senderId'] ?? 'paglachat_official', 
              data['senderImage'] ?? '',
              data['senderName'] ?? 'Official'
          ),
        const SizedBox(width: 10),
        Flexible(
          child: GestureDetector(
            onLongPress: () => _downloadMedia(msg, type),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // অফিশিয়াল মেসেজের ব্যাকগ্রাউন্ড একটু আলাদা ডিপ কালার দিলে ফুটবে সুন্দর
                color: finalIsMe
                    ? const Color.fromARGB(171, 241, 97, 145)
                    : isOfficial 
                        ? const Color(0xFF251F3D) // অফিশিয়াল এর জন্য স্পেশাল ডার্ক পার্পল ভাইব
                        : const Color(0xFF1E1E2F),
                borderRadius: BorderRadius.circular(15),
                // অফিশিয়াল মেসেজের চারপাশ গোল্ডেন বর্ডার দিলে আরও রয়্যাল লাগবে
                border: isOfficial 
                    ? Border.all(color: Colors.amberAccent.withOpacity(0.4), width: 1)
                    : null,
              ),
              child: _buildTypeContent(type, msg),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // ডান পাশের অবতার (যদি নিজের মেসেজ হয়)
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

  void _downloadMedia(String url, String type) async {
    try {
      if (type == 'image') {
        await Gal.putImage(url);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Image Saved to Gallery!")));
      } else if (type == 'video') {
        await Gal.putVideo(url);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Video Saved to Gallery!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Save failed: $e")));
    }
  }

  Widget _chatAvatar(String uID, String url, String name) {
  // 🔥 ফিক্স: আইডি যদি অফিশিয়াল হয়, তবে ফায়ারবেস চেক ছাড়াই সরাসরি গিটহাবের রয়্যাল লোগো দেখাবে
  if (uID == 'paglachat_official' || name == 'Official') {
    const String officialPic = "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/favicon.png";
    return GestureDetector(
      onTap: () => _showProfile(context, uID),
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
        onTap: () => _showProfile(context, uID),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: const BoxDecoration(
          color: Color(0xFF1E1E2F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Row(
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
                hintText: _isRecording ? "Recording..." : "Type a message...",
                filled: true,
                fillColor: const Color(0xFF0D0D1A),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
    );
  }
}
