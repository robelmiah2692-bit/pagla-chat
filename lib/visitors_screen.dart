import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VisitorsScreen extends StatelessWidget {
  const VisitorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Profile Visitors"),
        backgroundColor: Colors.grey[900],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // আপনার ডাটাবেজে যেখানে ভিজিটর লিস্ট সেভ হচ্ছে সেই কালেকশন পাথটি দিন
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(myUid)
            .collection('visitors')
            .orderBy('visitedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No visitors yet", style: TextStyle(color: Colors.white)));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              
              // কার্ড ডিজাইন
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)), // প্রিমিয়াম লুক
                ),
                child: ListTile(
                  leading: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(data['userImage'] ?? ''),
                      ),
                      // ফ্রেমের লজিক (আপনার ডাটাবেজ অনুযায়ী)
                      if (data['frameUrl'] != null)
                        Image.network(data['frameUrl'], width: 50, height: 50),
                    ],
                  ),
                  title: Text(data['userName'] ?? "Unknown", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Visited your profile", style: TextStyle(color: Colors.white70)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}