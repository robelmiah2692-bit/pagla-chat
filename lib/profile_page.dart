import 'widgets/animated_frame.dart'; // পাথটি আপনার ফোল্ডার অনুযায়ী ঠিক করে নিন
import 'package:firebase_storage/firebase_storage.dart';
import 'vip_service.dart'; // ফাইলের নাম অনুযায়ী
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

   @override
  void initState() {
    super.initState();
    setupUserAccount(); 
  }

  // ৩. ডাইনামিক আইডি জেনারেশন এবং অ্যাকাউন্ট সেটআপ লজিক (সংশোধিত)
  void setupUserAccount() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // 🔥 হৃদয় ভাই, এখানে আপনার অরিজিনাল ফায়ারবেস UID টা অবশ্যই বসাবেন
    const String ownerUID = "InvA1lNPokgfxj20SyxiPv5J5s83"; 

    try {
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      
      // সার্ভার এবং ক্যাশ দুই জায়গা থেকেই ডাটা চেক করবে
      DocumentSnapshot userDoc = await userRef.get(const GetOptions(source: Source.serverAndCache));

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        
        if (mounted) {
          setState(() {
            // ১. আইডি রিড (ছোট বা বড় হাতের যাই হোক)
            uIDValue = (data['uID'] ?? data['uid'] ?? "").toString();
            if (uIDValue.isEmpty || uIDValue == "null") {
              uIDValue = (100000 + (uid.hashCode.abs() % 899999)).toString();
              userRef.update({'uID': uIDValue}); 
            }
            
            // ২. ওনার চেক ও নাম সেটআপ
            if (uid == ownerUID) {
              userName = "Hridoy (Owner) 😎";
            } else {
              userName = data['name'] ?? "Pagla Type your name";
            }
            
            // ৩. গুরুত্বপূর্ণ: XP এবং VIP মেয়াদের ডাটা রিড
            diamonds = data['diamonds'] ?? 0;
            xp = data['xp'] ?? 0;
            vipExpiry = data['vipExpiry'] ?? 0; // মেয়াদের মাইল্ডিসেকেন্ড
            
            gender = data['gender'] ?? "Unfixed";
            userImageURL = data['profilePic'] ?? "";
            age = data['age'] ?? 22;
          });
        }
      } else {
        // নতুন ইউজারের ডাটাবেস এন্ট্রি
        String newUserID = (100000 + (uid.hashCode.abs() % 899999)).toString();
        String initialName = (uid == ownerUID) ? "Hridoy (Owner) 😎" : "Pagla Type your name";
        
        await userRef.set({
          'uID': newUserID,
          'name': initialName,
          'gender': "Unfixed",
          'diamonds': 200, 
          'xp': 0,
          'vipExpiry': 0, // শুরুতে মেয়াদ থাকবে না
          'profilePic': "",
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          setState(() {
            uIDValue = newUserID;
            userName = initialName;
            xp = 0;
            vipExpiry = 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Firebase Error: $e");
    }
  }

  // ২০টি রিয়েল অবতার লিস্ট
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
  // ১. গিটহাবের বেস লিঙ্ক (সব ছবির জন্য কমন)
final String githubBaseUrl = "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main";

// ২. VIP বেইজ লিংকের ফাংশন (গিটহাব থেকে সরাসরি লোড হবে)
String getVipBadge(int level) {
  if (level == 0) return ""; 
  
  switch (level) {
    case 1: return "$githubBaseUrl/vip1.png";
    case 2: return "$githubBaseUrl/vip2.png";
    case 3: return "$githubBaseUrl/vip3.png"; 
    case 4: return "$githubBaseUrl/vip4.png";
    case 5: return "$githubBaseUrl/vip5.png";
    case 6: return "$githubBaseUrl/vip6.png";
    case 7: return "$githubBaseUrl/vip7.png";
    case 8: return "$githubBaseUrl/vip8.png";
    default: return ""; 
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
        title: const Text("Name Change", style: TextStyle(color: Colors.white)),
        content: TextField(controller: _nameController, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
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
            child: const Text("Save", style: TextStyle(color: Colors.pinkAccent))
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
      title: const Text("Your age?", style: TextStyle(color: Colors.white)),
      content: SizedBox(height: 200, width: double.maxFinite, child: ListView.builder(itemCount: 40, itemBuilder: (context, index) => ListTile(title: Text("${index + 15} Year", style: const TextStyle(color: Colors.white)), onTap: () async {
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
        const Padding(padding: EdgeInsets.all(15), child: Text("Settings", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
        ListTile(leading: const Icon(Icons.wc, color: Colors.pinkAccent), title: Text("Gender (Now: $gender)", style: const TextStyle(color: Colors.white)),
          trailing: PopupMenuButton<String>(color: const Color(0xFF1E1E2F), onSelected: (val) async {
            String uid = FirebaseAuth.instance.currentUser!.uid;
            await FirebaseFirestore.instance.collection('users').doc(uid).update({'gender': val});
            setState(() => gender = val);
          }, itemBuilder: (ctx) => [const PopupMenuItem(value: "Male", child: Text("Male", style: TextStyle(color: Colors.white))), const PopupMenuItem(value: "Female", child: Text("Female", style: TextStyle(color: Colors.white)))]),
        ),
        ListTile(leading: const Icon(Icons.cake, color: Colors.orangeAccent), title: Text("Age change (Now: $age)", style: const TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); _showAgePicker(); }),
        ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text("Logout", style: TextStyle(color: Colors.redAccent)), onTap: () { FirebaseAuth.instance.signOut(); Navigator.pop(context); }),
        const SizedBox(height: 20),
      ]));
  }

  void _showFreeAvatars() {
    List<String> avatars = (gender == "Male") ? maleAvatars : femaleAvatars;
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A2E), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => GridView.builder(padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 10, crossAxisSpacing: 10),
        itemCount: avatars.length, itemBuilder: (context, index) => GestureDetector(onTap: () async {
          String uid = FirebaseAuth.instance.currentUser!.uid;
          await FirebaseFirestore.instance.collection('users').doc(uid).update({'profilePic': avatars[index]});
          Navigator.pop(context);
        }, child: ClipOval(child: Image.network(avatars[index], fit: BoxFit.cover)))));
  }

void _pickProfileImage() {
  showModalBottomSheet(
    context: context, 
    backgroundColor: const Color(0xFF1A1A2E), 
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => Wrap(children: [
      ListTile(
        leading: const Icon(Icons.face, color: Colors.blueAccent), 
        title: const Text("Real avtar (Free)", style: TextStyle(color: Colors.white)), 
        onTap: () { Navigator.pop(context); _showFreeAvatars(); }
      ),
      ListTile(
        leading: const Icon(Icons.photo_library, color: Colors.pinkAccent), 
        title: const Text("Gallery photo avtar", style: TextStyle(color: Colors.white)), 
        onTap: () async {
          if (hasPremiumCard || getVipLevel() >= 1) {
             try {
               final ImagePicker picker = ImagePicker();
               final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
               
               if (pickedFile != null) {
                 Navigator.pop(context); // বটম শিট বন্ধ
                 
                 // ছবি আপলোড ও পুরাতনটা মোছার লজিক কল করা
                 await _handleProfileUpdate(File(pickedFile.path));
               }
             } catch (e) {
               debugPrint("Error picking image: $e");
             }
          } else {
             Navigator.pop(context);
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
               content: Text("Premium card VIP 1 need!"), 
               backgroundColor: Colors.redAccent
             ));
          }
        }
      ),
    ])
  );
}

// ছবি আপলোড এবং পুরাতন ছবি হ্যান্ডেল করার ফাংশন
Future<void> _handleProfileUpdate(File newFile) async {
  try {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    // ইউনিক নাম তৈরির জন্য টাইমস্ট্যাম্প নিচ্ছি
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    
    // ১. স্টোরেজ রেফারেন্স (ইউনিক নাম দিলে পুরাতন ক্যাশ সমস্যা হবে না)
    // পাথ: user_profiles/UID/profile_12345678.jpg
    Reference storageFolder = FirebaseStorage.instance.ref().child('user_profiles').child(uid);
    Reference newStorageRef = storageFolder.child('profile_$timestamp.jpg');

    // ২. পুরাতন ফাইলগুলো ডিলিট করা (বাকেট ক্লিন রাখার জন্য)
    try {
      final listResult = await storageFolder.listAll();
      for (var item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      debugPrint("Old image delete error: $e");
    }

    // ৩. নতুন ছবি আপলোড করা
    UploadTask uploadTask = newStorageRef.putFile(newFile);
    TaskSnapshot snapshot = await uploadTask;
    
    // ৪. নতুন ইউআরএল নেওয়া
    String newDownloadUrl = await snapshot.ref.getDownloadURL();
    
    // ৫. ফায়ারস্টোরে আপডেট করা
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'userImage': newDownloadUrl,
    });

    // ৬. অ্যাপের লোকাল স্টেট আপডেট
    if (mounted) {
      setState(() {
        userImageURL = newDownloadUrl;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("প্রোফাইল পিকচার সফলভাবে আপডেট হয়েছে!"), backgroundColor: Colors.green),
    );

  } catch (e) {
    debugPrint("Update Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("আপডেট ব্যর্থ হয়েছে!"), backgroundColor: Colors.redAccent),
    );
  }
}

  // ১. ডায়মন্ড স্টোর ওপেন করার ফাংশন (Fix: userData প্যারামিটার যোগ করা হয়েছে)
  void _openDiamondStore(Map<String, dynamic> userData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 15),
          const Text("Diamond Store",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white10),

          // 🔥 এই অংশটি শুধুমাত্র এজেন্ট দেখতে পারবে
          if (userData['isAgent'] == true)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1e3c72), Color(0xFF2a5298)]),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.pinkAccent.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Agency Stock Balance",
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const Icon(Icons.verified, color: Colors.cyanAccent, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("${userData['agency_wallet'] ?? 0} 💎",
                        style: const TextStyle(
                            color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const AgentTransferPage()));
                        },
                        icon: const Icon(Icons.send, size: 16, color: Colors.white),
                        label: const Text("Diamond Selling",
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // রিচার্জ অপশনগুলো
          _buildDiamondOption("6k   💎", "100 Tk"),
          _buildDiamondOption("12k  💎", "150 Tk"),
          _buildDiamondOption("30k  💎", "350 Tk"),
          _buildDiamondOption("60k  💎", "650 Tk"),
          _buildDiamondOption("120k 💎", "1200 Tk"),
          _buildDiamondOption("240k 💎", "2300 Tk"),
          _buildDiamondOption("500k 💎", "4500 Tk"),
          _buildDiamondOption("1M   💎", "8500 Tk"),
          _buildDiamondOption("2M   💎", "17500 Tk"),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  // ২. ডায়মন্ড অপশন তৈরির হেল্পার উইজেট
  Widget _buildDiamondOption(String amount, String price) {
    return ListTile(
      leading: const Icon(Icons.diamond, color: Colors.cyanAccent),
      title: Text(amount, style: const TextStyle(color: Colors.white)),
      trailing: Text(price, style: const TextStyle(color: Colors.greenAccent)),
      onTap: () {
        Navigator.pop(context);
        _showPaymentMethods();
      },
    );
  }

  // ৩. পেমেন্ট মেথড দেখানোর ফাংশন
  void _showPaymentMethods() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Wrap(
        children: [
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: Center(
              child: Text("Select Pay",
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: Colors.pink),
            title: const Text("Bkash", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.money, color: Colors.orange),
            title: const Text("Nagad", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment, color: Colors.blue),
            title: const Text("Google Pay", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _openPremiumStore() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: const Color(0xFF1E1E2F), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DefaultTabController(length: 4, child: Container(height: MediaQuery.of(context).size.height * 0.7, padding: const EdgeInsets.all(10),
        child: Column(children: [
          const TabBar(isScrollable: true, indicatorColor: Colors.amber, tabs: [Tab(text: "Cards"), Tab(text: "Frames"), Tab(text: "Entry"), Tab(text: "Special")]),
          Expanded(child: TabBarView(children: [_buildStoreCardTab(), const Center(child: Text("Coming Soon", style: TextStyle(color: Colors.white54))), const Center(child: Text("Coming Soon", style: TextStyle(color: Colors.white54))), const Center(child: Text("Coming Soon", style: TextStyle(color: Colors.white54)))]))
        ]))));
  }

  // ১. আপনার সেই হারানো ব্যাকপ্যাক ওপেন করার মেইন ফাংশন
  // ১. ব্যাকপ্যাক ওপেন করার মেইন ফাংশন
void _openBackpack() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E1E2F),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20))
    ),
    builder: (context) => DefaultTabController(
      length: 4,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              indicatorColor: Colors.pinkAccent,
              tabs: [
                Tab(text: "My Cards"),
                Tab(text: "My Frames"),
                Tab(text: "Effects"),
                Tab(text: "Others")
              ]
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildMyCardsTab(), 
                  _buildMyFramesTab(), 
                  const Center(child: Text("Empty", style: TextStyle(color: Colors.white))),
                  const Center(child: Text("Empty", style: TextStyle(color: Colors.white)))
                ]
              )
            )
          ]
        )
      )
    )
  );
}

// ২. স্টোর কার্ড কেনার ফাংশন (uIDValue ব্যবহার করা হয়েছে)
Widget _buildStoreCardTab() {
  return SingleChildScrollView(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/premiumcard.png",
            height: 150, width: 220, fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 15),
        const Text("Pagla Premium Card", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const Text("Bonus: Premium Frame (10 Days Free!)", style: TextStyle(color: Colors.amber, fontSize: 13)),
        const Text("Cost: 6k 💎", style: TextStyle(color: Colors.cyanAccent, fontSize: 16)),
        const SizedBox(height: 20),
        
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12)),
          onPressed: () async {
            if (diamonds >= 6000) {
              try {
                DateTime now = DateTime.now();
                DateTime cardExpiry = now.add(const Duration(days: 30));
                DateTime frameExpiry = now.add(const Duration(days: 10));

                // এখানে uIDValue ব্যবহার করা হয়েছে
                await FirebaseFirestore.instance.collection('users').doc(uIDValue).update({
                  'diamonds': FieldValue.increment(-6000),
                  'hasPremiumCard': true,
                  'premiumUntil': Timestamp.fromDate(cardExpiry),
                  'hasFreeFrame': true,
                  'frameUntil': Timestamp.fromDate(frameExpiry),
                  'activeFrame': "", 
                });

                setState(() {
                  diamonds -= 6000;
                  hasPremiumCard = true;
                  premiumUntilDate = cardExpiry;
                  frameUntilDate = frameExpiry;
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success! Card & Free Frame Added.")));
              } catch (e) {
                debugPrint("Error: $e");
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Insufficient diamonds!")));
            }
          },
          child: const Text("BUY NOW"),
        ),
      ],
    ),
  );
}

// ৩. ব্যাকপ্যাক: ফ্রেম ট্যাব (Pick/Unpick লজিক + uIDValue)
Widget _buildMyFramesTab() {
  const String frameUrl = "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/premiumframe.png";
  bool isExpired = frameUntilDate != null && frameUntilDate!.isBefore(DateTime.now());

  if (!hasFreeFrame || isExpired) {
    return const Center(child: Text("No Active Frames", style: TextStyle(color: Colors.white54)));
  }

  return GridView.builder(
    padding: const EdgeInsets.all(15),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.8),
    itemCount: 1,
    itemBuilder: (context, index) {
      bool isPicked = activeFrameUrl == frameUrl; 

      return Container(
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15), border: isPicked ? Border.all(color: Colors.amber, width: 2) : null),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(frameUrl, height: 60),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isPicked ? Colors.redAccent : Colors.blueAccent, minimumSize: const Size(80, 30)),
              onPressed: () async {
                String newFrame = isPicked ? "" : frameUrl;
                
                // uIDValue ব্যবহার করে আপডেট
                await FirebaseFirestore.instance.collection('users').doc(uIDValue).update({
                  'activeFrame': newFrame
                });
                
                setState(() { activeFrameUrl = newFrame; });
              },
              child: Text(isPicked ? "UNPICK" : "PICK"),
            )
          ],
        ),
      );
    },
  );
}

// ৪. কার্ড ট্যাব যা মিসিং ছিল (বাড়তি সুবিধা হিসেবে যোগ করে দিলাম)
Widget _buildMyCardsTab() {
  return Center(
    child: hasPremiumCard 
      ? Image.network("https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/premiumcard.png", height: 120)
      : const Text("No Cards Found", style: TextStyle(color: Colors.white54)),
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
      stream: FirebaseFirestore.instance.collection('users').doc(targetUserId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Scaffold(body: Center(child: Text("Error!")));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0D1A), 
            body: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)),
          );
        }

        Map<String, dynamic> userData = {};
        if (snapshot.hasData && snapshot.data!.exists) {
          userData = snapshot.data!.data() as Map<String, dynamic>;
          
          userName = userData['name'] ?? "User";
          uIDValue = (userData['uid'] ?? userData['uID'] ?? "N/A").toString(); 
          diamonds = userData['diamonds'] ?? 0;
          xp = userData['xp'] ?? 0; 
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
          backgroundColor: const Color(0xFF0F0F1E),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: isMe ? Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Row(children: [
                const Text("💎", style: TextStyle(fontSize: 16)), 
                Text(" $diamonds", style: const TextStyle(color: Colors.white, fontSize: 12))
              ]),
            ) : const BackButton(color: Colors.white),
            actions: [
              if (isMe) IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: _openSettings)
            ],
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF0F0F1E),
                ],
              ),
            ), 
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // --- ম্যারেজ সেকশন ---
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('marriages')
                        .doc(targetUserId)
                        .snapshots(),
                    builder: (context, mSnapshot) {
                      if (mSnapshot.hasData && mSnapshot.data!.exists) {
                        var marriageData = mSnapshot.data!.data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildMarriageHeader(marriageData, userImageURL, ""),
                          ),
                        );
                      }
                      return const SizedBox(height: 20);
                    },
                  ),
                  const SizedBox(height: 20),

                  // প্রোফাইল পিকচার ও গোল্ডেন ফ্রেম
                  Center(
                    child: Stack(
                      alignment: Alignment.center, 
                      children: [
                        if (vipLevel > 0) 
                          Image.network(
                            "https://png.pngtree.com/png-clipart/20230501/original/pngtree-golden-vip-frame-png-image_9128509.png", 
                            width: 130, 
                            height: 130
                          ),
                        GestureDetector(
                          onTap: isMe ? _pickProfileImage : null, 
                          child: CircleAvatar(
                            radius: 50, 
                            backgroundColor: Colors.grey[900], 
                            backgroundImage: (userImageURL.isNotEmpty) ? NetworkImage(userImageURL) : null,
                            child: (userImageURL.isEmpty) ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                          ),
                        ),
                      ]
                    )
                  ),
                  
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (isMe) IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.pinkAccent), onPressed: _editName)
                  ]),

                  Text("User ID: $uIDValue", style: const TextStyle(color: Colors.pinkAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  // VIP এবং ডাইনামিক XP প্রগ্রেস বার সেকশন
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25), 
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      children: [
                        if (vipLevel > 0) 
                          Image.network(getVipBadge(vipLevel), width: 45, height: 45) 
                        else 
                          const Icon(Icons.stars_rounded, color: Colors.white24, size: 40),
                        
                        const SizedBox(width: 15),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vipLevel == 0 
                                    ? "Target VIP 1 (XP: $xp / $nextTarget)" 
                                    : "VIP Level $vipLevel (XP: $xp / $nextTarget)", 
                                style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progressValue, 
                                  minHeight: 8,
                                  valueColor: const AlwaysStoppedAnimation(Colors.amber), 
                                  backgroundColor: Colors.white10,
                                ),
                              ),
                            ],
                          )
                        ),
                        
                        const SizedBox(width: 15),
                        if (hasPremiumCard) 
                          Image.network(premiumBadgeUrl, width: 45, height: 45) 
                        else 
                          const SizedBox(width: 45),
                      ]
                    )
                  ),

                  const SizedBox(height: 25),

                  // ফলোয়ার ও ফলোয়িং
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _buildStat("Followers", followers, targetUserId, context), 
                    const SizedBox(width: 25),
                    if (!isMe) ...[
                      ElevatedButton(
                        onPressed: _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing ? Colors.blueGrey : Colors.pinkAccent, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                        ),
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
                    _buildStat("Following", following, targetUserId, context),
                  ]),

                  const SizedBox(height: 35),

                  if (isMe) ...[
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      _buildActionBox("Diamond", Icons.diamond, Colors.cyan, () => _openDiamondStore(userData)),
                      _buildActionBox("Premium", Icons.card_membership, Colors.purple, _openPremiumStore),
                      _buildActionBox("Backpack", Icons.backpack, Colors.orange, _openBackpack),
                    ]),

                    if (userData['isAgent'] == true) ...[
                      const SizedBox(height: 25),
                      _buildAgencyWalletCard(userData), 
                    ],

                    const SizedBox(height: 30),
                    _buildSoulmateSection(),
                  ],
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ফলোয়ার/ফলোয়িং লিস্ট সিকিউরিটি লজিক
  Widget _buildStat(String label, int value, String uID, BuildContext context) {
    final String myId = FirebaseAuth.instance.currentUser?.uid ?? "";
    return GestureDetector(
      onTap: () {
        if (myId == uID) {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => UserListScreen(title: label, userId: uID))
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("You not possible to see $label others parson List!"), 
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
// ✅ ২. অ্যাকশন বক্স উইজেট (পুরানো ডিজাইন সহ)
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

// ✅ ৩. প্রিয়জন (Soulmate) ৬ স্লট লজিক
Widget _buildSoulmateSection() {
  final String currentId = FirebaseAuth.instance.currentUser?.uid ?? '';
  // গিটহাবের সেই সঠিক পারমানেন্ট লিঙ্ক
  const String soulmateCardUrl = "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/soulmatecard.png";

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Text("প্রিয়জন (Soulmates)", 
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('soulmates')
            .where('ownerId', isEqualTo: currentId).limit(6).snapshots(),
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
            itemCount: 6, // সবসময় ৬টি ঘর
            itemBuilder: (context, index) {
              var dataDoc = (snapshot.hasData && snapshot.data!.docs.length > index) 
                  ? snapshot.data!.docs[index] : null;
              var data = dataDoc?.data() as Map<String, dynamic>?;

              return GestureDetector(
                onLongPress: dataDoc != null ? () => _showBreakupDialog(data!['partnerId']) : null,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    image: const DecorationImage(
                      image: NetworkImage(soulmateCardUrl), 
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: data != null ? _buildFilledSoulmate(data) : _buildEmptySoulmate(),
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

// কার্ড যখন এক্টিভ (ছবি ও লেভেল সহ)
Widget _buildFilledSoulmate(Map<String, dynamic> data) {
  // লেভেল লজিক: প্রতি ৫০০০ ডাইমন্ডে ১ লেভেল (ম্যাক্স ৫০)
  int totalGift = data['totalGift'] ?? 0;
  int level = (totalGift / 5000).floor().clamp(1, 50);

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // উপরের লেভেল ব্যাজ
      Align(
        alignment: Alignment.topRight,
        child: Container(
          margin: const EdgeInsets.only(right: 8, top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text("Lv.$level", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
      ),
      const Spacer(),
      // পার্টনারের ছবি
      Container(
        width: 58,
        height: 58,
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
      // নাম
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          data['partnerName'] ?? "Unknown",
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(height: 4),
      // সোলমেট ট্যাগ
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.8), borderRadius: BorderRadius.circular(10)),
        child: const Text("Soulmate", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 12),
    ],
  );
}

// কার্ড যখন খালি (Lock আইকন)
Widget _buildEmptySoulmate() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.2), size: 30),
        const SizedBox(height: 4),
        const Icon(Icons.add, color: Colors.white24, size: 20),
      ],
    ),
  );
}

// ✅ ৪. রিলেশনশিপ ব্রেকআপ ডায়ালগ (১০০০ ডায়মন্ড লজিক)
void _showBreakupDialog(String partnerId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E2F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text("Sure end relationship ?", style: TextStyle(color: Colors.white, fontSize: 16)),
      content: const Text("End relationship need 1k daimond", style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            String response = await SoulmateService().breakRelation(partnerId);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response), backgroundColor: Colors.pinkAccent));
          }, 
          child: const Text("Yes", style: TextStyle(color: Colors.redAccent))
        ),
      ],
    ),
  );
}

// ✅ ৫. ম্যারেজ হেডার ও ইউজার ফ্রেম (পুরানো সব ডেকোরেশন সহ)
Widget _buildMarriageHeader(Map<String, dynamic> data, String myImg, String myFrame) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildUserWithFrame(myImg, myFrame, 45), 
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Image.network(
            "https://i.ibb.co/ring-sample.png", 
            width: 60,
            height: 60,
          ),
        ),
        _buildUserWithFrame(data['partnerImage'] ?? '', data['partnerFrame'] ?? '', 45),
      ],
    ),
  );
}

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

// ✅ ৬. এজেন্সি ওয়ালেট কার্ড (ফুল লজিক)
Widget _buildAgencyWalletCard(Map<String, dynamic> userData) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFF1E1E2F),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.cyanAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.account_balance_wallet, color: Colors.cyanAccent, size: 28),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Agency Wallet Balance", 
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 5),
              Text("${userData['agency_wallet']?.toInt() ?? 0} 💎",
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AgentTransferPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 15),
          ),
          child: const Text("Transfer", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
}
