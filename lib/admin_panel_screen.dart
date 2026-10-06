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

  // Update user fields (Block, Verify, Super Admin, Super Host, etc.)
  void _updateUserField(String targetDocId, Map<String, dynamic> updates) async {
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
  void _blockFor24Hours(String targetDocId) {
    DateTime unblockTime = DateTime.now().add(const Duration(hours: 24));
    _updateUserField(targetDocId, {
      'isBlocked': true,
      'blockedUntil': Timestamp.fromDate(unblockTime),
    });
  }

  // One-click Device Block
  void _blockDevice(String targetDocId) {
    _updateUserField(targetDocId, {
      'isDeviceBlocked': true,
      'isBlocked': true,
    });
  }

  // Send Broadcast Message from current Admin ID to all users via chats/messages structure
  void _sendBroadcastMessage(String message) async {
    if (message.isEmpty) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
    );

    try {
      // Fetch current admin's details using widget.myUid
      var adminDoc = await FirebaseFirestore.instance.collection('users').doc(widget.myUid).get();
      String adminName = adminDoc.exists ? (adminDoc.data()?['name'] ?? 'Admin') : 'Admin';
      String adminUid = widget.myUid;
      String adminEmail = adminDoc.exists ? (adminDoc.data()?['email'] ?? '') : '';
      String adminImage = adminDoc.exists ? (adminDoc.data()?['image'] ?? '') : '';

      var allUsers = await FirebaseFirestore.instance.collection('users').get();
      
      // Batch writes are limited to 500 operations. If users are more, handle in loops or batches.
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var doc in allUsers.docs) {
        String targetUserId = doc.id;
        if (targetUserId == adminUid) continue; // Skip admin self

        // Create a unique chat room ID matching your app's convention (e.g., sorted UIDs joined by underscore)
        List<String> ids = [adminUid, targetUserId];
        ids.sort();
        String chatRoomId = ids.join('_');

        var chatRoomRef = FirebaseFirestore.instance.collection('chats').doc(chatRoomId);
        var messageRef = chatRoomRef.collection('messages').doc();

        // Set or update the chat room document
        batch.set(chatRoomRef, {
          'lastMessage': message,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'unReadCount_$targetUserId': FieldValue.increment(1),
          'unReadCount_$adminUid': 0,
        }, SetOptions(merge: true));

        // Set the message document inside the messages sub-collection
        batch.set(messageRef, {
          'message': message,
          'senderId': adminUid,
          'senderUid': adminUid,
          'senderName': adminName,
          'senderEmail': adminEmail,
          'senderImage': adminImage,
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
        const SnackBar(content: Text("Broadcast message sent to all chats successfully!"))
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
        // Neon mix color gradient background
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
                          border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pinkAccent.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Name: ${data['name'] ?? 'N/A'}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("UID: ${data['uID'] ?? docId}", style: const TextStyle(color: Colors.white70)),
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
                                  onPressed: () => _updateUserField(docId, {'isBlocked': !isBlocked}),
                                  child: Text(isBlocked ? "Unblock" : "Block Permanent"),
                                ),
                                // 24 Hours Block
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                  onPressed: () => _blockFor24Hours(docId),
                                  child: const Text("Block 24h"),
                                ),
                                // One-click Device Block Button
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                                  onPressed: () => _blockDevice(docId),
                                  child: const Text("Device Block"),
                                ),
                                // Verified Toggle
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  onPressed: () => _updateUserField(docId, {'isVerified': !isVerified}),
                                  child: Text(isVerified ? "Remove Verified" : "Make Verified"),
                                ),
                                // Official Toggle
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                                  onPressed: () => _updateUserField(docId, {'isOfficial': !isOfficial}),
                                  child: Text(isOfficial ? "Remove Official" : "Make Official"),
                                ),
                                // Super Admin Toggle
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                                  onPressed: () => _updateUserField(docId, {'isSuperAdmin': !isSuperAdmin}),
                                  child: Text(isSuperAdmin ? "Remove Super Admin" : "Make Super Admin"),
                                ),
                                // Super Host Toggle
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                  onPressed: () => _updateUserField(docId, {'isSuperHost': !isSuperHost}),
                                  child: Text(isSuperHost ? "Remove Super Host" : "Make Super Host"),
                                ),
                                // Gender Switch (Male/Female Toggle)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                                  onPressed: () {
                                    String newGender = gender.toLowerCase() == 'male' ? 'Female' : 'Male';
                                    _updateUserField(docId, {'gender': newGender});
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