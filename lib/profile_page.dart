import 'package:intl/intl.dart';
import 'package:pagla_chat/auth_service.dart';
import 'package:pagla_chat/help_desk_page.dart';
import 'package:pagla_chat/privacy_policy_page.dart';
import 'package:pagla_chat/services/diamond_recharge_view.dart';
import 'package:pagla_chat/services/follow_service.dart';
import 'package:pagla_chat/services/soulmate_detail_page.dart';
import 'package:pagla_chat/widgets/active_level_bar.dart';
import 'package:pagla_chat/widgets/gift_level_bar.dart';
import 'package:shimmer/shimmer.dart';
import 'widgets/animated_frame.dart'; // পাথটি আপনার ফোল্ডার অনুযায়ী ঠিক করে নিন
import 'package:firebase_storage/firebase_storage.dart';
import 'vip_service.dart'; // ফাইলের নাম অনুযায়ী
import 'dart:math' as math;
import 'dart:io';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'package:pagla_chat/user_list_screen.dart';
import 'chat_screen.dart';
import 'package:pagla_chat/services/database_service.dart';
import 'package:pagla_chat/services/soulmate_service.dart';
import 'package:pagla_chat/services/marriage_service.dart';
import 'package:pagla_chat/pages/agent_transfer_page.dart';
import 'dart:math';
import 'package:lottie/lottie.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;

  const ProfilePage({
    super.key,
    this.userId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseService _dbService = DatabaseService();
  // ... বাকি ভেরিয়েবলগুলো এখানে থাকবে
  // এই ভেরিয়েবলগুলো ক্লাসের একদম উপরে (build মেথডের বাইরে) যোগ করুন
  bool hasEntryEffect = false;
  DateTime? entryUntilDate;
  String activeEntryUrl = "";
  bool hasFreeFrame = false;
  String activeFrameUrl = "";
  DateTime? frameUntilDate;
  DateTime? premiumUntilDate;
  String userImageURL = "";
  String userName = "Unfixed";
  String uIDValue = "";
  String gender = "Unfixed";
  int age = 22;
  int diamonds = 200;
  int xp = 0;
  int vipExpiry = 0; // 🔥 এই লাইনটিই মিসিং ছিল, এখন যোগ করে দিলাম
  int followers = 0;
  int following = 0;
  bool isFollowing = false;
  bool hasPremiumCard = false;
  bool isVIP = false;
  DateTime premiumExpiryDate = DateTime.now().add(const Duration(days: 30));
  DateTime lastLevelUpDate = DateTime.now();
  bool isAgent = false; // একদম উপরে যেখানে অন্য ভেরিয়েবল আছে
  int vipLevel = 0; // 🔥 ভিআইপি লেভেলের জন্য এটি যোগ করুন
  String activeSpecialUrl =
      ""; // বর্তমানে কোন স্পেশাল ইফেক্টটি ব্যবহার হচ্ছে তার URL
  bool hasSpecialEffect =
      false; // ইউজার কি কোনো স্পেশাল ইফেক্ট অন করে রেখেছে কি না

  int totalActiveXp = 0;
  int totalGiftXp = 0;
  @override
  void initState() {
    super.initState();
    loadUserData(); // আইডি জেনারেশন বন্ধ, শুধু ডাটা লোড হবে
  }

// আইডি জেনারেশন ছাড়া শুধু ডাটা খুঁজে বের করার লজিক
  // আইডি জেনারেশন ছাড়া শুধু ডাটা খুঁজে বের করার লজিক
  void loadUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      DocumentSnapshot? userDoc;
      final collection = FirebaseFirestore.instance.collection('users');

      // ১. uID দিয়ে চেক
      var docById = await collection.doc(currentUser.uid).get();
      if (docById.exists) {
        userDoc = docById;
      }

      // ২. authUID দিয়ে চেক
      if (userDoc == null) {
        var queryAuth = await collection
            .where('authUID', isEqualTo: currentUser.uid)
            .limit(1)
            .get();
        if (queryAuth.docs.isNotEmpty) userDoc = queryAuth.docs.first;
      }

      // ৩. email দিয়ে চেক
      if (userDoc == null && currentUser.email != null) {
        var queryEmail = await collection
            .where('email', isEqualTo: currentUser.email)
            .limit(1)
            .get();
        if (queryEmail.docs.isNotEmpty) userDoc = queryEmail.docs.first;
      }

      // ৪. uID ফিল্ড দিয়ে চেক
      if (userDoc == null) {
        var queryuIDField = await collection
            .where('uID', isEqualTo: currentUser.uid)
            .limit(1)
            .get();
        if (queryuIDField.docs.isNotEmpty) userDoc = queryuIDField.docs.first;
      }

      // --- ডাটা পাওয়ার পর ভেরিয়েবলে সেট করা ---
      if (userDoc != null && userDoc.exists && mounted) {
        var data = userDoc.data() as Map<String, dynamic>;
        DateTime now = DateTime.now();

        setState(() {
          uIDValue = userDoc!.id;
          isAgent = data['isAgent'] == true;
          userName = data['name'] ?? data['userName'] ?? "Pagla User";
          userImageURL = data['profilePic'] ?? "";
          gender = data['gender'] ?? "Unfixed";

          var ageData = data['age'];
          age = (ageData is String)
              ? (int.tryParse(ageData) ?? 22)
              : (ageData ?? 22);

          diamonds = (data['diamonds'] ?? 200).toInt();
          xp = (data['vip_xp'] ?? 0).toInt();

          followers = (data['followers'] ?? 0).toInt();
          following = (data['following'] ?? 0).toInt();
          isVIP = data['isVIP'] ?? false;

          // ১. Premium Card এক্সপায়ারি
          hasPremiumCard = data['hasPremiumCard'] ?? false;
          if (data['premiumUntil'] != null) {
            premiumUntilDate = (data['premiumUntil'] as Timestamp).toDate();
            if (now.isAfter(premiumUntilDate!)) {
              hasPremiumCard = false;
              _clearExpiredData('hasPremiumCard', 'premiumUntil');
            }
          }

          activeSpecialUrl = data['activeSpecialUrl'] ?? "";
          hasSpecialEffect = data['hasSpecialEffect'] ?? false;
          // ২. Frame এক্সপায়ারি
          hasFreeFrame = data['hasFreeFrame'] ?? false;
          activeFrameUrl = data['activeFrameUrl'] ?? "";
          if (data['frameUntil'] != null) {
            frameUntilDate = (data['frameUntil'] as Timestamp).toDate();
            if (now.isAfter(frameUntilDate!)) {
              hasFreeFrame = false;
              activeFrameUrl = "";
              _clearExpiredData('hasFreeFrame', 'frameUntil',
                  extraField: 'activeFrameUrl');
            }
          }

          // ৩. Entry Effect এক্সপায়ারি
          activeEntryUrl = data['activeEntryUrl'] ?? "";
          hasEntryEffect = data['hasEntryEffect'] ?? false;
          if (data['entryUntil'] != null) {
            entryUntilDate = (data['entryUntil'] as Timestamp).toDate();
            if (now.isAfter(entryUntilDate!)) {
              activeEntryUrl = "";
              hasEntryEffect = false;
              _clearExpiredData('hasEntryEffect', 'entryUntil',
                  extraField: 'activeEntryUrl');
            }
          }
          // 🎯 আপনার setState এর একদম শেষ লাইনে এই প্রিন্টগুলো বসিয়ে দিন ভাই:
          totalActiveXp = (data['totalActiveXp'] ?? 0).toInt();

// 🇧🇩 [বাংলা মার্ক]: অ্যাক্টিভ এক্সপির জন্য মাস্টার প্রিন্ট লগ ট্র্যাকিং ভাই
          debugPrint("======== 🎁 [PaglaChat Active XP System] ========");
          debugPrint(
              "📥 ডাটাবেজ থেকে প্রাপ্ত totalActiveXp ফিল্ড: ${data['totalActiveXp']}");
          debugPrint(
              "📈 ভেরিয়েবলে সেটের পর totalActiveXp ভ্যালু: $totalActiveXp");
          debugPrint("=================================================");
          totalGiftXp = (data['totalGiftXp'] ?? 0).toInt();

          // 🇧🇩 [বাংলা মার্ক]: আসল প্রিন্ট লগ ট্র্যাকিং—যার মাধ্যমে এক সেকেন্ডে গোমর ফাঁস হবে!
          debugPrint("🔥 [প্রিন্ট ১ - ডাটাবেজ ম্যাপ]: " + data.toString());
          debugPrint("🔥 [প্রিন্ট ২ - ম্যাপের ভেতর totalGiftXp]: " +
              data['totalGiftXp'].toString());
          debugPrint(
              "🔥 [প্রিন্ট ৩ - সেটের পর totalGiftXp ভেরিয়েবল]: $totalGiftXp");
          debugPrint("🔥 [প্রিন্ট ৪ - কারেন্ট ইউজার আইডি]: $uIDValue");
        });
        debugPrint("✅ ডাটা লোড সম্পন্ন: $uIDValue");
      }
    } catch (e) {
      debugPrint("Firebase Search Error: $e");
    }
  } // <--- loadUserData এখানে শেষ

  void _checkCurrentFollowStatus(String tId) async {
    bool status = await FollowService().checkIfFollowing(tId);
    setState(() {
      isFollowing = status;
    });
  }

  void _toggleFollowWithId(String tId) async {
    // 🛠️ সরাসরি পাস হওয়া আইডি ব্যবহার করায় আর কোনো লাল দাগ আসবে না
    bool currentStatus = await FollowService().toggleFollowUser(tId);

    setState(() {
      isFollowing = currentStatus;
      if (currentStatus) {
        followers += 1;
      } else {
        followers -= 1;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(currentStatus
          ? "You started following!"
          : "Unfollowed successfully!"),
      backgroundColor: currentStatus ? Colors.pinkAccent : Colors.blueGrey,
      duration: const Duration(seconds: 1),
    ));
  }

  // ডাটাবেজ থেকে মেয়াদ শেষ হওয়া ডাটা মুছে ফেলার ফাংশন (এটি বাইরে থাকবে)
  void _clearExpiredData(String boolField, String dateField,
      {String? extraField}) async {
    if (uIDValue == null || uIDValue.isEmpty) return;

    Map<String, dynamic> updateData = {
      boolField: false,
      dateField: FieldValue.delete(),
    };

    if (extraField != null) {
      updateData[extraField] = "";
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uIDValue)
          .update(updateData);
      debugPrint("🔥 $boolField এর মেয়াদ শেষ! ক্লিয়ার করা হয়েছে।");
    } catch (e) {
      debugPrint("Error clearing data: $e");
    }
  }

  // ২০টি রিয়েল অবতার লিস্ট
  final List<String> maleAvatars = [
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(1).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(2).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(3).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(4).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(5).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(6).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(7).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(8).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(9).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(10).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(11).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(12).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(13).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(14).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(15).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(16).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(17).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(18).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(19).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(20).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(21).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(22).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(23).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(24).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/profilepic%20(25).jpg",
    "https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?auto=compress&cs=tinysrgb&w=200&v=1",
    "https://images.pexels.com/photos/2182970/pexels-photo-2182970.jpeg?auto=compress&cs=tinysrgb&w=200&v=2",
    "https://images.pexels.com/photos/1043474/pexels-photo-1043474.jpeg?auto=compress&cs=tinysrgb&w=200&v=3",
    "https://images.pexels.com/photos/91227/pexels-photo-91227.jpeg?auto=compress&cs=tinysrgb&w=200&v=5",
    "https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=200&v=6",
    "https://images.pexels.com/photos/837358/pexels-photo-837358.jpeg?auto=compress&cs=tinysrgb&w=200&v=7",
    "https://images.pexels.com/photos/775358/pexels-photo-775358.jpeg?auto=compress&cs=tinysrgb&w=200&v=8",
    "https://images.pexels.com/photos/1516680/pexels-photo-1516680.jpeg?auto=compress&cs=tinysrgb&w=200&v=9",
    "https://images.pexels.com/photos/1431282/pexels-photo-1431282.jpeg?auto=compress&cs=tinysrgb&w=200",
    "https://images.pexels.com/photos/1043471/pexels-photo-1043471.jpeg?auto=compress&cs=tinysrgb&w=200",
    "https://images.pexels.com/photos/1559486/pexels-photo-1559486.jpeg?auto=compress&cs=tinysrgb&w=200",
    "https://images.pexels.com/photos/1680172/pexels-photo-1680172.jpeg?auto=compress&cs=tinysrgb&w=200",
    "https://images.pexels.com/photos/1212984/pexels-photo-1212984.jpeg?auto=compress&cs=tinysrgb&w=200",
    "https://images.pexels.com/photos/1516680/pexels-photo-1516680.jpeg?auto=compress&cs=tinysrgb&w=200",
    "https://images.pexels.com/photos/614810/pexels-photo-614810.jpeg?auto=compress&cs=tinysrgb&w=200",
    "https://images.pexels.com/photos/1080213/pexels-photo-1080213.jpeg?auto=compress&cs=tinysrgb&w=200",
  ];
  final List<String> femaleAvatars = [
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(1).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(2).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(3).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(4).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(5).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(6).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(7).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(8).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(9).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(10).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(11).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(12).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(13).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(14).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(15).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(16).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(17).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(18).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(19).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(20).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(21).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(22).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(23).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(24).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(25).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(26).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(27).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(28).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(29).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(30).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(31).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(32).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(33).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(34).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(35).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(36).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(37).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(38).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(39).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(40).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(41).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(42).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(43).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(44).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(45).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(46).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(47).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(48).jpg",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(49).jpg",
    "https://images.pexels.com/photos/1181686/pexels-photo-1181686.jpeg?auto=compress&cs=tinysrgb&w=200&v=11",
    "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=200&v=12",
    "https://images.pexels.com/photos/712513/pexels-photo-712513.jpeg?auto=compress&cs=tinysrgb&w=200&v=13",
    "https://images.pexels.com/photos/1181519/pexels-photo-1181519.jpeg?auto=compress&cs=tinysrgb&w=200&v=14",
    "https://images.pexels.com/photos/1130626/pexels-photo-1130626.jpeg?auto=compress&cs=tinysrgb&w=200&v=15",
    "https://images.pexels.com/photos/1587009/pexels-photo-1587009.jpeg?auto=compress&cs=tinysrgb&w=200&v=16",
    "https://images.pexels.com/photos/764529/pexels-photo-764529.jpeg?auto=compress&cs=tinysrgb&w=200&v=17",
    "https://images.pexels.com/photos/1852300/pexels-photo-1852300.jpeg?auto=compress&cs=tinysrgb&w=200&v=18",
    "https://images.pexels.com/photos/718978/pexels-photo-718978.jpeg?auto=compress&cs=tinysrgb&w=200&v=19",
    "https://images.pexels.com/photos/1036622/pexels-photo-1036622.jpeg?auto=compress&cs=tinysrgb&w=200&v=16",
    "https://images.pexels.com/photos/1310522/pexels-photo-1310522.jpeg?auto=compress&cs=tinysrgb&w=200&v=20",
  ];

  final List<String> vipFrames = [
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/vipframe/framevip%20(1).png",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/vipframe/framevip%20(2).png",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/vipframe/framevip%20(3).png",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/vipframe/framevip%20(4).png",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/vipframe/framevip%20(5).png",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/vipframe/framevip%20(6).png",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/vipframe/framevip%20(7).png",
    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/vipframe/framevip%20(8).png",
  ];
  // ১. গিটহাবের বেস লিঙ্ক (সব ছবির জন্য কমন)
  final String githubBaseUrl =
      "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main";

// ২. VIP বেইজ লিংকের ফাংশন (গিটহাব থেকে সরাসরি লোড হবে)
  String getVipBadge(int level) {
    if (level == 0) return "";

    switch (level) {
      case 1:
        return "$githubBaseUrl/vip1.png";
      case 2:
        return "$githubBaseUrl/vip2.png";
      case 3:
        return "$githubBaseUrl/vip3.png";
      case 4:
        return "$githubBaseUrl/vip4.png";
      case 5:
        return "$githubBaseUrl/vip5.png";
      case 6:
        return "$githubBaseUrl/vip6.png";
      case 7:
        return "$githubBaseUrl/vip7.png";
      case 8:
        return "$githubBaseUrl/vip8.png";
      default:
        return "";
    }
  }

// ৩. প্রিমিয়াম ব্যাজের জন্য ডাইনামিক লিঙ্ক
  String get premiumBadgeUrl => "$githubBaseUrl/premium.png";

  // VIP লেভেল ক্যালকুলেশন (মেয়াদসহ)
  int getVipLevel() {
    int currentTime = DateTime.now().millisecondsSinceEpoch;

    // যদি মেয়াদ শেষ হয়ে যায়, তবে VIP ০ (লেভেল নেই)
    if (vipExpiry != 0 && currentTime > vipExpiry) {
      return 0;
    }

    if (xp >= 35000) return 8;
    if (xp >= 30000) return 7;
    if (xp >= 25000) return 6;
    if (xp >= 20000) return 5;
    if (xp >= 13000) return 4;
    if (xp >= 9000) return 3;
    if (xp >= 5000) return 2;
    if (xp >= 2500) return 1;
    return 0;
  }

  void _editName(Map<String, dynamic> userData) {
    TextEditingController _nameController =
        TextEditingController(text: userData['name'] ?? "");

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.lightBlue.shade200,
                Colors.blue.shade50,
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Change Name",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.5),
                  hintText: "Enter your name",
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.8), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide:
                        const BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.blueGrey)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      String newName = _nameController.text.trim();
                      if (newName.isNotEmpty) {
                        // ১. ম্যাপ থেকে আইডি খোঁজা
                        String? docId;
                        if (userData['uID'] != null &&
                            userData['uID'].toString().isNotEmpty &&
                            userData['uID'] != "null") {
                          docId = userData['uID'].toString();
                        } else if (userData['uid'] != null &&
                            userData['uid'].toString().isNotEmpty &&
                            userData['uid'] != "null") {
                          docId = userData['uid'].toString();
                        } else if (userData['email'] != null &&
                            userData['email'].toString().isNotEmpty &&
                            userData['email'] != "null") {
                          docId = userData['email'].toString();
                        }

                        // ২. ব্যাকআপ হিসেবে আপনার uIDValue ব্যবহার করা (এখন আর লাল দাগ আসবে না)
                        if (docId == null || docId == "null" || docId.isEmpty) {
                          docId = uIDValue;
                        }

                        // ৩. আপডেট লজিক
                        if (docId.isNotEmpty && docId != "null") {
                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(docId)
                                .update({'name': newName});

                            setState(() {
                              userName = newName; // স্ক্রিনে নাম পরিবর্তন হবে
                              if (userData.containsKey('name')) {
                                userData['name'] = newName;
                              }
                            });
                            Navigator.pop(context);
                          } catch (e) {
                            print("Update Error: $e");
                          }
                        } else {
                          print("Error: No ID found even in uIDValue!");
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Save",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFollow() async {
    String myuID = FirebaseAuth.instance.currentUser!.uid;
    String targetuID = uIDValue;
    var followRef = FirebaseFirestore.instance.collection('users');
    if (isFollowing) {
      await followRef
          .doc(myuID)
          .update({'following': FieldValue.increment(-1)});
      await followRef
          .doc(targetuID)
          .update({'followers': FieldValue.increment(-1)});
    } else {
      await followRef.doc(myuID).update({'following': FieldValue.increment(1)});
      await followRef
          .doc(targetuID)
          .update({'followers': FieldValue.increment(1)});
    }
    setState(() => isFollowing = !isFollowing);
  }

  void _showAgePicker() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E2F),
              title: const Text("Your age?",
                  style: TextStyle(color: Colors.white)),
              content: SizedBox(
                  height: 200,
                  width: double.maxFinite,
                  child: ListView.builder(
                      itemCount: 40,
                      itemBuilder: (context, index) => ListTile(
                          title: Text("${index + 15} Year",
                              style: const TextStyle(color: Colors.white)),
                          onTap: () async {
                            String uID = FirebaseAuth.instance.currentUser!.uid;
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uID)
                                .update({'age': index + 15});
                            setState(() => age = index + 15);
                            Navigator.pop(context);
                          }))),
            ));
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // গ্রেডিয়েন্ট দেখানোর জন্য
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          // প্রিমিয়াম আকাশী নীল গ্রেডিয়েন্ট
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.lightBlue.shade200,
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: Stack(
          children: [
            // ব্যাকগ্রাউন্ডে তারার ঝিকিমিকি
            ...List.generate(
                15,
                (index) => Positioned(
                      top: (index * 50.0) % 300,
                      left: (index * 80.0) % 380,
                      child: Icon(
                        Icons.star,
                        size: index % 3 == 0 ? 12 : 6,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    )),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                // ড্র্যাগ হ্যান্ডেল
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("Settings",
                        style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold))),

                // ১. বয়স পরিবর্তন (Age change)
                ListTile(
                    leading: const Icon(Icons.cake, color: Colors.orangeAccent),
                    title: Text("Age change (Now: $age)",
                        style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      _showAgePicker();
                    }),

                ListTile(
                  leading: const Icon(Icons.security, color: Colors.blueAccent),
                  title: const Text("Privacy Policy",
                      style: TextStyle(
                          color: Colors.black87, fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context); // ড্রয়ার বন্ধ হবে
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PrivacyPolicyPage()),
                    );
                  },
                ),

                // ৩. হেল্প ডেস্ক (Help Desk) - নেভিগেশনসহ আপডেট করা হয়েছে
                ListTile(
                  leading: const Icon(Icons.support_agent, color: Colors.green),
                  title: const Text(
                    "Help Desk",
                    style: TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context); // ড্রয়ার বন্ধ হবে
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HelpDeskPage()),
                    );
                  },
                ),
               // ৪. লগআউট (Logout)
ListTile(
  leading: const Icon(Icons.logout, color: Colors.redAccent),
  title: const Text(
    "Logout",
    style: TextStyle(
      color: Colors.redAccent,
      fontWeight: FontWeight.bold,
    ),
  ),
  onTap: () async {
    // AuthService ব্যবহার করে লগআউট
    await AuthService().signOut();
    
    // হ্যাং হওয়া রোধ করতে আগের সব স্ক্রিন মুছে দিয়ে LoginScreen-এ পাঠানো
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  },
),
const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    ),
  );
}

  void _showFreeAvatars() {
    List<String> avatars = (gender == "Male") ? maleAvatars : femaleAvatars;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.lightBlue.shade200,
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: Stack(
          children: [
            // প্রিমিয়াম তারার ইফেক্ট
            ...List.generate(
                15,
                (index) => Positioned(
                      top: (index * 35.0) % 300,
                      left: (index * 70.0) % 400,
                      child: Icon(
                        Icons.star,
                        size: index % 3 == 0 ? 12 : 6,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    )),

            Column(
              children: [
                const SizedBox(height: 12),
                // ড্র্যাগ হ্যান্ডেল
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text("Free Avatars",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent)),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12),
                    itemCount: avatars.length,
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () async {
                        try {
                          // ✅ আপনার uIDValue ব্যবহার করে ইউনিক আইডি আপডেট
                          if (uIDValue.isNotEmpty) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uIDValue)
                                .update({'profilePic': avatars[index]});

                            if (mounted) {
                              setState(() {
                                userImageURL = avatars[index];
                              });
                            }
                          }
                        } catch (e) {
                          debugPrint("Error: $e");
                        }
                        if (mounted) Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 4)
                          ],
                        ),
                        child: ClipOval(
                          child:
                              Image.network(avatars[index], fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _pickProfileImage() {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1A1A2E),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => Wrap(children: [
              ListTile(
                  leading: const Icon(Icons.face, color: Colors.blueAccent),
                  title: const Text("Real avatar (Free)",
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _showFreeAvatars();
                  }),
              ListTile(
                  leading:
                      const Icon(Icons.photo_library, color: Colors.pinkAccent),
                  title: const Text("Gallery photo avatar",
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    if (hasPremiumCard || getVipLevel() >= 1) {
                      try {
                        final ImagePicker picker = ImagePicker();
                        final XFile? pickedFile = await picker.pickImage(
                            source: ImageSource.gallery, imageQuality: 40);

                        if (pickedFile != null) {
                          if (!mounted) return;
                          Navigator.pop(context);
                          // ফাইল পাঠানোর আগে সিওর হয়ে নিন ফাইলটি এক্সিস্ট করে
                          await _handleProfileUpdate(File(pickedFile.path));
                        }
                      } catch (e) {
                        debugPrint("Error picking image: $e");
                      }
                    } else {
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text("Premium card or VIP 1 needed for Gallery!"),
                          backgroundColor: Colors.redAccent));
                    }
                  }),
            ]));
  }

  Future<void> _handleProfileUpdate(File newFile) async {
    try {
      // ✅ সবথেকে গুরুত্বপূর্ণ পরিবর্তন: Auth uID ব্যবহার করা
      String uID = FirebaseAuth.instance.currentUser!.uid;
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = 'profile_$timestamp.jpg';

      // ১. স্টোরেজ রেফারেন্স
      Reference storageFolder =
          FirebaseStorage.instance.ref().child('user_profiles').child(uID);
      Reference newStorageRef = storageFolder.child(fileName);

      // ২. ছবি আপলোড (putFile সরাসরি কাজ করবে যদি পাথ ঠিক থাকে)
      UploadTask uploadTask = newStorageRef.putFile(
          newFile, SettableMetadata(contentType: 'image/jpeg'));

      TaskSnapshot snapshot = await uploadTask;
      String newDownloadUrl = await snapshot.ref.getDownloadURL();

      // ৩. ফায়ারস্টোর আপডেট (ডকুমেন্ট আইডি হিসেবে uID নিশ্চিত করা হয়েছে)
      await FirebaseFirestore.instance.collection('users').doc(uID).update({
        'profilePic': newDownloadUrl,
      });

      // ৪. ইউজার ইন্টারফেস রিয়েল টাইম আপডেট
      if (mounted) {
        setState(() {
          userImageURL = newDownloadUrl;
        });
      }

      // ৫. পুরাতন ফাইল ডিলিট করার লজিক (নিরাপদভাবে)
      final ListResult result = await storageFolder.listAll();
      for (var item in result.items) {
        if (item.name != fileName) {
          await item
              .delete()
              .catchError((e) => debugPrint("Old file delete failed: $e"));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Profile updated successfully!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Update Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error: ${e.toString()}"),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _openDiamondStore([Map<String, dynamic>? userData]) {
    // যদি বাইরে থেকে userData আসে তবে সেটা নিবে, নয়তো লোকাল ভেরিয়েবল নিবে
    Map<String, dynamic> currentData = userData ??
        {
          'diamonds': diamonds,
          'isAgent': isAgent,
          'uID': uIDValue,
          'name': userName,
        };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DiamondStoreView(
        userData: currentData,
        isAgent: isAgent,
      ),
    );
  }

  // ১. প্রিমিয়াম স্টোর ওপেন করার ফাংশন
  void _openPremiumStore() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // নিচে কন্টেইনারে গ্রেডিয়েন্ট দিচ্ছি
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => DefaultTabController(
        length: 4,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            // বডি ডিজাইন: নীল আকাশ হালকা কালার গ্রেডিয়েন্ট
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.lightBlue.shade200,
                Colors.blue.shade50,
                Colors.white,
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: Stack(
            children: [
              // ব্যাকগ্রাউন্ডে তারার মতো ঝিকিমিকি ইফেক্ট (Stars)
              ...List.generate(
                  20,
                  (index) => Positioned(
                        top: (index * 40.0) % 450,
                        left: (index * 65.0) % 380,
                        child: Icon(
                          Icons.star,
                          size: index % 3 == 0 ? 14 : 8,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      )),

              Column(
                children: [
                  const SizedBox(height: 12),
                  // ড্র্যাগ হ্যান্ডেল
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const TabBar(
                    isScrollable: true,
                    indicatorColor: Colors.amber,
                    labelColor: Colors.blueAccent,
                    unselectedLabelColor: Colors.black45,
                    labelStyle: TextStyle(fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(text: "Cards"),
                      Tab(text: "Frames"),
                      Tab(text: "Entry"),
                      Tab(text: "Special"),
                    ],
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildStoreCardTab(), // স্টোর কার্ড ট্যাব
                        _buildFrameStoreTab(),
                        _buildEntryStoreTab(),
                        _buildSpecialStoreTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrameStoreTab() {
    // আপনার এন্ট্রি লিস্টের মতো করেই ফ্রেমের লিস্ট
    final List<Map<String, String>> frameList = [
      {
        "name": "Royal Gold 4 Star",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/frame%20saling/royelframe%20(1).png",
        "price": "7000"
      },
      {
        "name": "Royal Gold",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/frame%20saling/royelframe%20(2).png",
        "price": "20000"
      },
      {
        "name": "Royal 3 Star",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/frame%20saling/royelframe%20(3).png", // যদি লটি হয়
        "price": "8000"
      },
      {
        "name": "Royal 7",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/frame%20saling/royelframe%20(4).png", // যদি লটি হয়
        "price": "9000"
      },
      {
        "name": "Royal 11 Star",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/frame%20saling/royelframe%20(5).png", // যদি লটি হয়
        "price": "10000"
      },
      {
        "name": "Royal 7 Star",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/frame%20saling/royelframe%20(6).png", // যদি লটি হয়
        "price": "11000"
      },
      {
        "name": "Queen Blue",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/framequin.png", // যদি লটি হয়
        "price": "10500"
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12),
      itemCount: frameList.length,
      itemBuilder: (context, index) {
        var item = frameList[index];
        int itemPrice = int.parse(item['price']!);
        String url = item['url']!;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.amber, width: 2), // ফ্রেমের জন্য গোল্ডেন বর্ডার
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: url.endsWith('.json')
                      ? Lottie.network(url, fit: BoxFit.contain)
                      : Image.network(url,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(Icons.portrait,
                              size: 40, color: Colors.amber)),
                ),
              ),
              const SizedBox(height: 8),
              Text(item['name']!,
                  style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              Text("${item['price']} 💎",
                  style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 35,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (diamonds >= itemPrice) {
                      try {
                        DateTime now = DateTime.now();
                        DateTime expiry =
                            now.add(const Duration(days: 15)); // ১৫ দিন মেযাদ

                        WriteBatch batch = FirebaseFirestore.instance.batch();
                        DocumentReference userRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(uIDValue);

                        // ফ্রেমের জন্য ব্যাকপ্যাক সাব-কালেকশন: 'my_frames'
                        DocumentReference backpackRef =
                            userRef.collection('my_frames').doc(item['name']);

                        // ১. ডায়মন্ড কাটা
                        batch.update(userRef, {
                          'diamonds': FieldValue.increment(-itemPrice),
                        });

                        // ২. ব্যাকপ্যাকে ফ্রেম সেভ করা
                        batch.set(backpackRef, {
                          'name': item['name'],
                          'image_url':
                              url, // আপনার ব্যাকপ্যাক কোডে 'image_url' আছে
                          'expiryDate': Timestamp.fromDate(expiry),
                          'isPicked': true,
                        });

                        await batch.commit();

                        setState(() {
                          diamonds -= itemPrice;
                          activeFrameUrl = url; // সাথে সাথে সেট হয়ে যাবে
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              backgroundColor: Colors.green,
                              content:
                                  Text("Frame Bought & Added to Backpack!")),
                        );
                      } catch (e) {
                        debugPrint("Frame Buy Error: $e");
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            backgroundColor: Colors.redAccent,
                            content: Text("Not enough diamonds!")),
                      );
                    }
                  },
                  child: const Text("BUY",
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEntryStoreTab() {
    final List<Map<String, String>> entryList = [
      {
        "name": "Royal Entry 1",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/9994c4424e1097e9ff6c21d70b37b97ac341dd9c/entry%20(1).json",
        "price": "7000"
      },
      {
        "name": "Royal Entry 2",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/entry%20(2).json",
        "price": "8000"
      },
      {
        "name": "Royal Entry 3",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/entry%20(3).json",
        "price": "8000"
      },
      {
        "name": "Royal Entry 4",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/entry%20(4).json",
        "price": "8000"
      },
      {
        "name": "Royal Entry 5",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/entry%20(5).json",
        "price": "5000"
      },
      {
        "name": "Royal Entry 6",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/entry%20(6).json",
        "price": "16000"
      },
      {
        "name": "Royal Entry 7",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/entry%20(7).json",
        "price": "18000"
      },
      {
        "name": "Royal Entry 8",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/entry%20(8).json",
        "price": "15000"
      },
      {
        "name": "Royal Entry 9",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/entry%20(9).json",
        "price": "20000"
      },
      {
        "name": "Royal Entry 10",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/entry%20(10).json",
        "price": "4000"
      },
      {
        "name": "Royal Entry 11",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/entry%20(11).json",
        "price": "9000"
      },
      {
        "name": "Royal Entry 12",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/entry%20(12).json",
        "price": "8000"
      },
      {
        "name": "Royal Entry 13",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/entry%20(13).json",
        "price": "9000"
      },
      {
        "name": "Royal Entry 14",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/entry%20(14).json",
        "price": "11000"
      },
      {
        "name": "Royal Entry 15",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/entry%20(15).json",
        "price": "13000"
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12),
      itemCount: entryList.length,
      itemBuilder: (context, index) {
        var item = entryList[index];
        int itemPrice = int.parse(item['price']!);
        String url = item['url']!;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.cyan, width: 2),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: url.endsWith('.json')
                      ? Lottie.network(url, fit: BoxFit.contain)
                      : Image.network(url,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(
                              Icons.auto_awesome,
                              size: 40,
                              color: Colors.cyan)),
                ),
              ),
              const SizedBox(height: 8),
              Text(item['name']!,
                  style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              Text("${item['price']} 💎",
                  style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 35,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (diamonds >= itemPrice) {
                      try {
                        DateTime now = DateTime.now();
                        DateTime expiry = now.add(const Duration(days: 15));

                        // --- ডায়মন্ড কাটা এবং ব্যাকপ্যাকে পাঠানোর আসল লজিক শুরু ---
                        WriteBatch batch = FirebaseFirestore.instance.batch();
                        DocumentReference userRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(uIDValue);

                        // ব্যাকপ্যাকের জন্য সাব-কালেকশন রেফারেন্স
                        DocumentReference backpackRef =
                            userRef.collection('myEntries').doc(item['name']);

                        // ১. ডায়মন্ড আপডেট
                        batch.update(userRef, {
                          'diamonds': FieldValue.increment(-itemPrice),
                        });

                        // ২. ব্যাকপ্যাকে এন্ট্রি সেভ করা (যাতে পরে ব্যাকপ্যাক থেকে Pick করা যায়)
                        batch.set(backpackRef, {
                          'name': item['name'],
                          'url': url,
                          'expiryDate': Timestamp.fromDate(expiry),
                          'isPicked': true, // কেনার সাথে সাথে পিক হয়ে যাবে
                        });

                        await batch.commit();
                        // --- লজিক শেষ ---

                        setState(() {
                          diamonds -= itemPrice;
                          activeEntryUrl = url;
                        });

                        Navigator.pop(context); // স্টোর বন্ধ করা
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              backgroundColor: Colors.green,
                              content: Text("Bought & Added to Backpack!")),
                        );
                      } catch (e) {
                        debugPrint("Buy Error: $e");
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            backgroundColor: Colors.redAccent,
                            content: Text("Not enough diamonds!")),
                      );
                    }
                  },
                  child: const Text("BUY",
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecialStoreTab() {
    final List<Map<String, String>> specialList = [
      {
        "name": "Ripple Aura",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/Ripple.png",
        "price": "15000",
        "type": "Seat Effect"
      },
      {
        "name": "Full Page Love",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/pageframe/page%20frame%20(1).png",
        "price": "20000",
        "type": "Profile Page"
      },
      {
        "name": "Lovly frame",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/pageframe/page%20frame%20(2).png",
        "price": "22000",
        "type": "Profile Page"
      },
      {
        "name": "frame blu",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/pageframe/page%20frame%20(3).png",
        "price": "23000",
        "type": "Profile Page"
      },
      {
        "name": "red love",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/pageframe/page%20frame%20(3).png",
        "price": "25000",
        "type": "Profile Page"
      },
      {
        "name": "lovly frame",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/pageframe/page%20frame%20(4).png",
        "price": "26000",
        "type": "Profile Page"
      },
      {
        "name": "super frame",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/pageframe/page%20frame%20(5).png",
        "price": "27000",
        "type": "Profile Page"
      },
      {
        "name": "nion love",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/pageframe/page%20frame%20(6).png",
        "price": "28000",
        "type": "Profile Page"
      },
      {
        "name": "jum love",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/pageframe/page%20frame%20(7).png",
        "price": "29000",
        "type": "Profile Page"
      },
      {
        "name": "parpale love",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/pageframe/page%20frame%20(8).png",
        "price": "30000",
        "type": "Profile Page"
      },
      {
        "name": "my frame f",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/pageframe/page%20frame%20(9).png",
        "price": "31000",
        "type": "Profile Page"
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12),
      itemCount: specialList.length,
      itemBuilder: (context, index) {
        var item = specialList[index];

        // ডায়মন্ড এবং প্রাইস হ্যান্ডলিং (int64 এর জন্য নিরাপদ পদ্ধতি)
        int itemPrice = int.parse(item['price']!);
        String url = item['url']!;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.purpleAccent, width: 2),
            boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Column(
            children: [
              // ইমেজ অথবা লটি অ্যানিমেশন প্রিভিউ
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: url.toLowerCase().endsWith('.json')
                      ? Lottie.network(url, fit: BoxFit.contain)
                      : Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image,
                                  color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(item['name']!,
                  style: const TextStyle(
                      color: Colors.purple,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              Text(item['type']!,
                  style: const TextStyle(color: Colors.grey, fontSize: 10)),
              Text("${item['price']} 💎",
                  style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // কিনুন বাটন
              SizedBox(
                width: double.infinity,
                height: 35,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    // int64 ডায়মন্ডকে নিরাপদভাবে ইনটিজারে রূপান্তর
                    int currentDiamonds = 0;
                    try {
                      currentDiamonds = int.parse(diamonds.toString());
                    } catch (e) {
                      currentDiamonds = 0;
                    }

                    if (currentDiamonds >= itemPrice) {
                      try {
                        DateTime expiry =
                            DateTime.now().add(const Duration(days: 30));

                        // Firebase অপারেশন
                        WriteBatch batch = FirebaseFirestore.instance.batch();

                        if (uIDValue == null) return;

                        DocumentReference userRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(uIDValue);

                        DocumentReference backpackRef =
                            userRef.collection('my_special').doc(item['name']);

                        // ডায়মন্ড কমানো এবং আইটেম যোগ করা
                        batch.update(userRef,
                            {'diamonds': FieldValue.increment(-itemPrice)});
                        batch.set(backpackRef, {
                          'name': item['name'],
                          'image_url': url,
                          'type': item['type'],
                          'expiryDate': Timestamp.fromDate(expiry),
                          'isPicked': true, // কেনার পর অটোমেটিক সিলেক্টেড থাকবে
                        });

                        await batch.commit();

                        // লোকাল স্টেট আপডেট
                        setState(() {
                          diamonds = currentDiamonds - itemPrice;
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text("অভিনন্দন! আইটেমটি কেনা হয়েছে।")));
                      } catch (e) {
                        print("Purchase Error: $e");
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                "কিছু একটা সমস্যা হয়েছে! পরে চেষ্টা করুন।")));
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("আপনার যথেষ্ট ডায়মন্ড নেই!"),
                        backgroundColor: Colors.redAccent,
                      ));
                    }
                  },
                  child: const Text("BUY",
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ২. ব্যাকপ্যাক ওপেন করার ফাংশন
  void _openBackpack() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent, // গ্রেডিয়েন্ট দেখানোর জন্য স্বচ্ছ রাখা হয়েছে
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => DefaultTabController(
        length: 4,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            // প্রিমিয়াম সেই আকাশী নীল গ্রেডিয়েন্ট
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.lightBlue.shade200,
                Colors.blue.shade50,
                Colors.white,
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: Stack(
            children: [
              // ব্যাকগ্রাউন্ডে তারার ঝিকিমিকি ইফেক্ট
              ...List.generate(
                  20,
                  (index) => Positioned(
                        top: (index * 40.0) % 450,
                        left: (index * 65.0) % 380,
                        child: Icon(
                          Icons.star,
                          size: index % 3 == 0 ? 14 : 8,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      )),

              Column(
                children: [
                  const SizedBox(height: 12),
                  // ড্র্যাগ হ্যান্ডেল
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ট্যাব বার ডিজাইন
                  TabBar(
                    isScrollable: true,
                    indicatorColor:
                        Colors.amber, // প্রিমিয়াম লুকের জন্য অ্যাম্বার কালার
                    labelColor: Colors.blueAccent,
                    unselectedLabelColor: Colors.black45,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    tabs: const [
                      Tab(text: "My Cards"),
                      Tab(text: "My Frames"),
                      Tab(text: "Entry Effects"),
                      Tab(text: "My Special"),
                    ],
                  ),

                  // ট্যাব কন্টেন্ট
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildMyCardsTab(),
                        _buildMyFramesTab(),
                        _buildMyEntriesTab(),
                        _buildMySpecialTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ৩. স্টোর কার্ড কেনার ট্যাব (uIDValue ব্যবহার করা হয়েছে)
  Widget _buildStoreCardTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/premiumcard.png",
                    height: 160,
                    width: 240,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Pagla Premium Card",
                  style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Bonus: Premium Frame (10 Days Free!)",
                  style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const Text(
                  "Cost: 6k 💎",
                  style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 5,
                    ),
                    onPressed: () async {
                      if (diamonds >= 6000) {
                        try {
                          DateTime now = DateTime.now();
                          DateTime cardExpiry =
                              now.add(const Duration(days: 30));
                          DateTime frameExpiry =
                              now.add(const Duration(days: 10));

                          const String frameUrl =
                              "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/premiumframe.png";
                          // Firebase আপডেট লজিক
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uIDValue)
                              .update({
                            'diamonds': FieldValue.increment(-6000),
                            'hasPremiumCard': true,
                            'premiumUntil': Timestamp.fromDate(cardExpiry),
                            'hasFreeFrame': true,
                            'frameUntil': Timestamp.fromDate(frameExpiry),
                            'activeFrameUrl':
                                "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/premiumframe.png",
                          });

                          setState(() {
                            diamonds -= 6000;
                            hasPremiumCard = true;
                            premiumUntilDate = cardExpiry;
                            frameUntilDate = frameExpiry;
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.green,
                              content:
                                  Text("Success! Card & Free Frame Added."),
                            ),
                          );
                        } catch (e) {
                          debugPrint("Error: $e");
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.redAccent,
                            content: Text("Insufficient diamonds!"),
                          ),
                        );
                      }
                    },
                    child: const Text("BUY NOW",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMyCardsTab() {
    if (!hasPremiumCard) {
      return const Center(
          child:
              Text("No Cards Found", style: TextStyle(color: Colors.white54)));
    }
    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        ListTile(
          leading: Image.network(
              "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/premiumcard.png",
              width: 50),
          title: const Text("Pagla Premium Card",
              style: TextStyle(color: Colors.white)),
          subtitle: Text(
              "Expires: ${premiumUntilDate?.toLocal().toString().split(' ')[0]}",
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          trailing: const Icon(Icons.check_circle, color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildMyEntriesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uIDValue)
          .collection('myEntries')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var myEntries = snapshot.data!.docs;
        if (myEntries.isEmpty) {
          return const Center(
            child: Text("আপনার কোনো এন্ট্রি ইফেক্ট নেই",
                style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75, // কার্ডের সাইজ ঠিক রাখার জন্য
              crossAxisSpacing: 10,
              mainAxisSpacing: 10),
          itemCount: myEntries.length,
          itemBuilder: (context, index) {
            var data = myEntries[index].data() as Map<String, dynamic>;
            String url = data['url'] ?? "";
            String name = data['name'] ?? "Unknown";
            bool isPicked = activeEntryUrl == url;

            // এক্সপেয়ারি টাইম ক্যালকুলেশন
            Timestamp? expiryTimestamp = data['expiryDate'] as Timestamp?;
            DateTime expiryDate = expiryTimestamp?.toDate() ?? DateTime.now();
            Duration remaining = expiryDate.difference(DateTime.now());

            // সময় দেখানোর লজিক (দিন বা ঘণ্টা)
            String timeText = remaining.inDays > 0
                ? "${remaining.inDays} days left"
                : "${remaining.inHours} hours left";

            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    color:
                        isPicked ? Colors.orangeAccent : Colors.blue.shade100,
                    width: 2),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // এন্ট্রি প্রিভিউ (Lottie/Image)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: url.endsWith('.json')
                          ? Lottie.network(url, fit: BoxFit.contain)
                          : Image.network(url, fit: BoxFit.contain),
                    ),
                  ),

                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),

                  // এক্সপেয়ারি ওয়ার্নিং
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(timeText,
                        style: TextStyle(
                            color: remaining.inDays < 2
                                ? Colors.red
                                : Colors.blueGrey,
                            fontSize: 10,
                            fontWeight: FontWeight.w500)),
                  ),

                  // Pick/Unpick বাটন
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 10, left: 8, right: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isPicked ? Colors.redAccent : Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          String newUrl = isPicked ? "" : url;
                          bool newStatus = !isPicked;

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uIDValue)
                              .update({
                            'activeEntryUrl': newUrl,
                            'hasEntryEffect': newStatus,
                          });

                          setState(() {
                            activeEntryUrl = newUrl;
                            hasEntryEffect = newStatus;
                          });
                        },
                        child: Text(isPicked ? "Unpick" : "Pick",
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMySpecialTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uIDValue)
          .collection('my_special')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var mySpecialItems = snapshot.data!.docs;
        if (mySpecialItems.isEmpty) {
          return const Center(
            child: Text("No have any special",
                style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.70,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10),
          itemCount: mySpecialItems.length,
          itemBuilder: (context, index) {
            var data = mySpecialItems[index].data() as Map<String, dynamic>;
            String url = data['image_url'] ?? "";
            String name = data['name'] ?? "Special Item";
            String type = data['type'] ?? "Effect";

            // 🔥 পিকড অবস্থা চেক করার লজিক
            bool isPicked = (activeSpecialUrl == url);

            Timestamp? expiryTimestamp = data['expiryDate'] as Timestamp?;
            DateTime expiryDate = expiryTimestamp?.toDate() ?? DateTime.now();
            Duration remaining = expiryDate.difference(DateTime.now());

            String timeText = remaining.inDays > 0
                ? "${remaining.inDays} days left"
                : "${remaining.inHours} hours left";

            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    color:
                        isPicked ? Colors.purpleAccent : Colors.purple.shade50,
                    width: 2),
                boxShadow: [
                  const BoxShadow(color: Colors.black12, blurRadius: 5)
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: url.toLowerCase().endsWith('.json')
                          ? Lottie.network(url, fit: BoxFit.contain)
                          : Image.network(
                              url,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image,
                                      color: Colors.grey),
                            ),
                    ),
                  ),
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.purple)),
                  Text(type,
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(timeText,
                        style: TextStyle(
                            color: remaining.inDays < 2
                                ? Colors.red
                                : Colors.blueGrey,
                            fontSize: 10,
                            fontWeight: FontWeight.w500)),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 10, left: 8, right: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isPicked ? Colors.redAccent : Colors.purpleAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          // 🔄 পিক করলে পুরাতন রিং/ইউআরএল মুছে নতুনটা দিয়ে রিপ্লেস হবে
                          String newUrl = isPicked ? "" : url;
                          bool newStatus = !isPicked;

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uIDValue)
                              .update({
                            'activeSpecialUrl': newUrl,
                            'hasSpecialEffect': newStatus,
                            // এক্সট্রা ট্র্যাক রাখার জন্য রিং এর নামও আপডেট করে দেওয়া হলো
                            'activeSpecialName': isPicked ? "" : name,
                          });

                          setState(() {
                            activeSpecialUrl = newUrl;
                            hasSpecialEffect = newStatus;
                          });

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isPicked
                                    ? "$name Unpicked successfully!"
                                    : "$name Picked! Old item replaced successfully! 💍✨"),
                                backgroundColor:
                                    isPicked ? Colors.orange : Colors.purple,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        child: Text(isPicked ? "Unpick" : "Pick",
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyFramesTab() {
    int currentLevel = getVipLevel();

    // ১. কেনা ফ্রেমগুলোর জন্য স্ট্রিম বিল্ডার
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uIDValue) // আপনার ইউজার আইডি ভেরিয়েবল
          .collection('my_frames')
          .snapshots(),
      builder: (context, snapshot) {
        // কেনা ফ্রেমের লিস্ট তৈরি
        List<Map<String, String>> myAvailableFrames = [];

        // ২. প্রিমিয়াম কার্ডের ফ্রেম চেক (আপনার আগের লজিক)
        const String premiumFrameUrl =
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/premiumframe.png";
        bool isPremiumExpired =
            frameUntilDate != null && frameUntilDate!.isBefore(DateTime.now());

        if (hasFreeFrame && !isPremiumExpired) {
          myAvailableFrames.add({
            "name": "Premium Frame",
            "url": premiumFrameUrl,
            "expiry": frameUntilDate != null
                ? "${frameUntilDate!.day}/${frameUntilDate!.month}/${frameUntilDate!.year}"
                : "N/A"
          });
        }

        // ৩. VIP লেভেল অনুযায়ী ফ্রেম চেক (আপনার আগের লজিক)
        if (currentLevel >= 1 && currentLevel <= 8) {
          String vipFrameUrl =
              "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/vipframe/framevip%20($currentLevel).png";
          String vipExpiry = premiumUntilDate != null
              ? "${premiumUntilDate!.day}/${premiumUntilDate!.month}/${premiumUntilDate!.year}"
              : "Permanent";
          myAvailableFrames.add({
            "name": "VIP Level $currentLevel",
            "url": vipFrameUrl,
            "expiry": vipExpiry
          });
        }

        // ৪. 🔥 কেনা ফ্রেমগুলো লিস্টে যোগ করা
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;

            // ডাটাবেজ থেকে expiryDate নেওয়া
            dynamic expiryData = data['expiryDate'];
            String expiryString = "Permanent";

            // যদি ডাটাবেজে তারিখ থাকে তবে সেটি কনভার্ট করা
            if (expiryData != null && expiryData is Timestamp) {
              DateTime date = expiryData.toDate();
              // তারিখটিকে আপনার পছন্দমতো ফরম্যাটে সাজানো (দিন/মাস/বছর)
              expiryString = "${date.day}/${date.month}/${date.year}";
            }

            myAvailableFrames.add({
              "name": data['name']?.toString() ?? "Purchased Frame",
              "url": data['image_url']?.toString() ??
                  "", // স্টোর ট্যাবে আপনি 'image_url' হিসেবে সেভ করছেন
              "expiry": expiryString,
            });
          }
        }

        if (myAvailableFrames.isEmpty) {
          return const Center(
              child: Text("No Active Frames",
                  style: TextStyle(color: Colors.white54)));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(15),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10),
          itemCount: myAvailableFrames.length,
          itemBuilder: (context, index) {
            String currentUrl = myAvailableFrames[index]["url"]!;
            String currentName = myAvailableFrames[index]["name"]!;
            String expiryDate = myAvailableFrames[index]["expiry"]!;
            bool isPicked = activeFrameUrl == currentUrl;

            return Container(
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(15),
                  border: isPicked
                      ? Border.all(color: Colors.amber, width: 2)
                      : null),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  // লটি বা ইমেজ চেনার লজিক
                  SizedBox(
                    height: 65,
                    child: currentUrl.contains('.json')
                        ? Lottie.network(currentUrl)
                        : Image.network(currentUrl),
                  ),
                  const SizedBox(height: 8),
                  Text(currentName,
                      style: const TextStyle(
                          color: Color.fromARGB(252, 66, 191, 244),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("Expiry: $expiryDate",
                      style: const TextStyle(
                          color: Colors.orangeAccent, fontSize: 10)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isPicked ? Colors.redAccent : Colors.blueAccent,
                        minimumSize: const Size(80, 30),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed: () async {
                      String newFrame = isPicked ? "" : currentUrl;
                      try {
                        // ইউজারের মেইন ডাটাতে activeFrameUrl বা activeFrame আপডেট করুন
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uIDValue)
                            .update({
                          'activeFrameUrl': newFrame
                        }); // নাম মিলিয়ে নিন (activeFrameUrl/activeFrame)

                        setState(() {
                          activeFrameUrl = newFrame;
                        });
                      } catch (e) {
                        debugPrint("Update Error: $e");
                      }
                    },
                    child: Text(isPicked ? "UNPICK" : "PICK",
                        style: const TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String myId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final String targetUserId = widget.userId ?? myId;
    final bool isMe = myId == targetUserId;

    // পরবর্তী লেভেলের টার্গেট বের করার লজিক
    int getNextLevelTarget(int currentXP) {
      if (currentXP < 2500) return 2500;
      if (currentXP < 5000) return 5000;
      if (currentXP < 9000) return 9000;
      if (currentXP < 13000) return 13000;
      if (currentXP < 20000) return 20000;
      if (currentXP < 25000) return 25000;
      if (currentXP < 30000) return 30000;
      return 35000; // VIP 8 এর টার্গেট
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Scaffold(body: Center(child: Text("Error!")));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0D1A),
            body: Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent)),
          );
        }

        Map<String, dynamic> userData = {};
        if (snapshot.hasData && snapshot.data!.exists) {
          userData = snapshot.data!.data() as Map<String, dynamic>;

          userName = userData['name'] ?? "User";
          uIDValue = (userData['uID'] ?? userData['uID'] ?? "N/A").toString();
          diamonds = userData['diamonds'] ?? 0;
          xp = userData['vip_xp'] ?? 0;
          vipExpiry = userData['vipExpiry'] ?? 0;
          userImageURL = userData['profilePic'] ?? "";
          gender = userData['gender'] ?? "Unfixed";
          hasPremiumCard = userData['hasPremium'] ?? false;
          followers = userData['followers'] ?? 0;
          following = userData['following'] ?? 0;
        }

        // ভিআইপি লেভেল এবং পরবর্তী টার্গেট ক্যালকুলেশন
        int vipLevel = getVipLevel();
        int nextTarget = getNextLevelTarget(xp);
        double progressValue = (xp / nextTarget).clamp(0.0, 1.0);

        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: const Color(0xFF0F0F1E),
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(125, 4, 2, 58),
            elevation: 0,
            leading: isMe
                ? Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Row(children: [
                      const Text("💎", style: TextStyle(fontSize: 16)),
                      Text(" $diamonds",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12))
                    ]),
                  )
                : const BackButton(color: Colors.white),
            actions: [
              if (isMe)
                IconButton(
                    icon: const Icon(Icons.settings,
                        color: Color.fromARGB(255, 90, 191, 245)),
                    onPressed: _openSettings)
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: RainbowCascadePainter(),
                ),
              ),

              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: kToolbarHeight + 60),

                    // 🔥 পুরাতন প্রোফাইল সেকশনের জায়গায় ম্যারেজ লজিক ইন্টিগ্রেশন (১০০% অটোমেটিক লাইভ ফ্রেম ফিক্স)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('marriages')
                          .doc(targetUserId)
                          .snapshots(),
                      builder: (context, marriageSnapshot) {
                        // যদি ইউজার বিবাহিত হয় (marriages কালেকশনে ডাটা থাকে)
                        if (marriageSnapshot.hasData &&
                            marriageSnapshot.data!.exists) {
                          var marriageData = marriageSnapshot.data!.data()
                              as Map<String, dynamic>;

                          // 🔍 ১. ডাটাবেজ থেকে পার্টনারের ইউজার আইডি খুঁজে বের করা হচ্ছে
                          String partnerUid = marriageData['partnerUid'] ??
                              marriageData['partnerId'] ??
                              marriageData['partner_id'] ??
                              '';

                          // 🔄 ২. পার্টনারের আইডি ব্যবহার করে সরাসরি 'users' কালেকশন থেকে তার রিয়েল-টাইম ফ্রেম রিড করা হচ্ছে
                          return StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(partnerUid)
                                .snapshots(),
                            builder: (context, userSnapshot) {
                              String livePartnerFrame = '';

                              // পার্টনারের ইউজার ডক থেকে তার একদম কারেন্ট একটিভ ফ্রেমের লিংক নেওয়া হচ্ছে
                              if (userSnapshot.hasData &&
                                  userSnapshot.data!.exists) {
                                var userData = userSnapshot.data!.data()
                                    as Map<String, dynamic>;
                                livePartnerFrame = userData['activeFrameUrl'] ??
                                    userData['activeFrame'] ??
                                    '';
                              }

                              // ডাটাবেজের ফিল্ড ম্যাপ করা হচ্ছে যাতে ফ্লেক্সিবল থাকে
                              String partnerImg =
                                  marriageData['partnerProfilePic'] ??
                                      marriageData['partnerImage'] ??
                                      '';
                              String finalPartnerFrame =
                                  livePartnerFrame.trim().isNotEmpty
                                      ? livePartnerFrame
                                      : (marriageData['activeFrameUrl'] ??
                                          marriageData['partnerFrameUrl'] ??
                                          '');

                              // 🔍 [প্রিন্ট ১]: বিবাহিত প্রোফাইলের সমস্ত ইমেজ লিংক টেস্ট
                              debugPrint(
                                  "====== 💍 [MARRIAGE LIVE URLS] ======");
                              debugPrint("My Image: '$userImageURL'");
                              debugPrint("My Frame: '$activeFrameUrl'");
                              debugPrint("Partner Image: '$partnerImg'");
                              debugPrint("Partner Frame: '$finalPartnerFrame'");
                              debugPrint(
                                  "Ring Icon: '${marriageData['ringIconUrl'] ?? marriageData['ringIcon']}'");

                              Map<String, dynamic> formattedMarriageData = {
                                'ringIcon': marriageData['ringIconUrl'] ??
                                    marriageData['ringIcon'],
                                'partnerImage': partnerImg,
                                // 🔥 পার্টনারের ফ্রেম এখন সরাসরি 'users' কালেকশন থেকে লাইভ আসছে, তাই কখনো মিস হবে না
                                'partnerFrameUrl': finalPartnerFrame,
                              };

                              return Center(
                                child: _buildMarriageHeader(
                                  context, // ১. বটমশিট ওপেন করার জন্য context পাস করা হলো
                                  formattedMarriageData, // ২. ফরম্যাটেড ডাটা ম্যাপ
                                  userImageURL, // ৩. আপনার নিজের ইমেজ
                                  activeFrameUrl, // ৪. আপনার নিজের একটিভ ফ্রেম
                                  marriageData, // ৫. ফায়ারস্টোরের আসল র-ডক (বিয়ের তারিখ ও ছবির ডেটার জন্য)
                                ),
                              );
                            },
                          );
                        }

                        // 👤 যদি সিঙ্গেল হয় (কোনো পার্টনার না থাকে), তবে শুধু নিজের পুরাতন প্রোফাইল পিকচারটি দেখাব

                        // 🔍 [প্রিন্ট ২]: সিঙ্গেল প্রোফাইলের সমস্ত ইমেজ লিংক টেস্ট
                        debugPrint("====== 👤 [SINGLE USER URLS] ======");
                        debugPrint("My Image: '$userImageURL'");
                        debugPrint("My Frame: '$activeFrameUrl'");

                        return Center(
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: isMe ? _pickProfileImage : null,
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey[900],
                                  backgroundImage: (userImageURL.isNotEmpty &&
                                          !userImageURL.startsWith('file:'))
                                      ? NetworkImage(userImageURL)
                                      : null,
                                  child: (userImageURL.isEmpty ||
                                          userImageURL.startsWith('file:'))
                                      ? const Icon(Icons.person,
                                          size: 50, color: Colors.white)
                                      : null,
                                ),
                              ),
                              if (activeFrameUrl.isNotEmpty &&
                                  !activeFrameUrl.startsWith('file:'))
                                IgnorePointer(
                                  child: SizedBox(
                                    width: 0,
                                    height: 0,
                                    child: OverflowBox(
                                      minWidth: 193,
                                      maxWidth: 193,
                                      minHeight: 185,
                                      maxHeight: 185,
                                      child: activeFrameUrl.contains('.json')
                                          ? Transform.scale(
                                              scale: 0.9,
                                              child: Lottie.network(
                                                activeFrameUrl,
                                                fit: BoxFit.contain,
                                                errorBuilder: (c, e, s) =>
                                                    const SizedBox(),
                                              ),
                                            )
                                          : Image.network(
                                              activeFrameUrl,
                                              fit: BoxFit.contain,
                                              errorBuilder: (c, e, s) =>
                                                  const SizedBox(),
                                            ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 15),

                    // --- নামের গ্লাস বর্ডার বক্স ---
                    GestureDetector(
                      onTap: isMe ? () => _editName(userData) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purpleAccent.withOpacity(0.15),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                    // --- নামের গ্লাস বর্ডার বক্স শেষ ---

                    Text("User ID: $uIDValue",
                        style: const TextStyle(
                            color: Color.fromARGB(255, 4, 189, 251),
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),

                    // VIP এবং ডাইনামিক XP প্রগ্রেস বার সেকশন
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (vipLevel > 0 &&
                                  getVipBadge(vipLevel).toString().isNotEmpty &&
                                  !getVipBadge(vipLevel)
                                      .toString()
                                      .startsWith('file:'))
                                Image.network(getVipBadge(vipLevel),
                                    width: 45,
                                    height: 45,
                                    errorBuilder: (c, e, s) => const Icon(
                                        Icons.stars_rounded,
                                        color: Colors.white24,
                                        size: 40))
                              else
                                const Icon(Icons.stars_rounded,
                                    color: Colors.white24, size: 40),
                              const SizedBox(width: 15),
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      vipLevel == 0
                                          ? "Target VIP 1 (XP: $xp / $nextTarget)"
                                          : "VIP Level $vipLevel (XP: $xp / $nextTarget)",
                                      style: const TextStyle(
                                          color: Colors.amber,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  // 🔥 [আগুনের মতো জ্বলজ্বলে ডাইনামিক প্রগ্রেস বার]:
                                  // Shimmer দিয়ে আগুনের তরঙ্গ এবং মাথায় আলাদা আগুনের শিখা
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final double maxWidth =
                                          constraints.maxWidth;
                                      final double barWidth =
                                          maxWidth * progressValue;

                                      return Container(
                                        height:
                                            12, // সামান্য মোটা করা হলো যাতে ইফেক্টটি ভালো দেখা যায় ভাই
                                        width: maxWidth,
                                        decoration: BoxDecoration(
                                          color: Colors
                                              .white10, // বারের ব্যাকগ্রাউন্ড
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              width: 1), // বারের ধারালো বর্ডার
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Stack(
                                            children: [
                                              // ১. মূল গোল্ডেন এবং আগুনের রঙের তরঙ্গ (Shimmer Gradient)
                                              if (barWidth > 0)
                                                Positioned(
                                                  left: 0,
                                                  top: 0,
                                                  bottom: 0,
                                                  width: barWidth,
                                                  child: Shimmer.fromColors(
                                                    baseColor: const Color(
                                                        0xFFFFD700), // মূল গোল্ডেন কালার
                                                    highlightColor: const Color(
                                                        0xFFFF4500), // আগুনের তরঙ্গ (Orange-Red)
                                                    period: const Duration(
                                                        milliseconds:
                                                            1500), // অ্যানিমেশন স্পিড
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        // গ্রেডিয়েন্ট দেওয়া হলো যাতে শুরু থেকে মাথায় কালার চেঞ্জ হয়
                                                        gradient:
                                                            LinearGradient(
                                                          colors: const [
                                                            Color(
                                                                0xFFFFC107), // শুরু গোল্ডেন
                                                            Color(
                                                                0xFFFFD700), // মাছ গোল্ডেন
                                                          ],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              // ২. মাথায় সেই জ্বলজ্বলে আগুনের শিখা বা বিন্দু (The Glowing Fire Head)
                                              // এটি একদম মাথায় স্থির থেকে জ্বলজ্বল করবে
                                              if (barWidth > 0)
                                                Positioned(
                                                  left: barWidth -
                                                      10, // মাথার বিন্দুটি ঠিক প্রগ্রেসের শেষ মাথায় বসবে
                                                  top: 0,
                                                  bottom: 0,
                                                  child: Center(
                                                    child: Shimmer.fromColors(
                                                      baseColor: const Color(
                                                          0xFFFF4500), // আগুনের বিন্দুর বেস (Orange-Red)
                                                      highlightColor: Colors
                                                          .yellowAccent, // বিন্দুর জ্বলজ্বল (Yellow)
                                                      period: const Duration(
                                                          milliseconds:
                                                              500), // দ্রুত জ্বলজ্বল
                                                      child: Container(
                                                        width: 10,
                                                        height: 10,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Colors.orange,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .redAccent
                                                                  .withOpacity(
                                                                      0.8),
                                                              blurRadius: 6,
                                                              spreadRadius:
                                                                  2, // বিন্দুর চারপাশে আগুনের আভা
                                                            ),
                                                            BoxShadow(
                                                              color: Colors
                                                                  .orange
                                                                  .withOpacity(
                                                                      0.6),
                                                              blurRadius: 10,
                                                              spreadRadius: 4,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              )),
                              const SizedBox(width: 15),
                              if (hasPremiumCard &&
                                  (premiumBadgeUrl ?? '')
                                      .toString()
                                      .isNotEmpty &&
                                  !premiumBadgeUrl
                                      .toString()
                                      .startsWith('file:'))
                                Image.network(premiumBadgeUrl,
                                    width: 45,
                                    height: 45,
                                    errorBuilder: (c, e, s) =>
                                        const SizedBox(width: 45))
                              else
                                const SizedBox(width: 45),
                            ])),
                    const SizedBox(height: 15),

// 🇧🇩 [বাংলা মার্ক]: ValueKey যোগ করা হলো—ডাটা আসার সাথে সাথে স্ক্রিন রিয়েল-টাইমে আপডেট হবে ভাই!
                    ActiveLevelBar(
                      key: ValueKey(
                          totalActiveXp), // 👈 এই কি (Key) ভ্যালু পরিবর্তনের সাথে সাথে বার সচল করবে
                      totalActiveXp: totalActiveXp,
                    ),
                    const SizedBox(height: 5),

                    GiftLevelBar(
                        totalGiftXp:
                            totalGiftXp), // 👈 userData['totalGiftXp'] কেটে শুধু totalGiftXp

                    const SizedBox(height: 25),

                    // Followers & Following
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _buildStat("Followers", followers, targetUserId, context),
                      const SizedBox(width: 25),
                      if (!isMe) ...[
                        ElevatedButton(
                          onPressed: _toggleFollow,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing
                                  ? Colors.blueGrey
                                  : Colors.pinkAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20))),
                          child: Text(isFollowing ? "Friend" : "Follow",
                              style: const TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.mail, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                        receiverId: targetUserId,
                                        receiverName: userName)));
                          },
                        ),
                      ] else
                        const SizedBox(
                            width: 80,
                            child: Center(
                                child: Text("MY PROFILE",
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 10)))),
                      const SizedBox(width: 25),
                      _buildStat("Following", following, targetUserId, context),
                    ]),

                    const SizedBox(height: 35),

                    // 💎 অ্যাকশন বক্সগুলো (ডায়মন্ড, প্রিমিয়াম, ব্যাকপ্যাক) শুধুমাত্র নিজের প্রোফাইলে দেখাবে
                    if (isMe) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionBox("Diamond", Icons.diamond, Colors.cyan,
                              () => _openDiamondStore(userData)),
                          _buildActionBox("Premium", Icons.card_membership,
                              Colors.purple, _openPremiumStore),
                          _buildActionBox("Backpack", Icons.backpack,
                              Colors.orange, _openBackpack),
                        ],
                      ),
                      const SizedBox(height: 25),
                    ],

                    const SizedBox(height: 30),

                    // ❤️ সোলমেট সেকশন
                    _buildSoulmateSection(),

                    const SizedBox(height: 30),
                  ], // Column এর children শেষ
                ), // Column শেষ
              ), // SingleChildScrollView শেষ

              // --- ফুল পেজ ফ্রেম ---
              // 🔍 [প্রিন্ট ৩]: ব্যাকগ্রাউন্ড ফুল পেজ ফ্রেমের লিংক টেস্ট
              () {
                debugPrint("====== 🖼️ [FULL PAGE FRAME URL] ======");
                debugPrint("Active Special URL: '$activeSpecialUrl'");
                return const SizedBox();
              }(),
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    decoration: (activeSpecialUrl != null &&
                            activeSpecialUrl.toString().isNotEmpty &&
                            !activeSpecialUrl.toString().startsWith('file:'))
                        ? BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(activeSpecialUrl),
                              fit: BoxFit.fill,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ], // Stack এর children শেষ
          ), // Stack শেষ (বডি শেষ)
        ); // Scaffold শেষ
      }, // StreamBuilder builder শেষ
    ); // StreamBuilder শেষ
  }

  // ফলোয়ার/ফলোয়িং লিস্ট সিকিউরিটি লজিক
  Widget _buildStat(String label, int value, String uID, BuildContext context) {
    final String myId = FirebaseAuth.instance.currentUser?.uid ?? "";
    return GestureDetector(
      onTap: () {
        if (myId == uID) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      UserListScreen(title: label, userId: uID)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text("You not possible to see $label others parson List!"),
              backgroundColor: Colors.redAccent));
        }
      },
      child: Column(children: [
        Text(value.toString(),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }

// ✅ ২. অ্যাকশন বক্স উইজেট (পুরানো ডিজাইন সহ)
  Widget _buildActionBox(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          width: 100,
          height: 85,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.5))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 5),
            Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 11))
          ])),
    );
  }

// ✅ ৩. প্রিয়জন (Soulmate) ৬ স্লট মেইন উইজেট
  Widget _buildSoulmateSection() {
    // 🔥 সমাধান: লাল দাগ দূর করতে widget.userData কেটে সরাসরি 'uIDValue' এবং ব্যাকআপ চেক রাখা হলো
    String currentId = uIDValue.toString().trim();

    // একদম শেষে কোনো কারণে uIDValue ফাঁকা থাকলে কারেন্ট লগইন করা ইউজারের লম্বা UID ব্যাকআপ হিসেবে নেবে
    if (currentId.isEmpty) {
      currentId = FirebaseAuth.instance.currentUser?.uid ?? '';
    }

    // গิตহাবের সেই সঠিক পারমানেন্ট লিঙ্ক
    const String soulmateCardUrl =
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/soulmatecard.png";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Text("𝐇𝐚𝐫𝐭—̳͟͞͞💗(𝐒𝐨𝐮𝐥𝐦𝐚𝐭𝐞𝐬)",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ),
        StreamBuilder<QuerySnapshot>(
          // 🔥 মালিকের আইডি (ownerId) এখন আপনার প্রোফাইলের ৬ ডিজিটের আসল uID দিয়ে ডেটা লোড করবে
          stream: FirebaseFirestore.instance
              .collection('soulmates')
              .where('ownerId', isEqualTo: currentId)
              .limit(6)
              .snapshots(),
          builder: (context, snapshot) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // ২টা করে সারিতে থাকবে
                childAspectRatio: 0.82,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 6, // সবসময় ৬টি ঘর থাকবে
              itemBuilder: (context, index) {
                var dataDoc =
                    (snapshot.hasData && snapshot.data!.docs.length > index)
                        ? snapshot.data!.docs[index]
                        : null;
                var data = dataDoc?.data() as Map<String, dynamic>?;

                return GestureDetector(
                  onLongPress: dataDoc != null
                      ? () => _showBreakupDialog(data!['partnerId'])
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      image: const DecorationImage(
                        image: NetworkImage(soulmateCardUrl),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: data != null
                        ? _buildFilledSoulmate(data)
                        : _buildEmptySoulmate(),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

// 🔥 কার্ড যখন একটিভ (ব্যাকগ্রাউন্ড লিংকের উপরে ছবি, নাম ও লেভেল শো করার জন্য সম্পূর্ণ উইজেট)
  Widget _buildFilledSoulmate(Map<String, dynamic> data) {
    // লেভেল লজিক: প্রতি ৫০০০ ডাইমন্ডে ১ লেভেল (ম্যাক্স ৫০)
    int totalGift = data['totalGift'] ?? 0;
    int level = (totalGift / 5000).floor().clamp(1, 50);

    return GestureDetector(
      onTap: () {
        // 🚀 আপনার পাস করা 'data' ম্যাপটি হুবহু নতুন পেজে চলে যাবে, ডাটার রাস্তা একদম সেম থাকবে
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SoulmateDetailPage(soulmateData: data),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ১. কার্ডের ভেতরের উপরের ডানদিকের লেভেল ব্যাজ
          Align(
            alignment: Alignment.topRight,
            child: Container(
              margin: const EdgeInsets.only(right: 12, top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Lv.$level",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const Spacer(),

          // ২. পার্টনারের গোল প্রোফাইল ছবি (গোল্ডেন বর্ডার সহ ব্যাকগ্রাউন্ডের উপর সেট)
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 5,
                  spreadRadius: 1,
                )
              ],
              image: DecorationImage(
                image: NetworkImage(data['partnerImage'] ?? ""),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ৩. পার্টনারের নাম (ডিজাইনের ওপর পরিষ্কার দেখার জন্য শ্যাডো ও বোল্ড করা হয়েছে)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              data['partnerName'] ?? "Unknown",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black87,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 6),

          // ৪. সোলমেট ট্যাগ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 0.5),
            ),
            child: const Text(
              "Soulmate",
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 15),
        ],
      ),
    );
  }

// 🔒 কার্ড যখন খালি থাকবে (লক আইকন শো করবে)
  Widget _buildEmptySoulmate() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            color: Colors.white.withOpacity(0.25),
            size: 28,
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.add,
            color: Colors.white.withOpacity(0.2),
            size: 18,
          ),
        ],
      ),
    );
  }

// ✅ রিলেশনশিপ ব্রেকআপ ডায়ালগ (পুরাতন লজিক অক্ষুণ্ণ রাখা হলো)
  void _showBreakupDialog(String partnerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Sure end relationship ?",
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text("End relationship need 1500 daimond",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                String response =
                    await SoulmateService().breakRelation(partnerId);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(response),
                    backgroundColor: Colors.pinkAccent));
              },
              child:
                  const Text("Yes", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

// ✅ ৫. প্রিমিয়াম ম্যারেজ হেডার (চারপাশে সমান গোল ফ্রেম সাইজ কন্ট্রোল ১০০% ফিক্সড)
  Widget _buildMarriageHeader(BuildContext context, Map<String, dynamic> data,
      String myImg, String myFrame, Map<String, dynamic> rawMarriageDoc) {
    String ringIconUrl = data['ringIcon'] ??
        data['ringIconUrl'] ??
        "https://i.ibb.co/ring-sample.png";
    String partnerImg = data['partnerImage'] ?? data['partnerProfilePic'] ?? '';
    String partnerFrame = data['partnerFrameUrl'] ??
        data['activeFrameUrl'] ??
        data['partnerFrame'] ??
        data['activeFrame'] ??
        '';

    double avatarRadius = 45; // ছবির ব্যাসার্ধ

    // 🔥 [১ নম্বর কন্ট্রোল] লত্তি (.json) ফ্রেমের সাইজ কম-বেশি করার অপশন
    double lottieMultiplier = 3.1;

    // 🔥 [২ নম্বর কন্ট্রোল] সাধারণ ইমেজ (PNG/JPG) ফ্রেমের সাইজ কম-বেশি করার অপশন
    // এটি পরিবর্তন করলে ইমেজ ফ্রেম একদম সমান গোল হয়ে বড় বা ছোট হবে, লম্বা হবে না!
    double imageMultiplier = 2.8;

    // বর্তমান ইউজারের ফ্রেমের টাইপ অনুযায়ী ডায়নামিক সাইজ নির্ধারণ
    bool isMyFrameLottie = myFrame.contains('.json');
    double myFrameSize =
        avatarRadius * (isMyFrameLottie ? lottieMultiplier : imageMultiplier);

    // পার্টনারের ফ্রেমের টাইপ অনুযায়ী ডায়নামিক সাইজ নির্ধারণ
    bool isPartnerFrameLottie = partnerFrame.contains('.json');
    double partnerFrameSize = avatarRadius *
        (isPartnerFrameLottie ? lottieMultiplier : imageMultiplier);

    // 🔥 [৩ নম্বর কন্ট্রোল] ছবি দুটি রিং-এর কতটা কাছে আসবে তা এখান থেকে কন্ট্রোল করুন
    double overlapDistance = 25;

    // টোটাল উইডথ হিসাব
    double totalWidth = (myFrameSize + partnerFrameSize) - overlapDistance;
    double totalHeight =
        myFrameSize > partnerFrameSize ? myFrameSize : partnerFrameSize;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      alignment: Alignment.center,
      child: SizedBox(
        width: totalWidth,
        height: totalHeight,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // ১. নিজের প্রোফাইল ছবি ও ফ্রেম
            Positioned(
              left: (totalWidth / 2) - myFrameSize + (overlapDistance / 2),
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildUserWithFrame(myImg, myFrame, avatarRadius,
                    lottieMultiplier, imageMultiplier),
              ),
            ),

            // ২. পার্টনারের প্রোফাইল ছবি ও ফ্রেম
            Positioned(
              right:
                  (totalWidth / 2) - partnerFrameSize + (overlapDistance / 2),
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildUserWithFrame(partnerImg, partnerFrame,
                    avatarRadius, lottieMultiplier, imageMultiplier),
              ),
            ),

            // 💍 ম্যারেজ রিং আইকন (ঠিক মাঝখানে, ক্লিকেবল ডিভোর্স ও ডিটেইলস পপআপ)
            Positioned(
              child: GestureDetector(
                onTap: () async {
                  print(
                      "=================== 🔍 DEBUG START ===================");

                  // 🆔 কারেন্ট ইউজারের UID এবং পার্টনারের UID বের করা হলো
                  String currentUid =
                      FirebaseAuth.instance.currentUser?.uid ?? '';
                  String partnerAuthUID =
                      rawMarriageDoc['partnerAuthUID'] ?? '';
                  print("[Debug] Current User Auth UID: $currentUid");

                  // ফায়ারস্টোর ডকুমেন্টের আইডি নিশ্চিত করা
                  String marriageDocId = rawMarriageDoc['marriageId'] ??
                      rawMarriageDoc['id'] ??
                      rawMarriageDoc['docId'] ??
                      "${currentUid}_$partnerAuthUID";

                  String finalMyName = '';
                  String finalMyImage = '';

                  // 🔍 [১০০% ফিক্সড লজিক: where কুয়েরি ব্যবহার]:
                  // যেহেতু ডকুমেন্ট আইডি ৬ ডিজিটের, তাই আমরা uid ফিল্ড দিয়ে সার্চ করছি
                  try {
                    if (currentUid.isNotEmpty) {
                      QuerySnapshot userQuery = await FirebaseFirestore.instance
                          .collection(
                              'users') // 🔥 আপনার স্ক্রিনশট অনুযায়ী কালেকশনের নাম users
                          .where('uid',
                              isEqualTo:
                                  currentUid) // লম্বা আইডি দিয়ে ডাটাবেজে ফিল্টার
                          .limit(1)
                          .get();

                      if (userQuery.docs.isNotEmpty) {
                        var uData =
                            userQuery.docs.first.data() as Map<String, dynamic>;
                        print("[Debug] Live Database Data Found: $uData");

                        // ডাটাবেজের ফিল্ড অনুযায়ী নাম ও ছবি ফিল্টারিং
                        finalMyName = uData['name'] ??
                            uData['username'] ??
                            uData['nickName'] ??
                            '';
                        finalMyImage = uData['profilePic'] ??
                            uData['image'] ??
                            uData['avatar'] ??
                            '';
                      } else {
                        print("[Debug] ❌ User not found with uid: $currentUid");
                      }
                    }
                  } catch (e) {
                    print("[Debug] Firestore Error: $e");
                  }

                  // 🔐 ব্যাকআপ লজিক ১: ফায়ারস্টোরে না পাওয়া গেলে ফায়ারবেস আউথ প্রোফাইল চেক করবে
                  if (finalMyName.trim().isEmpty) {
                    finalMyName =
                        FirebaseAuth.instance.currentUser?.displayName ?? '';
                  }
                  if (finalMyImage.trim().isEmpty) {
                    finalMyImage =
                        FirebaseAuth.instance.currentUser?.photoURL ?? '';
                  }

                  // 🔐 ব্যাকআপ লজিক ২: যদি কারেন্ট পেজের উইজেটের ভেতর কোনো নাম থেকে থাকে
                  if (finalMyName.trim().isEmpty && data != null) {
                    finalMyName = data['name'] ?? data['username'] ?? '';
                  }

                  // 👑 চূড়ান্ত ব্যাকআপ নাম (খালি থাকলে)
                  if (finalMyName.trim().isEmpty) {
                    finalMyName = "User";
                  }

                  finalMyName = finalMyName.trim();
                  finalMyImage = finalMyImage.trim();

                  print("[Debug] 🏆 FINAL NAME TO PASS: $finalMyName");
                  print("=================== 🔍 DEBUG END ===================");

                  // 🛑 ম্যারেজ বটম শিট ওপেন (সরাসরি ডেটাবেজ থেকে লাইভ তুলে আনা নাম ও ছবি পাস করা হলো)
                  _showDivorceBottomSheet(
                    context: context,
                    marriageData: rawMarriageDoc,
                    marriageDocId: marriageDocId,
                    myName: finalMyName,
                    myImage: finalMyImage,
                  );
                },
                child: Image.network(
                  ringIconUrl,
                  width: 60,
                  height: 55,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.favorite,
                        color: Colors.pink, size: 30);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserWithFrame(String imageUrl, String frameUrl, double radius,
      double lottieMultiplier, double imageMultiplier) {
    double profileSize = radius * 2;

    bool isLottie = frameUrl.contains('.json');
    double frameSize = radius * (isLottie ? lottieMultiplier : imageMultiplier);

    String validImageUrl = imageUrl.trim().isEmpty
        ? "https://i.ibb.co/empty.png"
        : imageUrl.trim();

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // প্রোফাইল গোল ছবি
        Container(
          width: profileSize,
          height: profileSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                Border.all(color: Colors.pinkAccent.withOpacity(0.6), width: 2),
            image: DecorationImage(
              image: NetworkImage(validImageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // রিয়েল-টাইম প্রোফাইল ফ্রেম (লত্তি এবং ইমেজের জন্য নিখুঁত স্কয়ার হ্যান্ডলিং)
        if (frameUrl.trim().isNotEmpty && frameUrl.startsWith('http'))
          IgnorePointer(
            child: SizedBox(
              width: frameSize,
              height: frameSize,
              child: isLottie
                  ? Lottie.network(
                      frameUrl.trim(),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(),
                    )
                  : Container(
                      // 🔥 ফিক্স: 이미지 ফ্রেমটিকে কন্টেইনারের ব্যাকগ্রাউন্ড হিসেবে BoxFit.cover দেওয়া হয়েছে
                      // এর ফলে ইমেজটি লম্বা বা চ্যাপ্টা না হয়ে চারপাশে একদম সমান গোল (Perfect Circle) হয়ে বড়-ছোট হবে।
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(frameUrl.trim()),
                          fit: BoxFit
                              .cover, // রেশিও নষ্ট হওয়া রোধ করবে এবং সমানভাবে বড় করবে
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }

// 💔 ম্যারেজ ডিটেইলস এবং ডিভোর্স বটম শিট (পপআপ বার)
  void _showDivorceBottomSheet({
    required BuildContext context,
    required Map<String, dynamic> marriageData,
    required String marriageDocId,
    required String myName,
    required String myImage,
  }) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;

    // বিয়ের তারিখ ফরম্যাট করা
    String marriageDate = "Unknown";
    if (marriageData['marriedAt'] != null) {
      Timestamp timestamp = marriageData['marriedAt'];
      marriageDate =
          DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
    }

    // 👥 পার্টনারের তথ্য
    String partnerAuthUID = marriageData['partnerAuthUID'] ?? '';
    String partnerName = marriageData['partnerName'] ?? 'Partner';
    String partnerImage = marriageData['partnerImage'] ?? '';
    String ringName = marriageData['ringName'] ?? 'Wedding Ring';

    String currentUid = _auth.currentUser?.uid ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[950],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 20),
                  Text("💍 $ringName 💍",
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  // 👥 ২ জনের ছবি ও নাম পাশাপাশি গ্রাফিক্স
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 👤 নিজের প্রোফাইল (বাম পাশে)
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.grey[900],
                              child: ClipOval(
                                child: myImage.trim().isEmpty
                                    ? const Icon(Icons.person,
                                        color: Colors.white, size: 35)
                                    : Image.network(
                                        myImage.trim(),
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.person,
                                                    color: Colors.white,
                                                    size: 35),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              myName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      // ❤️ মাঝখানের লাভ আইকন
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child:
                            Icon(Icons.favorite, color: Colors.red, size: 35),
                      ),

                      // 👥 পার্টনারের প্রোফাইল (ডান পাশে)
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.grey[900],
                              child: ClipOval(
                                child: partnerImage.trim().isEmpty
                                    ? const Icon(Icons.person,
                                        color: Colors.white, size: 35)
                                    : Image.network(
                                        partnerImage.trim(),
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.person,
                                                    color: Colors.white,
                                                    size: 35),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              partnerName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 🗓️ বিয়ের তারিখ সেকশন
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_month,
                            color: Colors.pinkAccent, size: 20),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            "Marriage Date: $marriageDate",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 💔 ডিভোর্স বাটন লজিক (১০০% ফিক্সড এবং হ্যাং ইস্যু মুক্ত)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    icon: const Icon(Icons.heart_broken, color: Colors.white),
                    label: const Text("Divorce Cost(3000 💎)",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      if (currentUid.isEmpty) return;

                      bool confirm = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    backgroundColor: Colors.grey[900],
                                    title: const Text("Divorce Confirmation",
                                        style: TextStyle(color: Colors.white)),
                                    content: const Text(
                                        "Are You Sure? 3000 Diamonds will be deducted.",
                                        style: TextStyle(color: Colors.grey)),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("No")),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("Yes",
                                              style: TextStyle(
                                                  color: Colors.red))),
                                    ],
                                  )) ??
                          false;

                      if (confirm) {
                        // ❌ সাবধান: এখানে আগে Navigator.pop(context) কল করা যাবে না।
                        // করলে কনটেক্সট ডেড হয়ে যাবে এবং অ্যাপ হ্যাং করবে।

                        // ⏳ লোডিং ডায়ালগ ওপেন
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.redAccent)),
                        );

                        try {
                          print("==== 🔍 DIVORCE DEBUG START ====");

                          // ১. সঠিক ইউজার ডকুমেন্ট খোঁজা (where কুয়েরি দিয়ে)
                          QuerySnapshot userQuery = await _firestore
                              .collection('users')
                              .where('uid', isEqualTo: currentUid)
                              .limit(1)
                              .get();

                          if (userQuery.docs.isEmpty) {
                            throw "User document not found in database!";
                          }

                          DocumentReference userRef =
                              userQuery.docs.first.reference;
                          print("[Debug] User DocRef Found: ${userRef.id}");

                          // ২. ডায়মন্ড চেক এবং কাটা (Transaction)
                          await _firestore.runTransaction((transaction) async {
                            DocumentSnapshot userSnapshot =
                                await transaction.get(userRef);

                            if (!userSnapshot.exists) {
                              throw "User snapshot does not exist!";
                            }

                            var uData =
                                userSnapshot.data() as Map<String, dynamic>;
                            int currentDiamonds = uData['diamonds'] ?? 0;
                            print("[Debug] Current Diamonds: $currentDiamonds");

                            if (currentDiamonds < 3000) {
                              throw "Insufficient Diamonds! You need 3000 💎";
                            }

                            transaction.update(userRef, {
                              'diamonds': currentDiamonds - 3000,
                            });
                          });

                          print("[Debug] Diamonds deducted successfully!");

                          // ৩. দুইজনের ম্যারেজ রেকর্ড মুছে ফেলা (আপনার এবং পার্টনারের)
                          WriteBatch batch = _firestore.batch();
                          batch.delete(_firestore
                              .collection('marriages')
                              .doc(currentUid));
                          if (partnerAuthUID.isNotEmpty) {
                            batch.delete(_firestore
                                .collection('marriages')
                                .doc(partnerAuthUID));
                          }
                          await batch.commit();

                          print("[Debug] Both marriage records deleted!");
                          print("==== 🔍 DIVORCE DEBUG END ====");

                          // ৪. সাবধানে ডায়ালগ এবং বটম শিট বন্ধ করা
                          Navigator.pop(context); // প্রথমে লোডিং ডায়ালগ বন্ধ
                          Navigator.pop(context); // এরপর বটম শিট বন্ধ

                          // ৫. সাকসেস মেসেজ
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "💔 Divorce Completed Successfully! 3000 💎 Charged."),
                                backgroundColor: Colors.green),
                          );
                        } catch (e) {
                          print("[Debug] ❌ Error in Divorce: $e");

                          // এরর হলেও যাতে হ্যাং না হয়, সেজন্য লোডিংটা বন্ধ করতে হবে
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("❌ Error: $e"),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class RainbowCascadePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random =
        math.Random(42); // Seed ব্যবহার করা হয়েছে যাতে রেন্ডার ফিক্সড থাকে

    // আপনার রুম পেইজের থিমের সাথে মিল রেখে কালার প্যালেট
    List<Color> galaxyColors = [
      const Color(0xFF0F0C29), // গাঢ় নীল
      const Color(0xFF302B63), // বেগুনি আভা
      const Color(0xFF24243E), // নেভি ব্লু
    ];

    // ১. ব্যাকগ্রাউন্ডে গ্লাস ইফেক্টের জন্য রেডিয়াল গ্রেডিয়েন্ট (Glow)
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = RadialGradient(
      center: const Alignment(0.7, -0.6), // ডানদিকের উপরে হালকা গ্লো
      radius: 1.5,
      colors: [
        const Color(0xFF302B63).withOpacity(0.3),
        const Color(0xFF0F0C29).withOpacity(0.1),
        Colors.transparent,
      ],
    ).createShader(rect);
    canvas.drawRect(rect, paint);

    // ২. গ্যালাক্সি তারা বা স্পার্কেলস (Glowing Stars)
    for (int i = 0; i < 100; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double starSize = random.nextDouble() * 2.0;

      paint.shader = null;
      // কিছু তারা সাদা এবং কিছু হালকা বেগুনি
      paint.color = (i % 5 == 0)
          ? Colors.purpleAccent.withOpacity(random.nextDouble() * 0.7)
          : Colors.white.withOpacity(random.nextDouble() * 0.5);

      canvas.drawCircle(Offset(x, y), starSize, paint);

      // তারার চারপাশে হালকা গ্লো (ব্লায়ার ইফেক্ট)
      if (i % 10 == 0) {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(x, y), starSize * 2, paint);
        paint.maskFilter = null;
      }
    }

    // ৩. ওপর থেকে ঝুলে থাকা হালকা আলোর স্ট্রিং (Light Strings)
    for (int i = 0; i < 15; i++) {
      final double x = random.nextDouble() * size.width;
      final double lineLength = random.nextDouble() * 150 + 50;

      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blueAccent.withOpacity(0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(x, 0, 1, lineLength));

      paint.strokeWidth = 1.0;
      canvas.drawLine(Offset(x, 0), Offset(x, lineLength), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}