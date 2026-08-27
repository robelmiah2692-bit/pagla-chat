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
      backgroundColor: const Color(0xFF190033), // ব্যাকগ্রাউন্ড কালার থিমের সাথে সামঞ্জস্যপূর্ণ করা হয়েছে
      appBar: AppBar(
        title: const Text("Profile Visitors", style: TextStyle(color: Colors.cyanAccent)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: Container(
        decoration: const BoxDecoration(
          // সেটিংস উইজেটের হুবহু প্রিমিয়াম ব্লু ও পার্পল গ্রেডিয়েন্ট
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00B4DB), // Bright Cyan Blue
              Color(0xFF0083B0), // Mid Blue tone
              Color(0xFF4A00E0), // Deep Purple gradient match
              Color(0xFF190033), // Rich dark purple-blue base
            ],
          ),
        ),
        child: Stack(
          children: [
            // ব্যাকগ্রাউন্ডে তারার ঝিকিমিকি ইফেক্ট
            ...List.generate(
              15,
              (index) => Positioned(
                top: (index * 50.0) % 500,
                left: (index * 80.0) % 380,
                child: Icon(
                  Icons.star,
                  size: index % 3 == 0 ? 12 : 6,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            currentAuthUid.isEmpty
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
                        return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text("No visitors yet", style: TextStyle(color: Colors.white70, fontSize: 16)));
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          // ডাটাবেস থেকে ডাটা ম্যাপে কনভার্ট করছি
                          var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              // গ্লাস ইফেক্ট কার্ড ব্যাকগ্রাউন্ড
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyanAccent.withOpacity(0.05),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.white24,
                                    // আপনার দেয়া ফিল্ড অনুযায়ী: userImage
                                    backgroundImage: NetworkImage(data['userImage'] ?? ''),
                                  ),
                                  // আপনার দেয়া ফিল্ড অনুযায়ী: frameUrl
                                  if (data['frameUrl'] != null && data['frameUrl'].toString().isNotEmpty)
                                    Image.network(data['frameUrl'], width: 60, height: 60, fit: BoxFit.contain),
                                ],
                              ),
                              // আপনার দেয়া ফিল্ড অনুযায়ী: userName
                              title: Text(
                                data['userName'] ?? "User",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: const Text(
                                "Visited your profile",
                                style: TextStyle(color: Colors.cyanAccent, fontSize: 13),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}