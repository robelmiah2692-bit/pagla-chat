import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'voice_room.dart'; // আপনার ভয়েস রুম ফাইলের পাথ ঠিক আছে কি না দেখে নিন

class RoomLauncher extends StatelessWidget {
  const RoomLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Voice App")),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            backgroundColor: Colors.blueAccent,
          ),
          onPressed: () {
            // 🔥 এখান থেকেই ইউজার আইডি নিয়ে ইউনিক রুম তৈরি হবে
            final String myUid = FirebaseAuth.instance.currentUser?.uid ?? "guest_user";
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VoiceRoom(roomId: myUid),
              ),
            );
          },
          child: const Text(
            "আমার রুমে প্রবেশ করুন",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
