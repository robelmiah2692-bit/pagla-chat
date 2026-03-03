import 'dart:io'; 
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'main.dart'; 

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- আপনার অরিজিনাল ডাটা ---
  String userImageURL = ""; 
  String userName = "পাগলা ইউজার";
  String uIDValue = "885522"; 
  String roomIDValue = "441100"; 
  String gender = "পুরুষ"; 
  int age = 22; 
  int diamonds = 200; 
  int xp = 2500; 
  int followers = 0; 
  int following = 0;
  bool isFollowing = false;
  bool hasPremiumCard = true; 
  bool isVIP = false; 
  DateTime premiumExpiryDate = DateTime.now().add(const Duration(days: 30));
  bool hasVip1Items = false; 
  DateTime lastLevelUpDate = DateTime.now(); 

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
  // VIP স্টিকার লিঙ্কসমূহ
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

  @override
  void initState() {
    super.initState();
    _syncUserData(); 
  }

  void _syncUserData() {
    setState(() {
      userName = "পাগলা ইউজার";
      uIDValue = "885522"; 
      roomIDValue = "441100";
    });
  }

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
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E2F),
      title: const Text("নাম পরিবর্তন", style: TextStyle(color: Colors.white)),
      content: TextField(controller: _nameController, style: const TextStyle(color: Colors.white)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("বাতিল")),
        TextButton(onPressed: () { setState(() => userName = _nameController.text); Navigator.pop(context); }, child: const Text("সেভ", style: TextStyle(color: Colors.pinkAccent))),
      ],
    ));
  }

  void _showAgePicker() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E2F),
      title: const Text("আপনার বয়স কত?", style: TextStyle(color: Colors.white)),
      content: SizedBox(height: 200, width: double.maxFinite, child: ListView.builder(itemCount: 40, itemBuilder: (context, index) => ListTile(title: Text("${index + 15} বছর", style: const TextStyle(color: Colors.white)), onTap: () { setState(() => age = index + 15); Navigator.pop(context); }))),
    ));
  }

  void _openSettings() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1E1E2F), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(padding: EdgeInsets.all(15), child: Text("সেটিংস", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
        ListTile(leading: const Icon(Icons.wc, color: Colors.pinkAccent), title: Text("লিঙ্গ পরিবর্তন (বর্তমান: $gender)", style: const TextStyle(color: Colors.white)),
          trailing: PopupMenuButton<String>(color: const Color(0xFF1E1E2F), onSelected: (val) => setState(() => gender = val),
            itemBuilder: (ctx) => [const PopupMenuItem(value: "পুরুষ", child: Text("পুরুষ", style: TextStyle(color: Colors.white))), const PopupMenuItem(value: "নারী", child: Text("নারী", style: TextStyle(color: Colors.white)))]),
        ),
        ListTile(leading: const Icon(Icons.cake, color: Colors.orangeAccent), title: Text("বয়স পরিবর্তন (বর্তমান: $age)", style: const TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); _showAgePicker(); }),
        ListTile(leading: const Icon(Icons.block, color: Colors.redAccent), title: const Text("ব্লকলিস্ট", style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
        ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text("লগ আউট", style: TextStyle(color: Colors.redAccent)), onTap: () { Navigator.pop(context); Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (Route<dynamic> route) => false); }),
        const SizedBox(height: 20),
      ]));
  }

  void _showFreeAvatars() {
    List<String> avatars = (gender == "পুরুষ") ? maleAvatars : femaleAvatars;
    showModalBottomSheet(
      context: context, 
      backgroundColor: const Color(0xFF1A1A2E), 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => GridView.builder(
        padding: const EdgeInsets.all(15), 
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, 
          mainAxisSpacing: 10, 
          crossAxisSpacing: 10
        ),
        itemCount: avatars.length, 
        itemBuilder: (context, index) => GestureDetector(
          onTap: () { 
            setState(() => userImageURL = avatars[index]); 
            Navigator.pop(context); 
          },
          child: ClipOval(
            child: Image.network(
              avatars[index], 
              fit: BoxFit.cover,
              // লোডিং এর সময় গোল ঘুরবে, তাহলে বুঝবেন ছবি আসছে
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pinkAccent));
              },
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white54),
            ),
          ),
        )
      )
    );
  }

  void _pickProfileImage() {
    showModalBottomSheet(
      context: context, 
      backgroundColor: const Color(0xFF1A1A2E), 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Wrap(children: [
        ListTile(
          leading: const Icon(Icons.face, color: Colors.blueAccent), 
          title: const Text("২০টি রিয়েল অবতার (Free)", style: TextStyle(color: Colors.white)), 
          onTap: () { 
            Navigator.pop(context); 
            _showFreeAvatars(); 
          }
        ),
        ListTile(
          leading: const Icon(Icons.photo_library, color: Colors.pinkAccent), 
          title: const Text("গ্যালারি থেকে ছবি", style: TextStyle(color: Colors.white)), 
          onTap: () async {
            // আপনার অরিজিনাল কন্ডিশন (VIP/Premium)
            if (hasPremiumCard || getVipLevel() >= 1) {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null && mounted) { 
                setState(() => userImageURL = image.path); 
              }
              if (mounted) Navigator.pop(context);
            } else {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Colors.redAccent, 
                content: Text("প্রিমিয়াম কার্ড বা VIP 1 লেভেল প্রয়োজন!")
              ));
            }
          }
        ),
      ])
    );
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

  Widget _buildDiamondOption(String amount, String price) => ListTile(
    leading: const Icon(Icons.diamond, color: Colors.cyanAccent),
    title: Text(amount, style: const TextStyle(color: Colors.white)),
    trailing: Text(price, style: const TextStyle(color: Colors.greenAccent)),
    onTap: () { Navigator.pop(context); _showPaymentMethods(); },
  );

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
          const TabBar(isScrollable: true, indicatorColor: Colors.amber, labelColor: Colors.amber, unselectedLabelColor: Colors.white54, tabs: [Tab(text: "Cards"), Tab(text: "Frames"), Tab(text: "Entry"), Tab(text: "Special")]),
          Expanded(child: TabBarView(children: [_buildStoreCardTab(), const Center(child: Text("Coming Soon", style: TextStyle(color: Colors.white54))), const Center(child: Text("Coming Soon", style: TextStyle(color: Colors.white54))), const Center(child: Text("Coming Soon", style: TextStyle(color: Colors.white54)))]))
        ]))));
  }

  Widget _buildStoreCardTab() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network("https://i.ibb.co/3ykC7mP/premium-card.jpg", height: 150, width: 220, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.card_membership, size: 100, color: Colors.amber))),
      const SizedBox(height: 10),
      const Text("Pagla Premium Card", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const Text("মুল্য: ৬,০০০ ডায়মন্ড", style: TextStyle(color: Colors.cyanAccent)),
      const SizedBox(height: 15),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent), onPressed: () {
        if (diamonds >= 6000) {
          setState(() { diamonds -= 6000; hasPremiumCard = true; premiumExpiryDate = DateTime.now().add(const Duration(days: 30)); });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("অভিনন্দন! আপনি প্রিমিয়াম মেম্বার হলেন।")));
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
    int daysLeft = premiumExpiryDate.difference(DateTime.now()).inDays;
    return ListTile(
      leading: const Icon(Icons.card_membership, color: Colors.amber, size: 40),
      title: const Text("Pagla Chat Premium", style: TextStyle(color: Colors.white)),
      subtitle: Text("মেয়াদ: $daysLeft দিন বাকি", style: const TextStyle(color: Colors.orangeAccent)),
      trailing: ElevatedButton(onPressed: () { setState(() => isVIP = true); Navigator.pop(context); }, child: const Text("Wear")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          
          // আপনার অরিজিনাল ভেরিয়েবলগুলো ফায়ারবেস থেকে আপডেট হচ্ছে
          userName = userData['name'] ?? userName;
          uIDValue = userData['uID'] ?? uIDValue;
          roomIDValue = userData['roomID'] ?? roomIDValue; // রুম আইডি ডাটাবেস থেকে আসবে
          diamonds = userData['diamonds'] ?? diamonds;
          xp = userData['xp'] ?? 0; // শুরুতে ০ থাকবে, রিচার্জে বাড়বে
          userImageURL = userData['profilePic'] ?? userImageURL;
          gender = userData['gender'] ?? gender;
        }

        int vipLevel = getVipLevel();
        // আপনার অরিজিনাল এক্সপি কমানোর লজিক (৬০ দিন পর পর)
        if (DateTime.now().difference(lastLevelUpDate).inDays >= 60) {
          Future.delayed(Duration.zero, () { 
            setState(() { 
              xp = (xp - 500).clamp(0, 100000); 
              lastLevelUpDate = DateTime.now(); 
            }); 
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D1A),
          appBar: AppBar(
            backgroundColor: Colors.transparent, 
            elevation: 0,
            leading: Row(children: [
              const SizedBox(width: 10), 
              const Icon(Icons.diamond, color: Colors.cyanAccent, size: 18), 
              Text(" $diamonds", style: const TextStyle(color: Colors.white, fontSize: 12))
            ]),
            actions: [IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: _openSettings)],
          ),
          body: SingleChildScrollView(
            child: Column(children: [
              // প্রোফাইল পিকচার এবং ভিআইপি ফ্রেম
              Center(child: Stack(alignment: Alignment.center, children: [
                if (vipLevel > 0) Image.network("https://png.pngtree.com/png-clipart/20230501/original/pngtree-golden-vip-frame-png-image_9128509.png", width: 130, height: 130),
                GestureDetector(onTap: _pickProfileImage, child: CircleAvatar(radius: 50, backgroundColor: Colors.grey[900], backgroundImage: _getProfileImage())),
              ])),
              const SizedBox(height: 10),
              // নাম এবং এডিট বাটন
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)), 
                IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.pinkAccent), onPressed: _editName)
              ]),
              // আইডি গুলো
              Text("User ID: $uIDValue", style: const TextStyle(color: Colors.pinkAccent, fontSize: 13, fontWeight: FontWeight.bold)),
              Text("Room ID: $roomIDValue", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
              const SizedBox(height: 15),
              // ভিআইপি লেভেল বার এবং প্রিমিয়াম ব্যাজ
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (vipLevel > 0) Image.network(getVipBadge(vipLevel), width: 45, height: 45) else const SizedBox(width: 45),
                const SizedBox(width: 12),
                Expanded(child: Column(children: [
                  Text("VIP Level $vipLevel (XP: $xp / 25000)", style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: (xp / 25000).clamp(0, 1), valueColor: const AlwaysStoppedAnimation(Colors.amber), backgroundColor: Colors.white10),
                ])),
                const SizedBox(width: 12),
                if (hasPremiumCard) Image.network(premiumBadgeUrl, width: 45, height: 45, errorBuilder: (c,e,s) => const Icon(Icons.verified, color: Colors.amber)) else const SizedBox(width: 45),
              ])),
              const SizedBox(height: 20),
              // ফলোয়ার এবং মেসেজ বাটন
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _buildStat("Followers", followers),
                const SizedBox(width: 25),
                ElevatedButton(onPressed: () => setState(() { isFollowing = !isFollowing; followers = isFollowing ? 1 : 0; }), style: ElevatedButton.styleFrom(backgroundColor: isFollowing ? Colors.blueGrey : Colors.pinkAccent), child: Text(isFollowing ? "Friend" : "Follow")),
                const SizedBox(width: 10),
                IconButton(icon: const Icon(Icons.mail, color: Colors.white), onPressed: () {}),
                const SizedBox(width: 25),
                _buildStat("Following", following),
              ]),
              const SizedBox(height: 30),
              // ডায়মন্ড, প্রিমিয়াম এবং ব্যাকপ্যাক বক্স
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _buildActionBox("Diamond", Icons.diamond, Colors.cyan, _openDiamondStore),
                _buildActionBox("Premium", Icons.card_membership, Colors.purple, _openPremiumStore),
                _buildActionBox("Backpack", Icons.backpack, Colors.orange, _openBackpack),
              ]),
              const SizedBox(height: 30),
            ]),
          ),
        );
      },
    );
  }
