import 'package:cloud_firestore/cloud_firestore.dart';

class SupportService {
  // ১. ফায়ারস্টোর থেকে সাপোর্ট এজেন্টদের আইডি ফেচ করার ফাংশন
  static Future<List<String>> getAgentIds() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('system_config')
          .doc('app_settings')
          .get();
      
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        // ফায়ারস্টোরের 'protectedUserIds' বা 'supportAgents' অ্যারে থেকে আইডিগুলো নেওয়া
        if (data.containsKey('protectedUserIds')) {
          return List<String>.from(data['protectedUserIds']);
        }
      }
    } catch (e) {
      // কোনো এরর হলে ফাকা লিস্ট রিটার্ন করবে
    }
    return [];
  }

  // ২. অফিশিয়াল রুম আইডি
  static const String officialRoomId = "paglachat_official_room";

  // ৩. অটো-রেসপন্স লজিক
  static Future<String> getAutoResponse(String userMessage) async {
    DateTime now = DateTime.now().toUtc().add(const Duration(hours: 6)); 
    int hour = now.hour;

    bool isWorkingHours = (hour >= 20 && hour < 22);
    bool agentsOnline = await isAnyAgentOnline();

    if (isWorkingHours && agentsOnline) {
      return "Our support team is online now! Please tell us your issue, and I will forward your message to our agents immediately.";
    } else {
      return "Sorry! Our support team is currently offline. Please join our official room between 8:00 PM and 10:00 PM (Bangladesh Time). We will be there to help you.";
    }
  }

  // ৪. কোনো এজেন্ট অনলাইন কি না চেক করা
  static Future<bool> isAnyAgentOnline() async {
    try {
      List<String> agentIds = await getAgentIds();
      if (agentIds.isEmpty) return false;

      var query = await FirebaseFirestore.instance
          .collection('users')
          .where('uID', whereIn: agentIds) 
          .where('isOnline', isEqualTo: true)   
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}