import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GiftLogicHelper {
  
  // ১. ডায়মন্ড ভাগাভাগি লজিক (৪০% ইউজার, ১০% মালিক)
  static Map<String, int> calculateSplit(int totalPrice) {
    return {
      'userShare': (totalPrice * 0.40).floor(),
      'ownerShare': (totalPrice * 0.10).floor(),
    };
  }

  // ২. গিফট প্রসেসিং (এটি ডাটাবেজে এক্সট্রা ডকুমেন্ট তৈরি করবে না, শুধু ডায়মন্ড আপডেট করবে)
  static Future<void> processGift({
    required String senderId,
    required String targetType, // 'All Room', 'All Mic' অথবা নির্দিষ্ট UID
    required Map<String, dynamic> gift,
    required int count,
    required String roomId,
    required String senderName,
  }) async {
    final int unitPrice = (gift['price'] ?? 0) as int;
    final int totalPrice = unitPrice * count;
    final split = calculateSplit(totalPrice);
    
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // ক. সেন্ডারের ডায়মন্ড কাটা (যদি ফ্রি গিফট না হয়)
    if (unitPrice > 0) {
      DocumentReference senderRef = FirebaseFirestore.instance.collection('users').doc(senderId);
      batch.update(senderRef, {'diamonds': FieldValue.increment(-totalPrice)});
    }

    // খ. রুমের ভেতর 'last_gift' আপডেট (এটিই সবাই ৫ সেকেন্ডের জন্য দেখবে)
    // এটি ফায়ারবেসের স্টোরেজ খাবে না কারণ এটি বারবার ওভাররাইট হবে
    DocumentReference roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
    batch.update(roomRef, {
      'last_gift': {
        'id': gift['id'],
        'name': gift['name'],
        'image': gift['image'] ?? gift['icon'] ?? gift['url'],
        'senderId': senderId,
        'senderName': senderName,
        'target': targetType,
        'count': count,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }
    });

    // গ. ডায়মন্ড ভাগ করে দেওয়া (রিসিভারের একাউন্টে ৪০% যোগ করা)
    // যদি টার্গেট নির্দিষ্ট একজন ইউজার হয়
    if (targetType != 'All Room' && targetType != 'All Mic') {
      DocumentReference targetRef = FirebaseFirestore.instance.collection('users').doc(targetType);
      batch.update(targetRef, {'diamonds': FieldValue.increment(split['userShare'])});
    }

    await batch.commit();
  }

  // ৩. সিটে থাকা ইউজারদের ফিল্টার (আপনার অরিজিনাল লজিক)
  static List<Map<String, dynamic>> getAllMicUsers(List<dynamic> currentSeats) {
    List<Map<String, dynamic>> micUsers = [];
    for (var seat in currentSeats) {
      if (seat != null) {
        String? uid = seat['uid']?.toString() ?? 
                     seat['userId']?.toString() ?? 
                     seat['id']?.toString();
        
        if (uid != null && uid.isNotEmpty) {
          micUsers.add({
            'uid': uid,
            'name': seat['userName'] ?? seat['name'] ?? 'Unknown',
            'photoUrl': seat['userAvatar'] ?? seat['avatar'] ?? '',
            'uID': seat['uID']?.toString() ?? '0',
          });
        }
      }
    }
    return micUsers;
  }

  // ৪. টার্গেট সিলেক্টর পপআপ (সার্চ অপশন সহ পুরাতন UI ঠিক রেখে)
  static void showTargetSelector({
    required BuildContext context,
    required List<Map<String, dynamic>> micUsers,
    required Function(String uid, String name) onSelected,
  }) {
    TextEditingController searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "সার্চ করুন (ID/uID)",
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white10,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: Colors.pinkAccent),
                        onPressed: () async {
                          String input = searchController.text.trim();
                          if (input.isEmpty) return;

                          var query = await FirebaseFirestore.instance.collection('users')
                              .where('uID', isEqualTo: input).get();
                          
                          if (query.docs.isEmpty && int.tryParse(input) != null) {
                            query = await FirebaseFirestore.instance.collection('users')
                                .where('uID', isEqualTo: int.parse(input)).get();
                          }

                          if (query.docs.isNotEmpty) {
                            var d = query.docs.first.data();
                            onSelected(d['uid'].toString(), d['name'] ?? "No Name");
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("ইউজার পাওয়া যায়নি!"))
                            );
                          }
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text("Select Mic User", 
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                          subtitle: Text("ID: ${user['uID']}", style: const TextStyle(color: Colors.white24, fontSize: 10)),
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
          ),
        );
      },
    );
  }
}
