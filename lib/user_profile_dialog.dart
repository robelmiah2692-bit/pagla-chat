import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void showUserProfile(BuildContext context, String userId) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var data = snapshot.data!.data() as Map<String, dynamic>;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E2F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // প্রোফাইল পিকচার ও ভিআইপি ব্যাজ
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(data['imageURL'] ?? 'https://via.placeholder.com/150'),
                  ),
                  if (data['isVIP'] == true)
                    const Icon(Icons.verified, color: Colors.gold, size: 30),
                ],
              ),
              const SizedBox(height: 10),
              // নাম এবং প্রিমিয়াম ব্যাজ
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(data['name'] ?? 'ইউজার', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  if (data['hasPremiumCard'] == true)
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                ],
              ),
              const SizedBox(height: 15),
              // ফলোয়ার ও ফলোইং স্ট্যাট
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat("Followers", data['followers'] ?? 0),
                  _buildStat("Following", data['following'] ?? 0),
                ],
              ),
              const SizedBox(height: 20),
              // ফলো ও মেসেজ বাটন
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () { /* ফলো লজিক */ },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                    child: const Text("Follow"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // ডায়ালগ বন্ধ করে চ্যাটে নিয়ে যাবে
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                    child: const Text("Message"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildStat(String label, int count) {
  return Column(
    children: [
      Text(count.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white54)),
    ],
  );
}
