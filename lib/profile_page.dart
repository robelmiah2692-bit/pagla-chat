import 'dart:io'; 
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; 
import 'chat_screen.dart';
import 'package:pagla_chat/services/database_service.dart';
import 'user_list_screen.dart';
import 'package:pagla_chat/services/soulmate_service.dart';

class ProfilePage extends StatefulWidget {
  final String? userId; // ✅ এটি যোগ করা হয়েছে যাতে অন্যের প্রোফাইল আইডি রিসিভ করা যায়
  const ProfilePage({super.key, this.userId}); // ✅ কনস্ট্রাক্টর আপডেট করা হয়েছে

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseService _dbService = DatabaseService();
  // ... বাকি ভেরিয়েবলগুলো এখানে থাকবে
  // ১. ভেরিয়েবল সেকশন
  String userImageURL = ""; 
  String userName = "পাগলা ইউজার";
  String uIDValue = ""; 
  String gender = "অনির্ধারিত"; 
  int age = 22; 
  int diamonds = 200; 
  int xp = 0; 
  int followers = 0; 
  int following = 0;
  bool isFollowing = false;
  bool hasPremiumCard = false; 
  bool isVIP = false; 
  DateTime premiumExpiryDate = DateTime.now().add(const Duration(days: 30));
  DateTime lastLevelUpDate = DateTime.now(); 

  @override
  void initState() {
    super.initState();
    setupUserAccount(); 
  }

  // ৩. ডাইনামিক আইডি জেনারেশন এবং অ্যাকাউন্ট সেটআপ লজিক
  void setupUserAccount() async {
  String? uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  // 🔥 হৃদয় ভাই, এখানে আপনার অরিজিনাল ফায়ারবেস UID টা বসাবেন
  const String ownerUID = "YOUR_ACTUAL_FIREBASE_UID_HERE"; 

  try {
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    
    // সার্ভার এবং ক্যাশ দুই জায়গা থেকেই ডাটা চেক করবে যাতে স্পিড বাড়ে
    DocumentSnapshot userDoc = await userRef.get(const GetOptions(source: Source.serverAndCache));

    if (userDoc.exists && userDoc.data() != null) {
      var data = userDoc.data() as Map<String, dynamic>;
      
      if (mounted) {
        setState(() {
          // আইডি যদি ডাটাবেসে না থাকে বা ফাঁকা থাকে, তবে সাথে সাথে তৈরি করবে
          String? serverID = data['uID']?.toString();
          if (serverID == null || serverID.isEmpty) {
            uIDValue = (100000 + (uid.hashCode.abs() % 899999)).toString();
            userRef.update({'uID': uIDValue}); // ডাটাবেসে আপডেট করে দিবে
          } else {
            uIDValue = serverID;
          }
          
          // আপনার ওনার আইডি চেক
          if (uid == ownerUID) {
            userName = "Hridoy (Owner) 😎";
          } else {
            userName = data['name'] ?? "পাগলা ইউজার";
          }
          
          gender = data['gender'] ?? "অনির্ধারিত";
          diamonds = data['diamonds'] ?? 0;
          xp = data['xp'] ?? 0;
          userImageURL = data['profilePic'] ?? "";
          age = data['age'] ?? 22;
        });
      }
    } else {
      // যদি ইউজার একদম নতুন হয়, তবে সাথে সাথে আইডি জেনারেট হবে
      String newUserID = (100000 + (uid.hashCode.abs() % 899999)).toString();
      
      if (mounted) {
        setState(() {
          uIDValue = newUserID;
          userName = (uid == ownerUID) ? "Hridoy (Owner) 😎" : "পাগলা ইউজার";
        });
      }

      // নতুন ইউজারের ডাটাবেস এন্ট্রি
      await userRef.set({
        'uID': newUserID,
        'name': (uid == ownerUID) ? "Hridoy (Owner) 😎" : "পাগলা ইউজার",
        'gender': "অনির্ধারিত",
        'diamonds': 200, 
        'xp': 0,
        'profilePic': "",
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  } catch (e) {
    debugPrint("Firebase Error: $e");
    // যদি ইন্টারনেটের কারণে এরর হয়, তবুও যাতে আইডি ফাঁকা না থাকে
    if (mounted && uIDValue.isEmpty) {
      setState(() {
        uIDValue = (100000 + (uid.hashCode.abs() % 899999)).toString();
      });
    }
  }
}

  // আপনার ২০টি রিয়েল অবতার লিস্ট
  final List<String> maleAvatars = [
    "https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?auto=compress&cs=tinysrgb&w=200&v=1",
    "https://images.pexels.com/photos/2182970/pexels-photo-2182970.jpeg?auto=compress&cs=tinysrgb&w=200&v=2",
    "https://images.pexels.com/photos/1043474/pexels-photo-1043474.jpeg?auto=compress&cs=tinysrgb&w=200&v=3",
    "https://images.pexels.com/photos/2589409/pexels-photo-2589409.jpeg?auto=compress&cs=tinysrgb&w=200&v=4",
    "https://images.pexels.com/photos/1212984/pexels-photo-1212984.jpeg?auto=compress&cs=tinysrgb&w=200&v=5",
    "https://images.pexels.com/photos/91227/pexels-photo-91227.jpeg?auto=compress&cs=tinysrgb&w=200&v=6",
    "https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=200&v=7",
    "https://images.pexels.com/photos/837358/pexels-photo-837358.jpeg?auto=compress&cs=tinysrgb&w=200&v=8",
    "https://images.pexels.com/photos/775358/pexels-photo-775358.jpeg?auto=compress&cs=tinysrgb&w=200&v=9",
    "https://images.pexels.com/photos/1516680/pexels-photo-1516680.jpeg?auto=compress&cs=tinysrgb&w=200&v=10",
  ];

  final List<String> femaleAvatars = [
    "https://images.pexels.com/photos/1181686/pexels-photo-1181686.jpeg?auto=compress&cs=tinysrgb&w=200&v=11",
    "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=200&v=12",
    "https://images.pexels.com/photos/712513/pexels-photo-712513.jpeg?auto=compress&cs=tinysrgb&w=200&v=13",
    "https://images.pexels.com/photos/1181519/pexels-photo-1181519.jpeg?auto=compress&cs=tinysrgb&w=200&v=14",
    "https://images.pexels.com/photos/1130626/pexels-photo-1130626.jpeg?auto=compress&cs=tinysrgb&w=200&v=15",
    "https://images.pexels.com/photos/1587009/pexels-photo-1587009.jpeg?auto=compress&cs=tinysrgb&w=200&v=16",
    "https://images.pexels.com/photos/764529/pexels-photo-764529.jpeg?auto=compress&cs=tinysrgb&w=200&v=17",
    "https://images.pexels.com/photos/1852300/pexels-photo-1852300.jpeg?auto=compress&cs=tinysrgb&w=200&v=18",
    "https://images.pexels.com/photos/718978/pexels-photo-718978.jpeg?auto=compress&cs=tinysrgb&w=200&v=19",
    "https://images.pexels.com/photos/1310522/pexels-photo-1310522.jpeg?auto=compress&cs=tinysrgb&w=200&v=20",
  ];

  String getVipBadge(int level) {
    switch (level) {
      case 1: return "https://i.ibb.co/6P0f9pX/vip1.png";
      case 2: return "https://i.ibb.co/YyYfD6B/vip2.png";
      case 3: return "https://i.ibb.co/PZf3B8M/vip3.png"; 
      case 4: return "https://i.ibb.co/v4S8W5p/vip4.png";
      case 5: return "https://i.ibb.co/L9H0YvY/vip5.png";
      case 6: return "https://i.ibb.co/N1pXyFm/vip6.png";
      case 7: return "https://i.ibb.co/mXzR1vB/vip7.png";
      case 8: return "https://i.ibb.co/G0S4mXF/vip8.png";
      default: return ""; 
    }
  }

  String premiumBadgeUrl = "https://i.ibb.co/3ykC7mP/premium-gold.png";

  int getVipLevel() {
    if (xp >= 35000) return 8;
    if (xp >= 30000) return 7;
    if (xp >= 25000) return 6;
    if (xp >= 20000) return 5;
    if (xp >= 13000) return 4;
    if (xp >= 9000)  return 3;
    if (xp >= 5000)  return 2;
    if (xp >= 2500)  return 1;
    return 0;
  }

  void _editName() {
    TextEditingController _nameController = TextEditingController(text: userName);
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        title: const Text("নাম পরিবর্তন", style: TextStyle(color: Colors.white)),
        content: TextField(controller: _nameController, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("বাতিল")),
          TextButton(
            onPressed: () async {
              String newName = _nameController.text.trim(); 
              if (newName.isNotEmpty) {
                String uid = FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance.collection('users').doc(uid).set({'name': newName}, SetOptions(merge: true));
                setState(() => userName = newName);
                Navigator.pop(context);
              }
            }, 
            child: const Text("সেভ", style: TextStyle(color: Colors.pinkAccent))
          ),
        ],
      ),
    );
  }

  void _toggleFollow() async {
    String myUid = FirebaseAuth.instance.currentUser!.uid;
    String targetUid = uIDValue; 
    var followRef = FirebaseFirestore.instance.collection('users');
    if (isFollowing) {
      await followRef.doc(myUid).update({'following': FieldValue.increment(-1)});
      await followRef.doc(targetUid).update({'followers': FieldValue.increment(-1)});
    } else {
      await followRef.doc(myUid).update({'following': FieldValue.increment(1)});
      await followRef.doc(targetUid).update({'followers': FieldValue.increment(1)});
    }
    setState(() => isFollowing = !isFollowing);
  }
 
  void _showAgePicker() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E2F),
      title: const Text("আপনার বয়স কত?", style: TextStyle(color: Colors.white)),
      content: SizedBox(height: 200, width: double.maxFinite, child: ListView.builder(itemCount: 40, itemBuilder: (context, index) => ListTile(title: Text("${index + 15} বছর", style: const TextStyle(color: Colors.white)), onTap: () async {
        String uid = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseFirestore.instance.collection('users').doc(uid).update({'age': index + 15});
        setState(() => age = index + 15);
        Navigator.pop(context);
      }))),
    ));
  }

  void _openSettings() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1E1E2F), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(padding: EdgeInsets.all(15), child: Text("সেটিংস", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
        ListTile(leading: const Icon(Icons.wc, color: Colors.pinkAccent), title: Text("লিঙ্গ পরিবর্তন (বর্তমান: $gender)", style: const TextStyle(color: Colors.white)),
          trailing: PopupMenuButton<String>(color: const Color(0xFF1E1E2F), onSelected: (val) async {
            String uid = FirebaseAuth.instance.currentUser!.uid;
            await FirebaseFirestore.instance.collection('users').doc(uid).update({'gender': val});
            setState(() => gender = val);
          }, itemBuilder: (ctx) => [const PopupMenuItem(value: "পুরুষ", child: Text("পুরুষ", style: TextStyle(color: Colors.white))), const PopupMenuItem(value: "নারী", child: Text("নারী", style: TextStyle(color: Colors.white)))]),
        ),
        ListTile(leading: const Icon(Icons.cake, color: Colors.orangeAccent), title: Text("বয়স পরিবর্তন (বর্তমান: $age)", style: const TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); _showAgePicker(); }),
        ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text("লগ আউট", style: TextStyle(color: Colors.redAccent)), onTap: () { FirebaseAuth.instance.signOut(); Navigator.pop(context); }),
        const SizedBox(height: 20),
      ]));
  }

  void _showFreeAvatars() {
    List<String> avatars = (gender == "পুরুষ") ? maleAvatars : femaleAvatars;
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A2E), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => GridView.builder(padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 10, crossAxisSpacing: 10),
        itemCount: avatars.length, itemBuilder: (context, index) => GestureDetector(onTap: () async {
          String uid = FirebaseAuth.instance.currentUser!.uid;
          await FirebaseFirestore.instance.collection('users').doc(uid).update({'profilePic': avatars[index]});
          Navigator.pop(context);
        }, child: ClipOval(child: Image.network(avatars[index], fit: BoxFit.cover)))));
  }

  void _pickProfileImage() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A2E), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Wrap(children: [
        ListTile(leading: const Icon(Icons.face, color: Colors.blueAccent), title: const Text("২০টি রিয়েল অবতার (Free)", style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); _showFreeAvatars(); }),
        ListTile(leading: const Icon(Icons.photo_library, color: Colors.pinkAccent), title: const Text("গ্যালারি থেকে ছবি", style: TextStyle(color: Colors.white)), onTap: () async {
          if (hasPremiumCard || getVipLevel() >= 1) {
             final ImagePicker picker = ImagePicker();
             final XFile? image = await picker.pickImage(source: ImageSource.gallery);
             if (image != null) setState(() => userImageURL = image.path);
             Navigator.pop(context);
          } else {
             Navigator.pop(context);
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("প্রিমিয়াম কার্ড বা VIP 1 প্রয়োজন!")));
          }
        }),
      ]));
  }

  void _openDiamondStore() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1E1E2F), builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
      _buildDiamondOption("৬,০০০ ডায়মন্ড", "১৫০ টাকা"),
      _buildDiamondOption("১২,০০০ ডায়মন্ড", "৩০০ টাকা"),
      _buildDiamondOption("২৫,০০০ ডায়মন্ড", "৬০০ টাকা"),
      _buildDiamondOption("৬০,০০০ ডায়মন্ড", "১,৫০০ টাকা"),
      _buildDiamondOption("১,২০,০০০ ডায়মন্ড", "৩,০০০ টাকা"),
      _buildDiamondOption("৫,০০,০০০ ডায়মন্ড", "১২,০০০ টাকা"),
      const SizedBox(height: 15),
    ]));
  }

  Widget _buildDiamondOption(String amount, String price) => ListTile(leading: const Icon(Icons.diamond, color: Colors.cyanAccent), title: Text(amount, style: const TextStyle(color: Colors.white)), trailing: Text(price, style: const TextStyle(color: Colors.greenAccent)), onTap: () { Navigator.pop(context); _showPaymentMethods(); });

  void _showPaymentMethods() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A2E), builder: (context) => Wrap(children: [
      ListTile(leading: const Icon(Icons.account_balance_wallet, color: Colors.pink), title: const Text("Bkash", style: TextStyle(color: Colors.white))),
      ListTile(leading: const Icon(Icons.money, color: Colors.orange), title: const Text("Nagad", style: TextStyle(color: Colors.white))),
      ListTile(leading: const Icon(Icons.payment, color: Colors.blue), title: const Text("Google Pay", style: TextStyle(color: Colors.white))),
    ]));
  }

  void _openPremiumStore() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: const Color(0xFF1E1E2F), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DefaultTabController(length: 4, child: Container(height: MediaQuery.of(context).size.height * 0.7, padding: const EdgeInsets.all(10),
        child: Column(children: [
          const TabBar(isScrollable: true, indicatorColor: Colors.amber, tabs: [Tab(text: "Cards"), Tab(text: "Frames"), Tab(text: "Entry"), Tab(text: "Special")]),
          Expanded(child: TabBarView(children: [_buildStoreCardTab(), const Center(child: Text("Coming Soon", style: TextStyle(color: Colors.white54))), const Center(child: Text("Coming Soon", style: TextStyle(color: Colors.white54))), const Center(child: Text("Coming Soon", style: TextStyle(color: Colors.white54)))]))
        ]))));
  }

  Widget _buildStoreCardTab() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network("https://i.ibb.co/3ykC7mP/premium-card.jpg", height: 150, width: 220, fit: BoxFit.cover)),
      const SizedBox(height: 10),
      const Text("Pagla Premium Card", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const Text("মুল্য: ৬,০০০ ডায়মন্ড", style: TextStyle(color: Colors.cyanAccent)),
      const SizedBox(height: 15),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent), onPressed: () {
        if (diamonds >= 6000) {
          setState(() { diamonds -= 6000; hasPremiumCard = true; });
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("পর্যাপ্ত ডায়মন্ড নেই!")));
        }
      }, child: const Text("BUY NOW")),
    ]);
  }

  void _openBackpack() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: const Color(0xFF1E1E2F), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DefaultTabController(length: 4, child: Container(height: MediaQuery.of(context).size.height * 0.7, padding: const EdgeInsets.all(10),
        child: Column(children: [
          const TabBar(isScrollable: true, indicatorColor: Colors.pinkAccent, tabs: [Tab(text: "My Cards"), Tab(text: "My Frames"), Tab(text: "Effects"), Tab(text: "Others")]),
          Expanded(child: TabBarView(children: [_buildMyCardsTab(), const Center(child: Text("খালি", style: TextStyle(color: Colors.white))), const Center(child: Text("খালি", style: TextStyle(color: Colors.white))), const Center(child: Text("খালি", style: TextStyle(color: Colors.white)))]))
        ]))));
  }

  Widget _buildMyCardsTab() {
    if (!hasPremiumCard) return const Center(child: Text("আপনার কাছে কোনো কার্ড নেই", style: TextStyle(color: Colors.white54)));
    return ListTile(
      leading: const Icon(Icons.card_membership, color: Colors.amber, size: 40),
      title: const Text("Pagla Chat Premium", style: TextStyle(color: Colors.white)),
      trailing: ElevatedButton(onPressed: () { setState(() => isVIP = true); Navigator.pop(context); }, child: const Text("Wear")),
    );
  }

    @override
Widget build(BuildContext context) {
  final String myId = FirebaseAuth.instance.currentUser?.uid ?? "";
  // যদি এই পেজটি অন্য কারো আইডির জন্য ওপেন করা হয়, তবে 'userId' ব্যবহার হবে, নাহলে নিজের 'myId'
  final String targetUserId = widget.userId ?? myId; 
  final bool isMe = myId == targetUserId;

  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance.collection('users').doc(targetUserId).snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Scaffold(body: Center(child: Text("Error!")));
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(backgroundColor: Color(0xFF0D0D1A), body: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)));
      }

      if (snapshot.hasData && snapshot.data!.exists) {
        var userData = snapshot.data!.data() as Map<String, dynamic>;
        userName = userData['name'] ?? "User";
        uIDValue = userData['uID']?.toString() ?? "N/A";
        diamonds = userData['diamonds'] ?? 0;
        xp = userData['xp'] ?? 0;
        userImageURL = userData['profilePic'] ?? "";
        gender = userData['gender'] ?? "অনির্ধারিত";
        hasPremiumCard = userData['hasPremium'] ?? false;
        followers = userData['followers'] ?? 0;
        following = userData['following'] ?? 0;
      }

      int vipLevel = getVipLevel();

      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          // ✅ শুধু নিজের প্রোফাইলে ডায়মন্ড দেখাবে, অন্যের প্রোফাইলে ব্যাক বাটন
          leading: isMe ? Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(children: [
              const Icon(Icons.diamond, color: Colors.cyanAccent, size: 18),
              Text(" $diamonds", style: const TextStyle(color: Colors.white, fontSize: 12))
            ]),
          ) : const BackButton(color: Colors.white),
          // ✅ শুধু নিজের প্রোফাইলে সেটিংস বাটন থাকবে
          actions: [
            if (isMe) IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: _openSettings)
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(children: [
            StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('marriages').doc(targetUserId).snapshots(),
          builder: (context, mSnapshot) {
            if (mSnapshot.hasData && mSnapshot.data!.exists) {
              var marriageData = mSnapshot.data!.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildMarriageHeader(
                    marriageData,
                    userImageURL, // ✅ এটি আপনার পেজে আছে
                    "", // ⚠️ আপাতত ফ্রেম খালি রাখা হলো যাতে বিল্ড ফেল না হয়
                  ),
                ),
              );
            }
            return const SizedBox(height: 20);
          },
        ),
            
            const SizedBox(height: 20),
            Center(child: Stack(alignment: Alignment.center, children: [
              if (vipLevel > 0) Image.network("https://png.pngtree.com/png-clipart/20230501/original/pngtree-golden-vip-frame-png-image_9128509.png", width: 130, height: 130),
              GestureDetector(
                onTap: isMe ? _pickProfileImage : null, // অন্যের প্রোফাইল পিকচার চেঞ্জ করা যাবে না
                child: CircleAvatar(radius: 50, backgroundColor: Colors.grey[900], backgroundImage: _getProfileImage())
              ),
            ])),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              // ✅ শুধু নিজের নাম এডিট করা যাবে
              if (isMe) IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.pinkAccent), onPressed: _editName)
            ]),

            Text("User ID: $uIDValue", style: const TextStyle(color: Colors.pinkAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // VIP এবং XP সেকশন
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (vipLevel > 0) Image.network(getVipBadge(vipLevel), width: 45, height: 45) else const SizedBox(width: 45),
              const SizedBox(width: 12),
              Expanded(child: Column(children: [
                Text("VIP Level $vipLevel (XP: $xp / 25000)", style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: (xp / 25000).clamp(0, 1), valueColor: const AlwaysStoppedAnimation(Colors.amber), backgroundColor: Colors.white10),
              ])),
              const SizedBox(width: 12),
              if (hasPremiumCard) Image.network(premiumBadgeUrl, width: 45, height: 45) else const SizedBox(width: 45),
            ])),

            const SizedBox(height: 25),

            // ✅ ফলোয়ার, মেসেজ এবং ফলোয়িং স্ট্যাটাস (ফিক্সড কোড)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              // ফলোয়ার অংশ (Fix: context added)
              _buildStat("Followers", followers, targetUserId, context), 
              
              const SizedBox(width: 25),

              if (!isMe) ...[
                ElevatedButton(
                  onPressed: _toggleFollow,
                  style: ElevatedButton.styleFrom(backgroundColor: isFollowing ? Colors.blueGrey : Colors.pinkAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: Text(isFollowing ? "Friend" : "Follow", style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.mail, color: Colors.white),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(receiverId: targetUserId, receiverName: userName)));
                  },
                ),
              ] else
                const SizedBox(width: 80, child: Center(child: Text("MY PROFILE", style: TextStyle(color: Colors.white54, fontSize: 10)))),

              const SizedBox(width: 25),
              
              // ফলোয়িং অংশ (Fix: context added)
              _buildStat("Following", following, targetUserId, context),
            ]),

            const SizedBox(height: 35),

            // ✅ মেইন অ্যাকশন বক্স: শুধু নিজের জন্য দেখাবে
            if (isMe) ...[
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _buildActionBox("Diamond", Icons.diamond, Colors.cyan, _openDiamondStore),
                _buildActionBox("Premium", Icons.card_membership, Colors.purple, _openPremiumStore),
                _buildActionBox("Backpack", Icons.backpack, Colors.orange, _openBackpack),
              ]),
              const SizedBox(height: 30),
              // ✅ আপনার নতুন "প্রিয়জন" সেকশনটি এখানে থাকবে
              _buildSoulmateSection(),
            ],
            
            const SizedBox(height: 30),
          ]),
        ),
      );
    },
  );
}

// ✅ ১. ফলোয়ার/ফলোয়িং লিস্ট দেখার উইজেট (প্যারামিটারে context যোগ করা হয়েছে)
Widget _buildStat(String label, int value, String uID, BuildContext context) {
  final String myId = FirebaseAuth.instance.currentUser?.uid ?? "";

  return GestureDetector(
    onTap: () {
      // ✅ সিকিউরিটি লজিক: শুধু প্রোফাইলের মালিক লিস্ট দেখতে পারবে
      if (myId == uID) {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => UserListScreen(title: label, userId: uID))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("আপনি অন্যের $label লিস্ট দেখতে পারবেন না!"), 
            backgroundColor: Colors.redAccent
          )
        );
      }
    },
    child: Column(children: [
      Text(value.toString(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]),
  );
}

// ✅ ২. অ্যাকশন বক্স উইজেট
Widget _buildActionBox(String title, IconData icon, Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap, 
    child: Container(
      width: 100, 
      height: 85, 
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: color.withOpacity(0.5))
      ), 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Icon(icon, color: color, size: 28), 
          const SizedBox(height: 5), 
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 11))
        ]
      )
    ),
  );
}

// ✅ ৩. প্রোফাইল ইমেজ হ্যান্ডলার
ImageProvider _getProfileImage() {
  if (userImageURL.isEmpty) {
    return NetworkImage(maleAvatars[0]);
  }
  // ওয়েব এবং ইউআরএল এর জন্য
  if (userImageURL.startsWith('http') || kIsWeb) {
    return NetworkImage(userImageURL);
  }
  // লোকাল ফাইলের জন্য
  return FileImage(File(userImageURL));
}

// ৪. আপনার নতুন "প্রিয়জন" সেকশনটি এখানে বসবে (যা আমি আগের মেসেজে দিয়েছিলাম)
Widget _buildSoulmateSection() {
  // ✅ এই লাইনটি এখন ফাংশনের ভেতরে আছে, তাই আর এরর আসবে না
  final String currentId = FirebaseAuth.instance.currentUser?.uid ?? '';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text("প্রিয়জন (Soulmates)", 
          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 150, 
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('soulmates')
              .where('ownerId', isEqualTo: currentId).limit(6).snapshots(),
          builder: (context, snapshot) {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: 6, 
              itemBuilder: (context, index) {
                var data = (snapshot.hasData && snapshot.data!.docs.length > index) 
                    ? snapshot.data!.docs[index] : null;

                return Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: const DecorationImage(
                      // ⚠️ এখানে আপনার সেই সোলমেট কার্ডের অরিজিনাল লিংকটি বসিয়ে দিন
                      image: NetworkImage("https://your-design-card-url.png"), 
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: data != null ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          image: DecorationImage(
                            image: NetworkImage(data['partnerImage']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['partnerName'],
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 11, 
                          fontWeight: FontWeight.bold, 
                          shadows: [Shadow(blurRadius: 5, color: Colors.black)]
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ) : const Center(child: Icon(Icons.add, color: Colors.white24)), 
                );
              },
            );
          },
        ),
      ),
    ],
  );
}
  // ✅ ১০০০ ডায়মন্ড কেটে সম্পর্ক ছিন্ন করার পপ-আপ
  void _showBreakupDialog(String partnerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("সম্পর্ক ছিন্ন করবেন?", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text("এটি করতে আপনার অ্যাকাউন্ট থেকে ১০০০ ডায়মন্ড কেটে নেওয়া হবে।", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("বাতিল")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              String response = await SoulmateService().breakRelation(partnerId);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response), backgroundColor: Colors.pinkAccent));
            }, 
            child: const Text("হ্যাঁ, কাটবো", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }
// --- এই অংশটুকু ফাইলের শেষে অন্য ফাংশনের সাথে বসান ---

// ১. ম্যারেজ হেডার ফাংশন আপডেট
Widget _buildMarriageHeader(Map<String, dynamic> data, String myImg, String myFrame) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ✅ আপনার ছবি ও ফ্রেম (প্যারামিটার থেকে আসছে)
        _buildUserWithFrame(myImg, myFrame, 45), 

        // মাঝখানে সেই স্পেশাল রিং
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Image.network(
            "https://i.ibb.co/ring-sample.png", // আপনার রিং এর লিংক
            width: 60,
            height: 60,
          ),
        ),

        // ডানে পার্টনারের প্রোফাইল (snapshot data থেকে আসছে)
        _buildUserWithFrame(data['partnerImage'] ?? '', data['partnerFrame'] ?? '', 45),
      ],
    ),
  );
}

// ২. ইউজার ফ্রেম ফাংশন (আগের মতোই থাকবে)
Widget _buildUserWithFrame(String imageUrl, String frameUrl, double radius) {
  return Stack(
    alignment: Alignment.center,
    children: [
      Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(imageUrl.isEmpty ? "https://i.ibb.co/empty.png" : imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
      if (frameUrl.isNotEmpty)
        Image.network(
          frameUrl,
          width: radius * 3, 
          height: radius * 3,
          fit: BoxFit.contain,
        ),
    ],
  );
}
} // এই লাস্ট ব্র্যাকেটটি আপনার _ProfilePageState ক্লাসের শেষ ব্র্যাকেট
