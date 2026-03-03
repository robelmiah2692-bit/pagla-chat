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
          // আইডি নাম্বার দিয়ে সার্চ বার
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

                // ক্লায়েন্ট সাইড ফিল্টারিং (যাতে আইডি বা নাম যাই লিখুন কাজ করে)
                var users = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String name = (data['name'] ?? "").toString().toLowerCase();
                  String customId = (data['userId'] ?? "").toString().toLowerCase();
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

                    // ছবির জন্য মাল্টিপল কী চেক করা হচ্ছে যাতে 'U' না আসে
                    String imageUrl = userData['imageURL'] ?? 
                                     userData['profilePic'] ?? 
                                     userData['userImageURL'] ?? 
                                     userData['photoUrl'] ?? "";

                    return _buildPremiumInboxTile(
                      context,
                      id: userId,
                      name: userData['name'] ?? "User",
                      image: imageUrl,
                      isOnline: userData['isOnline'] ?? false,
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

  Widget _buildPremiumInboxTile(BuildContext context, {required String id, required String name, required String image, required bool isOnline}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(receiverId: id, receiverName: name),
            ),
          );
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
                  if (isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        height: 12,
                        width: 12,
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
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    const Text("চ্যাট করতে ক্লিক করুন...", style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
