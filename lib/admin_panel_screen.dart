import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanelScreen extends StatefulWidget {
  final String myUid;
  const AdminPanelScreen({super.key, required this.myUid});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _broadcastController = TextEditingController();
  
  DocumentSnapshot? _searchedUser;
  bool _isLoading = false;
  late TabController _tabController;

  // 🛡️ স্পেশাল মালিকের আইডি দুটি এখানে ডিফাইন করা হলো
  final List<String> specialOwnerIds = ['444333', '444222'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _broadcastController.dispose();
    super.dispose();
  }

  // Search user by UID or Username
  void _searchUser(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      var result = await FirebaseFirestore.instance
          .collection('users')
          .where('uID', isEqualTo: query)
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        setState(() => _searchedUser = result.docs.first);
      } else {
        var docResult = await FirebaseFirestore.instance.collection('users').doc(query).get();
        if (docResult.exists) {
          setState(() => _searchedUser = docResult);
        } else {
          setState(() => _searchedUser = null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User not found!"))
          );
        }
      }
    } catch (e) {
      // Error handling without print
    }
    setState(() => _isLoading = false);
  }

  // 🛡️ ইউএফ ফিল্ড আপডেট করার সময় মালিকের আইডি প্রটেকশন চেক
  void _updateUserField(String targetDocId, Map<String, dynamic> updates, {String? targetUid}) async {
    // যদি টার্গেট ইউজার স্পেশাল আইডিগুলোর একটি হয়
    if (targetUid != null && specialOwnerIds.contains(targetUid)) {
      // যদি ব্লক বা জেন্ডার বা ট্যাগ রিমুভ করার চেষ্টা করা হয়
      bool isTryingToBlock = updates.containsKey('isBlocked') && updates['isBlocked'] == true;
      bool isTryingToDeviceBlock = updates.containsKey('isDeviceBlocked') && updates['isDeviceBlocked'] == true;
      
      if (isTryingToBlock || isTryingToDeviceBlock) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Warning: This is the Owner's ID! Cannot block or modify restrictions."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(targetDocId).update(updates);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Successfully updated!"))
      );
      _searchUser(_searchController.text.trim()); // Refresh data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error occurred: $e"))
      );
    }
  }

  // Block for 24 hours
  void _blockFor24Hours(String targetDocId, String targetUid) {
    if (specialOwnerIds.contains(targetUid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Warning: This is the Owner's ID! Cannot block."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    DateTime unblockTime = DateTime.now().add(const Duration(hours: 24));
    _updateUserField(targetDocId, {
      'isBlocked': true,
      'blockedUntil': Timestamp.fromDate(unblockTime),
    }, targetUid: targetUid);
  }

  // One-click Device Block
  void _blockDevice(String targetDocId, String targetUid) {
    if (specialOwnerIds.contains(targetUid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Warning: This is the Owner's ID! Cannot block device."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    _updateUserField(targetDocId, {
      'isDeviceBlocked': true,
      'isBlocked': true,
    }, targetUid: targetUid);
  }

  // Send Broadcast Message from official account
  void _sendBroadcastMessage(String message) async {
    if (message.isEmpty) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
    );

    try {
      var officialUserQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('uID', isEqualTo: 'paglachat_official')
          .limit(1)
          .get();

      String officialUid = 'paglachat_official'; 
      String officialName = 'PaglaChat Official';
      String officialEmail = 'official@paglachat.com';
      String officialImage = '';
      String officialNumericId = '333444';

      if (officialUserQuery.docs.isNotEmpty) {
        var docSnap = officialUserQuery.docs.first;
        var officialData = docSnap.data();
        officialUid = docSnap.id; 
        officialName = officialData['name'] ?? 'PaglaChat Official';
        officialEmail = officialData['email'] ?? '';
        officialImage = officialData['profilePic'] ?? officialData['image'] ?? '';
        officialNumericId = officialData['numericID']?.toString() ?? '333444';
      } else {
        var directDoc = await FirebaseFirestore.instance.collection('users').doc('paglachat_official').get();
        if (directDoc.exists) {
          var directData = directDoc.data();
          officialUid = directDoc.id;
          officialName = directData?['name'] ?? 'PaglaChat Official';
          officialEmail = directData?['email'] ?? '';
          officialImage = directData?['profilePic'] ?? directData?['image'] ?? '';
          officialNumericId = directData?['numericID']?.toString() ?? '333444';
        }
      }

      var allUsers = await FirebaseFirestore.instance.collection('users').get();
      
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var doc in allUsers.docs) {
        String targetUserId = doc.id; 
        String targetUserUid = doc.data()['uID']?.toString() ?? '';
        
        if (targetUserId == officialUid || targetUserUid == 'paglachat_official') continue;

        String chatRoomId = "paglachat_official_$targetUserId";

        var chatRoomRef = FirebaseFirestore.instance.collection('chats').doc(chatRoomId);
        var messageRef = chatRoomRef.collection('messages').doc();

        batch.set(chatRoomRef, {
          'lastMessage': message,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'unReadCount_$targetUserId': FieldValue.increment(1),
          'unReadCount_$officialUid': 0,
          'participants': [officialUid, targetUserId],
          'uIDs': [officialNumericId, doc.data()['numericID']?.toString() ?? ''],
          'senderId': officialUid,
          'receiverId': targetUserId,
        }, SetOptions(merge: true));

        batch.set(messageRef, {
          'message': message,
          'senderId': officialUid,
          'senderUid': officialUid,
          'senderNumericId': officialNumericId,
          'senderName': officialName,
          'senderEmail': officialEmail,
          'senderImage': officialImage,
          'receiverId': targetUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'text',
          'isRead': false,
        });
      }

      await batch.commit();
      Navigator.pop(context);
      _broadcastController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Official Broadcast message sent to all chats successfully!"))
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Broadcast Error: $e"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F0529), 
            Color(0xFF2A0845), 
            Color(0xFF151B54), 
            Color(0xFF4A0E4E), 
          ],
          stops: [0.0, 0.4, 0.7, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        appBar: AppBar(
          title: const Text("Pagla Admin Panel", style: TextStyle(color: Colors.cyanAccent)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.pinkAccent,
            labelColor: Colors.cyanAccent,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(icon: Icon(Icons.search), text: "User Control"),
              Tab(icon: Icon(Icons.campaign), text: "Broadcast"),
              Tab(icon: Icon(Icons.security), text: "Security"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: User Control & Management
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("User Control & Management:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Enter 6-digit UID",
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.08),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                        onPressed: () => _searchUser(_searchController.text.trim()),
                        child: const Text("Search", style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                  else if (_searchedUser != null) ...[
                    Builder(builder: (context) {
                      var data = _searchedUser!.data() as Map<String, dynamic>;
                      String docId = _searchedUser!.id;
                      String userUid = data['uID']?.toString() ?? docId;
                      
                      // 🛡️ চেক করা হচ্ছে ইউজারটি মালিকের আইডি কিনা
                      bool isSpecialOwner = specialOwnerIds.contains(userUid);

                      bool isBlocked = data['isBlocked'] ?? false;
                      bool isDeviceBlocked = data['isDeviceBlocked'] ?? false;
                      bool isVerified = data['isVerified'] ?? false;
                      bool isOfficial = data['isOfficial'] ?? false;
                      bool isSuperAdmin = data['isSuperAdmin'] ?? false;
                      bool isSuperHost = data['isSuperHost'] ?? false;
                      String gender = data['gender'] ?? "Unfixed";

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSpecialOwner ? Colors.amberAccent : Colors.cyanAccent.withOpacity(0.4),
                            width: isSpecialOwner ? 2.0 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSpecialOwner ? Colors.amber.withOpacity(0.4) : Colors.pinkAccent.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🌟 কার্ডে মালিকের আইডি হলে স্পেশাল লেবেল শো করবে
                            if (isSpecialOwner)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  "👑 মালিকের আইডি (Owner ID)",
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            Text("Name: ${data['name'] ?? 'N/A'}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("UID: $userUid", style: const TextStyle(color: Colors.white70)),
                            Text("Gender: $gender", style: const TextStyle(color: Colors.cyanAccent)),
                            Text("Status: ${isBlocked ? 'Blocked ❌' : 'Active ✅'}", style: TextStyle(color: isBlocked ? Colors.red : Colors.green)),
                            Text("Device Status: ${isDeviceBlocked ? 'Device Blocked ❌' : 'Normal ✅'}", style: TextStyle(color: isDeviceBlocked ? Colors.red : Colors.green)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                // Block / Unblock Button
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: isBlocked ? Colors.green : Colors.red),
                                  onPressed: () => _updateUserField(docId, {'isBlocked': !isBlocked}, targetUid: userUid),
                                  child: Text(isBlocked ? "Unblock" : "Block Permanent"),
                                ),
                                // 24 Hours Block
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                  onPressed: () => _blockFor24Hours(docId, userUid),
                                  child: const Text("Block 24h"),
                                ),
                                // One-click Device Block Button
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                                  onPressed: () => _blockDevice(docId, userUid),
                                  child: const Text("Device Block"),
                                ),
                                // Verified Toggle
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  onPressed: () {
                                    if (isSpecialOwner) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("⚠️ Owner's tags cannot be removed!"), backgroundColor: Colors.redAccent),
                                      );
                                      return;
                                    }
                                    _updateUserField(docId, {'isVerified': !isVerified}, targetUid: userUid);
                                  },
                                  child: Text(isVerified ? "Remove Verified" : "Make Verified"),
                                ),
                                // Official Toggle
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                                  onPressed: () {
                                    if (isSpecialOwner) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("⚠️ Owner's tags cannot be removed!"), backgroundColor: Colors.redAccent),
                                      );
                                      return;
                                    }
                                    _updateUserField(docId, {'isOfficial': !isOfficial}, targetUid: userUid);
                                  },
                                  child: Text(isOfficial ? "Remove Official" : "Make Official"),
                                ),
                                // Super Admin Toggle
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                                  onPressed: () {
                                    if (isSpecialOwner) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("⚠️ Owner's roles cannot be removed!"), backgroundColor: Colors.redAccent),
                                      );
                                      return;
                                    }
                                    _updateUserField(docId, {'isSuperAdmin': !isSuperAdmin}, targetUid: userUid);
                                  },
                                  child: Text(isSuperAdmin ? "Remove Super Admin" : "Make Super Admin"),
                                ),
                                // Super Host Toggle
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                  onPressed: () {
                                    if (isSpecialOwner) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("⚠️ Owner's roles cannot be removed!"), backgroundColor: Colors.redAccent),
                                      );
                                      return;
                                    }
                                    _updateUserField(docId, {'isSuperHost': !isSuperHost}, targetUid: userUid);
                                  },
                                  child: Text(isSuperHost ? "Remove Super Host" : "Make Super Host"),
                                ),
                                // Gender Switch (Male/Female Toggle)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                                  onPressed: () {
                                    if (isSpecialOwner) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("⚠️ Owner's gender cannot be changed!"), backgroundColor: Colors.redAccent),
                                      );
                                      return;
                                    }
                                    String newGender = gender.toLowerCase() == 'male' ? 'Female' : 'Male';
                                    _updateUserField(docId, {'gender': newGender}, targetUid: userUid);
                                  },
                                  child: Text("Set ${gender.toLowerCase() == 'male' ? 'Female' : 'Male'}"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ]
                ],
              ),
            ),

            // Tab 2: Broadcast Section
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Send Message to Everyone in One Click:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _broadcastController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Write official notice or message...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                    onPressed: () => _sendBroadcastMessage(_broadcastController.text.trim()),
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text("Send to All Users", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),

            // Tab 3: Security & Advanced Tools
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Security Overview & Quick Actions", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text("Here you can monitor security policies, device tracking, and high-level role delegations.", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}