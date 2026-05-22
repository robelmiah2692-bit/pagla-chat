import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 💡 UID চেক করার জন্য ইম্পোর্ট করা হলো ভাই
import 'package:intl/intl.dart'; 

class NotificationPanel extends StatelessWidget {
  // 💡 এখানে 'required this.myCustomDocId' কেটে দিয়ে একদম সাধারণ করে দেওয়া হলো ভাই
  const NotificationPanel({super.key}); 

  @override
  Widget build(BuildContext context) {
    // কারেন্ট লগইন থাকা ইউজারের আসল ফায়ারবেস UID নেওয়া হলো
    final currentUser = FirebaseAuth.instance.currentUser;
    final myUid = currentUser?.uid ?? '';

    debugPrint("🔍 [PaglaChat] NotificationPanel ওপেন হয়েছে। আমার আসল UID (receiverId): $myUid");

    return Container(
      height: MediaQuery.of(context).size.height * 0.75, 
      decoration: const BoxDecoration(
        color: Color(0xFF1E2A4A), 
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 50, 
            height: 5, 
            decoration: BoxDecoration(
              color: Colors.white24, 
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            "Notifications",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white10, thickness: 1),
          
          Expanded(
            child: myUid.isEmpty 
              ? const Center(child: Text("User not logged in", style: TextStyle(color: Colors.white38)))
              : StreamBuilder<QuerySnapshot>(
                  // 💡 এখানে receiverId হিসেবে সরাসরি ইউজারের UID ম্যাচ করানো হচ্ছে ভাই
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .where('receiverId', isEqualTo: myUid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      debugPrint("❌ [PaglaChat] ফায়ারস্টোর এরর: ${snapshot.error}");
                      return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No new notifications\n(ডাটাবেজে নতুন নোটিফিকেশন আসলে এখানে দেখাবে)", 
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38),
                        ),
                      );
                    }

                    final allDocs = snapshot.data!.docs;
                    
                    final notifDocs = allDocs.where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final type = d['type'] ?? '';
                      return type == 'like' || type == 'comment';
                    }).toList();

                    // নতুন নোটিফিকেশন সবার উপরে দেখানোর জন্য সর্ট করা হলো
                    notifDocs.sort((a, b) {
                      final tsA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                      final tsB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                      if (tsA == null || tsB == null) return 0;
                      return tsB.compareTo(tsA);
                    });

                    debugPrint("📩 [PaglaChat] ফিল্টার করার পর মোট লাইক/কমেন্ট নোটিফিকেশন পাওয়া গেছে: ${notifDocs.length} টি");

                    if (notifDocs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No new notifications", 
                          style: TextStyle(color: Colors.white38),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: notifDocs.length,
                      itemBuilder: (context, index) {
                        final data = notifDocs[index].data() as Map<String, dynamic>;
                        
                        String senderName = data['senderName'] ?? 'Someone';
                        String senderPic = data['senderPic'] ?? '';
                        String type = data['type'] ?? '';
                        String commentText = data['commentText'] ?? '';
                        String postImage = data['postImage'] ?? '';
                        Timestamp? time = data['timestamp'] as Timestamp?;
                        String senderId = data['senderId'] ?? '';

                        String message = type == 'like' ? "liked your post." : "commented: \"$commentText\"";

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            leading: GestureDetector(
                              onTap: () {
                                if (senderId.isNotEmpty) {
                                  debugPrint("➡️ [PaglaChat] প্রোফাইল ওপেন ক্লিক আইডি: $senderId");
                                }
                              },
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white10,
                                backgroundImage: senderPic.isNotEmpty ? NetworkImage(senderPic) : null,
                                child: senderPic.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                              ),
                            ),
                            title: RichText(
                              text: TextSpan(
                                text: "$senderName ",
                                style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: message,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
                                  ),
                                ],
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                time != null ? DateFormat('hh:mm a, dd MMM').format(time.toDate()) : '',
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ),
                            trailing: postImage.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: Image.network(postImage, width: 35, height: 35, fit: BoxFit.cover),
                                  )
                                : Icon(
                                    type == 'like' ? Icons.favorite : Icons.comment,
                                    color: type == 'like' ? Colors.pinkAccent : Colors.cyanAccent,
                                    size: 20,
                                  ),
                          ),
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
}