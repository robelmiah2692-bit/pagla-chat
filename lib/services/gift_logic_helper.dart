import 'package:flutter/material.dart';

class GiftLogicHelper {
  // ১. অল রুম লজিক (রুমের সব ইউজার কাউন্ট - মেম্বার লিস্ট থেকে আসবে)
  static int getAllRoomCount(List<dynamic> roomMembers) {
    return roomMembers.length;
  }

  // ২. অল মাইক লজিক (সিটে যারা আছে তাদের ডাটা ফিল্টার করা)
  static List<Map<String, dynamic>> getAllMicUsers(List<dynamic> currentSeats) {
    List<Map<String, dynamic>> micUsers = [];
    for (var seat in currentSeats) {
      if (seat != null && seat['uid'] != null && seat['uid'].toString().isNotEmpty) {
        micUsers.add({
          'uid': seat['uid'],
          'name': seat['userName'] ?? 'Unknown',
          'photoUrl': seat['userAvatar'] ?? '',
        });
      }
    }
    return micUsers;
  }

  // ৩. টার্গেট ইউজার সিলেক্টর (বটম শিট এর ভেতর আরেকটি পপআপ)
  static void showTargetSelector({
    required BuildContext context,
    required List<Map<String, dynamic>> micUsers,
    required Function(String uid, String name) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(15.0),
                child: Text(
                  "Select Seat User",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              if (micUsers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30.0),
                  child: Text("No one is on the mic!", style: TextStyle(color: Colors.white54)),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: micUsers.length,
                    itemBuilder: (context, index) {
                      final user = micUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white10,
                          backgroundImage: user['photoUrl'].isNotEmpty 
                              ? NetworkImage(user['photoUrl']) 
                              : null,
                          child: user['photoUrl'].isEmpty 
                              ? const Icon(Icons.person, color: Colors.white24) 
                              : null,
                        ),
                        title: Text(user['name'], style: const TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                        onTap: () {
                          onSelected(user['uid'], user['name']);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
