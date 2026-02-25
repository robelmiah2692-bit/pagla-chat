import 'package:flutter/material.dart';

class FollowerListHandler {
  static void show(BuildContext context, int followerCount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            const Text(
              "ফলোয়ার লিস্ট",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView(
                children: [
                  _buildUserTile("রুম মালিক (You)", "Owner", Colors.amber),
                  _buildUserTile("এডমিন ১", "Admin", Colors.pinkAccent),
                  ...List.generate(
                    followerCount,
                    (index) => _buildUserTile("ইউজার আইডি: ${100 + index}", "Follower", Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ইউজার টাইল ডিজাইনটি এখানে নিয়ে আসলাম
  static Widget _buildUserTile(String name, String role, Color color) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.white10,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(name, style: const TextStyle(color: Colors.white)),
      subtitle: Text(role, style: TextStyle(color: color, fontSize: 12)),
      trailing: const Icon(Icons.info_outline, color: Colors.white24, size: 18),
    );
  }
}
