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
        title: const Text("Voice App", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                
                if (user != null && user.email != null) {
                  // ১. ইউজারের ৬-ডিজিটের uID খুঁজে বের করা
                  var userQuery = await FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: user.email)
                      .limit(1)
                      .get();

                  if (userQuery.docs.isNotEmpty) {
                    String mySixDigitID = userQuery.docs.first['uID'].toString();

                    // ২. এই uID দিয়ে ইউজারের তৈরি করা রুম আইডি খুঁজে বের করা
                    var roomQuery = await FirebaseFirestore.instance
                        .collection('rooms')
                        .where('ownerId', isEqualTo: mySixDigitID)
                        .limit(1)
                        .get();

                    if (roomQuery.docs.isNotEmpty) {
                      String actualRoomId = roomQuery.docs.first['roomId']; // ৫-ডিজিটের আইডি

                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VoiceRoom(roomId: actualRoomId),
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("আপনার কোনো রুম তৈরি করা নেই!")),
                        );
                      }
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please Login First!")),
                  );
                }
              },
              child: const Text(
                "Enter My Room",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
