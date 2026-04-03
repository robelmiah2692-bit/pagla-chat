import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/voice_room.dart';

class RoomLauncher extends StatelessWidget {
  const RoomLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Voice App", style: TextStyle(fontWeight: FontWeight.bold)),
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
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                
                if (user != null) {
                  final String myUid = user.uid;

                  // ফিক্সড লজিক: roomId এবং ownerId দুইটাই পাঠানো হচ্ছে
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VoiceRoom(
                        roomId: myUid,      // রুম আইডি ইউজারের ইউআইডি
                        ownerId: myUid,     // মালিকও আপনি নিজে (এইটা আগে মিস ছিল)
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("দয়া করে আগে লগইন করুন!")),
                  );
                }
              },
              child: const Text(
                "আমার রুমে প্রবেশ করুন",
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 18, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
