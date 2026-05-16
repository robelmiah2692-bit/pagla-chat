import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  void _markAsRead(String chatId) async {
    try {
      // চ্যাট আইডি থেকে ৬ ডিজিটের আইডি আলাদা করে নেওয়া
      String sixDigitId = chatId.split('_')[0];

      // ১. ওই চ্যাটের সব আনরিড মেসেজ একবারেই টেনে আনা
      var unreadMessages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      // ২. লুপ চালিয়ে আইডি মিলিয়ে রিড হিসেবে মার্ক করা
      for (var doc in unreadMessages.docs) {
        var data = doc.data();
        String dbReceiverId = (data['receiverId'] ?? "").toString();

        // আইডি যেভাবে থাকুক—লম্বা বা ৬ ডিজিট—মিললে আপডেট হবে
        if (dbReceiverId == currentUserId || dbReceiverId == sixDigitId) {
          await doc.reference.update({'isRead': true});
        }
      }

      print("✅ মেসেজ ক্লিন সফল: $chatId");
    } catch (e) {
      debugPrint("❌ ক্লিন এরর: $e");
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Inbox",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          IconButton(
            icon: const Icon(Icons.notifications_active,
                color: Colors.pinkAccent),
            onPressed: () {},
          )
        ],
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
              border: Border.all(color: Colors.white10),
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
            if (!sortedSnapshot.hasData) return const SizedBox.shrink();
            final sortedList = sortedSnapshot.data!;

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
    // ১. আপনার নিজের ৬ ডিজিট আইডি (uID) নিশ্চিতভাবে খুঁজে বের করা
    String mySixDigitId = "";
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

    // ২. ইউজার লিস্ট প্রসেস করা
    List<Map<String, dynamic>> results =
        await Future.wait(users.map((user) async {
      String userAuthId = user.id;
      var userData = user.data() as Map<String, dynamic>;
      String friendSixDigitId = (userData['uID'] ?? "").toString();

      String chatId;
      if (friendSixDigitId == "paglachat_official") {
        chatId = "paglachat_official_$currentUserId";
      } else {
        // ৩. আইডি সর্ট করা যেন ভুল না হয় (যদি আপনার আইডি ফাঁকা না থাকে)
        if (mySixDigitId.isNotEmpty) {
          List<String> ids = [mySixDigitId, friendSixDigitId];
          ids.sort();
          chatId = ids.join("_");
        } else {
          // সেফটি হিসেবে পুরাতন লজিক বা একটা ডিফল্ট রাখা
          chatId = "unknown_$friendSixDigitId";
        }
      }

      // ৪. মেসেজ এবং টাইমেস্ট্যাম্প চেক
      var lastMsg = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      Timestamp lastTs = lastMsg.docs.isNotEmpty
          ? (lastMsg.docs.first['timestamp'] as Timestamp? ?? Timestamp.now())
          : Timestamp.fromMillisecondsSinceEpoch(0);

      return {
        'id': userAuthId,
        'data': userData,
        'chatId': chatId,
        'lastTs': lastTs
      };
    }));

    // ৫. সর্টিং করা
    results.sort((a, b) {
      final Map<String, dynamic> aData = a['data'] as Map<String, dynamic>;
      final Map<String, dynamic> bData = b['data'] as Map<String, dynamic>;
      if (aData['uID'] == "paglachat_official") return -1;
      if (bData['uID'] == "paglachat_official") return 1;
      return (b['lastTs'] as Timestamp).compareTo(a['lastTs'] as Timestamp);
    });

    yield results;
  }

  // --- নতুন ও পুরাতন ডিজাইনের মিশ্রণে আপডেট করা মেথড ---
  // --- নতুন ও পুরাতন ডিজাইনের মিশ্রণে আপডেট করা মেথড ---
  Widget _buildGlassChatTile(
      Map<String, dynamic> userData, String userId, String chatId) {
    // 🔥 ফিক্স ১: এটি অফিশিয়াল চ্যাট কি না তা নিখুঁতভাবে সনাক্ত করা
    bool isOfficial =
        userId == 'paglachat_official' || chatId.contains('paglachat_official');

    // 🔥 ফিক্স ২: অফিশিয়াল আইডি হলে হার্ডকোডেড নাম ও গিটহাবের প্রোফাইল পিকচার সেট করা
    // সাধারণ ইউজারদের জন্য আপনার আগের সিক্স ডিজিটের আইডি বা ডাটা যা ছিল হুবহু তাই থাকবে
    String displayId = isOfficial
        ? "paglachat_official"
        : (userData['uID'] ?? "N/A").toString();
    String name =
        isOfficial ? "PaglaChat Official" : (userData['name'] ?? "User");
    String image = isOfficial
        ? "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/favicon.png"
        : (userData['profilePic'] ?? "");

    String? frameUrl = isOfficial
        ? null
        : userData['activeFrame']; // অফিশিয়ালের ফ্রেম লাগবে না
    String? currentRoomId = userData['currentRoomId'];
    bool isLive = currentRoomId != null && currentRoomId.toString().isNotEmpty;

    // 🔥 ফিক্স ৩: চ্যাট আইডি কন্ডিশন (সাধারণ ইউজারদের ৬-ডিজিটের লজিক পুরোপুরি সুরক্ষিত)
    String finalChatId = chatId;
    if (isOfficial) {
      // অফিশিয়াল মেসেজ ক্লিনের লগের সাথে মিল রেখে লম্বা Auth UID (currentUserId) ব্যবহার করা হলো
      finalChatId = "paglachat_official_$currentUserId";
    } else {
      // সাধারণ ইউজার হলে ফায়ারবেস থেকে আসা অরিজিনাল সর্ট করা চ্যাট আইডি-ই থাকবে
      finalChatId = chatId;
    }

    // --- ডিবাগ প্রিন্ট শুরু ---
    print("--- Inbox User Check: $name ---");
    print("User ID in Database: $userId");
    print("Correct Chat ID used: $finalChatId");
    print("Current Room ID found: '$currentRoomId'");
    print("Is Live Status: $isLive");
    print("------------------------------------------");
    // --- ডিবাগ প্রিন্ট শেষ ---
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
                _markAsRead(chatId); // আপনার পুরাতন লজিক: ক্লিক করলে রিড হবে
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
                    // ১. প্রোফাইল পিকচার
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
                    // ২. ইউজার ফ্রেম (নতুন যোগ করা হয়েছে)
                    // ২. ইউজার ফ্রেম (বড় সাইজ কিন্তু নামের গ্যাপ বাড়াবে না)
                    if (frameUrl != null && frameUrl.isNotEmpty)
                      Positioned(
                        top: -35, // ফ্রেমের পজিশন অ্যাডজাস্ট করার জন্য
                        left: -35,
                        right: -35,
                        bottom: -35,
                        child: Image.network(
                          frameUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                    // ৩. অনলাইন স্ট্যাটাস (পুরাতন লজিক - সবুজ ডট)
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
                    // ৪. লাইভ বাটন (নতুন যোগ করা হয়েছে - বরতমান রুমে যাওয়ার জন্য)
                    if (isLive)
                      Positioned(
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      VoiceRoom(roomId: currentRoomId!),
                                ));
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
              // ৫. পুরাতন মেসেজ কাউন্টার লজিক (একই রাখা হয়েছে)
              trailing: _buildUnreadCounter(chatId),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadCounter(String chatId) {
    // ১. আগের অরিজিনাল চ্যাট আইডিটি যেভাবে আসছে সেভাবেই থাকবে
    String finalChatId = chatId.trim();
    bool isOfficial = finalChatId.contains('paglachat_official');

    // ২. শুধু অফিশিয়ালের জন্য সেফটি চেক (সাধারণ ইউজারদের লজিকে কোনো টাচ করবে না)
    if (isOfficial) {
      // 🎯 ফিক্স: লম্বা আইডির বদলে আপনার ৬-ডিজিটের আইডি ভেরিয়েবলটি ব্যবহার করা হলো
      finalChatId = "paglachat_official_$currentSixDigitId";
    }

    // মেইন স্ট্রিম: মেসেজেস সাব-কালেকশন থেকে আনরিড মেসেজ খোঁজা
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(finalChatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        int countFromMessages = 0;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          // মেসেজের ভেতর থেকে আনরিড কাউন্ট হিসাব
          var unreadDocs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String dbSenderId = (data['senderId'] ?? "").toString();

            // আপনি নিজে সেন্ডার না হলে কাউন্ট হবে
            return dbSenderId != currentUserId &&
                dbSenderId != currentSixDigitId;
          }).toList();

          countFromMessages = unreadDocs.length;
        }

        // ৩. ডাবল লেয়ার প্রোটেকশন (যদি মেসেজের ভেতর কাউন্ট না পায়, তবে মেইন ডকুমেন্ট চেক করবে)
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(finalChatId)
              .snapshots(),
          builder: (context, docSnapshot) {
            int countFromDoc = 0;

            if (docSnapshot.hasData && docSnapshot.data?.data() != null) {
              var data = docSnapshot.data!.data() as Map<String, dynamic>;
              // 🎯 স্ক্রিনশটের সেই 'unReadCount' ফিল্ডের ডেটা সরাসরি রিড করবে
              countFromDoc = data['unReadCount'] ?? 0;
            }

            // দুইটার মধ্যে যেটা বড় বা যেটায় ডেটা পাওয়া যাবে, সেটাই চূড়ান্ত কাউন্ট
            int finalCount = countFromMessages > countFromDoc
                ? countFromMessages
                : countFromDoc;

            // কাউন্ট যদি ০ থেকে বড় হয়, তবেই সুন্দর বাবল দেখাবে
            if (finalCount > 0) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.pinkAccent,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(
                  "$finalCount",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              );
            }

            // কোনো আনরিড মেসেজ না থাকলে সাধারণ ডানদিকের তীর (Arrow)
            return const Icon(Icons.arrow_forward_ios,
                color: Colors.white10, size: 14);
          },
        );
      },
    );
  }
}
