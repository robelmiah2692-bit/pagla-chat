import 'package:flutter/material.dart';

class GiftLogicHelper {
  
  // ১. ডায়মন্ড ভাগাভাগির হিসাব (যা আপনি মেইন ফাইলে কল করেছেন)
  static Map<String, int> calculateSplit(int totalPrice) {
    return {
      'userShare': (totalPrice * 0.40).floor(),   // ইউজার ৪০%
      'ownerShare': (totalPrice * 0.10).floor(),  // মালিক ১০%
    };
  }

  // ২. সিটে থাকা ইউজারদের ফিল্টার করা
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

  // ৩. টার্গেট সিলেক্টর পপআপ (বটম শিট)
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
                child: Text("Select Seat User", 
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                          backgroundImage: NetworkImage(user['photoUrl']),
                          child: user['photoUrl'].isEmpty ? const Icon(Icons.person) : null,
                        ),
                        title: Text(user['name'], style: const TextStyle(color: Colors.white)),
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
