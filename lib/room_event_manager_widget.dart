import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomEventManagerWidget extends StatelessWidget {
  final String roomId;
  final Map<String, dynamic> roomData;

  const RoomEventManagerWidget(
      {super.key, required this.roomId, required this.roomData});

  @override
  Widget build(BuildContext context) {
    return EventDashboardTab(roomId: roomId, roomData: roomData);
  }
}

class EventDashboardTab extends StatefulWidget {
  final String roomId;
  final Map<String, dynamic> roomData;

  const EventDashboardTab(
      {super.key, required this.roomId, required this.roomData});

  @override
  State<EventDashboardTab> createState() => _EventDashboardTabState();
}

class _EventDashboardTabState extends State<EventDashboardTab> {
  // স্ক্রিনশট অনুযায়ী ফায়ারবেস অথ আইডি দিয়ে ইউজারের ৬ ডিজিট আইডি (ডকুমেন্ট আইডি) খুঁজে বের করার ফাংশন
  Future<Map<String, dynamic>?> _getCreatorProfileData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    try {
      // ১. প্রথমে চেক করবো ফায়ারবেস অথ আইডি (currentUser.uid) কোনো ডকুমেন্টের 'uid' ফিল্ডে আছে কিনা
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        // ডকুমেন্টের আইডি নিজেই যেহেতু ৬ ডিজিটের ইউআইডি, তাই সেটিও যুক্ত করে দিলাম
        data['documentId'] = doc.id;
        return data;
      }

      // ২. যদি কুয়ারিতে না পাওয়া যায়, তবে সরাসরি কারেন্ট ইউজারের আইডি দিয়ে চেষ্টা করবো
      final directDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (directDoc.exists && directDoc.data() != null) {
        final data = directDoc.data()!;
        data['documentId'] = directDoc.id;
        return data;
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Events & History",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _checkAndShowCreateEventDialog(context);
                },
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text("Create Event",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text("Live History",
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const Divider(color: Colors.white24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .collection('room_events')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.amber));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No events created yet.",
                        style: TextStyle(color: Colors.white54)),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final eventData =
                        docs[index].data() as Map<String, dynamic>;
                    eventData['id'] = docs[index].id;
                    return EventCardWidget(
                        roomId: widget.roomId,
                        eventData: eventData,
                        roomData: widget.roomData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAndShowCreateEventDialog(BuildContext context) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('room_events')
          .where('status', whereIn: ['Live', 'Waiting for live']).get();

      if (querySnapshot.docs.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "An event is already Live or Waiting for live! Please wait until it ends."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } catch (e) {
      debugPrint("Error checking active events: $e");
    }

    if (context.mounted) {
      _showCreateEventDialog(context);
    }
  }

  void _showCreateEventDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    String? selectedTarget;
    File? selectedImage;
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();
    int durationMinutes = 30;
    bool isUploading = false;
    final List<String> targets = ['50K', '100K', '200K', '300K', '500K'];
    final List<int> durations = [15, 30, 45, 60, 90, 120];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16213E),
              title: const Text("Create New Event",
                  style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUploading)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: Colors.amber),
                      )
                    else ...[
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Event Name",
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white38)),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          selectedImage != null
                              ? Image.file(selectedImage!,
                                  width: 50, height: 50, fit: BoxFit.cover)
                              : Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.image,
                                      color: Colors.white)),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(
                                  source: ImageSource.gallery);
                              if (pickedFile != null) {
                                setDialogState(() {
                                  selectedImage = File(pickedFile.path);
                                });
                              }
                            },
                            child: const Text("Pick Event Pic",
                                style: TextStyle(color: Colors.amber)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF16213E),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            labelText: "Event Target",
                            labelStyle: TextStyle(color: Colors.white70)),
                        items: targets
                            .map((target) => DropdownMenuItem(
                                value: target, child: Text(target)))
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedTarget = val),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<int>(
                        dropdownColor: const Color(0xFF16213E),
                        value: durationMinutes,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            labelText: "Event Duration (Minutes)",
                            labelStyle: TextStyle(color: Colors.white70)),
                        items: durations
                            .map((d) => DropdownMenuItem(
                                value: d, child: Text("$d Minutes")))
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => durationMinutes = val!),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              "Date: ${selectedDate.toLocal().toString().split(' ')[0]}",
                              style: const TextStyle(color: Colors.white)),
                          TextButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) {
                                setDialogState(() => selectedDate = date);
                              }
                            },
                            child: const Text("Select Date",
                                style: TextStyle(color: Colors.amber)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Start Time: ${startTime.format(context)}",
                              style: const TextStyle(color: Colors.white)),
                          TextButton(
                            onPressed: () async {
                              final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now());
                              if (time != null) {
                                setDialogState(() => startTime = time);
                              }
                            },
                            child: const Text("Select Time",
                                style: TextStyle(color: Colors.amber)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: isUploading
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel",
                            style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isNotEmpty &&
                              selectedTarget != null) {
                            setDialogState(() => isUploading = true);

                            try {
                              QuerySnapshot doubleCheck =
                                  await FirebaseFirestore.instance
                                      .collection('rooms')
                                      .doc(widget.roomId)
                                      .collection('room_events')
                                      .where('status', whereIn: [
                                'Live',
                                'Waiting for live'
                              ]).get();

                              if (doubleCheck.docs.isNotEmpty) {
                                setDialogState(() => isUploading = false);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "An event is already Live or Waiting for live!"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }

                              // স্ক্রিনশটের গঠন অনুযায়ী সঠিক ইউজার প্রোফাইল ফেচ করা
                              final userProfile =
                                  await _getCreatorProfileData();
                              final currentUser =
                                  FirebaseAuth.instance.currentUser;

                              // স্ক্রিনশট অনুযায়ী ৬ ডিজিটের ইউজার আইডি (যেমন: 454488) হলো ডকুমেন্টের আইডি বা uID ফিল্ড
                              final sixDigitUid = userProfile?['documentId'] ??
                                  userProfile?['uID'] ??
                                  userProfile?['uid'] ??
                                  '';

                              final resolvedIdentifier =
                                  userProfile?['uid'] ?? currentUser?.uid ?? '';

                              // স্ক্রিনশটের নাম (`name`) এবং প্রোফাইল পিক (`profilePic`) ফিল্ড ধরে ডাটা নেওয়া
                              final creatorName =
                                  userProfile?['name'] ?? 'Unknown';
                              final creatorImage = userProfile?['profilePic'] ??
                                  userProfile?['image'] ??
                                  '';

                              String eventId = FirebaseFirestore.instance
                                  .collection('rooms')
                                  .doc(widget.roomId)
                                  .collection('room_events')
                                  .doc()
                                  .id;

                              String imageUrl = '';
                              if (selectedImage != null) {
                                Reference ref = FirebaseStorage.instance
                                    .ref()
                                    .child('room_events')
                                    .child(widget.roomId)
                                    .child('$eventId.jpg');

                                await ref.putFile(selectedImage!);
                                imageUrl = await ref.getDownloadURL();
                              }

                              final DateTime startDateTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                startTime.hour,
                                startTime.minute,
                              );
                              final DateTime endDateTime = startDateTime
                                  .add(Duration(minutes: durationMinutes));

                              // ইভেন্ট ডেটা সেভ করার সময় 'createdBy' এ ইভেন্ট ক্রিয়েটরের সঠিক আইডি সংরক্ষিত আছে
                              Map<String, dynamic> eventData = {
                                'id': eventId,
                                'name': nameController.text,
                                'target': selectedTarget,
                                'imagePath': imageUrl,
                                'startTime': Timestamp.fromDate(startDateTime),
                                'endTime': Timestamp.fromDate(endDateTime),
                                'durationMinutes': durationMinutes,
                                'status': 'Waiting for live',
                                'createdAt': FieldValue.serverTimestamp(),
                                'topGifters': [],
                                'totalDiamonds': 0, // <--- এই ফিল্ডটি নতুন যোগ করা হলো, যা শুরুতেই ০ থাকবে
                                'createdBy':
                                    resolvedIdentifier, // এটি হলো ইভেন্ট ক্রিয়েটরের আইডি
                                'creatorName': creatorName,
                                'creatorImage': creatorImage,
                                'creatorSixDigitUID': sixDigitUid,
                              };

                              await FirebaseFirestore.instance
                                  .collection('rooms')
                                  .doc(widget.roomId)
                                  .collection('room_events')
                                  .doc(eventId)
                                  .set(eventData);

                              _sendEventNotification(
                                  sixDigitUid, // এখানে ৬ ডিজিটের আইডি পাস করা হলো
                                  nameController.text,
                                  selectedTarget!);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              setDialogState(() => isUploading = false);
                              debugPrint("Event Creation Error: $e");
                            }
                          }
                        },
                        child: const Text("Save"),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  void _sendEventNotification(
      String creatorSixDigitUid, String eventName, String target) async {
    try {
      debugPrint("=== START SENDING NOTIFICATION ===");
      debugPrint("Creator 6-Digit UID: $creatorSixDigitUid");

      if (creatorSixDigitUid.isEmpty) {
        debugPrint(
            "Error: Creator 6-Digit UID is empty! Notification cannot be sent.");
        return;
      }

      // আপনার ডাটাবেস স্ট্রাকচার অনুযায়ী ৬ ডিজিটের আইডি দিয়ে চ্যাট রুমের আইডি তৈরি
      String chatId = 'paglachat_official_$creatorSixDigitUid';
      debugPrint("Target Chat Document ID: $chatId");

      var chatDocRef =
          FirebaseFirestore.instance.collection('chats').doc(chatId);

      // চ্যাট রুমের মূল ডকুমেন্ট আপডেট বা তৈরি করা (অফিসিয়াল চ্যাটের নিয়মে)
      await chatDocRef.set({
        'lastMessage':
            "🔥 Your Event has been scheduled! Event: $eventName | Target: $target is Waiting for live.",
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'type': 'official_event',
        'user1': 'paglachat_official',
        'user2': creatorSixDigitUid,
        // যদি আপনার চ্যাটে আনরিড কাউন্ট বাড়ানোর সিস্টেম থাকে:
        'unReadCount_$creatorSixDigitUid': FieldValue.increment(1),
      }, SetOptions(merge: true));
      debugPrint("Chat main document updated successfully.");

      // 'messages' সাব-কালেকশনে মেসেজ যুক্ত করা
      var docRef = await chatDocRef.collection('messages').add({
        'senderId': 'paglachat_official',
        'receiverId': creatorSixDigitUid, // রিসিভার হিসেবে ৬ ডিজিটের আইডি
        'message':
            "🔥 Your Event has been scheduled! Event: $eventName | Target: $target is Waiting for live.",
        'type': 'official_event',
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint(
          "Message successfully added to sub-collection with ID: ${docRef.id}");
      debugPrint("=== NOTIFICATION SENT SUCCESSFULLY ===");
    } catch (e) {
      debugPrint("❌ Notification Error Exception: $e");
    }
  }
}

class EventCardWidget extends StatefulWidget {
  final String roomId;
  final Map<String, dynamic> eventData;
  final Map<String, dynamic> roomData;

  const EventCardWidget({
    super.key,
    required this.roomId,
    required this.eventData,
    required this.roomData,
  });

  @override
  State<EventCardWidget> createState() => _EventCardWidgetState();
}

class _EventCardWidgetState extends State<EventCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _timer;
  String _timeStatusText = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _calculateTimeStatus();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeStatus();
    });
  }

  void _calculateTimeStatus() {
    String currentStatus = widget.eventData['status'] ?? 'Waiting for live';

    if (currentStatus == 'Ended') {
      if (mounted) {
        setState(() {
          _timeStatusText = '';
        });
      }
      return;
    }

    DateTime now = DateTime.now();
    DateTime? startTime;
    DateTime? endTime;

    if (widget.eventData['startTime'] != null) {
      startTime = (widget.eventData['startTime'] as Timestamp).toDate();
    }
    if (widget.eventData['endTime'] != null) {
      endTime = (widget.eventData['endTime'] as Timestamp).toDate();
    }

    // ১. startTime সেট না করা থাকলে বা আসার আগ পর্যন্ত কাউন্টডাউন দেখাবে
    if (startTime != null && now.isBefore(startTime)) {
      Duration remaining = startTime.difference(now);
      int hours = remaining.inHours;
      int minutes = remaining.inMinutes % 60;
      int seconds = remaining.inSeconds % 60;

      if (currentStatus == 'Live') {
        _updateStatus('Waiting for live');
      }

      if (mounted) {
        setState(() {
          _timeStatusText = 'Starts in: ${hours}h ${minutes}m ${seconds}s';
        });
      }
    }
    // ২. startTime পার হয়ে গেলে কিন্তু endTime শেষ না হলে ইভেন্ট লাইভ হবে
    else if (startTime != null &&
        now.isAfter(startTime) &&
        endTime != null &&
        now.isBefore(endTime)) {
      if (currentStatus != 'Live') {
        _updateStatus('Live');
      }

      Duration remaining = endTime.difference(now);
      int hours = remaining.inHours;
      int minutes = remaining.inMinutes % 60;
      int seconds = remaining.inSeconds % 60;

      if (mounted) {
        setState(() {
          _timeStatusText = 'Left: ${hours}h ${minutes}m ${seconds}s';
        });
      }
    }
    // ৩. endTime পার হয়ে গেলে ইভেন্ট শেষ (Ended) হয়ে যাবে
    else if (endTime != null && now.isAfter(endTime)) {
      if (currentStatus != 'Ended') {
        _updateStatus('Ended');
      }
      if (mounted) {
        setState(() {
          _timeStatusText = '';
        });
      }
    }
    // যদি কোনো টাইম সেট করা না থাকে
    else {
      if (mounted) {
        setState(() {
          _timeStatusText = '0h 0m 0s';
        });
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _updateStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('room_events')
          .doc(widget.eventData['id'])
          .update({'status': newStatus});
    } catch (e) {
      // Ignore or handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    String status = widget.eventData['status'] ?? 'Waiting for live';

    Color statusColor = status == 'Live'
        ? Colors.green
        : (status == 'Waiting for live' ? Colors.orange : Colors.red);

    String imagePath = widget.eventData['imagePath'] ?? '';
    List topGifters = widget.eventData['topGifters'] ?? [];

    // টুটাল ডাইমন্ড ফিল্ড হ্যান্ডলিং (যদি ডাটাবেজে না থাকে তবে 0 দেখাবে অথবা টপ গিফটারদের গিফট যোগ করে হিসাব করবে)
    int totalDiamonds = widget.eventData['totalDiamonds'] ?? 
        widget.eventData['totalDiamonds'] ?? 
        topGifters.fold(0, (sum, gifter) => sum + ((gifter['gift'] ?? 0) as num).toInt());

    // ক্রিয়েটার ইনফো ফেচ করা
    String creatorName = widget.eventData['creatorName'] ?? 'Unknown Creator';
    String creatorImage = widget.eventData['creatorImage'] ?? '';
    String creatorUid = widget.eventData['creatorSixDigitUID'] ??
        widget.eventData['createdBy'] ??
        '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== ক্রিয়েটর ইনফো সেকশন ====================
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey[700],
                backgroundImage:
                    creatorImage.isNotEmpty && creatorImage.startsWith('http')
                        ? NetworkImage(creatorImage)
                        : null,
                child: creatorImage.isEmpty || !creatorImage.startsWith('http')
                    ? const Icon(Icons.person, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Created by: $creatorName ${creatorUid.isNotEmpty ? '(ID: $creatorUid)' : ''}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 8),
          // =========================================================================

          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imagePath.isNotEmpty
                    ? (imagePath.startsWith('http')
                        ? Image.network(
                            imagePath,
                            width: 45,
                            height: 45,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image,
                                    color: Colors.white),
                          )
                        : Image.file(
                            File(imagePath),
                            width: 45,
                            height: 45,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image,
                                    color: Colors.white),
                          ))
                    : Container(
                        width: 45,
                        height: 45,
                        color: Colors.grey[800],
                        child: const Icon(Icons.event, color: Colors.white),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.eventData['name'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeStatusText.isNotEmpty
                          ? "Target: ${widget.eventData['target'] ?? 0} | $_timeStatusText"
                          : "Target: ${widget.eventData['target'] ?? 0}",
                      style: const TextStyle(
                          color: Colors.amberAccent, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (status == 'Waiting for live')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Waiting for live",
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                )
              else if (status == 'Live')
                FadeTransition(
                  opacity: _animController,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "LIVE",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                )
              else if (status == 'Ended')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Event Ended",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(color: Colors.white24, height: 15),
          
          // ==================== টুটাল ডাইমন্ড ফিল্ড (নতুন যোগ করা হয়েছে) ====================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Diamonds:",
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "$totalDiamonds 💎",
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // =========================================================================

          const Text(
            "Top Gifters:",
            style: TextStyle(
                color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          topGifters.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    "No gifts yet. Start gifting from 0!",
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: topGifters.map((gifter) {
                    String gifterImg =
                        gifter['image'] ?? gifter['gifterPic'] ?? '';
                    return Column(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.grey,
                          backgroundImage: gifterImg.isNotEmpty &&
                                  gifterImg.startsWith('http')
                              ? NetworkImage(gifterImg)
                              : null,
                          child:
                              gifterImg.isEmpty || !gifterImg.startsWith('http')
                                  ? const Icon(Icons.person,
                                      size: 14, color: Colors.white)
                                  : null,
                        ),
                        const SizedBox(height: 2),
                        Text(gifter['name'] ?? '',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
                        Text('${gifter['gift'] ?? 0} 💎',
                            style: const TextStyle(
                                color: Colors.amberAccent, fontSize: 9)),
                      ],
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}