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

  // ২. গিফট প্রসেসিং (ফায়ারবেস স্ক্রিনশট অনুযায়ী নিখুঁত ফিল্ড নেম সহ)
  static Future<void> processGift({
    required String senderAuthId, // লগইন করা ইউজারের লম্বা uID
    required String targetAuthId, // রিসিভারের লম্বা uID
    required Map<String, dynamic> gift,
    required int count,
    required String roomId,
    required String senderName,
    required String? roomOwnerAuthId, // রুম ওনারের লম্বা uID
  }) async {
    final int unitPrice = (gift['price'] ?? 0) as int;
    final int totalPrice = unitPrice * count;
    final Map<String, int> split = calculateSplit(totalPrice);
    
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // ক. সেন্ডারের একাউন্ট আপডেট (ডায়মন্ড কাটা + মোট খরচ বাড়ানো)
    if (unitPrice > 0) {
      DocumentReference senderRef = FirebaseFirestore.instance.collection('users').doc(senderAuthId);
      batch.update(senderRef, {
        'diamonds': FieldValue.increment(-totalPrice),
        'totalSpent': FieldValue.increment(totalPrice), // বস হওয়ার জন্য এক্সপি
      });
    }

    // খ. রুমের তথ্য আপডেট (লাস্ট গিফট ব্যানার এবং টোটাল ডায়মন্ড)
    DocumentReference roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
    
    Map<String, dynamic> giftBanner = {
      'id': gift['id'],
      'name': gift['name'],
      'image': gift['image'] ?? gift['profilePic'] ?? gift['icon'],
      'senderAuthId': senderAuthId,
      'senderName': senderName,
      'targetAuthId': targetAuthId,
      'count': count,
      'totalPrice': totalPrice,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    batch.update(roomRef, {
      'last_gift': giftBanner,
      'totalDiamonds': FieldValue.increment(totalPrice), // 'room_total_diamonds' এর বদলে 'totalDiamonds'
    });

    // গ. রিসিভারের একাউন্টে ৪০% যোগ করা (স্ক্রিনশট অনুযায়ী 'diamonds' ফিল্ডে)
    if (targetAuthId != 'All Room' && targetAuthId != 'All Mic') {
      DocumentReference targetRef = FirebaseFirestore.instance.collection('users').doc(targetAuthId);
      int userAmount = split['userShare'] ?? 0;
      batch.update(targetRef, {
        'diamonds': FieldValue.increment(userAmount),
        'receivedDiamonds': FieldValue.increment(totalPrice), // Charming Score এর জন্য
      });
    }

    // ঘ. রুম ওনারের একাউন্টে ১০% যোগ করা
    if (roomOwnerAuthId != null && roomOwnerAuthId.isNotEmpty && unitPrice > 0) {
      DocumentReference ownerRef = FirebaseFirestore.instance.collection('users').doc(roomOwnerAuthId);
      int ownerAmount = split['ownerShare'] ?? 0;
      batch.update(ownerRef, {'diamonds': FieldValue.increment(ownerAmount)});
    }

    await batch.commit();
  }

  // ৩. সিটে থাকা ইউজারদের ফিল্টার (আপনার স্ক্রিনশটের সিট স্ট্রাকচার অনুযায়ী)
  static List<Map<String, dynamic>> getAllMicUsers(List<dynamic> currentSeats) {
    List<Map<String, dynamic>> micUsers = [];
    for (var seat in currentSeats) {
      if (seat != null && seat['isOccupied'] == true) {
        String? authuID = seat['authuID']?.toString() ?? seat['uID']?.toString();
        
        if (authuID != null && authuID.isNotEmpty) {
          micUsers.add({
            'uID': authuID, // লম্বা আইডি
            'uID': seat['uID']?.toString() ?? '0', // মালিকের চেনার ৬-ডিজিটের আইডি
            'name': seat['name'] ?? seat['userName'] ?? 'Unknown',
            'photoUrl': seat['profilePic'] ?? seat['userImage'] ?? '',
          });
        }
      }
    }
    return micUsers;
  }

  // ৪. গিফট ব্যানার ডিজাইন (UI)
  static Widget buildGiftSuccessBanner({
    required BuildContext context,
    required Map<String, dynamic> bannerData,
    required VoidCallback onShare,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.pink]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("🌟 TOP CHARMING 🌟", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bannerUserCircle(bannerData['senderName'] ?? "User", "SENDER"),
              Column(
                children: [
                  Image.network(bannerData['image'] ?? "", width: 50, height: 50, 
                    errorBuilder: (c, e, s) => const Icon(Icons.card_giftcard, color: Colors.white)),
                  Text("x${bannerData['count']}", 
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              _bannerUserCircle(bannerData['targetAuthId'].toString() == "All Room" ? "Room" : "Receiver", "TARGET"),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share, color: Colors.white, size: 16),
            label: const Text("Share to Story", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  static Widget _bannerUserCircle(String name, String label) {
    return Column(
      children: [
        const CircleAvatar(radius: 20, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
        const SizedBox(height: 5),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 11), overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 8)),
      ],
    );
  }

  // ৫. টার্গেট সিলেক্টর পপআপ (যেখানে ইউজার ID/uID দেখা যাবে)
  static void showTargetSelector({
    required BuildContext context,
    required List<Map<String, dynamic>> micUsers,
    required Function(String authuID, String name) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: micUsers.length,
          itemBuilder: (context, index) {
            final user = micUsers[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user['profilePic'].toString().isNotEmpty 
                    ? NetworkImage(user['profilePic']) : null,
                child: user['profilePic'].toString().isEmpty ? const Icon(Icons.person) : null,
              ),
              title: Text(user['name'], style: const TextStyle(color: Colors.white)),
              subtitle: Text("User ID: ${user['uID']}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
              onTap: () {
                onSelected(user['uID'], user['name']);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }
}
