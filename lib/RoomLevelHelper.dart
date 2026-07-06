import 'package:cloud_firestore/cloud_firestore.dart';

class RoomLevelHelper {
  // ১০০০ ডাইমন্ড = ১ XP (আপনি যদি মনে করেন এটা ঠিক আছে, তবে এটাই থাক)
  static const int xpPerDiamond = 1000; 
  static const int baseLevelXp = 250;

  static int calculateLevel(int totalXp) {
    int level = (totalXp / baseLevelXp).floor();
    return level < 1 ? 1 : (level > 50 ? 50 : level);
  }

  // এখানে amount হলো ডায়মন্ডের পরিমাণ যা গিফট থেকে আসছে
  static Future<void> addXpToRoom(String roomId, int diamondAmount) async {
    // এখানে ক্যালকুলেশন করুন
    int xpToAdd = (diamondAmount / xpPerDiamond).floor();
    
    // যদি xpToAdd ০ হয় (অর্থাৎ গিফট ১০০০ এর কম), তবে কমপক্ষে ১ XP যোগ করুন 
    // অথবা আপনি যদি চান শুধু ১০০০ এর উপরে গেলেই XP বাড়বে, তবে নিচের কোডটিই সঠিক:
    if (xpToAdd < 1) return; 

    await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
      'totalXp': FieldValue.increment(xpToAdd),
    });
  }
}