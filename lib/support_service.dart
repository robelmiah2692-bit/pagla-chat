import 'package:cloud_firestore/cloud_firestore.dart';

class SupportService {
  // ১. আপনার সাপোর্ট এজেন্টদের আইডি এখানে বসানো আছে
  static final List<String> supportAgents = ["978051", "454488", "paglachat_official"];

  // ২. অফিশিয়াল রুম আইডি
  static const String officialRoomId = "paglachat_official_room";

  // ৩. অটো-রেসপন্স লজিক
  static Future<String> getAutoResponse(String userMessage) async {
    // বর্তমান বাংলাদেশ টাইম (UTC+6)
    DateTime now = DateTime.now().toUtc().add(const Duration(hours: 6)); 
    int hour = now.hour;

    // সাপোর্ট টাইম রাত ৮টা (20) থেকে ১০টা (22) এর মধ্যে কি না চেক করা
    bool isWorkingHours = (hour >= 20 && hour < 22);
    
    // এজেন্ট অনলাইনে আছে কি না চেক করা
    bool agentsOnline = await isAnyAgentOnline();

    // লজিক: সময় ঠিক থাকতে হবে AND এজেন্টকে অনলাইনে থাকতে হবে
    if (isWorkingHours && agentsOnline) {
      return "Our support team is online now! Please tell us your issue, and I will forward your message to our agents immediately.";
    } else {
      return "Sorry! Our support team is currently offline. Please join our official room between 8:00 PM and 10:00 PM (Bangladesh Time). We will be there to help you.";
    }
  }

  // ৪. কোনো এজেন্ট অনলাইন কি না চেক করা
  static Future<bool> isAnyAgentOnline() async {
    try {
      var query = await FirebaseFirestore.instance
          .collection('users')
          .where('uID', whereIn: supportAgents) // নির্দিষ্ট এজেন্ট আইডিগুলো দিয়ে সার্চ
          .where('isOnline', isEqualTo: true)   // অনলাইন স্ট্যাটাস চেক
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      // যদি ডাটাবেজ এরর হয়, তবে অফলাইন ধরে নিবে
      return false;
    }
  }
}