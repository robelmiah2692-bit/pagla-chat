import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserListScreen extends StatelessWidget {
  final String title; // এটি "Followers" অথবা "Following" রিসিভ করবে
  final String userId; // কোন ইউজারের লিস্ট দেখা হচ্ছে তার আইডি

  const UserListScreen({super.key, required this.title, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A), // অ্যাপের থিম কালার
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ডাটাবেস পাথ: users -> {userId} -> followers/following
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(title.toLowerCase()) 
            .snapshots(),
        builder: (context, snapshot) {
          // ১. লোডিং অবস্থা
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
          }

          // ২. যদি কোনো ডাটা না থাকে
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, color: Colors.white24, size: 80),
                  const SizedBox(height: 10),
                  Text("এখনো কোনো $title নেই!", style: const TextStyle(color: Colors.white54, fontSize: 16)),
                ],
              ),
            );
          }

          // ৩. লিস্ট রেন্ডার করা
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[800],
                    backgroundImage: NetworkImage(
                      data['profilePic'] != null && data['profilePic'] != ""
                          ? data['profilePic']
                          : "https://www.pngitem.com/pimgs/m/150-1503945_transparent-user-png-default-user-image-png-png.png",
                    ),
                  ),
                  title: Text(
                    data['name'] ?? "অচেনা ইউজার",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "ID: ${data['uID'] ?? "N/A"}",
                    style: const TextStyle(color: Colors.pinkAccent, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
                  onTap: () {
                    // এখানে ক্লিক করলে ঐ ইউজারের প্রোফাইলে যাওয়ার লজিক পরে যোগ করা হবে
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
