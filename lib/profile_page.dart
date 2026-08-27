import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pagla_chat/agency_badge.dart';
import 'package:pagla_chat/auth_service.dart';
import 'package:pagla_chat/delete_account_service.dart';
import 'package:pagla_chat/help_desk_page.dart';
import 'package:pagla_chat/privacy_policy_page.dart';
import 'package:pagla_chat/services/diamond_recharge_view.dart';
import 'package:pagla_chat/services/follow_service.dart';
import 'package:pagla_chat/services/soulmate_detail_page.dart';
import 'package:pagla_chat/team_panel_and_soulmate_section.dart';
import 'package:pagla_chat/user_badge_widget.dart';
import 'package:pagla_chat/user_badges_row.dart';
import 'package:pagla_chat/user_profile_features.dart';
import 'package:pagla_chat/utils/daily_bonus_popup.dart';
import 'package:pagla_chat/vip_benefits_screen.dart';
import 'package:pagla_chat/widgets/active_level_bar.dart';
import 'package:pagla_chat/widgets/gift_level_bar.dart';
import 'package:shimmer/shimmer.dart';
// পাথটি আপনার ফোল্ডার অনুযায়ী ঠিক করে নিন
import 'package:firebase_storage/firebase_storage.dart';
// ফাইলের নাম অনুযায়ী
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';
import 'package:pagla_chat/user_list_screen.dart';
import 'chat_screen.dart';
import 'package:pagla_chat/services/database_service.dart';
import 'package:pagla_chat/services/soulmate_service.dart';
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

  String sixDigitProfileID = ""; // এটি ক্লাসের শুরুতে ভেরিয়েবল হিসেবে যোগ করুন
  // ক্লাসের একদম উপরে এই ভেরিয়েবলটি যোগ করুন
  String myAuthUID = FirebaseAuth.instance.currentUser?.uid ?? "";
  String mySixDigitUID = ""; // এটি আপনার নিজের ৬ ডিজিটের আইডি
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

  bool isMarried = false;
  String partnerUid = '';
  String marriageDocId = '';

  int totalActiveXp = 0;
  int totalGiftXp = 0;
  bool isFriend = false; // নতুন ভেরিয়েবল

  @override
  void initState() {
    super.initState();
    loadUserData(); // আইডি জেনারেশন বন্ধ, শুধু ডাটা লোড হবে
  }

  // আইডি জেনারেশন ছাড়া শুধু ডাটা খুঁজে বের করার নিখুঁত লজিক
  void loadUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // টার্গেট আইডি নির্ধারণ (অন্যের প্রোফাইল হলে widget.userId, নিজের হলে currentUser.uid)
    String targetId = widget.userId ?? currentUser.uid;

    try {
      DocumentSnapshot? userDoc;
      final collection = FirebaseFirestore.instance.collection('users');

      // ১. যদি অন্যের প্রোফাইল হয় অথবা widget.userId দেওয়া থাকে
      if (widget.userId != null) {
        userDoc = await collection.doc(targetId).get();
      } else {
        // ২. নিজের প্রোফাইল হলে সবচেয়ে নির্ভরযোগ্য কুয়েরিগুলো ধাপে ধাপে চালানো:

        // ক) প্রথমে 'uID' ফিল্ডে ফায়ারবেস UID বা ৬-ডিজিটের আইডি দিয়ে চেক করা
        var queryuIDField = await collection
            .where('uID', isEqualTo: currentUser.uid)
            .limit(1)
            .get();
        if (queryuIDField.docs.isNotEmpty) {
          userDoc = queryuIDField.docs.first;
        }

        // খ) যদি না পাওয়া যায়, তবে 'authUID' ফিল্ড দিয়ে চেক করা
        if (userDoc == null || !userDoc.exists) {
          var queryAuth = await collection
              .where('authUID', isEqualTo: currentUser.uid)
              .limit(1)
              .get();
          if (queryAuth.docs.isNotEmpty) {
            userDoc = queryAuth.docs.first;
          }
        }

        // গ) যদি তাতেও না পাওয়া যায়, তবে 'uid' ফিল্ড দিয়ে চেক করা
        if (userDoc == null || !userDoc.exists) {
          var queryUidField = await collection
              .where('uid', isEqualTo: currentUser.uid)
              .limit(1)
              .get();
          if (queryUidField.docs.isNotEmpty) {
            userDoc = queryUidField.docs.first;
          }
        }

        // ঘ) সর্বশেষ ইমেইল দিয়ে চেক করা
        if ((userDoc == null || !userDoc.exists) && currentUser.email != null) {
          var queryEmail = await collection
              .where('email', isEqualTo: currentUser.email)
              .limit(1)
              .get();
          if (queryEmail.docs.isNotEmpty) {
            userDoc = queryEmail.docs.first;
          }
        }
      }

      // --- ডাটা পাওয়ার পর ভেরিয়েবলে সেট করা ---
      if (userDoc != null && userDoc.exists && mounted) {
        var data = userDoc.data() as Map<String, dynamic>;
        DateTime now = DateTime.now();

        // নিজের আইডি যদি খালি থাকে, তবে রিফ্রেশ করে নেওয়া
        if (widget.userId != null && mySixDigitUID.isEmpty) {
          _refreshMyOwnUID(currentUser);
        }

        setState(() {
          uIDValue = userDoc!.id;
          sixDigitProfileID = data['uID'] ?? userDoc.id;

          // নিজের আইডি সেট করার লজিক (এজেন্সি ও পার্সোনাল উভয় অ্যাকাউন্টের জন্য নিরাপদ)
          if ((userDoc.id == currentUser.uid ||
              data['authUID'] == currentUser.uid ||
              data['uid'] == currentUser.uid ||
              data['uID'] == currentUser.uid)) {
            mySixDigitUID = userDoc.id;
          }

          isAgent = data['isAgent'] == true;
          userName = data['name'] ?? data['userName'] ?? "Pagla User";
          userImageURL = data['profilePic'] ?? "";
          gender = data['gender'] ?? "Unfixed";

          var ageData = data['age'];
          age = (ageData is String)
              ? (int.tryParse(ageData) ?? 22)
              : (ageData ?? 22);

          // নিরাপদ উপায়ে ডায়মন্ড কনভার্ট (এজেন্সি বা পার্সোনাল অ্যাকাউন্টের লেনদেনের জন্য জরুরি)
          var diamondData = data['diamonds'];
          diamonds = (diamondData is String)
              ? (int.tryParse(diamondData) ?? 200)
              : (diamondData ?? 200).toInt();

          // নিরাপদ উপায়ে ভিআইপি এক্সপি কনভার্ট
          var xpData = data['vip_xp'];
          xp = (xpData is String)
              ? (int.tryParse(xpData) ?? 0)
              : (xpData ?? 0).toInt();

          // নিরাপদ উপায়ে ফলোয়ার্স কনভার্ট
          var followersData = data['followers'];
          followers = (followersData is String)
              ? (int.tryParse(followersData) ?? 0)
              : (followersData ?? 0).toInt();

          // নিরাপদ উপায়ে ফলোয়িং কনভার্ট
          var followingData = data['following'];
          following = (followingData is String)
              ? (int.tryParse(followingData) ?? 0)
              : (followingData ?? 0).toInt();

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

          // ২. Frame ও Special Effect
          activeSpecialUrl = data['activeSpecialUrl'] ?? "";
          hasSpecialEffect = data['hasSpecialEffect'] ?? false;
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

          isMarried = data['isMarried'] ?? false;
          partnerUid = data['partnerUid'] ?? '';
          marriageDocId = data['marriageDocId'] ?? '';

          var totalActiveXpData = data['totalActiveXp'];
          totalActiveXp = (totalActiveXpData is String)
              ? (int.tryParse(totalActiveXpData) ?? 0)
              : (totalActiveXpData ?? 0).toInt();

          var totalGiftXpData = data['totalGiftXp'];
          totalGiftXp = (totalGiftXpData is String)
              ? (int.tryParse(totalGiftXpData) ?? 0)
              : (totalGiftXpData ?? 0).toInt();
        });

        _checkInitialStatus();
        _addVisitor();
      }
    } catch (e) {
      // সাইলেন্টলি হ্যান্ডেল করা হয়েছে
    }
  }

  // ২. আলাদা ফাংশন যা শুধু আপনার নিজের আইডি খুঁজে বের করবে
  void _refreshMyOwnUID(User currentUser) async {
    final collection = FirebaseFirestore.instance.collection('users');
    var query = await collection
        .where('authUID', isEqualTo: currentUser.uid)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      setState(() {
        mySixDigitUID = query.docs.first.id;
      });
    }
  }

  // ৩. ফলো এবং ফ্রেন্ড স্ট্যাটাস চেক করার সম্পূর্ণ সুরক্ষিত লজিক
  void _checkInitialStatus() async {
    // ১. টার্গেট আইডি ভ্যালিডেশন
    String targetId = widget.userId ?? uIDValue;
    if (targetId.isEmpty) {
      // যদি উইজেটে আইডি না থাকে, তবে গ্লোবাল বা অন্য কোনো ভেরিয়েবল থেকে নেওয়ার চেষ্টা
      return;
    }

    // ২. নিজের বিভিন্ন ধরনের আইডি বা কেসগুলো সিকিউর করা (authUID, uID, uid, myId, sixDigitUID, email ইত্যাদি)
    User? currentUser = FirebaseAuth.instance.currentUser;
    String authUID = currentUser?.uid ?? "";
    String email = currentUser?.email ?? "";

    // আপনার প্রজেক্টে যে যে ভেরিয়েবল বা আইডি থাকতে পারে তার একটি কমপ্লিট প্রায়োরিটি লিস্ট
    String resolvedMyId = "";

    if (mySixDigitUID.isNotEmpty) {
      resolvedMyId = mySixDigitUID;
    } else if (uIDValue.isNotEmpty) {
      resolvedMyId = uIDValue;
    } else if (authUID.isNotEmpty) {
      resolvedMyId = authUID;
    }

    // যদি নিজের আইডি এবং টার্গেট আইডি দুটোই পাওয়া যায় তবেই সার্ভিসে চেক করতে পাঠাবে
    if (resolvedMyId.isNotEmpty &&
        targetId.isNotEmpty &&
        resolvedMyId != targetId) {
      try {
        // আপনি তাকে ফলো করেন কিনা চেক
        bool following =
            await FollowService().checkIfFollowing(targetId, resolvedMyId);

        // সেও আপনাকে ফলো করে কিনা (Mutual Friend / Friend স্ট্যাটাসের জন্য) চেক
        bool mutual =
            await FollowService().checkIfMutualFriend(targetId, resolvedMyId);

        if (mounted) {
          setState(() {
            isFollowing = following;
            isFriend =
                mutual; // এখানে ফ্রেন্ড ও ফলোইং স্টেটাস একদম পারফেক্টলি সেট হলো
          });
        }
      } catch (e) {
        // কোনো এরর হ্যান্ডেল করার জন্য
        print("Status Check Error: $e");
      }
    }
  }

  // ৪. ডাটা ফেচ করার ফাংশন
  void _fetchUserData() async {
    if (uIDValue.isEmpty) return;

    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uIDValue)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          var fData = userDoc.data()?['followers'];
          followers = (fData is String)
              ? (int.tryParse(fData) ?? 0)
              : (fData ?? 0).toInt();

          var fgData = userDoc.data()?['following'];
          following = (fgData is String)
              ? (int.tryParse(fgData) ?? 0)
              : (fgData ?? 0).toInt();
        });
      }
    } catch (e) {
      // সাইলেন্টলি হ্যান্ডেল করা হয়েছে
    }
  }

  // ৫. ডাটাবেজ থেকে মেয়াদ শেষ হওয়া ডাটা মুছে ফেলার ফাংশন
  void _clearExpiredData(String boolField, String dateField,
      {String? extraField}) async {
    if (uIDValue.isEmpty) return;

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
    } catch (e) {
      // সাইলেন্টলি হ্যান্ডেল করা হয়েছে
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
                          } catch (e) {}
                        } else {}
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
      backgroundColor: Colors.transparent, // গ্রেডিয়েন্ট দেখানোর জন্য
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          // VIP Benefits এর সাথে মিলিয়ে প্রিমিয়াম ব্লু ও পার্পল গ্রেডিয়েন্ট
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00B4DB), // Bright Cyan Blue
              Color(0xFF0083B0), // Mid Blue tone
              Color(0xFF4A00E0), // Deep Purple gradient match
              Color(0xFF190033), // Rich dark purple-blue base
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.2),
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
                    color: Colors.cyanAccent.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("Settings",
                        style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 22,
                            fontWeight: FontWeight.bold))),

                // সেটিংস অপশনগুলো রিয়েলিস্টিক কার্ড ডিজাইন এবং গ্লাস ইফেক্টসহ
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        // ১. বয়স পরিবর্তন (Age change)
                        ListTile(
                            leading: const Icon(Icons.cake,
                                color: Colors.orangeAccent),
                            title: Text("Age change (Now: $age)",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500)),
                            onTap: () {
                              Navigator.pop(context);
                              _showAgePicker();
                            }),

                        // ২. প্রাইভেসি পলিসি
                        ListTile(
                          leading: const Icon(Icons.security,
                              color: Colors.cyanAccent),
                          title: const Text("Privacy Policy",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PrivacyPolicyPage()),
                            );
                          },
                        ),

                        // ৩. হেল্প ডেস্ক (Help Desk)
                        ListTile(
                          leading: const Icon(Icons.support_agent,
                              color: Colors.greenAccent),
                          title: const Text(
                            "Help Desk",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const HelpDeskPage()),
                            );
                          },
                        ),

                        // ৪. অ্যাকাউন্ট ডিলিট করার বাটন
                        ListTile(
                          leading: const Icon(Icons.delete_forever,
                              color: Colors.purpleAccent),
                          title: const Text(
                            "Delete Account",
                            style: TextStyle(
                              color: Colors.purpleAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showDeleteConfirmationDialog(context);
                          },
                        ),

                        // ৫. লগআউট (Logout)
                        ListTile(
                          leading:
                              const Icon(Icons.logout, color: Colors.redAccent),
                          title: const Text(
                            "Logout",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () async {
                            await AuthService().signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addVisitor() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }
    if (widget.userId == null) {
      return;
    }

    var myUserQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('authUID', isEqualTo: currentUser.uid)
        .limit(1)
        .get();

    if (myUserQuery.docs.isEmpty) {
      return;
    }

    var myData = myUserQuery.docs.first.data();
    String mySixDigitID = myData['uID'].toString();

    if (mySixDigitID == widget.userId.toString()) {
      return;
    }

    var ownerQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('uID', isEqualTo: widget.userId)
        .limit(1)
        .get();

    if (ownerQuery.docs.isEmpty) {
      return;
    }

    String ownerDocId = ownerQuery.docs.first.id;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerDocId)
          .collection('visitors')
          .doc(mySixDigitID)
          .set({
        'userName': myData['name'] ?? 'User',
        'userImage': myData['profilePic'] ?? '',
        'frameUrl': myData['activeFrameUrl'] ?? '',
        'visitedAt': FieldValue.serverTimestamp(),
        'isSeen': false,
      });
    } catch (e) {
      // ক্যাচ ব্লকের প্রিন্ট রিমুভ করা হয়েছে
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("Are you sure? "),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DeleteAccountService.requestAccountDeletion(AppData.myID);
              Navigator.pop(context);
              // লগআউট করে দিন
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
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
                          child: CachedNetworkImage(
                            imageUrl: avatars[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[900],
                              child: const Icon(Icons.person,
                                  color: Colors.white54, size: 20),
                            ),
                          ),
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
                      } catch (e) {}
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
      // ১. আপনার লোকাল ভেরিয়েবল বা স্টেট থেকে আইডি নিন (স্ক্রিনশট অনুযায়ী আপনার আইডি হলো '454488')
      // নিশ্চিত করুন যে এই 'uIDValue' বা যেই ভেরিয়েবলে আপনার আইডি আছে, সেটি সঠিক।
      String targetUID = uIDValue.toString();

      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = 'profile_$timestamp.jpg';

      // ২. স্টোরেজ রেফারেন্স (এখানেও FirebaseAuth UID এর বদলে আপনার 'targetUID' ব্যবহার করুন)
      Reference storageFolder = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child(targetUID);
      Reference newStorageRef = storageFolder.child(fileName);

      // ৩. ছবি আপলোড
      UploadTask uploadTask = newStorageRef.putFile(
          newFile, SettableMetadata(contentType: 'image/jpeg'));
      TaskSnapshot snapshot = await uploadTask;
      String newDownloadUrl = await snapshot.ref.getDownloadURL();

      // ৪. গুরুত্বপূর্ণ পরিবর্তন: কোয়েরি করে সঠিক ডকুমেন্টটি খুঁজে বের করা
      // এখানে আমরা 'uID' ফিল্ডটি চেক করছি যা আপনার ডাটাবেসে আছে
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uID', isEqualTo: targetUID)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // সঠিক ডকুমেন্ট পাওয়া গেছে, এখন আপডেট করুন
        String docId = querySnapshot.docs.first.id;
        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'profilePic': newDownloadUrl,
        });
      } else {
        // যদি ডাটাবেসে ডকুমেন্ট না থাকে, তবে নতুন করে তৈরি করুন
        await FirebaseFirestore.instance.collection('users').add({
          'uID': targetUID,
          'profilePic': newDownloadUrl,
        });
      }

      // ৫. ইন্টারফেস আপডেট
      if (mounted) {
        setState(() {
          userImageURL = newDownloadUrl;
        });
      }

      // ৬. পুরাতন ফাইল ডিলিট করার লজিক
      final ListResult result = await storageFolder.listAll();
      for (var item in result.items) {
        if (item.name != fileName) {
          await item.delete();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Profile updated successfully!"),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent));
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

  void _openVisitors() => UserProfileFeatures.openVisitors(context);
  void _openMyPosts() => UserProfileFeatures.openMyPosts(context);
  // প্রোফাইল পেজের ফাংশনটি হবে এরকম:
  // এই নতুন ফাংশনটি আপনার প্রোফাইল পেজে যোগ করুন
  Map<String, dynamic> getCurrentUserData() {
    return {
      'name': userName,
      'uID': sixDigitProfileID,
      'profilePic': userImageURL, // আপনার প্রোফাইল পিকচার ভেরিয়েবলটি এখানে দিন
      'vip_xp': xp, // আপনার প্রোফাইলের XP ভেরিয়েবল
      'isVIP': isVIP,
      'vipLevel': vipLevel,
      // অন্য প্রয়োজনীয় ফিল্ডগুলো এখানে যোগ করতে পারেন
    };
  }

// আপনার বর্তমান _openVIP ফাংশনটিকে এভাবে পরিবর্তন করুন:
  void _openVIP() {
    // ১. বর্তমান ডাটাগুলো একটি ম্যাপে নিয়ে নিন
    Map<String, dynamic> userDataMap = getCurrentUserData();

    // ২. এখন এটি পাস করুন (লাল দাগ আর থাকবে না)
    UserProfileFeatures.openVIP(context, userDataMap);
  }

  void _openGames() => UserProfileFeatures.openGames(context);
// এটি আপনার ফাইলে যোগ করুন
  void _openFacebook() async {
    final Uri url =
        Uri.parse('https://www.facebook.com/profile.php?id=61591420921368');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // এরর হ্যান্ডলিং
    }
  }

  // ১. প্রিমিয়াম স্টোর ওপেন করার ফাংশন
  void _openPremiumStore() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // গ্রেডিয়েন্ট দেখানোর জন্য
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => DefaultTabController(
        length: 4,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            // সেটিংস পেজের সেইম প্রিমিয়াম ব্লু ও পার্পল গ্রেডিয়েন্ট
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF00B4DB), // Bright Cyan Blue
                Color(0xFF0083B0), // Mid Blue tone
                Color(0xFF4A00E0), // Deep Purple gradient match
                Color(0xFF190033), // Rich dark purple-blue base
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: Stack(
            children: [
              // ব্যাকগ্রাউন্ডে তারার ঝিকিমিকি ইফেক্ট
              ...List.generate(
                15,
                (index) => Positioned(
                  top: (index * 50.0) % 450,
                  left: (index * 80.0) % 380,
                  child: Icon(
                    Icons.star,
                    size: index % 3 == 0 ? 12 : 6,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),

              Column(
                children: [
                  const SizedBox(height: 12),
                  // ড্র্যাগ হ্যান্ডেল
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const TabBar(
                    isScrollable: true,
                    indicatorColor: Colors.cyanAccent,
                    labelColor: Colors.cyanAccent,
                    unselectedLabelColor: Colors.white60,
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
                      ? Lottie.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.error,
                            size: 40,
                            color: Colors.amber,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: Colors.white10,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.portrait,
                            size: 40,
                            color: Colors.amber,
                          ),
                        ),
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
                      } catch (e) {}
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
                      ? Lottie.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.auto_awesome,
                            size: 40,
                            color: Colors.cyan,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: Colors.white10,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.auto_awesome,
                            size: 40,
                            color: Colors.cyan,
                          ),
                        ),
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
                      } catch (e) {}
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
        "name": "musicframe",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/pageframe/Profile_Frame.json",
        "price": "15000",
        "type": "Profile Page"
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
      {
        "name": "parpul",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/pageframe/framing.json",
        "price": "31000",
        "type": "Profile Page"
      },
      {
        "name": "parpul2",
        "url":
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/pageframe/glowing-star.json",
        "price": "300",
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
              // ইমেজ বা লটি হ্যান্ডলিং অংশটুকু এভাবে লিখুন
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: url.toLowerCase().contains('.json')
                      ? LottieBuilder.network(
                          url,
                          fit: BoxFit.contain,
                          animate: true,
                          repeat: true,
                          onLoaded: (composition) {
                            print("Lottie Loaded Successfully: $url");
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print("Lottie Error: $error | URL: $url");
                            return const Icon(Icons.error_outline,
                                color: Colors.red);
                          },
                        )
                      : CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: Colors.white10,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
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
                        WriteBatch batch = FirebaseFirestore.instance.batch();
                        DocumentReference userRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(uIDValue);
                        DocumentReference backpackRef =
                            userRef.collection('my_special').doc(item['name']);

                        batch.update(userRef,
                            {'diamonds': FieldValue.increment(-itemPrice)});
                        batch.set(backpackRef, {
                          'name': item['name'],
                          'image_url': url,
                          'type': item['type'],
                          'expiryDate': Timestamp.fromDate(expiry),
                          'isPicked': true,
                        });

                        await batch.commit();
                        setState(() {
                          diamonds = currentDiamonds - itemPrice;
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("অভিনন্দন! আইটেমটি কেনা হয়েছে।")));
                        }
                      } catch (e) {
                        print("Purchase Error: $e");
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                "কিছু একটা সমস্যা হয়েছে! পরে চেষ্টা করুন।")));
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
          Colors.transparent, // গ্রেডিয়েন্ট দেখানোর জন্য স্বচ্ছ রাখা হয়েছে
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => DefaultTabController(
        length: 4,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            // সেটিংসের মতো সেইম প্রিমিয়াম ব্লু ও পার্পল গ্রেডিয়েন্ট
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF00B4DB), // Bright Cyan Blue
                Color(0xFF0083B0), // Mid Blue tone
                Color(0xFF4A00E0), // Deep Purple gradient match
                Color(0xFF190033), // Rich dark purple-blue base
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: Stack(
            children: [
              // ব্যাকগ্রাউন্ডে তারার ঝিকিমিকি ইফেক্ট
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
                children: [
                  const SizedBox(height: 12),
                  // ড্র্যাগ হ্যান্ডেল
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ট্যাব বার ডিজাইন
                  TabBar(
                    isScrollable: true,
                    indicatorColor:
                        Colors.amber, // প্রিমিয়াম লুকের জন্য অ্যাম্বার কালার
                    labelColor: Colors.cyanAccent,
                    unselectedLabelColor: Colors.white60,
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
                  child: CachedNetworkImage(
                    imageUrl:
                        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/premiumcard.png",
                    height: 160,
                    width: 240,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      height: 160,
                      width: 240,
                      color: Colors.white10,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 160,
                      width: 240,
                      color: Colors.grey[900],
                      child: const Icon(Icons.broken_image,
                          color: Colors.grey, size: 40),
                    ),
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
                  "Cost: 30k 💎",
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
                      if (diamonds >= 30000) {
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
                            'diamonds': FieldValue.increment(-30000),
                            'hasPremiumCard': true,
                            'premiumUntil': Timestamp.fromDate(cardExpiry),
                            'hasFreeFrame': true,
                            'frameUntil': Timestamp.fromDate(frameExpiry),
                            'activeFrameUrl':
                                "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/premiumframe.png",
                          });

                          setState(() {
                            diamonds -= 30000;
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
                        } catch (e) {}
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
          leading: CachedNetworkImage(
            imageUrl:
                "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/premiumcard.png",
            width: 50,
            fit: BoxFit.contain,
            placeholder: (context, url) => const SizedBox(
              width: 30,
              height: 30,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.white70,
                ),
              ),
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 30,
            ),
          ),
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
                          ? Lottie.network(
                              url,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Container(
                                color: Colors.white10,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

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
                  // একই লজিক এখানেও ব্যবহার করুন
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: url.toLowerCase().contains('.json')
                          ? LottieBuilder.network(
                              url,
                              fit: BoxFit.contain,
                              animate: true,
                              repeat: true,
                              onLoaded: (composition) {},
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.error_outline,
                                    color: Colors.red);
                              },
                            )
                          : CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Container(
                                color: Colors.white10,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
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
                          String newUrl = isPicked ? "" : url;
                          bool newStatus = !isPicked;
                          String newName = isPicked ? "" : name;

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uIDValue)
                              .update({
                            'activeSpecialUrl': newUrl,
                            'hasSpecialEffect': newStatus,
                            'activeSpecialName': newName,
                          });

                          QuerySnapshot marriageQuery = await FirebaseFirestore
                              .instance
                              .collection('marriages')
                              .where('myAuthUID', isEqualTo: uIDValue)
                              .limit(1)
                              .get();

                          if (marriageQuery.docs.isEmpty) {
                            marriageQuery = await FirebaseFirestore.instance
                                .collection('marriages')
                                .where('partnerAuthUID', isEqualTo: uIDValue)
                                .limit(1)
                                .get();
                          }

                          if (marriageQuery.docs.isNotEmpty) {
                            String marriageDocId = marriageQuery.docs.first.id;
                            await FirebaseFirestore.instance
                                .collection('marriages')
                                .doc(marriageDocId)
                                .update({
                              'ringIcon': newUrl,
                              'ringName': newName,
                            });
                          }

                          setState(() {
                            activeSpecialUrl = newUrl;
                            hasSpecialEffect = newStatus;
                          });

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isPicked
                                    ? "$name Unpicked!"
                                    : "$name Picked & Applied! 💍✨"),
                                backgroundColor:
                                    isPicked ? Colors.orange : Colors.purple,
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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uIDValue)
          .collection('my_frames')
          .snapshots(),
      builder: (context, snapshot) {
        List<Map<String, String>> myAvailableFrames = [];

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

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            dynamic expiryData = data['expiryDate'];
            String expiryString = "Permanent";

            if (expiryData != null && expiryData is Timestamp) {
              DateTime date = expiryData.toDate();
              expiryString = "${date.day}/${date.month}/${date.year}";
            }

            myAvailableFrames.add({
              "name": data['name']?.toString() ?? "Purchased Frame",
              "url": data['image_url']?.toString() ?? "",
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
                  SizedBox(
                    height: 65,
                    child: currentUrl.contains('.json')
                        ? Lottie.network(currentUrl) // Lottie নিজেই ক্যাশ করে
                        : CachedNetworkImage(
                            imageUrl: currentUrl,
                            fit: BoxFit.contain,
                            errorWidget: (context, url, error) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey),
                          ),
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
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uIDValue)
                            .update({'activeFrameUrl': newFrame});
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
    final String myAuthId = FirebaseAuth.instance.currentUser?.uid ?? "";

    // এখানে মূল সমাধান: নিজের প্রোফাইল হলে mySixDigitUID ব্যবহার করতে হবে,
    // কারণ আপনার আসল ডকুমেন্ট আইডি ফায়ারস্টোরের কাস্টম বা অটো আইডি হতে পারে।
    final String targetUserId =
        widget.userId ?? (mySixDigitUID.isNotEmpty ? mySixDigitUID : myAuthId);
    final bool isMe = widget.userId == null ||
        widget.userId == myAuthId ||
        targetUserId == mySixDigitUID;

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
        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F1E),
            body: Center(
                child: Text("Error!", style: TextStyle(color: Colors.white))),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            diamonds == 0) {
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
          uIDValue = (userData['uID'] ?? "N/A").toString();

          // রিয়েল-টাইম ডায়মন্ড আপডেট
          var diamondData = userData['diamonds'];
          diamonds = (diamondData is String)
              ? (int.tryParse(diamondData) ?? 0)
              : (diamondData ?? 0).toInt();

          var xpData = userData['vip_xp'];
          xp = (xpData is String)
              ? (int.tryParse(xpData) ?? 0)
              : (xpData ?? 0).toInt();

          vipExpiry = userData['vipExpiry'] ?? 0;
          userImageURL = userData['profilePic'] ?? "";
          gender = userData['gender'] ?? "Unfixed";
          hasPremiumCard = userData['hasPremiumCard'] ?? false;

          var followersData = userData['followers'];
          followers = (followersData is String)
              ? (int.tryParse(followersData) ?? 0)
              : (followersData ?? 0).toInt();

          var followingData = userData['following'];
          following = (followingData is String)
              ? (int.tryParse(followingData) ?? 0)
              : (followingData ?? 0).toInt();

          isMarried = userData['isMarried'] ?? false;
          partnerUid = userData['partnerUid'] ?? '';
          marriageDocId = userData['marriageDocId'] ?? '';
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
            // leadinWidth বাদ দেওয়া হলো যাতে ডাইমন্ডের টেক্সট বড় বা ছোট হলে বক্স নিজে থেকেই জায়গা অ্যাডজাস্ট করে নিতে পারে
            leadingWidth: isMe ? 150 : 56,
            leading: isMe
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        // প্রিমিয়াম মাল্টি-কালার গ্লাস ব্যাকগ্রাউন্ড (বর্ডারের ভেতরের মিক্স কালার)
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade900.withOpacity(0.6),
                            Colors.blue.shade900.withOpacity(0.6),
                            Colors.black.withOpacity(0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(
                              0xFFFFD700), // রিয়েল গোল্ডেন চিকন বর্ডার
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.25),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize
                            .min, // ডাইমন্ড কম-বেশি হলে বক্স অটো ছোট-বড় হবে
                        children: [
                          // প্রিমিয়াম রিয়ালিস্টিক ডায়মন্ড লুক টেক্সট শ্যাডো সহ
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF00E5FF),
                                Color(0xFF7C4DFF),
                                Color(0xFFFF4081)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Text(
                              "💎",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "$diamonds",
                            style: const TextStyle(
                              color: Color(
                                  0xFFFFE082), // গোল্ডেনশ মাল্টি-কালার টেক্সট
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const BackButton(color: Colors.white),
            actions: [
              if (isMe)
                Center(
                  child: Container(
                    height: 32,
                    width: 32,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      // সেটিংস বাটনেও প্রিমিয়াম মাল্টি-কালার মিক্স গ্লাস ব্যাকগ্রাউন্ড
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade900.withOpacity(0.6),
                          Colors.purple.shade900.withOpacity(0.6),
                          Colors.black.withOpacity(0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(
                            0xFFFFD700), // রিয়েল গোল্ডেন চিকন বর্ডার
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.25),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.settings,
                        color: Color(0xFF80D8FF), // প্রিমিয়াম ব্রাইট আইকন কালার
                        size: 16,
                      ),
                      onPressed: _openSettings,
                    ),
                  ),
                ),
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
                          .doc(marriageDocId.isNotEmpty
                              ? marriageDocId
                              : targetUserId)
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
                          // পার্টনারের আইডি ব্যবহার করে সরাসরি 'users' কালেকশন থেকে ডাটা নেওয়া হচ্ছে
                          return StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(partnerUid) // পার্টনারের লাইভ ইউজার ডক
                                .snapshots(),
                            builder: (context, userSnapshot) {
                              // পার্টনারের লাইভ ডাটা
                              var partnerData = {};
                              if (userSnapshot.hasData &&
                                  userSnapshot.data!.exists) {
                                partnerData = userSnapshot.data!.data()
                                    as Map<String, dynamic>;
                              }

                              // 🔥 এখানে ভুল ছিল: আমরা marriageData থেকে না নিয়ে partnerData থেকে ডাটা নেবো
                              String partnerImg = partnerData['profilePic'] ??
                                  marriageData['partnerImage'] ??
                                  '';
                              String livePartnerFrame =
                                  partnerData['activeFrameUrl'] ??
                                      partnerData['activeFrame'] ??
                                      '';

                              // ফ্রেমের জন্য লজিক: লাইভ ফ্রেম না থাকলে পুরাতন বা ম্যারেজ ডাটা থেকে নিবে
                              String finalPartnerFrame =
                                  livePartnerFrame.isNotEmpty
                                      ? livePartnerFrame
                                      : (marriageData['partnerFrameUrl'] ?? '');

                              Map<String, dynamic> formattedMarriageData = {
                                'ringIcon': marriageData['ringIconUrl'] ??
                                    marriageData['ringIcon'],
                                'partnerImage':
                                    partnerImg, // এখানে এখন পার্টনারের লাইভ প্রোফাইল পিক আসবে
                                'partnerFrameUrl':
                                    finalPartnerFrame, // এখানে পার্টনারের লাইভ ফ্রেম আসবে
                              };

                              return Center(
                                child: _buildMarriageHeader(
                                  context,
                                  formattedMarriageData,
                                  userImageURL,
                                  activeFrameUrl,
                                  marriageData,
                                  isMe,
                                ),
                              );
                            },
                          );
                        }
                        // 👤 যদি সিঙ্গেল হয় (কোনো পার্টনার না থাকে), তবে শুধু নিজের পুরাতন প্রোফাইল পিকচারটি দেখা

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
                                          : CachedNetworkImage(
                                              imageUrl: activeFrameUrl,
                                              fit: BoxFit.contain,
                                              placeholder: (context, url) =>
                                                  const SizedBox(),
                                              errorWidget: (c, e, s) =>
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
                    (() {
                      // রোল বা স্ট্যাটাস চেক করার লজিক
                      bool isOfficial = (userData['isOfficial'] == true) ||
                          (userData['role'] == 'official');
                      bool isSuperAdmin = (userData['isSuperAdmin'] == true) ||
                          (userData['role'] == 'super_admin');
                      bool isSpecialUser = isOfficial || isSuperAdmin;

                      // অফিশিয়াল বা সুপার এডমিন হলে স্পেশাল শিমার ডিজাইন, না হলে নরমাল ডিজাইন
                      return GestureDetector(
                        onTap: isMe ? () => _editName(userData) : null,
                        child: Container(
                          // 🌟 প্যাডিং কমিয়ে স্লিম ও স্মুথ করা হলো (ব্যাজের মতো করে)
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSpecialUser
                                ? Colors.black.withOpacity(0.4)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                20), // বর্ডার রেডিয়াসও একটু স্লিম লুকের জন্য অ্যাডজাস্ট করা হলো
                            border: Border.all(
                              color: isSpecialUser
                                  ? const Color(0xFFFFD700)
                                  : Colors.white.withOpacity(
                                      0.3), // গোল্ডেন বর্ডার শুধু স্পেশালদের জন্য
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSpecialUser
                                    ? const Color(0xFFFFD700).withOpacity(0.3)
                                    : Colors.purpleAccent.withOpacity(0.15),
                                blurRadius: isSpecialUser ? 6 : 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: isSpecialUser
                              ? Shimmer.fromColors(
                                  baseColor: isOfficial
                                      ? Colors.amber
                                      : Colors.purpleAccent,
                                  highlightColor: Colors.white,
                                  period: const Duration(milliseconds: 1500),
                                  child: Text(
                                    userName,
                                    style: const TextStyle(
                                      fontSize:
                                          16, // সাইজও প্রফাইলের সাথে সামঞ্জস্য রাখা হলো
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                      height: 1.0,
                                    ),
                                  ),
                                )
                              : Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                    height: 1.0,
                                  ),
                                ),
                        ),
                      );
                    })(),
// --- নামের গ্লাস বর্ডার বক্স শেষ ---

                    Stack(
                      clipBehavior: Clip
                          .none, // এটা খুব জরুরি, যাতে ব্যাজটি আইডির সীমানার বাইরেও ভেসে থাকতে পারে
                      children: [
                        // ১. আপনার আইডি (এটি যেমন ছিল ঠিক তেমনই থাকবে, কিচ্ছু সরবে না)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: uIDValue.toString()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("ID Copied!"),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Builder(
                            builder: (context) {
                              bool isOfficial =
                                  (userData['isOfficial'] == true) ||
                                      (userData['role'] == 'official');
                              bool isSuperAdmin =
                                  (userData['isSuperAdmin'] == true) ||
                                      (userData['role'] == 'super_admin');
                              bool isSpecialUser = isOfficial || isSuperAdmin;

                              // যদি অফিশিয়াল বা সুপার এডমিন হয়, তবে আইডিতেও হালকা শিমার বা প্রিমিয়াম লুক আসবে, অন্যথায় নরমাল থাকবে
                              return isSpecialUser
                                  ? Shimmer.fromColors(
                                      baseColor: const Color.fromARGB(
                                          255, 4, 189, 251),
                                      highlightColor: Colors.white,
                                      period:
                                          const Duration(milliseconds: 1500),
                                      child: Text(
                                        "ID: $uIDValue",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      "ID: $uIDValue",
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 4, 189, 251),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                            },
                          ),
                        ),

                        // ২. ভাসমান ব্যাজ (এটি আইডির ওপর বা পাশে ভাসবে)
                        Positioned(
                          left: -80,
                          top: -5,
                          child: UserBadgeWidget(
                            gender:
                                gender, // এটি আপনার ওই ভেরিয়েবল যা ডাটা লোড হওয়ার পর আপডেট হয়েছে
                            age: age.toString(), // এটি আপনার ওই age ভেরিয়েবল
                          ),
                        ),
                        // ৩. ডান পাশের ব্যাজ (এজেন্সি থাকলে এজেন্সি, না থাকলে ভেরিফাইড ব্যাজ)
                        Positioned(
                          right: -80,
                          top: -5,
                          child: isAgent
                              ? AgencyBadgeWidget(
                                  isAgent: isAgent,
                                  imageUrl:
                                      "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/agancy.png",
                                )
                              : (userData['isVerified'] == true
                                  ? const Icon(
                                      Icons.verified,
                                      color: Color(0xFF00FBFF),
                                      size: 17,
                                    )
                                  : const SizedBox
                                      .shrink()), // দুটোই না থাকলে খালি থাকবে
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    UserBadgesRow(userId: uIDValue.toString()),
                    const SizedBox(height: 5),
                    // VIP এবং ডাইনামিক XP প্রগ্রেস বার সেকশন
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 🔥 ১. VIP ব্যাজের ওপর শিমার শাইনিং ইফেক্ট (অরিজিনাল লজিক ঠিক রেখে)
                          if (vipLevel > 0 &&
                              getVipBadge(vipLevel).toString().isNotEmpty &&
                              !getVipBadge(vipLevel)
                                  .toString()
                                  .startsWith('file:'))
                            _buildShiningBadgeWrapper(
                              CachedNetworkImage(
                                imageUrl: getVipBadge(vipLevel),
                                width: 45,
                                height: 45,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                errorWidget: (c, e, s) => const Icon(
                                  Icons.stars_rounded,
                                  color: Colors.white24,
                                  size: 40,
                                ),
                              ),
                            )
                          else
                            _buildShiningBadgeWrapper(
                              const Icon(Icons.stars_rounded,
                                  color: Colors.white24, size: 40),
                            ),

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
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Shimmer দিয়ে আগুনের তরঙ্গ এবং মাথায় আলাদা আগুনের শিখা
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double maxWidth =
                                        constraints.maxWidth;
                                    final double barWidth =
                                        maxWidth * progressValue;

                                    return Container(
                                      height:
                                          12, // সামান্য মোটা করা হলো যাতে ইফেক্টটি ভালো দেখা যায় ভাই
                                      width: maxWidth,
                                      decoration: BoxDecoration(
                                        color: Colors
                                            .white10, // বারের ব্যাকগ্রাউন্ড
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ), // বারের ধারালো বর্ডার
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
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
                                                      // গ্রেডিয়েন্ট দেওয়া হলো যাতে শুরু থেকে মাথায় কালার চেঞ্জ হয়
                                                      gradient:
                                                          const LinearGradient(
                                                        colors: [
                                                          Color(
                                                              0xFFFFC107), // শুরু গোল্ডেন
                                                          Color(
                                                              0xFFFFD700), // মাছ গোল্ডেন
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                            // ২. মাথায় সেই জ্বলজ্বলে আগুনের শিখা বা বিন্দু (The Glowing Fire Head)
                                            if (barWidth > 0)
                                              Positioned(
                                                left: barWidth -
                                                    10, // মাথার বিন্দুটি ঠিক প্রগ্রেসের শেষ মাথায় বসবে
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
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
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
                                                            color: Colors.orange
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
                            ),
                          ),
                          const SizedBox(width: 15),

                          // 🔥 ২. প্রিমিয়াম ব্যাজের ওপর শিমার শাইনিং ইফেক্ট (অরিজিনাল লজিক ঠিক রেখে)
                          if (hasPremiumCard &&
                              (premiumBadgeUrl ?? '').toString().isNotEmpty &&
                              !premiumBadgeUrl.toString().startsWith('file:'))
                            _buildShiningBadgeWrapper(
                              CachedNetworkImage(
                                imageUrl: premiumBadgeUrl,
                                width: 45,
                                height: 45,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                errorWidget: (c, e, s) =>
                                    const SizedBox(width: 45),
                              ),
                            )
                          else
                            const SizedBox(width: 45),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),

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

                    const SizedBox(height: 5),

                    // Followers & Following
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStat(
                            "Followers", followers, sixDigitProfileID, context),
                        const SizedBox(width: 25),
                        if (!isMe) ...[
                          // ফলো / আনফলো বাটন (ব্যাজের মতো গ্লাস ইফেক্ট, চিকন গোল্ডেন বর্ডার ও মাল্টি-কালার টেক্সট)
                          Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black
                                  .withOpacity(0.4), // গ্লাস ব্যাকগ্রাউন্ড
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(
                                    0xFFFFD700), // রিয়েল গোল্ড চিকন বর্ডার
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFFD700).withOpacity(0.2),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () async {
                                  // সার্ভিস কল: ফলো বা আনফলো করা
                                  bool nowFollowing = await FollowService()
                                      .toggleFollowUser(
                                          targetUserId, mySixDigitUID);

                                  // সাথে সাথে চেক করা সেও আপনাকে ফলো করে কি না (Mutual Friend চেক)
                                  bool mutual = await FollowService()
                                      .checkIfMutualFriend(
                                          targetUserId, mySixDigitUID);

                                  if (mounted) {
                                    setState(() {
                                      isFollowing = nowFollowing;
                                      isFriend =
                                          mutual; // ফ্রেন্ড স্ট্যাটাস আপডেট

                                      // কাউন্ট আপডেট লজিক
                                      if (nowFollowing) {
                                        followers += 1;
                                      } else {
                                        followers =
                                            (followers > 0) ? followers - 1 : 0;
                                        isFriend =
                                            false; // আনফলো করলে ফ্রেন্ডশিপও থাকবে না
                                      }
                                    });
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  child: Center(
                                    child: DefaultTextStyle(
                                      style: TextStyle(
                                        // গ্লোবাল থিম ওভাররাইড ঠেকানোর জন্য এখানে কালার ফিক্সড করে দেওয়া হলো
                                        color: isFriend || isFollowing
                                            ? const Color(0xFFFFE082)
                                            : const Color(0xFFFF80AB),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        height: 1.0,
                                      ),
                                      child: Text(
                                        isFriend
                                            ? "Friend"
                                            : (isFollowing
                                                ? "Following"
                                                : "Follow"),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                              width: 10), // আগের দূরত্ব অপরিবর্তিত রাখা হয়েছে
                          // মেইল বা মেসেজ আইকন (ব্যাজের স্টাইলের মতো গ্লাস ও চিকন গোল্ডেন বর্ডার)
                          Container(
                            height: 32,
                            width: 32,
                            decoration: BoxDecoration(
                              color: Colors.black
                                  .withOpacity(0.4), // গ্লাস ব্যাকগ্রাউন্ড
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(
                                    0xFFFFD700), // রিয়েল গোল্ড চিকন বর্ডার
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFFD700).withOpacity(0.2),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.mail,
                                  color: Color(0xFF80D8FF),
                                  size:
                                      16), // মাল্টি-কালার লুকের জন্য লাইট সায়ান আইকন
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      receiverId: targetUserId,
                                      receiverName: userName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ] else
                          const SizedBox(
                            width: 80,
                            child: Center(
                              child: Text(
                                "MY PROFILE",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 25),
                        _buildStat(
                            "Following", following, sixDigitProfileID, context),
                      ],
                    ),
                    const SizedBox(height: 15),

                    if (isMe) ...[
                      // প্রথম লাইন (৪টি বাটন)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionBox("Diamond", Icons.diamond, Colors.cyan,
                              () => _openDiamondStore(userData)),
                          _buildActionBox("Premium", Icons.card_membership,
                              Colors.purple, _openPremiumStore),
                          _buildActionBox("Backpack", Icons.backpack,
                              Colors.orange, _openBackpack),
                          _buildActionBox("Visitors", Icons.visibility,
                              Colors.green, _openVisitors), // নতুন ১
                        ],
                      ),
                      const SizedBox(height: 10), // দুই লাইনের মাঝে ফাঁকা জায়গা

                      // দ্বিতীয় লাইন (৪টি বাটন)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionBox("My Post", Icons.post_add,
                              Colors.blue, _openMyPosts),
                          _buildActionBox(
                              "VIP", Icons.star, Colors.amber, _openVIP),

                          _buildActionBox("Games", Icons.videogame_asset,
                              Colors.red, _openGames),

                          _buildActionBox(
                              "Facebook",
                              Icons.facebook,
                              Colors.blueAccent,
                              _openFacebook), // নতুন ৪ (লিংকসহ)
                        ],
                      ),
                      const SizedBox(height: 25),
                    ],
                    const SizedBox(height: 0),
                    // ❤️ সোলমেট সেকশন
                    TeamPanelAndSoulmateSection(uIDValue: uIDValue),
                    const SizedBox(height: 10),
                    // আপনার মেইন ফাইলের সোলমেট সেকশনটি এখন ঠিক নিচে কল করুন:
                    _buildSoulmateSection(),

                    const SizedBox(height: 30),
                  ], // Column এর children শেষ
                ), // Column শেষ
              ), // SingleChildScrollView শেষ

              // --- ফুল পেজ ফ্রেম ---
// 🔍 [প্রিন্ট ৩]: ব্যাকগ্রাউন্ড ফুল পেজ ফ্রেমের লিংক টেস্ট
              () {
                return const SizedBox();
              }(),
// লজিক চেক: যদি URL থাকে তবেই লটি বা ইমেজ দেখাবে, নয়তো খালি থাকবে
              if (activeSpecialUrl.toString().isNotEmpty &&
                  !activeSpecialUrl.toString().startsWith('file:'))
                Positioned.fill(
                  child: IgnorePointer(
                    child: activeSpecialUrl
                            .toString()
                            .toLowerCase()
                            .contains('.json')
                        ? Lottie.network(
                            activeSpecialUrl,
                            fit: BoxFit.fill,
                            repeat: true,
                            animate: true,
                          )
                        : Container(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(activeSpecialUrl),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                  ),
                ),
            ], // Stack এর children শেষ
          ), // Stack শেষ (বডি শেষ)
        ); // Scaffold শেষ
      }, // StreamBuilder builder শেষ
    ); // StreamBuilder শেষ
  }

  Widget _buildStat(
      String label, int value, String profileUID, BuildContext context) {
    // logic: যদি আমার নিজের আইডি (mySixDigitUID) এবং বর্তমানে যে প্রোফাইলটি দেখছি তার আইডি (profileUID) সমান হয়, তবেই লিস্ট দেখা যাবে।
    bool isMyProfile = (mySixDigitUID == profileUID);

    return GestureDetector(
      onTap: () {
        if (isMyProfile) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserListScreen(
                  title: label,
                  userId: profileUID,
                  mySixDigitUID: mySixDigitUID),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("You can only see your own list!"),
            backgroundColor: Colors.redAccent,
          ));
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

  Widget _buildActionBox(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // সাইজ কমিয়ে দিলাম (আপনার আগেরটি ছিল 100x85)
        width: 75,
        height: 70,
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10), // রাউন্ড একটু কমিয়ে দিলাম
            border: Border.all(color: color.withOpacity(0.5))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 22), // আইকন সাইজ ২৮ থেকে ২২ করলাম
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10)) // ফন্ট সাইজ ১১ থেকে ১০ করলাম
        ]),
      ),
    );
  }

// ✅ ৩. প্রিয়জন (Soulmate) ৬ স্লট মেইন উইজেট (আপডেট করা)
  Widget _buildSoulmateSection() {
    String currentId = uIDValue.toString().trim();
    if (currentId.isEmpty) {
      currentId = FirebaseAuth.instance.currentUser?.uid ?? '';
    }

    const String soulmateCardUrl =
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/soulmatecard.jpg";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Text("𝐇𝐚𝐫𝐭—̳͟͞͞💗(𝐒𝐨𝐮𝐥𝐦𝐚𝐭𝐞𝐬)",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ),
        StreamBuilder<DocumentSnapshot>(
          // সরাসরি নিজের ডকুমেন্ট থেকে সোলমেট আইডিগুলোর অ্যারে নিচ্ছি
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: CircularProgressIndicator());
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;
            List<dynamic> soulmatesList = userData['soulmates'] ?? [];

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.82,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 6, // সবসময় ৬টি ঘর
              itemBuilder: (context, index) {
                bool hasData = index < soulmatesList.length;

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    image: const DecorationImage(
                      image: CachedNetworkImageProvider(soulmateCardUrl),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: hasData
                      ? _buildFilledSoulmateFromId(soulmatesList[
                          index]) // আইডি থেকে পার্টনারের ডাটা লোড হবে
                      : _buildEmptySoulmate(),
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

// ✨ নিখুঁত, হালকা ও স্মুথ শিমার শাইনিং ইফেক্ট উইজেট
  Widget _buildShiningBadgeWrapper(Widget child) {
    return SizedBox(
      width: 45,
      height: 45,
      child: Stack(
        alignment: Alignment.center,
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: Shimmer.fromColors(
                baseColor: Colors.white.withOpacity(0.05),
                highlightColor: Colors.white
                    .withOpacity(0.85), // খুব বেশি কড়া নয়, একদম ন্যাচারাল
                period: const Duration(
                    milliseconds:
                        2200), // গতি একটু ধীর করা হয়েছে যাতে স্মুথ লাগে
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.05),
                        Colors.amberAccent
                            .withOpacity(0.25), // হালকা সোনালী আভা
                        Colors.white.withOpacity(0.4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// 💡 হেল্পার উইজেট: আইডি থেকে পার্টনারের ডাটা লোড করবে
  Widget _buildFilledSoulmateFromId(String partnerUid) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(partnerUid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        var partnerData = snapshot.data!.data() as Map<String, dynamic>;

        // এখানে partnerData থেকেই সব তথ্য নেওয়া হচ্ছে, যা আগে ঠিক ছিল
        Map<String, dynamic> displayData = {
          'partnerName': partnerData['name'] ?? 'Unknown',
          'partnerImage':
              partnerData['image'] ?? partnerData['profilePic'] ?? '',
          'totalGift': partnerData['totalGift'] ?? 0,
          // ব্রেকআপ বাটন কাজ করার জন্য পার্টনারের আইডিটি এখানে যোগ করে দিলাম
          'partnerId': partnerUid,
          'ownerId': uIDValue,
        };

        return _buildFilledSoulmate(displayData);
      },
    );
  }

// 🔥 কার্ড উইজেট
  Widget _buildFilledSoulmate(Map<String, dynamic> data) {
    int totalGift = data['totalGift'] ?? 0;
    int level = (totalGift / 5000).floor().clamp(1, 50);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SoulmateDetailPage(
              soulmateData: data,
              uIDValue: uIDValue, // আপনার গ্লোবাল ইউজার আইডি
            ),
          ),
        );
      },
      // 🔥 ব্রেকআপ বাটন ট্রিগার করার জন্য লং প্রেস
      onLongPress: () {
        String partnerId = data['partnerId'] ?? '';
        if (partnerId.isNotEmpty) {
          _showBreakupDialog(partnerId);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              margin: const EdgeInsets.only(right: 12, top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text("Lv.$level",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const Spacer(),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber, width: 2),
              image: DecorationImage(
                image: NetworkImage(data['partnerImage'] ?? ""),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              data['partnerName'] ?? "Unknown",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text("Soulmate",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold)),
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

// ✅ ৫. প্রিমিয়াম ম্যারেজ হেডার (চারপাশে সমান গোল ফ্রেম সাইজ কন্ট্রোল ১০০% ফিক্সড + লাইফটাইম রিং অ্যানিমেশন ও শিমার শাইনিং - ক্রাশপ্রুফ ফিক্সড)
  Widget _buildMarriageHeader(
      BuildContext context,
      Map<String, dynamic> data,
      String myImg,
      String myFrame,
      Map<String, dynamic> rawMarriageDoc,
      bool isMe) {
    String ringIconUrl = data['ringIcon'] ??
        data['ringIconUrl'] ??
        "https://i.ibb.co/ring-sample.png";
    String partnerImg = data['partnerImage'] ?? data['partnerProfilePic'] ?? '';

    // 🔥 পার্টনারের ফ্রেমের জন্য সেফ চেক ও ফলব্যাক (ইরর হ্যান্ডেলিং সহ)
    String partnerFrame = (data['partnerFrameUrl'] ??
            data['activeFrameUrl'] ??
            data['partnerFrame'] ??
            data['activeFrame'] ??
            '')
        .toString();

    double avatarRadius = 45; // ছবির ব্যাসার্ধ

    // 🔥 [১ নম্বর কন্ট্রোল] লত্তি (.json) ফ্রেমের সাইজ কম-বেশি করার অপশন
    double lottieMultiplier = 3.1;

    // 🔥 [২ নম্বর কন্ট্রোল] সাধারণ ইমেজ (PNG/JPG) ফ্রেমের সাইজ কম-বেশি করার অপশন
    double imageMultiplier = 2.8;

    // বর্তমান ইউজারের ফ্রেমের টাইপ অনুযায়ী ডায়নামিক সাইজ নির্ধারণ
    bool isMyFrameLottie = myFrame.contains('.json');
    double myFrameSize =
        avatarRadius * (isMyFrameLottie ? lottieMultiplier : imageMultiplier);

    // পার্টনারের ফ্রেমের টাইপ অনুযায়ী ডায়নামিক সাইজ নির্ধারণ
    bool isPartnerFrameLottie =
        partnerFrame.isNotEmpty && partnerFrame.contains('.json');
    double partnerFrameSize = avatarRadius *
        (isPartnerFrameLottie ? lottieMultiplier : imageMultiplier);

    // 🔥 [৩ নম্বর কন্ট্রোল] ছবি দুটি রিং-এর কতটা কাছে আসবে তা এখান থেকে কন্ট্রোল করুন
    double overlapDistance = 25;

    // টোটাল উইডথ হিসাব
    double totalWidth = (myFrameSize + partnerFrameSize) - overlapDistance;
    double totalHeight =
        myFrameSize > partnerFrameSize ? myFrameSize : partnerFrameSize;

    return Container(
      padding: EdgeInsets.zero,
      alignment: Alignment.topCenter,
      constraints: BoxConstraints(maxHeight: totalHeight),
      child: SizedBox(
        width: totalWidth,
        height: totalHeight,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // ১. নিজের প্রোফাইল ছবি ও ফ্রেম
            Positioned(
              left: (totalWidth / 2) - myFrameSize + (overlapDistance / 2),
              top: 0,
              child: GestureDetector(
                onTap: isMe ? _pickProfileImage : null,
                child: _buildUserWithFrame(myImg, myFrame, avatarRadius,
                    lottieMultiplier, imageMultiplier),
              ),
            ),

            // ২. পার্টনারের প্রোফাইল ছবি ও ফ্রেম (সেফ চেকসহ)
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

            // 💍 ম্যারেজ রিং আইকন (সম্পূর্ণ সেফ ও লাইফটাইম অ্যানিমেটেড রিং উইজেট)
            Positioned(
              top: 15,
              child: GestureDetector(
                onTap: () async {
                  String currentUid =
                      FirebaseAuth.instance.currentUser?.uid ?? '';
                  String partnerAuthUID =
                      rawMarriageDoc['partnerAuthUID'] ?? '';

                  String marriageDocId = rawMarriageDoc['marriageId'] ??
                      rawMarriageDoc['id'] ??
                      rawMarriageDoc['docId'] ??
                      "${currentUid}_$partnerAuthUID";

                  String finalMyName = '';
                  String finalMyImage = '';

                  try {
                    if (currentUid.isNotEmpty) {
                      QuerySnapshot userQuery = await FirebaseFirestore.instance
                          .collection('users')
                          .where('uid', isEqualTo: currentUid)
                          .limit(1)
                          .get();

                      if (userQuery.docs.isNotEmpty) {
                        var uData =
                            userQuery.docs.first.data() as Map<String, dynamic>;

                        finalMyName = uData['name'] ??
                            uData['username'] ??
                            uData['nickName'] ??
                            '';
                        finalMyImage = uData['profilePic'] ??
                            uData['image'] ??
                            uData['avatar'] ??
                            '';
                      }
                    }
                  } catch (e) {
                    // ক্যাচ ব্লক
                  }

                  if (finalMyName.trim().isEmpty) {
                    finalMyName =
                        FirebaseAuth.instance.currentUser?.displayName ?? '';
                  }
                  if (finalMyImage.trim().isEmpty) {
                    finalMyImage =
                        FirebaseAuth.instance.currentUser?.photoURL ?? '';
                  }

                  if (finalMyName.trim().isEmpty) {
                    finalMyName = data['name'] ?? data['username'] ?? '';
                  }

                  if (finalMyName.trim().isEmpty) {
                    finalMyName = "User";
                  }

                  finalMyName = finalMyName.trim();
                  finalMyImage = finalMyImage.trim();

                  _showDivorceBottomSheet(
                    context: context,
                    marriageData: rawMarriageDoc,
                    marriageDocId: marriageDocId,
                    myName: finalMyName,
                    myImage: finalMyImage,
                  );
                },
                child: _InfiniteRingAnimator(
                  ringIconUrl: ringIconUrl,
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
                                    : CachedNetworkImage(
                                        imageUrl: myImage.trim(),
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, error,
                                                stackTrace) =>
                                            const Icon(Icons.person,
                                                color: Colors.white, size: 35),
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
                                    : CachedNetworkImage(
                                        imageUrl: partnerImage.trim(),
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, error,
                                                stackTrace) =>
                                            const Icon(Icons.person,
                                                color: Colors.white, size: 35),
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
                                          style: TextStyle(color: Colors.red))),
                                ]),
                          ) ??
                          false;

                      if (confirm) {
                        // ❌ সাবধান: এখানে আগে Navigator.pop(context) কল করা যাবে না।
                        // করলে কনটেক্সট ডেড হয়ে যাবে এবং অ্যাপ হ্যাং করবে।

                        // ⏳ লোডিং ডায়ালগ ওপেন
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.redAccent)),
                        );

                        try {
                          // ১. সঠিক ইউজার ডকুমেন্ট খোঁজা (where কুয়েরি দিয়ে)
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

                            if (currentDiamonds < 3000) {
                              throw "Insufficient Diamonds! You need 3000 💎";
                            }

                            transaction.update(userRef, {
                              'diamonds': currentDiamonds - 3000,
                            });
                          });

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

                          // ৪. সাবধানে ডায়ালগ এবং বটম শিট বন্ধ করা
                          Navigator.pop(context); // প্রথমে লোডিং ডায়ালগ বন্ধ
                          Navigator.pop(context); // এরপর বটম শিট বন্ধ

                          // ۵. সাকসেস মেসেজ
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "💔 Divorce Completed Successfully! 3000 💎 Charged."),
                                backgroundColor: Colors.green),
                          );
                        } catch (e) {
                          // এরর হলেও যাতে হ্যাং না হয়, সেজন্য লোডিংটা বন্ধ করতে হবে
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

    // ১. একদম ডিপ ব্ল্যাক ও ভায়োলেট কালার দিয়ে ফুল স্ক্রিন বেস ফিল করা
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF070510), // খুব গাঢ় ডিপ ব্ল্যাক-পার্পল
        Color(0xFF030206), // নিরেট কালো
        Color(0xFF0A0612),
      ],
    ).createShader(rect);
    canvas.drawRect(rect, paint);

    // ২. ছবির বাম পাশের মতো প্রিমিয়াম নিয়ন পার্পল/ভায়োলেট গ্লো কার্ভ (Soft Glowing Wave)
    final Paint glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 60); // হালকা ব্লার ইফেক্ট

    // বাম পাশের প্রধান পার্পল গ্লো
    glowPaint.shader = RadialGradient(
      center: const Alignment(-0.8, -0.3),
      radius: 0.9,
      colors: [
        const Color(0xFF8B00FF).withOpacity(0.55), // উজ্জ্বল ভায়োলেট/পার্পল
        const Color(0xFF4A00E0).withOpacity(0.3), // ডিপ ব্লু-পার্পল
        Colors.transparent,
      ],
    ).createShader(rect);

    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.3),
        size.width * 0.5, glowPaint);

    // ৩. মাঝখান থেকে ডানপাশের দিকে ছড়ানো ডিপ ব্লু এবং রয়্যাল পার্পল শ্যাডো
    final Paint secondaryGlow = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    secondaryGlow.shader = RadialGradient(
      center: const Alignment(-0.2, 0.4),
      radius: 1.1,
      colors: [
        const Color(0xFF3F00FF).withOpacity(0.25), // রয়্যাল ব্লু আভা
        const Color(0xFF150033).withOpacity(0.15),
        Colors.transparent,
      ],
    ).createShader(rect);

    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.7),
        size.width * 0.7, secondaryGlow);

    // ৪. ছবির ফিনিশিংয়ের সাথে মিল রেখে অত্যন্ত সূক্ষ্ম ও মিহি কিছু স্পার্কল/তারকা (যা দেখতে রিয়েলিস্টিক গ্লাস ফিলের মতো লাগে)
    final random = math.Random(42);
    for (int i = 0; i < 40; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double starSize = random.nextDouble() * 1.5;

      paint.shader = null;
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.25);
      canvas.drawCircle(Offset(x, y), starSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 🔄 শতভাগ নিরাপদ ও ক্রাশপ্রুফ ইনফিনিট লুপ রিং অ্যানিমেটর উইজেট (Assertion Error Fixed)
class _InfiniteRingAnimator extends StatefulWidget {
  final String ringIconUrl;
  const _InfiniteRingAnimator({required this.ringIconUrl});

  @override
  State<_InfiniteRingAnimator> createState() => _InfiniteRingAnimatorState();
}

class _InfiniteRingAnimatorState extends State<_InfiniteRingAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double val = _controller.value;

        // সেফটি ক্যালকুলেশন যাতে অপাসিটি বা সাইজ কোনোভাবেই ০ এবং ১ এর সীমানা পার হয়ে এরর না দেয়
        double sineValue = sin(val * pi * 2);
        double scale = 1.0 + (0.05 * sineValue);
        double glowOpacity = (0.3 + (0.3 * sineValue)).clamp(0.0, 1.0);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 65,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(glowOpacity),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.ringIconUrl,
                    width: 60,
                    height: 55,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const SizedBox(
                      width: 20,
                      height: 20,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    errorWidget: (context, error, stackTrace) {
                      return const Icon(Icons.favorite,
                          color: Colors.pink, size: 30);
                    },
                  ),
                  // ✨ সেফ শিমার শাইনিং ইফেক্ট
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment(
                        (val * 4.0) - 2.0,
                        0.0,
                      ),
                      child: Container(
                        width: 15,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.4),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
