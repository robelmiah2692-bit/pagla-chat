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
  const InboxPage({super.key});
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
    _fetchMyDetails();
  }

  Future<void> _fetchMyDetails() async {
    try {
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
      String sixDigitId = chatId.split('_')[0];

      var unreadMessages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

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
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent));
        }

        var users = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String userAuthUID = data['authUID'] ?? "";
          bool isNotMe = userAuthUID != currentUserId;
          String name = (data['name'] ?? "").toString().toLowerCase();
          String customId = (data['uID'] ?? "").toString().toLowerCase();
          bool matchesSearch = name.contains(_searchQuery.toLowerCase()) ||
              customId.contains(_searchQuery.toLowerCase());

          return isNotMe && matchesSearch;
        }).toList();

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getSortedUserStream(users),
          builder: (context, sortedSnapshot) {
            if (!sortedSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              );
            }
            final sortedList = sortedSnapshot.data!;

            if (sortedList.isEmpty) {
              return const Center(
                child: Text(
                  "No chats found",
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              );
            }

            return ListView.builder(
              itemCount: sortedList.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (context, index) {
                var userData =
                    sortedList[index]['data'] as Map<String, dynamic>;
                String userId = sortedList[index]['id'];
                String chatId = sortedList[index]['chatId'];

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
          .catchError((e) => null);

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
        isOfficial ? "PaglaChat Official" : (userData['name'] ?? "User");
    String image = isOfficial
        ? "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/favicon.png"
        : (userData['profilePic'] ?? "");

    String officialFrameUrl =
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/officialframe.png";

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
              onTap: () {
                _markAsRead(chatId);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                          receiverId: userId,
                          receiverName: name,
                          receiverData: userData),
                    ));
              },
              leading: SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
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
                    if (effectiveFrameUrl.isNotEmpty)
                      Positioned(
                        top: -35,
                        left: -35,
                        right: -35,
                        bottom: -35,
                        child: effectiveFrameUrl.contains('.json')
                            ? SizedBox(
                                width: 70,
                                height: 70,
                                child: Lottie.network(
                                  effectiveFrameUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox.shrink(),
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: effectiveFrameUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.contain,
                                placeholder: (context, url) =>
                                    const SizedBox.shrink(),
                                errorWidget: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                      ),
                    if (userData['isOnline'] == true)
                      Positioned(
                        bottom: 8,
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
                    if (isLive)
                      Positioned(
                        bottom: 0,
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
