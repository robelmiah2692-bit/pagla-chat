import 'package:flutter/material.dart';

class GiftLogicHelper {
  // ১. ডায়মন্ড ভাগাভাগির হিসাব (৪০% ইউজার, ১০% মালিক)
  static Map<String, int> calculateSplit(int totalPrice) {
    return {
      'userShare': (totalPrice * 0.40).floor(),
      'ownerShare': (totalPrice * 0.10).floor(),
    };
  }

  // ২. সিটে থাকা ইউজারদের ফিল্টার করা (TargetSelector এর জন্য)
  static List<Map<String, dynamic>> getAllMicUsers(List<dynamic> currentSeats) {
    List<Map<String, dynamic>> micUsers = [];
    for (var seat in currentSeats) {
      if (seat != null) {
        // UID পাওয়ার জন্য সব সম্ভাব্য কি (Key) চেক করা হচ্ছে যেন মিস না হয়
        String? uid = seat['uid']?.toString() ?? 
                      seat['userId']?.toString() ?? 
                      seat['id']?.toString();
        
        if (uid != null && uid.isNotEmpty) {
          micUsers.add({
            'uid': uid,
            'name': seat['userName'] ?? seat['name'] ?? 'Unknown',
            'photoUrl': seat['userAvatar'] ?? seat['avatar'] ?? '',
          });
        }
      }
    }
    return micUsers;
  }

  // ৩. টার্গেট সিলেক্টর পপআপ (সিটের ইউজারদের লিস্ট দেখাবে)
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
                          backgroundColor: Colors.white10,
                          backgroundImage: user['photoUrl'].toString().startsWith('http') 
                              ? NetworkImage(user['photoUrl']) 
                              : null,
                          child: (user['photoUrl'] == null || user['photoUrl'].isEmpty) 
                              ? const Icon(Icons.person, color: Colors.white54) 
                              : null,
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
