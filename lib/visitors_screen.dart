import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VisitorsScreen extends StatelessWidget {
  const VisitorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // বর্তমান ইউজারের AuthUID ব্যবহার করে তার নিজের ডকুমেন্ট আইডি খুঁজে বের করছি
    final String currentAuthUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Profile Visitors"),
        backgroundColor: Colors.grey[900],
      ),
      body: currentAuthUid.isEmpty
          ? const Center(child: Text("Please login", style: TextStyle(color: Colors.white)))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('authUID', isEqualTo: currentAuthUid)
                  .snapshots()
                  .asyncMap((userSnapshot) async {
                if (userSnapshot.docs.isEmpty) {
                  return FirebaseFirestore.instance
                      .collection('invalid_path')
                      .snapshots()
                      .first;
                }

                // নিজের ডকুমেন্ট আইডি পাচ্ছি
                String myDocId = userSnapshot.docs.first.id;

                // নিজের ভিজিটর কালেকশন থেকে ডাটা রিড করছি
                return await FirebaseFirestore.instance
                    .collection('users')
                    .doc(myDocId)
                    .collection('visitors')
                    .orderBy('visitedAt', descending: true)
                    .get()
                    .then((snapshot) => snapshot);
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No visitors yet", style: TextStyle(color: Colors.white)));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    // ডাটাবেস থেকে ডাটা ম্যাপে কনভার্ট করছি
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: ListTile(
                        leading: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              // আপনার দেয়া ফিল্ড অনুযায়ী: userImage
                              backgroundImage: NetworkImage(data['userImage'] ?? ''),
                            ),
                            // আপনার দেয়া ফিল্ড অনুযায়ী: frameUrl
                            if (data['frameUrl'] != null && data['frameUrl'].toString().isNotEmpty)
                              Image.network(data['frameUrl'], width: 50, height: 50),
                          ],
                        ),
                        // আপনার দেয়া ফিল্ড অনুযায়ী: userName
                        title: Text(
                          data['userName'] ?? "User",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          "Visited your profile",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}