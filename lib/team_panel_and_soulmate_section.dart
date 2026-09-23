import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pagla_chat/team_panel_chat_room.dart';

class TeamPanelAndSoulmateSection extends StatefulWidget {
  final String uIDValue;

  const TeamPanelAndSoulmateSection({super.key, required this.uIDValue});

  @override
  State<TeamPanelAndSoulmateSection> createState() =>
      _TeamPanelAndSoulmateSectionState();
}

class _TeamPanelAndSoulmateSectionState
    extends State<TeamPanelAndSoulmateSection> {
  int _selectedTabIndex = 0; // 0 = Soulmates, 1 = Team Panel
  bool _isUploadingPic = false;

  // সঠিক ডকুমেন্ট আইডি খুঁজে পাওয়ার হেল্পার মেথড
  Future<String> _resolveUserDocId(String inputId) async {
    String trimmedId = inputId.trim();
    if (trimmedId.isEmpty) {
      trimmedId = FirebaseAuth.instance.currentUser?.uid ?? '';
    }

    var docCheck = await FirebaseFirestore.instance
        .collection('users')
        .doc(trimmedId)
        .get();
    if (docCheck.exists) {
      return trimmedId;
    }

    var queryByUid = await FirebaseFirestore.instance
        .collection('users')
        .where('uID', isEqualTo: trimmedId)
        .limit(1)
        .get();

    if (queryByUid.docs.isNotEmpty) {
      return queryByUid.docs.first.id;
    }

    var queryByOwner = await FirebaseFirestore.instance
        .collection('users')
        .where('ownerId', isEqualTo: trimmedId)
        .limit(1)
        .get();

    if (queryByOwner.docs.isNotEmpty) {
      return queryByOwner.docs.first.id;
    }

    return trimmedId;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _resolveUserDocId(widget.uIDValue),
      builder: (context, docIdSnapshot) {
        if (!docIdSnapshot.hasData) {
          return const Center(child: CircularIndicatorOrSizedBox());
        }

        String resolvedDocId = docIdSnapshot.data!;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(resolvedDocId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const SizedBox();
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;

            bool hasTeamPanel = userData.containsKey('teamPanel') &&
                userData['teamPanel'] != null;
            var teamPanelData = hasTeamPanel
                ? (userData['teamPanel'] as Map<String, dynamic>)
                : null;

            if (!hasTeamPanel && _selectedTabIndex == 1) {
              _selectedTabIndex = 0;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- হেডার সুইচিং বাটন ---
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _selectedTabIndex == 0
                                    ? [Colors.pinkAccent, Colors.purpleAccent]
                                    : [
                                        Colors.white.withOpacity(0.1),
                                        Colors.white.withOpacity(0.05)
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: _selectedTabIndex == 0
                                    ? Colors.pinkAccent
                                    : Colors.white24,
                                width: 1.2,
                              ),
                            ),
                            child: const Text(
                              "𝐇𝐚𝐫𝐭—̳͟͞͞💗(𝐒𝐨𝐮𝐥𝐦𝐚𝐭𝐞𝐬)",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      if (hasTeamPanel) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTabIndex = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _selectedTabIndex == 1
                                      ? [
                                          const Color(0xFFFFD700),
                                          Colors.deepOrangeAccent
                                        ]
                                      : [
                                          Colors.white.withOpacity(0.1),
                                          Colors.white.withOpacity(0.05)
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: _selectedTabIndex == 1
                                      ? const Color(0xFFFFD700)
                                      : Colors.white24,
                                  width: 1.2,
                                ),
                              ),
                              child: const Text(
                                "🛡️(𝐓𝐞𝐚𝐦 𝐏𝐚𝐧𝐞𝐥)",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 5),

                if (_selectedTabIndex == 1)
                  _buildTeamPanelSection(
                      resolvedDocId, teamPanelData, userData),

                const SizedBox(height: 5),
              ],
            );
          },
        );
      },
    );
  }

  // ✅ টিম প্যানেল মেইন সেকশন (সম্পূর্ণ ত্রুটিমুক্ত সংস্করণ ও লেভেল-এক্সপি যুক্ত)
  Widget _buildTeamPanelSection(String inputOwnerDocId,
      Map<String, dynamic>? teamPanelData, Map<String, dynamic> ownerUserData) {
    // ডাটাবেস বা প্যানেল ডাটা থেকে আসল ওনারের আইডি বা uID বের করে আনা (যাতে ভুল আইডি পাস হলেও সমস্যা না হয়)
    String realOwnerDocId = teamPanelData?['ownerDocId']?.toString() ??
        teamPanelData?['uID']?.toString() ??
        teamPanelData?['ownerId']?.toString() ??
        inputOwnerDocId;

    
    String myAuthUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    return FutureBuilder<DocumentSnapshot>(
      // সব সময় সঠিক realOwnerDocId দিয়ে ওনারের ডাটা ফেচ করা হবে
      future: _fetchOwnerData(realOwnerDocId),
      builder: (context, ownerSnapshot) {
        Map<String, dynamic> actualOwnerData = ownerUserData;
        if (ownerSnapshot.hasData && ownerSnapshot.data!.exists) {
          actualOwnerData = ownerSnapshot.data!.data() as Map<String, dynamic>;
        }

        String panelName = teamPanelData?['panelName'] ?? "My Team Panel";
        String panelPic = teamPanelData?['panelPic'] ?? '';

        if (panelPic.isEmpty) {
          panelPic = actualOwnerData['userImage'] ??
              actualOwnerData['profilePic'] ??
              '';
        }

        String panelOwnerUid =
            actualOwnerData['uID']?.toString() ?? realOwnerDocId;
        String ownerDocumentId =
            ownerSnapshot.hasData ? ownerSnapshot.data!.id : realOwnerDocId;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('team_panels')
              .doc(ownerDocumentId)
              .snapshots(),
          builder: (context, panelDocSnap) {
            var currentPanelData =
                panelDocSnap.data?.data() as Map<String, dynamic>? ??
                    teamPanelData ??
                    {};
            int totalXp = currentPanelData['teamXp'] ?? 0;

            int currentLevel = 0;
            int xpForNextLevel = 1000;
            int tempXp = totalXp;

// লজিক: লেভেল ১ এর জন্য ১০০০, এরপর প্রতি লেভেলে ৫০০ করে বাড়বে (যেমন: লেভেল ২ এর জন্য ১৫০০, লেভেল ৩ এর জন্য ২০০০ এভাবে)
            while (tempXp >= xpForNextLevel && currentLevel < 100) {
              tempXp -= xpForNextLevel;
              currentLevel++;
              xpForNextLevel +=
                  500; // প্রতি লেভেল পার হওয়ার পর পরবর্তী লেভেলের রিকোয়ারমেন্ট ৫০০ করে বাড়বে
            }

// সর্বোচ্চ লেভেল ১০০ পর্যন্ত সীমাবদ্ধ রাখা
            if (currentLevel > 100) {
              currentLevel = 100;
              currentLevel = 100;
            }

            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where('authUID', isEqualTo: myAuthUid)
                  .limit(1)
                  .get(),
              builder: (context, currentUserSnap) {
                String myUniqueUserId = myAuthUid;
                String currentUserDocId = '';
                String currentUidField = '';

                if (currentUserSnap.hasData &&
                    currentUserSnap.data!.docs.isNotEmpty) {
                  var currentUserDoc = currentUserSnap.data!.docs.first;
                  currentUserDocId = currentUserDoc.id;
                  var currentUserMap =
                      currentUserDoc.data() as Map<String, dynamic>;
                  currentUidField = currentUserMap['uID']?.toString() ?? '';
                  myUniqueUserId = currentUserDocId;
                }

                // সঠিক ওনারশিপ যাচাই শর্ত (এখানে মেম্বারের আইডি আর ওনারের আইডি কোনোভাবেই এক হবে না)
                bool isPanelOwner = (currentUserDocId == ownerDocumentId ||
                    currentUidField == panelOwnerUid ||
                    currentUidField == realOwnerDocId ||
                    myAuthUid == ownerDocumentId ||
                    myAuthUid == panelOwnerUid ||
                    myAuthUid == realOwnerDocId);

                

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                         
                          _openTeamPanelDetailsModal(
                              context,
                              ownerDocumentId,
                              panelName,
                              panelPic,
                              isPanelOwner,
                              actualOwnerData);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1F1C2C), Color(0xFF928DAB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFFFFD700), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.grey[800],
                                    backgroundImage: panelPic.isNotEmpty
                                        ? CachedNetworkImageProvider(panelPic) as ImageProvider
                                        : null,
                                    child: panelPic.isEmpty
                                        ? const Icon(Icons.person,
                                            color: Colors.white, size: 30)
                                        : null,
                                  ),
                                  if (_isUploadingPic)
                                    const Positioned.fill(
                                      child: CircularProgressIndicator(
                                          color: Colors.amber),
                                    ),
                                  if (isPanelOwner)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            
                                            _changePanelPicture(
                                                ownerDocumentId, teamPanelData);
                                          },
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: Colors.amber,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.camera_alt,
                                                size: 14, color: Colors.black),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            panelName,
                                            style: const TextStyle(
                                                color: Color(0xFFFFD700),
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        // মেইন কার্ডে লেভেল এবং এক্সপি ব্যাজ যোগ করা হলো
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Colors.amber,
                                                Colors.deepOrange
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.amber
                                                    .withOpacity(0.4),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              )
                                            ],
                                          ),
                                          child: Text(
                                            "Lvl $currentLevel • $totalXp XP",
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Owner: ${actualOwnerData['userName'] ?? actualOwnerData['name'] ?? 'Owner'}",
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "ID: ${actualOwnerData['uID'] ?? realOwnerDocId}",
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isPanelOwner)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: StreamBuilder<DocumentSnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('team_panels')
                                        .doc(ownerDocumentId)
                                        .collection('members')
                                        .doc(myUniqueUserId)
                                        .snapshots(),
                                    builder: (context, memberCheckSnap) {
                                      bool isAlreadyMember =
                                          memberCheckSnap.hasData &&
                                              memberCheckSnap.data!.exists;

                                      if (isAlreadyMember) {
                                        return const Text("Joined",
                                            style: TextStyle(
                                                color: Colors.greenAccent,
                                                fontWeight: FontWeight.bold));
                                      }

                                      return StreamBuilder<DocumentSnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('team_panels')
                                            .doc(ownerDocumentId)
                                            .collection('requests')
                                            .doc(myUniqueUserId)
                                            .snapshots(),
                                        builder: (context, reqSnap) {
                                          bool hasRequested = reqSnap.hasData &&
                                              reqSnap.data!.exists;

                                          return ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: hasRequested
                                                  ? Colors.grey
                                                  : Colors.amber,
                                            ),
                                            onPressed: hasRequested
                                                ? null
                                                : () {
                                                   
                                                    _sendJoinRequest(
                                                        ownerDocumentId,
                                                        myUniqueUserId);
                                                  },
                                            child: Text(
                                              hasRequested
                                                  ? "Requested"
                                                  : "Join Panel",
                                              style: const TextStyle(
                                                  color: Colors.black),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (isPanelOwner) ...[
                        const Text(
                          "⏳ Join Requests",
                          style: TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('team_panels')
                                .doc(ownerDocumentId)
                                .collection('requests')
                                .snapshots(),
                            builder: (context, reqSnapshot) {
                              if (!reqSnapshot.hasData ||
                                  reqSnapshot.data!.docs.isEmpty) {
                                return const Text("No pending requests.",
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 12));
                              }

                              var requests = reqSnapshot.data!.docs;
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: requests.length,
                                itemBuilder: (context, index) {
                                  var reqData = requests[index].data()
                                      as Map<String, dynamic>;
                                  String requesterDocId = requests[index].id;

                                  String uName = reqData['userName'] ?? 'User';
                                  String uPic = reqData['profilePic'] ?? '';

                                  return Container(
                                    width: 240,
                                    margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 25,
                                          backgroundImage: uPic.isNotEmpty
                                              ? CachedNetworkImageProvider(uPic) as ImageProvider
                                              : null,
                                          child: uPic.isEmpty
                                              ? const Icon(Icons.person,
                                                  color: Colors.white)
                                              : null,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                uName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(height: 15),
                                              Row(
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      _acceptRequest(
                                                          ownerDocumentId,
                                                          requesterDocId,
                                                          reqData);
                                                    },
                                                    child: const Icon(
                                                        Icons.check_circle,
                                                        color: Colors.green,
                                                        size: 28),
                                                  ),
                                                  const SizedBox(width: 20),
                                                  InkWell(
                                                    onTap: () {
                                                      _rejectRequest(
                                                          ownerDocumentId,
                                                          requesterDocId);
                                                    },
                                                    child: const Icon(
                                                        Icons.cancel,
                                                        color: Colors.red,
                                                        size: 28),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 15),
                      ]
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ওনারের সঠিক ডাটা ফেচ করার হেল্পার ফাংশন
  Future<DocumentSnapshot> _fetchOwnerData(String ownerDocId) async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerDocId)
          .get();
      if (doc.exists) {
        return doc;
      }

      var query = await FirebaseFirestore.instance
          .collection('users')
          .where('uID', isEqualTo: ownerDocId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first;
      }

      return doc;
    } catch (e) {
      print("Error fetching owner data: $e");
      rethrow;
    }
  }

  // 📂 কার্ডে ক্লিক করলে মডালে দুটি ট্যাব (যেখানে শুধু ওনার ও মেম্বাররা মেম্বার রুম দেখতে পাবে)
  void _openTeamPanelDetailsModal(
      BuildContext context,
      String ownerDocId,
      String panelName,
      String panelPic,
      bool isPanelOwner,
      Map<String, dynamic> ownerUserData) async {
    

    // বর্তমান ইউজার এই প্যানেলের মেম্বার কিনা বা ওনার কিনা চেক করা
    String currentAuthUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    String currentUserId = '';

    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentAuthUid)
          .get();
      if (userDoc.exists) {
        currentUserId = userDoc.id;
      } else {
        var query = await FirebaseFirestore.instance
            .collection('users')
            .where('authUID', isEqualTo: currentAuthUid)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          currentUserId = query.docs.first.id;
        }
      }
    } catch (e) {
      print("Error fetching current user ID: $e");
    }

    // মেম্বার লিস্ট চেক করা যে সে এই প্যানেলের মেম্বার কি না
    bool isTeamMember = isPanelOwner;
    if (!isTeamMember && currentUserId.isNotEmpty) {
      var memberCheck = await FirebaseFirestore.instance
          .collection('team_panels')
          .doc(ownerDocId)
          .collection('members')
          .where('uID', isEqualTo: currentUserId)
          .get();
      if (memberCheck.docs.isNotEmpty) {
        isTeamMember = true;
      }
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('team_panels')
              .doc(ownerDocId)
              .snapshots(),
          builder: (context, panelSnapshot) {
            var panelData =
                panelSnapshot.data?.data() as Map<String, dynamic>? ?? {};
            int totalXp = panelData['teamXp'] ?? 0;

            int currentLevel = 0;
            int xpForNextLevel = 1000;
            int tempXp = totalXp;

// লজিক: লেভেল ১ এর জন্য ১০০০, এরপর প্রতি লেভেলে ৫০০ করে বাড়বে (যেমন: লেভেল ২ এর জন্য ১৫০০, লেভেল ৩ এর জন্য ২০০০ এভাবে)
            while (tempXp >= xpForNextLevel && currentLevel < 100) {
              tempXp -= xpForNextLevel;
              currentLevel++;
              xpForNextLevel +=
                  500; // প্রতি লেভেল পার হওয়ার পর পরবর্তী লেভেলের রিকোয়ারমেন্ট ৫০০ করে বাড়বে
            }

// সর্বোচ্চ লেভেল ১০০ পর্যন্ত সীমাবদ্ধ রাখা
            if (currentLevel > 100) {
              currentLevel = 100;
              currentLevel = 100;
            }

            return DefaultTabController(
              length: isTeamMember ? 2 : 1,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1F1C2C),
                      Color(0xFF6B1153),
                      Color(0xFF1B2A4A),
                      Color(0xFF0F0C1B)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  border: Border(
                      top: BorderSide(color: Color(0xFFFFD700), width: 1.5)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // প্যানেল হেডার ইনফো এবং টিম লেভেল ব্যাজ
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: panelPic.isNotEmpty
                                ? CachedNetworkImageProvider(panelPic) as ImageProvider
                                : null,
                            child: panelPic.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(panelName,
                                    style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    Text("ID: $ownerDocId",
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11)),
                                    const SizedBox(width: 8),
                                    // সুন্দর মিক্স ডিজাইনের টিম লেভেল এবং এক্সপি উইজেট
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Colors.amber,
                                            Colors.deepOrange
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.amber.withOpacity(0.4),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                      ),
                                      child: Text(
                                        "Lvl $currentLevel • $totalXp XP",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    
                    const SizedBox(height: 15),
                    // ট্যাব বার (শুধু ওনার ও মেম্বার হলে দুটি ট্যাব দেখাবে)
                    TabBar(
                      indicatorColor: Colors.amber,
                      labelColor: Colors.amberAccent,
                      unselectedLabelColor: Colors.white60,
                      tabs: [
                        const Tab(
                            icon: Icon(Icons.group), text: "All Panel Members"),
                        if (isTeamMember)
                          const Tab(
                              icon: Icon(Icons.chat), text: "Member Room"),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    // ট্যাবের ভেতরের কন্টেন্ট
                    Expanded(
                      child: TabBarView(
                        children: [
                          // ট্যাব ১: অল প্যানেল মেম্বার লিস্ট ও তাদের தனிப்பட்ட XP
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('team_panels')
                                .doc(ownerDocId)
                                .collection('members')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.amber));
                              }
                              var members = snapshot.data!.docs;

                              List<Map<String, dynamic>> sortedMembers = [];
                              Map<String, dynamic>? ownerMemberData;

                              for (var doc in members) {
                                var mData = doc.data() as Map<String, dynamic>;
                                bool isOwner = mData['uID'] == ownerDocId;
                                if (isOwner) {
                                  ownerMemberData = mData;
                                } else {
                                  sortedMembers.add(mData);
                                }
                              }

                              ownerMemberData ??= {
                                'uID': ownerDocId,
                                'userName': ownerUserData['userName'] ??
                                    ownerUserData['name'] ??
                                    'Owner',
                                'profilePic': ownerUserData['userImage'] ??
                                    ownerUserData['profilePic'] ??
                                    '',
                                'frame': ownerUserData['activeFrameUrl'] ?? '',
                                'memberXp': 0,
                              };

                              sortedMembers.insert(0, ownerMemberData);

                              return ListView.builder(
                                itemCount: sortedMembers.length,
                                itemBuilder: (context, index) {
                                  var mData = sortedMembers[index];
                                  bool isThisOwner =
                                      index == 0 || mData['uID'] == ownerDocId;
                                  String profilePicUrl = mData['profilePic'] ??
                                      mData['userImage'] ??
                                      '';
                                  String frameUrl = mData['frame'] ?? '';
                                  int memberXp = mData['memberXp'] ?? 0;

                                  return ListTile(
                                    leading: SizedBox(
                                      width: 45,
                                      height: 45,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundImage: profilePicUrl
                                                    .isNotEmpty
                                                ? CachedNetworkImageProvider(profilePicUrl) as ImageProvider
                                                : null,
                                            child: profilePicUrl.isEmpty
                                                ? const Icon(Icons.person,
                                                    size: 20)
                                                : null,
                                          ),
                                          if (frameUrl.isNotEmpty)
                                            Positioned.fill(
                                              child: Image.network(frameUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      const SizedBox()),
                                            ),
                                        ],
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(mData['userName'] ?? 'Member',
                                            style: const TextStyle(
                                                color: Colors.white)),
                                        if (isThisOwner) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: Colors.amber,
                                                borderRadius:
                                                    BorderRadius.circular(4)),
                                            child: const Text("Owner",
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ]
                                      ],
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Text("ID: ${mData['uID']}",
                                            style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 11)),
                                        const SizedBox(width: 8),
                                        Text("XP: $memberXp",
                                            style: const TextStyle(
                                                color: Colors.amberAccent,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                    trailing: isPanelOwner && !isThisOwner
                                        ? IconButton(
                                            icon: const Icon(
                                                Icons.remove_circle,
                                                color: Colors.redAccent),
                                            onPressed: () {
                                              _removeMember(
                                                  ownerDocId, mData['uID']);
                                            },
                                          )
                                        : null,
                                  );
                                },
                              );
                            },
                          ),

                          // ট্যাব ২: মেম্বার রুম (গ্রুপ চ্যাট) - শুধু মেম্বার/ওনার দেখতে পাবে
                          if (isTeamMember)
                            TeamPanelChatRoom(
                                ownerDocId: ownerDocId, panelName: panelName),
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
  }

  // 🖼️ প্যানেল ছবি পরিবর্তন করার ফাংশন
  Future<void> _changePanelPicture(
      String ownerDocId, Map<String, dynamic>? currentTeamPanelData) async {
    
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
       
        return;
      }

      setState(() {
        _isUploadingPic = true;
      });

      File file = File(pickedFile.path);
      String fileName =
          'team_panels/${ownerDocId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      

      Map<String, dynamic> updatedTeamPanel = currentTeamPanelData != null
          ? Map<String, dynamic>.from(currentTeamPanelData)
          : {};
      updatedTeamPanel['panelPic'] = downloadUrl;

      await FirebaseFirestore.instance.collection('users').doc(ownerDocId).set({
        'teamPanel': updatedTeamPanel,
      }, SetOptions(merge: true));
      

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Panel picture updated successfully!")),
      );
    } catch (e) {
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update picture: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPic = false;
        });
      }
    }
  }

  void _sendJoinRequest(String panelOwnerDocId, String currentAuthUid) async {
   
    try {
      // ১. প্যানেল ওনারের সঠিক ডকুমেন্ট আইডি নিশ্চিত করা
      String resolvedOwnerId = panelOwnerDocId;
      var docCheck = await FirebaseFirestore.instance
          .collection('users')
          .doc(panelOwnerDocId)
          .get();

      if (!docCheck.exists) {
        var queryByUid = await FirebaseFirestore.instance
            .collection('users')
            .where('uID', isEqualTo: panelOwnerDocId)
            .limit(1)
            .get();
        if (queryByUid.docs.isNotEmpty) {
          resolvedOwnerId = queryByUid.docs.first.id;
        }
      }
      

      // ২. authUID দিয়ে users কালেকশন থেকে ইউজারের সঠিক ডকুমেন্ট খুঁজে বের করা
      String uniqueUserId = currentAuthUid;
      String userName = 'User';
      String profilePic = '';
      String activeFrame = '';

      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: currentAuthUid)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        var userDoc = userQuery.docs.first;
        var data = userDoc.data();

        uniqueUserId = userDoc.id;
        userName = data['name'] ?? data['userName'] ?? 'User';
        profilePic = data['profilePic'] ?? data['userImage'] ?? '';
        activeFrame = data['activeFrameUrl'] ?? data['activeFrame'] ?? '';
      } else {
        var directDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentAuthUid)
            .get();
        if (directDoc.exists && directDoc.data() != null) {
          var data = directDoc.data()!;
          uniqueUserId = directDoc.id;
          userName = data['name'] ?? data['userName'] ?? 'User';
          profilePic = data['profilePic'] ?? data['userImage'] ?? '';
          activeFrame = data['activeFrameUrl'] ?? data['activeFrame'] ?? '';
        }
      }

     

      // 🛑 ৩. নতুন চেক: ইউজার ইতিমধ্যে অন্য কোনো প্যানেলের ওনার বা মেম্বার কি না তা যাচাই করা

      // ক. চেক করা সে নিজেই কোনো প্যানেলের ওনার কিনা
      var ownedPanelCheck = await FirebaseFirestore.instance
          .collection('team_panels')
          .doc(uniqueUserId)
          .get();

      if (ownedPanelCheck.exists) {
        if (!mounted) return;
        _showAlreadyHasTeamDialog(
            "You already have your own team panel. You cannot join another panel.");
        return;
      }

      // খ. চেক করা সে অন্য কোনো প্যানেলের মেম্বার হিসেবে যুক্ত আছে কিনা
      var allPanels =
          await FirebaseFirestore.instance.collection('team_panels').get();
      for (var panelDoc in allPanels.docs) {
        var memberDoc = await FirebaseFirestore.instance
            .collection('team_panels')
            .doc(panelDoc.id)
            .collection('members')
            .doc(uniqueUserId)
            .get();

        if (memberDoc.exists) {
          if (!mounted) return;
          _showAlreadyHasTeamDialog(
              "You are already a member of another team panel!");
          return;
        }
      }

      // ৪. টিম প্যানেলের মূল ডকুমেন্টটি ডাটাবেজে এক্সিস্ট করে কি না নিশ্চিত করা
      await FirebaseFirestore.instance
          .collection('team_panels')
          .doc(resolvedOwnerId)
          .set({
        'ownerId': resolvedOwnerId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ৫. requests কালেকশনে ইউজারের ইউনিক আইডি দিয়ে সঠিক ডাটা সেভ করা
      await FirebaseFirestore.instance
          .collection('team_panels')
          .doc(resolvedOwnerId)
          .collection('requests')
          .doc(uniqueUserId)
          .set({
        'uID': uniqueUserId,
        'authUid': currentAuthUid,
        'userName': userName,
        'profilePic': profilePic,
        'frame': activeFrame,
        'timestamp': FieldValue.serverTimestamp(),
      });

      

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Join request sent to panel owner!")),
      );
    } catch (e) {
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send request: $e")),
      );
    }
  }

  // পপ-আপ দেখানোর জন্য ছোট্ট হেল্পার ফাংশন
  void _showAlreadyHasTeamDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1C2C),
        title:
            const Text("Notice", style: TextStyle(color: Colors.amberAccent)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  void _acceptRequest(String ownerDocId, String requesterUid,
      Map<String, dynamic> uInfo) async {
    
    // প্যানেলের আসল মালিকের সঠিক authUID এবং ডকুমেন্ট ডাটা বের করার জন্য users কালেকশন চেক করা
    DocumentSnapshot ownerUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(ownerDocId)
        .get();

    String correctOwnerAuthId = ownerDocId;
    String ownerName = "Owner";
    String panelName = "Team Panel";
    String panelPic = "";

    if (ownerUserDoc.exists) {
      var ownerData = ownerUserDoc.data() as Map<String, dynamic>?;
      if (ownerData != null) {
        correctOwnerAuthId = ownerData['authUID'] ?? ownerDocId;
        ownerName = ownerData['name'] ?? ownerData['userName'] ?? 'Owner';
        if (ownerData.containsKey('teamPanel')) {
          var tPanel = ownerData['teamPanel'] as Map<String, dynamic>?;
          if (tPanel != null) {
            panelName = tPanel['panelName'] ?? panelName;
            panelPic = tPanel['panelPic'] ?? panelPic;
          }
        }
      }
    }

    // ১. প্যানেলের members কালেকশনে মেম্বার অ্যাড করা (সঠিক আইডি ম্যাপ করে)
    await FirebaseFirestore.instance
        .collection('team_panels')
        .doc(ownerDocId)
        .collection('members')
        .doc(requesterUid)
        .set({
      'uID': requesterUid,
      'ownerDocId': ownerDocId,
      'ownerId': correctOwnerAuthId,
      'userName': uInfo['userName'] ?? 'Member',
      'profilePic': uInfo['userImage'] ?? uInfo['profilePic'] ?? '',
      'frame': uInfo['activeFrameUrl'] ?? '',
      'isOwner': false, // স্পষ্টভাবে মার্ক করা হলো যে এই মেম্বারটি মালিক নয়
      'joinedAt': FieldValue.serverTimestamp(),
    });

    // ২. রিকোয়েস্ট ডিলিট করা
    await FirebaseFirestore.instance
        .collection('team_panels')
        .doc(ownerDocId)
        .collection('requests')
        .doc(requesterUid)
        .delete();

    // ৩. মেম্বারের `users` ডকুমেন্টে প্যানেল ডাটা সেভ করা (আপনার স্ক্রিনশটের ফিল্ড স্ট্রাকচার অনুযায়ী)
    await FirebaseFirestore.instance
        .collection('users')
        .doc(requesterUid)
        .update({
      'teamPanel': {
        'panelName': panelName,
        'panelPic': panelPic,
        'ownerId': correctOwnerAuthId, // ফায়ারবেস Auth UID
        'ownerDocId': ownerDocId, // প্যানেল ওনারের ডকুমেন্ট আইডি
        'uID': ownerDocId, // ইউনিক আইডি (যেমন: 454488)
        'Owner': ownerName,
        'Panel ID': ownerDocId,
        'isOwner':
            false, // মেম্বারের প্রোফাইলে সে মালিক নয় তা পরিষ্কারভাবে মার্ক করা হলো
      }
    });

    
  }

  void _rejectRequest(String ownerId, String requesterUid) async {
    
    await FirebaseFirestore.instance
        .collection('team_panels')
        .doc(ownerId)
        .collection('requests')
        .doc(requesterUid)
        .delete();
    
  }

  void _removeMember(String ownerId, String memberUid) async {
    

    // ১. প্যানেলের members থেকে মেম্বার ডিলিট করা
    await FirebaseFirestore.instance
        .collection('team_panels')
        .doc(ownerId)
        .collection('members')
        .doc(memberUid)
        .delete();

    // ২. মেম্বারের প্রফাইল থেকে টিম প্যানেল ডাটা সম্পূর্ণ মুছে ফেলা
    await FirebaseFirestore.instance.collection('users').doc(memberUid).update({
      'teamPanel': FieldValue.delete(),
    });

    
  }
}

class ContainerIconWrapper extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double? size; // ১. সাইজ প্রপার্টি ডিক্লেয়ার করা হলো

  const ContainerIconWrapper({
    super.key,
    required this.icon,
    required this.color,
    this.size, // ২. কন্সট্রাক্টরে যুক্ত করা হলো (চাইলে required this.size ও দিতে পারেন)
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon,
          color: color, size: size ?? 24), // ৩. এখানে আর লাল দাগ আসবে না
    );
  }
}

class ContainerTag extends StatelessWidget {
  final String text;
  final Color color;

  const ContainerTag({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class CircularIndicatorOrSizedBox extends StatelessWidget {
  const CircularIndicatorOrSizedBox({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator(
      color: Colors.pinkAccent,
    );
  }
}
