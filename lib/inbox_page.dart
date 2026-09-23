import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:pagla_chat/widgets/room_settings_handler.dart';
import 'dart:ui';
import 'chat_screen.dart';
import 'screens/voice_room.dart';

class InboxPage extends StatefulWidget {
  final bool isSharingRoom;
  final String? roomId;
  final String? roomName;
  final String? roomImage;

  const InboxPage({
    super.key,
    this.isSharingRoom = false,
    this.roomId,
    this.roomName,
    this.roomImage,
  });

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String currentSixDigitId = "";

  @override
  void initState() {
    super.initState();
    print("DEBUG_LOG: InboxPage initState called.");
    _fetchMyDetails();
  }

  Future<void> _fetchMyDetails() async {
    try {
      print("DEBUG_LOG: Fetching my details from Firestore for authUID: $currentUserId");
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: currentUserId)
          .get();

      if (userDoc.docs.isNotEmpty) {
        setState(() {
          currentSixDigitId =
              userDoc.docs.first.data()['uID']?.toString() ?? "";
          print("DEBUG: Loaded my ID: $currentSixDigitId");
        });
      }
    } catch (e) {
      print("Error fetching my details: $e");
    }
  }

  void _markAsRead(String chatId) async {
    try {
      print("DEBUG_LOG: _markAsRead triggered for chatId: $chatId");
      String sixDigitId = chatId.split('_')[0];

      var unreadMessages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();
print("DEBUG_LOG: Found ${unreadMessages.docs.length} unread messages to mark as read in chatId: $chatId");
      for (var doc in unreadMessages.docs) {
        var data = doc.data();
        String dbReceiverId = (data['receiverId'] ?? "").toString();

        if (dbReceiverId == currentUserId || dbReceiverId == sixDigitId) {
          await doc.reference.update({'isRead': true});
        }
      }
    } catch (e) {
      print("Error marking as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildSearchBar(),
              Expanded(child: _buildUserList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: CachedNetworkImageProvider(
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/inboxbenar.jpg",
          ),
          fit: BoxFit.fill,
        ),
        border: Border.all(
          color: Colors.amber.shade700,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: const Color.fromARGB(104, 9, 43, 233)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                print("DEBUG_LOG: Search query changed to: $val");
                setState(() => _searchQuery = val.trim());
              },
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Search by Name or ID...",
                hintStyle: TextStyle(color: Color.fromARGB(245, 101, 196, 244)),
                prefixIcon: Icon(Icons.search, color: Colors.cyanAccent),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    print("DEBUG_LOG: _buildUserList called.");

    // যদি ছয় ডিজিটের uID না থাকে, তবে আগে তা লোকাল বা স্টেট থেকে নিশ্চিত করতে হবে
    if (currentSixDigitId.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.pinkAccent),
      );
    }

    // সরাসরি chats কালেকশন থেকে স্ট্রিম নেব, যেখানে আপনার uID যুক্ত আছে
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .orderBy('lastMessageTimestamp', descending: true)
          .snapshots(),
      builder: (context, chatSnapshot) {
        if (!chatSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.pinkAccent),
          );
        }

        var chatDocs = chatSnapshot.data!.docs;

        // যে সমস্ত চ্যাট ডকুমেন্টের আইডিতে বর্তমান ইউজারের ছয় ডিজিটের uID আছে বা অফিসিয়াল আইডি আছে, শুধু সেগুলো ফিল্টার করব
        var myChats = chatDocs.where((doc) {
          String chatId = doc.id; // যেমন: "219616_686008" বা অফিসিয়াল চ্যাট আইডি
          return chatId.contains(currentSixDigitId) || 
                 chatId.contains('paglachat_official') || 
                 chatId.contains('333444');
        }).toList();

        // ডুপ্লিকেট চ্যাট বা আইডি এভয়েড করার জন্য ইউনিক লিস্ট তৈরি করা (ডাবল চেক সহ)
        Set<String> seenUserIds = {};
        var uniqueChats = <QueryDocumentSnapshot>[];

        for (var chatDoc in myChats) {
          String chatId = chatDoc.id;
          
          // অফিসিয়াল চ্যাট আইডির জন্য ইউনিক কি নির্ধারণ
          bool isChatOfficial = chatId.contains('paglachat_official') || chatId.contains('333444');
          String uniqueIdentifier = "";

          if (isChatOfficial) {
            uniqueIdentifier = "paglachat_official"; // অফিসিয়ালের জন্য ফিক্সড ইউনিক কি যাতে ডাবল না আসে
          } else {
            List<String> ids = chatId.split('_');
            for (var id in ids) {
              if (id != currentSixDigitId) {
                uniqueIdentifier = id;
                break;
              }
            }
            if (uniqueIdentifier.isEmpty) {
              uniqueIdentifier = chatId.replaceAll(currentSixDigitId, "").replaceAll("_", "");
            }
          }

          // যদি এই আইডি বা অফিসিয়াল চ্যাট ইতিপূর্বে লিস্টে না যোগ হয়ে থাকে, তবেই নেব
          if (uniqueIdentifier.isNotEmpty && !seenUserIds.contains(uniqueIdentifier)) {
            seenUserIds.add(uniqueIdentifier);
            uniqueChats.add(chatDoc);
          }
        }

        if (uniqueChats.isEmpty) {
          return const Center(
            child: Text(
              "No chats found",
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          );
        }

        // অফিসিয়াল আইডি সবসময় সবার উপরে রাখার জন্য লিস্ট সর্ট করা
        uniqueChats.sort((a, b) {
          bool aIsOfficial = a.id.contains('paglachat_official') || a.id.contains('333444');
          bool bIsOfficial = b.id.contains('paglachat_official') || b.id.contains('333444');
          
          if (aIsOfficial && !bIsOfficial) return -1;
          if (!aIsOfficial && bIsOfficial) return 1;
          return 0;
        });

        return ListView.builder(
          itemCount: uniqueChats.length,
          padding: const EdgeInsets.all(10),
          itemBuilder: (context, index) {
            var chatDoc = uniqueChats[index];
            var chatData = chatDoc.data() as Map<String, dynamic>;
            String chatId = chatDoc.id;

            bool isChatOfficial = chatId.contains('paglachat_official') || chatId.contains('333444');
            String otherSixDigitId = "";

            if (isChatOfficial) {
              otherSixDigitId = "paglachat_official";
            } else {
              List<String> ids = chatId.split('_');
              for (var id in ids) {
                if (id != currentSixDigitId) {
                  otherSixDigitId = id;
                  break;
                }
              }
              if (otherSixDigitId.isEmpty) {
                otherSixDigitId = chatId.replaceAll(currentSixDigitId, "").replaceAll("_", "");
              }
            }

            // অন্য ইউজারের বা অফিসিয়াল প্রোফাইল ডাটা ফেচ করার জন্য FutureBuilder
            return FutureBuilder<QuerySnapshot>(
              future: isChatOfficial
                  ? FirebaseFirestore.instance
                      .collection('users')
                      .where('uID', isEqualTo: 'paglachat_official')
                      .limit(1)
                      .get()
                  : FirebaseFirestore.instance
                      .collection('users')
                      .where('uID', isEqualTo: otherSixDigitId)
                      .limit(1)
                      .get(),
              builder: (context, userSnapshot) {
                // যদি প্রথম কুয়েরিতে অফিসিয়াল আইডি না পাওয়া যায়, তবে numericID দিয়ে ব্যাকআপ চেক করব
                if ((!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) && isChatOfficial) {
                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .where('numericID', isEqualTo: '333444')
                        .limit(1)
                        .get(),
                    builder: (context, officialSnapshot) {
                      if (!officialSnapshot.hasData || officialSnapshot.data!.docs.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      var userDoc = officialSnapshot.data!.docs.first;
                      var userData = userDoc.data() as Map<String, dynamic>;
                      String userId = userDoc.id;

                      // সার্চ কুয়েরি ফিল্টার
                      String name = (userData['name'] ?? "").toString().toLowerCase();
                      String customId = (userData['uID'] ?? "").toString().toLowerCase();
                      if (_searchQuery.isNotEmpty) {
                        if (!name.contains(_searchQuery.toLowerCase()) &&
                            !customId.contains(_searchQuery.toLowerCase())) {
                          return const SizedBox.shrink();
                        }
                      }

                      return _buildGlassChatTile(userData, userId, chatId);
                    },
                  );
                }

                if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                var userDoc = userSnapshot.data!.docs.first;
                var userData = userDoc.data() as Map<String, dynamic>;
                String userId = userDoc.id; // authUID বা ডকুমেন্ট আইডি

                // অফিসিয়াল চেক 
                String friendSixDigitId = (userData['uID'] ?? "").toString();
                String numericIdVal = (userData['numericID'] ?? "").toString();
                bool isOfficial = friendSixDigitId == "paglachat_official" || 
                                  numericIdVal == "333444" || 
                                  userId == 'paglachat_official' ||
                                  isChatOfficial;

                // সার্চ কুয়েরি ফিল্টার (যদি ইউজার সার্চ বক্সে কিছু লিখে থাকে)
                String name = (userData['name'] ?? "").toString().toLowerCase();
                String customId = (userData['uID'] ?? "").toString().toLowerCase();
                if (_searchQuery.isNotEmpty && !isOfficial) {
                  if (!name.contains(_searchQuery.toLowerCase()) &&
                      !customId.contains(_searchQuery.toLowerCase())) {
                    return const SizedBox.shrink();
                  }
                }

                return _buildGlassChatTile(userData, userId, chatId);
              },
            );
          },
        );
      },
    );
  }
  Stream<List<Map<String, dynamic>>> _getSortedUserStream(
      List<QueryDocumentSnapshot> users) async* {
    
    String mySixDigitId = currentSixDigitId;
    if (mySixDigitId.isEmpty) {
      try {
        var myDoc = await FirebaseFirestore.instance
            .collection('users')
            .where('authUID', isEqualTo: currentUserId)
            .get();

        if (myDoc.docs.isNotEmpty) {
          mySixDigitId = (myDoc.docs.first.data()['uID'] ?? "").toString();
        }
      } catch (e) {
        print("Error fetching my uID: $e");
      }
    }

    List<Map<String, dynamic>> results = [];

    var futures = users.map((user) async {
      String userAuthId = user.id;
      var userData = user.data() as Map<String, dynamic>;
      String friendSixDigitId = (userData['uID'] ?? "").toString();

      bool isOfficial = friendSixDigitId == "paglachat_official" ||
          userAuthId == 'paglachat_official';

      String chatId;
      if (isOfficial) {
        chatId = "paglachat_official_$currentUserId";
      } else {
        if (mySixDigitId.isNotEmpty && friendSixDigitId.isNotEmpty) {
          List<String> ids = [mySixDigitId, friendSixDigitId];
          ids.sort();
          chatId = ids.join("_");
        } else {
          chatId = "unknown_$friendSixDigitId";
        }
      }

      var lastMsgQuery = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get()
          .catchError((e) {
            print("DEBUG_LOG_ERROR: Failed to fetch messages for chatId $chatId: $e");
            return null;
          });

      // যদি কোনো মেসেজ না থাকে এবং অফিসিয়াল না হয়:
      // কিন্তু যদি ইউজার সার্চ বক্স কিছু লিখে সার্চ করে, তবে তাকে বাদ দেওয়া যাবে না যাতে নতুন ইউজারের আইডি দিয়ে সার্চ করলে পাওয়া যায়।
      if ((lastMsgQuery == null || lastMsgQuery.docs.isEmpty) && !isOfficial) {
        if (_searchQuery.isEmpty) {
          return null;
        }
      }

      Timestamp lastTs = (lastMsgQuery != null && lastMsgQuery.docs.isNotEmpty)
          ? (lastMsgQuery.docs.first['timestamp'] as Timestamp? ??
              Timestamp.now())
          : Timestamp.fromMillisecondsSinceEpoch(0);

      return {
        'id': userAuthId,
        'data': userData,
        'chatId': chatId,
        'lastTs': lastTs,
        'isOfficial': isOfficial
      };
    });

    var resolvedResults = await Future.wait(futures);

    for (var res in resolvedResults) {
      if (res != null) {
        results.add(res);
      }
    }

    results.sort((a, b) {
      bool aOfficial = a['isOfficial'] == true;
      bool bOfficial = b['isOfficial'] == true;

      if (aOfficial && !bOfficial) return -1;
      if (!aOfficial && bOfficial) return 1;

      Timestamp aTime = a['lastTs'] as Timestamp;
      Timestamp bTime = b['lastTs'] as Timestamp;
      return bTime.compareTo(aTime);
    });

    yield results;
  }

  Widget _buildGlassChatTile(
      Map<String, dynamic> userData, String userId, String chatId) {
    bool isOfficial =
        userId == 'paglachat_official' || chatId.contains('paglachat_official');

    String displayId = isOfficial
        ? "paglachat_official"
        : (userData['uID'] ?? "N/A").toString();
    String name =
        isOfficial ? "👑𝐏𝐚𝐠𝐥𝐚𝐂𝐡𝐚𝐭𝐎𝐟𝐟𝐢𝐜𝐢𝐚𝐥⭐" : (userData['name'] ?? "User");
    String image = isOfficial
        ? "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/newframe/logo.png"
        : (userData['profilePic'] ?? "");

    String officialFrameUrl =
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/OFFICIALrose.webp";

    String? dbFrameUrl = isOfficial ? null : userData['activeFrameUrl'];
    String? jsonFrameUrl = userData['activeFrameUrl'];

    String effectiveFrameUrl = "";

    if (isOfficial) {
      effectiveFrameUrl = officialFrameUrl;
    } else if (dbFrameUrl != null && dbFrameUrl.isNotEmpty) {
      effectiveFrameUrl = dbFrameUrl;
    } else if (jsonFrameUrl != null && jsonFrameUrl.isNotEmpty) {
      effectiveFrameUrl = jsonFrameUrl;
    }

    String? currentRoomId = userData['currentRoomId'];
    bool isLive = currentRoomId != null && currentRoomId.toString().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: ListTile(
              onTap: () async {
                _markAsRead(chatId);

                // 🔥 নতুন রুম শেয়ারিং লজিক এখানে যুক্ত করা হলো
                if (widget.isSharingRoom && widget.roomId != null) {
                  // ১. ইনভাইটেশন মেসেজ পাঠিয়ে দেওয়া
                  await shareRoomInChat(
                    widget.roomId!,
                    userId,
                    widget.roomName ?? "My Room",
                    widget.roomImage ??
                        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/room_default.png",
                  );

                  // ২. সাকসেস মেসেজ দেখানো
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Room invitation sent!")),
                  );

                  // ৩. চ্যাট স্ক্রিনে নিয়ে যাওয়া
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        receiverId: userId,
                        receiverName: name,
                        receiverData: userData,
                      ),
                    ),
                  );
                } else {
                  // সাধারণ চ্যাটে যাওয়ার পূর্বের কোড
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        receiverId: userId,
                        receiverName: name,
                        receiverData: userData,
                      ),
                    ),
                  );
                }
              },
              leading: SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // ১. ইউজারের মূল গোল অবতার
                    CircleAvatar(
                      radius: 24,
                      backgroundImage:
                          image.isNotEmpty ? NetworkImage(image) : null,
                      backgroundColor: Colors.white10,
                      child: image.isEmpty
                          ? Text(name[0],
                              style: const TextStyle(color: Colors.white))
                          : null,
                    ),

                    // ২. ফ্রেম (যা একদম অবতারের বর্ডার বরাবর ফিট হবে)
                    if (effectiveFrameUrl.isNotEmpty)
                      Positioned(
                        top: -6, // অবতারের চারপাশ থেকে সমান দূরত্ব রাখার জন্য
                        left: -6,
                        right: -6,
                        bottom: -6,
                        child: effectiveFrameUrl.contains('.json')
                            ? SizedBox(
                                width: 60,
                                height: 60,
                                child: Lottie.network(
                                  effectiveFrameUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox.shrink(),
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: effectiveFrameUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.contain,
                                placeholder: (context, url) =>
                                    const SizedBox.shrink(),
                                errorWidget: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                      ),

                    // ৩. অনলাইন স্ট্যাটাস ডট
                    if (userData['isOnline'] == true)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          height: 12,
                          width: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                      ),

                    // ৪. লাইভ ব্যাজ
                    if (isLive)
                      Positioned(
                        bottom: -2,
                        child: GestureDetector(
                          onTap: () async {
                            var roomDoc = await FirebaseFirestore.instance
                                .collection('rooms')
                                .doc(currentRoomId)
                                .get();
                            if (!roomDoc.exists) return;

                            var data = roomDoc.data() as Map<String, dynamic>;
                            bool isLocked = data['isLocked'] ?? false;
                            String password = data['password'] ?? "";
                            String ownerId = data['ownerId'] ?? "";

                            String myUID =
                                FirebaseAuth.instance.currentUser?.uid ?? "";

                            if (isLocked && ownerId != myUID) {
                              RoomSettingsHandler.showJoinPasswordDialog(
                                  context, currentRoomId, password, () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            VoiceRoom(roomId: currentRoomId)));
                              });
                            } else {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          VoiceRoom(roomId: currentRoomId)));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E88E5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.sensors,
                                    color: Colors.white, size: 8),
                                SizedBox(width: 2),
                                Text("Live",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  if (userData['isVerified'] == true) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: Colors.blue, size: 14),
                  ],
                ],
              ),
              subtitle: Text("ID: $displayId",
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
              trailing: _buildUnreadCounter(chatId),
            ),
          ),
        ),
      ),
    );
  }

// ইনবক্সে রুম ইনভাইট পাঠানোর ফাংশনটি এখানে যুক্ত করে দিও
  Future<void> shareRoomInChat(String roomId, String targetUserId,
      String roomName, String roomImage) async {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    List<String> ids = [currentSixDigitId, targetUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    Map<String, dynamic> roomMessage = {
      'senderId': currentUserId,
      'senderuID': currentSixDigitId,
      'receiverId': targetUserId,
      'message': "Join my room: $roomName",
      'type': 'room_invite',
      'roomId': roomId,
      'roomName': roomName,
      'roomImage': roomImage,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(roomMessage);

    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
      'lastMessage': "Room Invitation: $roomName",
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'type': 'room_invite',
    }, SetOptions(merge: true));
  }

  Widget _buildUnreadCounter(String chatId) {
    if (currentSixDigitId.isEmpty) return const SizedBox.shrink();

    String finalChatId = chatId.trim();
    if (finalChatId.contains('paglachat_official')) {
      finalChatId = "paglachat_official_$currentSixDigitId";
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(finalChatId)
          .snapshots(includeMetadataChanges: true),
      builder: (context, docSnapshot) {
        if (!docSnapshot.hasData || docSnapshot.data?.data() == null) {
          return const SizedBox.shrink();
        }

        var data = docSnapshot.data!.data() as Map<String, dynamic>;

        String fieldName = "unReadCount_$currentSixDigitId";
        int finalCount = data[fieldName] ?? 0;

        if (finalCount > 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.pinkAccent,
                borderRadius: BorderRadius.circular(12)),
            child: Text("$finalCount",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          );
        }
        return const Icon(Icons.arrow_forward_ios,
            color: Colors.white10, size: 14);
      },
    );
  }
}
