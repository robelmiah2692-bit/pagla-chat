import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GiftLogicHelper {
  
  // ১. ডায়মন্ড ভাগাভাগি লজিক (৪০% রিসিভার, ১০% রুম ওনার)
  static Map<String, int> calculateSplit(int totalPrice) {
    return {
      'userShare': (totalPrice * 0.40).floor(),
      'ownerShare': (totalPrice * 0.10).floor(),
    };
  }

  // ২. গিফট প্রসেসিং (ডায়মন্ড আপডেট + টপ চার্মিং/বস লজিক)
  static Future<void> processGift({
    required String senderId,
    required String targetId, // 'All Room', 'All Mic' অথবা নির্দিষ্ট UID
    required Map<String, dynamic> gift,
    required int count,
    required String roomId,
    required String senderName,
    required String? roomOwnerId,
  }) async {
    final int unitPrice = (gift['price'] ?? 0) as int;
    final int totalPrice = unitPrice * count;
    final split = calculateSplit(totalPrice);
    
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // ক. সেন্ডারের ডায়মন্ড কাটা এবং 'Top Contributor' (বস) এক্সপি বাড়ানো
    if (unitPrice > 0) {
      DocumentReference senderRef = FirebaseFirestore.instance.collection('users').doc(senderId);
      batch.update(senderRef, {
        'diamonds': FieldValue.increment(-totalPrice),
        'totalSpent': FieldValue.increment(totalPrice), // বস হওয়ার জন্য
      });
    }

    // খ. রুমের ভেতর ব্যানার এবং চার্মিং ডাটা আপডেট
    DocumentReference roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
    
    // ব্যানার ডাটা (যাতে ইউজার পোস্ট/স্টোরি করতে পারে)
    Map<String, dynamic> giftBanner = {
      'id': gift['id'],
      'name': gift['name'],
      'image': gift['image'] ?? gift['icon'] ?? gift['url'],
      'senderId': senderId,
      'senderName': senderName,
      'targetId': targetId,
      'count': count,
      'totalPrice': totalPrice,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    batch.update(roomRef, {
      'last_gift_banner': giftBanner,
      // রুমের টপ চার্মিং লিস্টে যোগ করা (রুমের জন্য আলাদা কালেকশন হতে পারে, এখানে ফিল্ডে রাখা হলো)
      'room_total_diamonds': FieldValue.increment(totalPrice),
    });

    // গ. রিসিভারের একাউন্টে ৪০% যোগ করা এবং 'Charming' (বসিনি) স্কোর বাড়ানো
    if (targetId != 'All Room' && targetId != 'All Mic') {
      DocumentReference targetRef = FirebaseFirestore.instance.collection('users').doc(targetId);
      batch.update(targetRef, {
        'diamonds': FieldValue.increment(split['userShare']),
        'charmingScore': FieldValue.increment(totalPrice), // চার্মিং হওয়ার জন্য
      });
    }

    // ঘ. রুম ওনারের একাউন্টে ১০% যোগ করা
    if (roomOwnerId != null && roomOwnerId.isNotEmpty && unitPrice > 0) {
      DocumentReference ownerRef = FirebaseFirestore.instance.collection('users').doc(roomOwnerId);
      batch.update(ownerRef, {'diamonds': FieldValue.increment(split['ownerShare'])});
    }

    await batch.commit();
  }

  // ৩. সিটে থাকা ইউজারদের ফিল্টার (আপনার অরিজিনাল লজিক যা আপনি চেয়েছিলেন)
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

  // ৪. টপ চার্মিং ব্যানার ডিজাইন (যা ইউজার শেয়ার করতে পারবে)
  static Widget buildGiftSuccessBanner({
    required BuildContext context,
    required Map<String, dynamic> bannerData,
    required VoidCallback onShare,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.purple, Colors.pinkAccent]),
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage("https://www.transparenttextures.com/patterns/carbon-fibre.png"),
          opacity: 0.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("🔥 TOP CHARMING MOMENT 🔥", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bannerUserCircle(bannerData['senderName'], "SENDER"),
              Column(
                children: [
                  Image.network(bannerData['image'], width: 60, height: 60),
                  Text("x${bannerData['count']}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              _bannerUserCircle(bannerData['targetId'].toString() == "All Room" ? "Room" : "Receiver", "TARGET"),
            ],
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share, size: 16),
            label: const Text("Share to Story / Post"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, shape: const StadiumBorder()),
          )
        ],
      ),
    );
  }

  static Widget _bannerUserCircle(String name, String label) {
    return Column(
      children: [
        const CircleAvatar(radius: 25, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
        const SizedBox(height: 5),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
      ],
    );
  }

  // ৫. টার্গেট সিলেক্টর পপআপ (সার্চসহ)
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                    hintText: "Search User ID...",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white10,
                    suffixIcon: const Icon(Icons.search, color: Colors.pinkAccent),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text("Mic Users", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: micUsers.length,
                  itemBuilder: (context, index) {
                    final user = micUsers[index];
                    return ListTile(
                      leading: CircleAvatar(backgroundImage: NetworkImage(user['photoUrl'])),
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
        );
      },
    );
  }
}
