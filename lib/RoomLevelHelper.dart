import 'package:cloud_firestore/cloud_firestore.dart';

class RoomLevelHelper {
  // ১০০০ ডাইমন্ড = ১ XP
  static const int xpPerDiamond = 1000; 

  // সঠিক লেভেল ক্যালকুলেশন লজিক (Level 1 = 250, এরপর প্রতি লেভেলে ৫০০ করে বাড়বে)
  static Map<String, int> calculateLevelAndProgress(int totalXp) {
    int level = 1;
    int remainingXp = totalXp;
    int currentLevelRequiredXp = 250; // লেভেল ১ এর জন্য ২৫০ XP

    while (level < 50) {
      if (remainingXp >= currentLevelRequiredXp) {
        remainingXp -= currentLevelRequiredXp;
        level++;
        currentLevelRequiredXp += 500; // প্রতি লেভেল শেষে ৫০০ XP করে টার্গেট বাড়াবে
      } else {
        break;
      }
    }

    if (level >= 50) {
      level = 50;
      remainingXp = currentLevelRequiredXp; // ৫০ লেভেলে পৌঁছে গেলে ফুল দেখাবে
    }

    return {
      'level': level,
      'currentXp': remainingXp,
      'requiredXp': currentLevelRequiredXp,
    };
  }

  // সুবিধার্থে সরাসরি লেভেল রিটার্ন করার জন্য
  static int calculateLevel(int totalXp) {
    return calculateLevelAndProgress(totalXp)['level']!;
  }

  // এখানে amount হলো ডায়মন্ডের পরিমাণ যা গিফট থেকে আসছে
  static Future<void> addXpToRoom(String roomId, int diamondAmount) async {
    int xpToAdd = (diamondAmount / xpPerDiamond).floor();
    
    if (xpToAdd < 1) return; 

    await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
      'totalXp': FieldValue.increment(xpToAdd),
    });
  }
}