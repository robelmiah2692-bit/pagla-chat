import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onEmojiTap;
  final Function(Map<String, String>) onMessageSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onEmojiTap,
    required this.onMessageSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.black45,
      child: Row(
        children: [
          // ইমোজি বাটন
          IconButton(
            onPressed: onEmojiTap,
            icon: const Icon(Icons.emoji_emotions, color: Colors.amber),
          ),
          
          // টেক্সট ইনপুট
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "মেসেজ লিখুন...",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white24),
              ),
            ),
          ),

          // সেন্ড বাটন
          IconButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
                
                // মেসেজ ডাটা তৈরি করে মেইন ফাইলে পাঠানো
                onMessageSend({
                  'userName': user?.displayName ?? "User",
                  'userImage': user?.photoURL ?? "https://picsum.photos/100",
                  'text': controller.text,
                });
                
                controller.clear(); // বক্স খালি করা
              }
            },
            icon: const Icon(Icons.send, color: Colors.blueAccent),
          ),
        ],
      ),
    );
  }
}
