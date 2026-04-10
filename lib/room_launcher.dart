import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/voice_room.dart';

class RoomLauncher extends StatelessWidget {
  const RoomLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voice App", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE3F2FD)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic_none_rounded, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                
                if (user != null) {
                  // এখানে রুম আইডি হিসেবে ইউজারের নিজস্ব UID ব্যবহার করা হচ্ছে 
                  // কারণ সাধারণত নিজের রুমে ঢোকার বাটন এটি।
                  // তবে মালিকানা নির্ধারণ হবে VoiceRoom এর ভেতর ডাটাবেস চেক করে।
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VoiceRoom(
                        roomId: user.uid, 
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Login fast!")),
                  );
                }
              },
              child: const Text(
                "well come this room",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
