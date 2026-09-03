import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

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
                const SizedBox(height: 10),

                if (_selectedTabIndex == 1)
                  _buildTeamPanelSection(
                      resolvedDocId, teamPanelData, userData),

                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }

  // ✅ টিম প্যানেল মেইন সেকশন
  Widget _buildTeamPanelSection(String ownerDocId,
      Map<String, dynamic>? teamPanelData, Map<String, dynamic> ownerUserData) {
    String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    String panelName = teamPanelData?['panelName'] ?? "My Team Panel";
    String panelPic = teamPanelData?['panelPic'] ?? '';

    if (panelPic.isEmpty) {
      panelPic =
          ownerUserData['userImage'] ?? ownerUserData['profilePic'] ?? '';
    }

    String panelOwnerIdFromDb = teamPanelData?['ownerId']?.toString() ??
        teamPanelData?['uID']?.toString() ??
        ownerUserData['uID']?.toString() ??
        ownerDocId;

    // নিখুঁতভাবে ওনার চেক করা
    bool isPanelOwner = (myUid.isNotEmpty &&
        (panelOwnerIdFromDb == myUid ||
            ownerDocId == myUid ||
            ownerUserData['uID'] == myUid ||
            ownerUserData['ownerId'] == myUid));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // কার্ডে ক্লিক করলে মেম্বার ট্যাব বা ডিটেইলস ওপেন হওয়ার জন্য GestureDetector
          GestureDetector(
            onTap: () {
              _openTeamPanelDetailsModal(context, ownerDocId, panelName,
                  panelPic, isPanelOwner, ownerUserData);
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
                border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
              ),
              child: Row(
                children: [
                  // টিম প্যানেলের ছবি এবং ক্যামেরা আইকন অংশ
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[800],
                        backgroundImage:
                            panelPic.isNotEmpty ? NetworkImage(panelPic) : null,
                        child: panelPic.isEmpty
                            ? const Icon(Icons.person,
                                color: Colors.white, size: 30)
                            : null,
                      ),
                      if (_isUploadingPic)
                        const Positioned.fill(
                          child: CircularProgressIndicator(color: Colors.amber),
                        ),
                      if (isPanelOwner)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _changePanelPicture(
                                  ownerDocId, teamPanelData),
                              borderRadius: BorderRadius.circular(12),
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
                        Text(
                          panelName,
                          style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Owner: ${ownerUserData['userName'] ?? ownerUserData['name'] ?? 'Owner'}",
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "ID: $ownerDocId",
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // ওনার হলে জয়েন বাটন দেখাবে না
                  if (!isPanelOwner)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('team_panels')
                          .doc(ownerDocId)
                          .collection('members')
                          .doc(myUid)
                          .snapshots(),
                      builder: (context, memberCheckSnap) {
                        bool isAlreadyMember = memberCheckSnap.hasData &&
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
                              .doc(ownerDocId)
                              .collection('requests')
                              .doc(myUid)
                              .snapshots(),
                          builder: (context, reqSnap) {
                            bool hasRequested =
                                reqSnap.hasData && reqSnap.data!.exists;

                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    hasRequested ? Colors.grey : Colors.amber,
                              ),
                              onPressed: hasRequested
                                  ? null
                                  : () => _sendJoinRequest(ownerDocId, myUid),
                              child: Text(
                                hasRequested ? "Requested" : "Join Panel",
                                style: const TextStyle(color: Colors.black),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),

          // যদি আপনি ওনার হন, তবেই রিকোয়েস্ট লিস্ট দেখাবে
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
              height: 90,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('team_panels')
                    .doc(ownerDocId)
                    .collection('requests')
                    .snapshots(),
                builder: (context, reqSnapshot) {
                  if (!reqSnapshot.hasData || reqSnapshot.data!.docs.isEmpty) {
                    return const Text("No pending requests.",
                        style: TextStyle(color: Colors.white54, fontSize: 12));
                  }

                  var requests = reqSnapshot.data!.docs;

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      var reqData =
                          requests[index].data() as Map<String, dynamic>;
                      String requesterUid =
                          reqData['uID'] ?? requests[index].id;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(requesterUid)
                            .get(),
                        builder: (context, userSnap) {
                          if (!userSnap.hasData || !userSnap.data!.exists)
                            return const SizedBox();
                          var uInfo =
                              userSnap.data!.data() as Map<String, dynamic>;

                          return Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(
                                      uInfo['userImage'] ??
                                          uInfo['profilePic'] ??
                                          ''),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(uInfo['userName'] ?? 'User',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12)),
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () => _acceptRequest(
                                              ownerDocId, requesterUid, uInfo),
                                          child: const Icon(Icons.check_circle,
                                              color: Colors.green, size: 22),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _rejectRequest(
                                              ownerDocId, requesterUid),
                                          child: const Icon(Icons.cancel,
                                              color: Colors.red, size: 22),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 15),
          ],
        ],
      ),
    );
  }

  // 📂 কার্ডে ক্লিক করলে মডালে সবার উপরে ওনার সহ মেম্বার লিস্ট দেখানোর ফাংশন
  void _openTeamPanelDetailsModal(
      BuildContext context,
      String ownerDocId,
      String panelName,
      String panelPic,
      bool isPanelOwner,
      Map<String, dynamic> ownerUserData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage:
                            panelPic.isNotEmpty ? NetworkImage(panelPic) : null,
                        child:
                            panelPic.isEmpty ? const Icon(Icons.person) : null,
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
                            Text("Panel ID: $ownerDocId",
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 30),
                  const Text("🛡️ All Panel Members",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('team_panels')
                          .doc(ownerDocId)
                          .collection('members')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        var members = snapshot.data!.docs;

                        // ওনারকে প্রথমে রাখার জন্য লিস্ট ফিল্টার ও সাজিয়ে নেওয়া
                        List<Map<String, dynamic>> sortedMembers = [];
                        Map<String, dynamic>? ownerMemberData;

                        for (var doc in members) {
                          var mData = doc.data() as Map<String, dynamic>;
                          bool isOwner = mData['uID'] == ownerDocId ||
                              mData['uID'] == widget.uIDValue;
                          if (isOwner) {
                            ownerMemberData = mData;
                          } else {
                            sortedMembers.add(mData);
                          }
                        }

                        // যদি মেম্বার লিস্টে ওনারের ডাটা না থাকে, তবে ওনারের ইউজার ডাটা থেকে তৈরি করে নেব
                        ownerMemberData ??= {
                          'uID': ownerDocId,
                          'userName': ownerUserData['userName'] ??
                              ownerUserData['name'] ??
                              'Owner',
                          'profilePic': ownerUserData['userImage'] ??
                              ownerUserData['profilePic'] ??
                              '',
                          'frame': ownerUserData['activeFrameUrl'] ?? '',
                        };

                        // সবার উপরে ওনারকে যুক্ত করা
                        sortedMembers.insert(0, ownerMemberData);

                        if (sortedMembers.isEmpty) {
                          return const Center(
                              child: Text("No members found in this panel.",
                                  style: TextStyle(color: Colors.white54)));
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: sortedMembers.length,
                          itemBuilder: (context, index) {
                            var mData = sortedMembers[index];
                            bool isThisOwner =
                                index == 0 || mData['uID'] == ownerDocId;

                            String profilePicUrl =
                                mData['profilePic'] ?? mData['userImage'] ?? '';
                            String frameUrl = mData['frame'] ?? '';

                            return ListTile(
                              // স্ট্যাক ব্যবহার করে প্রোফাইল পিকচার এবং ফ্রেম একসাথে সেট করা হলো যাতে ফ্রেম বাইরে না গিয়ে পিকচারের উপরে বসে
                              leading: SizedBox(
                                width: 45,
                                height: 45,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: profilePicUrl.isNotEmpty
                                          ? NetworkImage(profilePicUrl)
                                          : null,
                                      child: profilePicUrl.isEmpty
                                          ? const Icon(Icons.person, size: 20)
                                          : null,
                                    ),
                                    if (frameUrl.isNotEmpty)
                                      Positioned.fill(
                                        child: Image.network(
                                          frameUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const SizedBox(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(mData['userName'] ?? 'Member',
                                      style:
                                          const TextStyle(color: Colors.white)),
                                  if (isThisOwner) ...[
                                    const SizedBox(width: 6),
                                    const ContainerTag(
                                        text: "Owner", color: Colors.amber),
                                  ]
                                ],
                              ),
                              subtitle: Text("ID: ${mData['uID']}",
                                  style:
                                      const TextStyle(color: Colors.white60)),
                              trailing: isPanelOwner && !isThisOwner
                                  ? IconButton(
                                      icon: const Icon(Icons.remove_circle,
                                          color: Colors.redAccent),
                                      onPressed: () => _removeMember(
                                          ownerDocId, mData['uID']),
                                    )
                                  : null,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
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

      if (pickedFile == null) return;

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
    // ১. সঠিক প্যানেল ওনার আইডি বের করে নেওয়া
    var docCheck = await FirebaseFirestore.instance
        .collection('users')
        .doc(panelOwnerDocId)
        .get();

    String resolvedOwnerId = panelOwnerDocId;
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

    // ২. বর্তমান ইউজারের সঠিক কাস্টম ৬ ডিজিটের আইডি বের করা
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentAuthUid)
        .get();

    String customUserId = currentAuthUid;

    if (userDoc.exists && userDoc.data() != null) {
      var userData = userDoc.data()!;
      customUserId = userData['uID']?.toString() ?? 
                     userData['customId']?.toString() ?? 
                     currentAuthUid;
      
      if (currentAuthUid.length < 15 && !currentAuthUid.contains('Z')) {
        customUserId = currentAuthUid;
      }
    } else {
      var userQueryByUid = await FirebaseFirestore.instance
          .collection('users')
          .where('uID', isEqualTo: currentAuthUid)
          .limit(1)
          .get();

      if (userQueryByUid.docs.isNotEmpty) {
        var docData = userQueryByUid.docs.first.data();
        // এখানে ঠিক করে userQueryByUid.docs.first.id দেওয়া হয়েছে
        customUserId = docData['uID']?.toString() ?? userQueryByUid.docs.first.id;
      } else {
        var queryByAuth = await FirebaseFirestore.instance
            .collection('users')
            .where('authUid', isEqualTo: currentAuthUid)
            .limit(1)
            .get();
        if (queryByAuth.docs.isNotEmpty) {
          var authData = queryByAuth.docs.first.data();
          customUserId = authData['uID']?.toString() ?? queryByAuth.docs.first.id;
        }
      }
    }

    // ৩. ফায়ারবেসে রিকোয়েস্ট সাবমিট করা
    await FirebaseFirestore.instance
        .collection('team_panels')
        .doc(resolvedOwnerId)
        .collection('requests')
        .doc(customUserId)
        .set({
      'uID': customUserId,
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

  void _acceptRequest(
      String ownerId, String requesterUid, Map<String, dynamic> uInfo) async {
    await FirebaseFirestore.instance
        .collection('team_panels')
        .doc(ownerId)
        .collection('members')
        .doc(requesterUid)
        .set({
      'uID': requesterUid,
      'userName': uInfo['userName'] ?? 'Member',
      'profilePic': uInfo['userImage'] ?? uInfo['profilePic'] ?? '',
      'frame': uInfo['activeFrameUrl'] ?? '',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('team_panels')
        .doc(ownerId)
        .collection('requests')
        .doc(requesterUid)
        .delete();
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
    await FirebaseFirestore.instance
        .collection('team_panels')
        .doc(ownerId)
        .collection('members')
        .doc(memberUid)
        .delete();
  }
}

class ContainerTag extends StatelessWidget {
  final String text;
  final Color color;
  const ContainerTag({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class CircularIndicatorOrSizedBox extends StatelessWidget {
  const CircularIndicatorOrSizedBox({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: Colors.amber));
  }
}
