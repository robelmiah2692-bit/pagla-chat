import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});
  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // কাস্টমার সাপোর্ট ডায়ালগ (৩ দিনের ওয়েটিং মেসেজ)
  void _showSupportNotice(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Support",
      pageBuilder: (context, anim1, anim2) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Gemini AI Support", style: TextStyle(color: Colors.pinkAccent)),
        content: const Text(
          "আপনার সমস্যাটি আইডি সহ নোট করা হয়েছে। অনুগ্রহ করে ৩ দিন অপেক্ষা করুন। সমাধান হলে Paglachat Officials থেকে আপনাকে মেসেজ পাঠানো হবে।",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ঠিক আছে", style: TextStyle(color: Colors.pinkAccent)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text("মেসেজ", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E2F),
        elevation: 0,
      ),
      body: Column(
        children: [
          // সার্চ বার (নাম এবং আইডি দিয়ে সার্চ ফিক্সড)
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "ইউজার আইডি বা নাম লিখুন...",
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.search, color: Colors.pinkAccent),
                filled: true,
                fillColor: const Color(0xFF1E1E2F),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("ইউজার পাওয়া যায়নি!", style: TextStyle(color: Colors.white54)));
                }

                var users = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String name = (data['name'] ?? "").toString().toLowerCase();
                  // আইডি সার্চের জন্য 'userId' বা 'myRoomId' চেক করা হচ্ছে
                  String customId = (data['userId'] ?? data['myRoomId'] ?? "").toString().toLowerCase();
                  String fireId = doc.id.toLowerCase();
                  
                  return name.contains(_searchQuery.toLowerCase()) || 
                         customId.contains(_searchQuery.toLowerCase()) ||
                         fireId.contains(_searchQuery.toLowerCase());
                }).toList();

                if (users.isEmpty) {
                   return const Center(child: Text("ইউজার খুঁজে পাওয়া যায়নি", style: TextStyle(color: Colors.white54)));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var userData = users[index].data() as Map<String, dynamic>;
                    String userId = users[index].id;

                    if (userId == currentUserId) return const SizedBox.shrink();

                    String imageUrl = userData['imageURL'] ?? 
                                     userData['profilePic'] ?? 
                                     userData['userImageURL'] ?? 
                                     userData['photoUrl'] ?? "";

                    return _buildPremiumInboxTile(
                      context,
                      id: userId,
                      name: userData['name'] ?? "User",
                      image: imageUrl,
                      isOnline: userData['isOnline'] ?? false, // রিয়েল টাইম গ্রিন ডট
                      customId: (userData['userId'] ?? userData['myRoomId'] ?? "N/A").toString(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumInboxTile(BuildContext context, {required String id, required String name, required String image, required bool isOnline, required String customId}) {
    List<String> ids = [currentUserId, id];
    ids.sort();
    String chatId = ids.join("_");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: InkWell(
        onTap: () async {
          // Gemini AI সাপোর্ট চেক
          if (id == "gemini_ai_support" || name.contains("Gemini AI")) {
            _showSupportNotice(context);
          }

          // আনরিড মেসেজ Read করা
          var unreadMessages = await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .where('receiverId', isEqualTo: currentUserId)
              .where('isRead', isEqualTo: false)
              .get();

          for (var doc in unreadMessages.docs) {
            doc.reference.update({'isRead': true});
          }

          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(receiverId: id, receiverName: name),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10, width: 0.5),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.pinkAccent,
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF0D0D1A),
                      backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                      child: image.isEmpty 
                        ? Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) 
                        : null,
                    ),
                  ),
                  // গ্রিন ডট লজিক (অনলাইন থাকলে দেখাবে)
                  if (isOnline)
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        height: 14,
                        width: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1E1E2F), width: 2),
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
                      name, 
                      style: TextStyle(
                        color: (id == "paglachat_official" || id == "gemini_ai_support") ? Colors.pinkAccent : Colors.white, 
                        fontSize: 16, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                    const SizedBox(height: 5),
                    Text("ID: $customId", style: const TextStyle(color: Colors.white24, fontSize: 12)),
                  ],
                ),
              ),
              
              // মেসেজ নোটিফিকেশন কাউন্টার (লাল ডট)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .where('receiverId', isEqualTo: currentUserId)
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    int count = snapshot.data!.docs.length;
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "$count",
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  return const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 16);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
