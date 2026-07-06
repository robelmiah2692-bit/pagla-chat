import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSelectionScreen extends StatelessWidget {
  final String roomId;
  
  const UserSelectionScreen({super.key, required this.roomId});

  Future<void> shareRoomInChat(String roomId, String targetUserId, String roomName, BuildContext context) async {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  
  // আপনার আগের চ্যাট আইডি তৈরির লজিক (আপনার লজিকের সাথে সামঞ্জস্যপূর্ণ)
  String chatRoomId = "${currentUserId}_$targetUserId"; 
  if (currentUserId.compareTo(targetUserId) > 0) {
    chatRoomId = "${targetUserId}_$currentUserId";
  }

  // 🔥 নতুন ডাটা সহ রুম ইনভাইটেশন মেসেজ
  Map<String, dynamic> roomMessage = {
    'senderId': currentUserId,
    'receiverId': targetUserId,
    'message': "Join my room: $roomName",
    'type': 'room_invite',
    'roomId': roomId,
    'roomName': roomName, // নতুন যোগ করা হয়েছে
    'roomImage': 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/room_default.png', // আপনার রুমের ডিফল্ট ইমেজ লিঙ্ক বা ডাটাবেস থেকে পাওয়া লিঙ্ক
    'timestamp': FieldValue.serverTimestamp(),
    'isRead': false,
  };

  await FirebaseFirestore.instance
      .collection('chats')
      .doc(chatRoomId)
      .collection('messages')
      .add(roomMessage);

  // ইনভাইটেশন পাঠানোর পর মেইন চ্যাট ডকুমেন্ট আপডেট করতে চাইলে এখানে করতে পারেন
  await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
    'lastMessage': "Join my room: $roomName",
    'type': 'room_invite', // ইনবক্স পেজে যেন 'room_invite' হিসেবে চিনতে পারে
    'lastTs': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: const Text("Share Room", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(user['profilePic'] ?? 'https://via.placeholder.com/150'),
                ),
                title: Text(user['name'] ?? 'User', style: const TextStyle(color: Colors.white)),
                trailing: IconButton(
                  icon: const Icon(Icons.send, color: Colors.greenAccent),
                  onPressed: () {
                    shareRoomInChat(roomId, user['uID'], "My Room", context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invitation sent!")),
                    );
                    Navigator.pop(context);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}