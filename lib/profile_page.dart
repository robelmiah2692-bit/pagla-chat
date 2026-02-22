import 'main.dart';
import 'dart:math'; 
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- আপনার অরিজিনাল ডাটা (একদম অক্ষত) ---
  String userImageURL = ""; 
  String userName = "পাগলা ইউজার";
  String uIDValue = "885522"; 
  String roomIDValue = "441100"; 
  String gender = "পুরুষ"; 
  int age = 22; 
  int diamonds = 200; 
  int xp = 2500; 
  int followers = 0; // ৫ নং দাবি: ০ থেকে শুরু
  int following = 0;
  bool isFollowing = false;
  bool hasPremiumCard = true; 
  bool isVIP = false; 
  DateTime premiumExpiryDate = DateTime.now();
  
  // আপনার দেওয়া ছবি অনুযায়ী VIP স্টিকারের লিঙ্ক লজিক
  String getVipBadge(int level) {
    switch (level) {
      case 1: return "https://i.ibb.co/example/vip1.png"; // আপনার VIP 1 লিঙ্ক
      case 2: return "https://i.ibb.co/example/vip2.png"; // আপনার VIP 2 লিঙ্ক
      case 3: return "https://i.ibb.co/example/vip3.png"; 
      case 4: return "https://i.ibb.co/example/vip4.png";
      case 5: return "https://i.ibb.co/example/vip5.png";
      case 6: return "https://i.ibb.co/example/vip6.png";
      case 7: return "https://i.ibb.co/example/vip7.png";
      case 8: return "https://i.ibb.co/example/vip8.png";
      default: return ""; 
    }
  }

  // প্রিমিয়াম স্টিকার লিঙ্ক
  String premiumBadgeUrl = "https://i.ibb.co/example/premium_gold.png";
  // ৩ নং দাবি: ২০টি রিয়েল টাইপ অবতার
  List<String> maleAvatars = List.generate(10, (i) => "https://xsgames.co/randomusers/assets/avatars/male/${i + 1}.jpg");
  List<String> femaleAvatars = List.generate(10, (i) => "https://xsgames.co/randomusers/assets/avatars/female/${i + 1}.jpg");

  @override
  void initState() {
    super.initState();
    _syncUserData(); 
  }

  // আপনার অরিজিনাল সিঙ্ক ফাংশন (অক্ষত)
  void _syncUserData() {
    setState(() {
      userName    = "পাগলা ইউজার (Offline)";
      uIDValue    = "885522"; 
      roomIDValue = "441100";
      gender      = "পুরুষ";
      age         = 22;
      diamonds    = 200;
      xp          = 2500; 
      userImageURL = ""; 
    });
  }

  // আপনার অরিজিনাল লেভেল ক্যালকুলেশন
  int getVipLevel() {
    if (xp >= 35000) return 8; // ভিআইপি ৮ (সর্বোচ্চ)
    if (xp >= 30000) return 7;
    if (xp >= 25000) return 6;
    if (xp >= 20000) return 5;
    if (xp >= 13000) return 4;
    if (xp >= 9000)  return 3;
    if (xp >= 5000)  return 2;
    if (xp >= 2500)  return 1; // ভিআইপি ১ শুরু
    return 0; 
  }

  // আপনার অরিজিনাল নাম এডিট (অক্ষত)
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
          TextButton(onPressed: () { setState(() => userName = _nameController.text); Navigator.pop(context); }, child: const Text("সেভ", style: TextStyle(color: Colors.pinkAccent))),
        ],
      ),
    );
  }

  // আপনার অরিজিনাল বয়স পিকার (অক্ষত)
  void _showAgePicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        title: const Text("আপনার বয়স কত?", style: TextStyle(color: Colors.white)),
        content: SizedBox(height: 200, width: double.maxFinite, child: ListView.builder(itemCount: 40, itemBuilder: (context, index) => ListTile(title: Text("${index + 15} বছর", style: const TextStyle(color: Colors.white)), onTap: () { setState(() => age = index + 15); Navigator.pop(context); }))),
      ),
    );
  }

  // ২ নং দাবি: আপনার সেটিংস এর সব ঠিক রেখে ব্লকলিস্ট যোগ
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(15), child: Text("সেটিংস", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          ListTile(
          leading: const Icon(Icons.wc, color: Colors.pinkAccent),
          title: Text("লিঙ্গ পরিবর্তন (বর্তমান: $gender)", style: const TextStyle(color: Colors.white)),
          trailing: PopupMenuButton<String>(
            color: const Color(0xFF1E1E2F),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            onSelected: (val) => setState(() => gender = val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: "পুরুষ", child: Text("পুরুষ", style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: "নারী", child: Text("নারী", style: TextStyle(color: Colors.white))),
            ],
          ),
        ),
          ListTile(leading: const Icon(Icons.cake, color: Colors.orangeAccent), title: Text("বয়স পরিবর্তন (বর্তমান: $age)", style: const TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); _showAgePicker(); }),
          ListTile(leading: const Icon(Icons.block, color: Colors.redAccent), title: const Text("ব্লকলিস্ট", style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("লগ আউট", style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context); // সেটিংস বন্ধ হবে
              // মেইন ফাইলের LoginScreen-এ নিয়ে যাবে
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
 
  // আপনার অরিজিনাল ইমেজ পিকার + ৩ নং দাবি (২০টি অবতার)
  void _showFreeAvatars() {
    List<String> avatars = (gender == "পুরুষ") ? maleAvatars : femaleAvatars;
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A2E), builder: (context) => GridView.builder(padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5), itemCount: 10, itemBuilder: (context, index) => GestureDetector(onTap: () { setState(() => userImageURL = avatars[index]); Navigator.pop(context); Navigator.pop(context); }, child: CircleAvatar(backgroundImage: NetworkImage(avatars[index])))));
  }

  void _pickProfileImage() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A2E), builder: (context) => Wrap(children: [
      ListTile(leading: const Icon(Icons.face, color: Colors.blue), title: const Text("২০টি রিয়েল অবতার", style: TextStyle(color: Colors.white)), onTap: _showFreeAvatars),
      ListTile(leading: const Icon(Icons.photo_library, color: Colors.pinkAccent), title: const Text("গ্যালারি", style: TextStyle(color: Colors.white)), onTap: () async {
        final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (image != null) setState(() => userImageURL = image.path);
        Navigator.pop(context);
      }),
    ]));
  }

  // ৬ নং দাবি: ডায়মন্ড স্টোর পেমেন্ট লজিক
  void _openDiamondStore() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1E1E2F), builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
      _buildDiamondOption("৬,০০০ ডায়মন্ড", "১৫০ টাকা"),
          _buildDiamondOption("১২,০০০ ডায়মন্ড", "৩০০ টাকা"),
          _buildDiamondOption("২৫,০০০ ডায়মন্ড", "৬০০ টাকা"),
          _buildDiamondOption("৬০,০০০ ডায়মন্ড", "১,৫০০ টাকা"),
          _buildDiamondOption("১,২০,০০০ ডায়মন্ড", "৩,০০০ টাকা"),
          _buildDiamondOption("৫,০০,০০০ ডায়মন্ড", "১২,০০০ টাকা"), // সঠিক রেইট
          const SizedBox(height: 15),
        ],
      ),
    );
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // পুরো স্ক্রিন জুড়ে দেখানোর জন্য
    backgroundColor: const Color(0xFF1E1E2F),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => DefaultTabController(
      length: 4, // কয়টি ট্যাব হবে (কার্ড, ফ্রেম, এন্ট্রি, অন্যান্য)
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7, // স্ক্রিনের ৭০% উচ্চতা
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // উপরে ট্যাব বার
            const TabBar(
              isScrollable: true,
              indicatorColor: Colors.amber,
              labelColor: Colors.amber,
              unselectedLabelColor: Colors.white54,
              tabs: [
                Tab(text: "Cards"),
                Tab(text: "Frames"),
                Tab(text: "Entry Effects"),
                Tab(text: "Special"),
              ],
            ),
            const SizedBox(height: 20),
            // ট্যাবের ভেতরের কন্টেন্ট
            Expanded(
              child: TabBarView(
                children: [
                  // ১. কার্ড ট্যাব (আপনার বর্তমান কোড এখানে)
                  _buildStoreCardTab(),
                  
                  // ২. ফ্রেম ট্যাব (ভবিষ্যতের জন্য খালি বা মেসেজ)
                  const Center(child: Text("Frames Coming Soon...", style: TextStyle(color: Colors.white54))),
                  
                  // ৩. এন্ট্রি ইফেক্ট
                  const Center(child: Text("Effects Coming Soon...", style: TextStyle(color: Colors.white54))),
                  
                  // ৪. স্পেশাল
                  const Center(child: Text("More Items...", style: TextStyle(color: Colors.white54))),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// কার্ড ট্যাবের ডিজাইন আলাদা করে নিচে দিয়ে দিলাম
Widget _buildStoreCardTab() {
  return Column(
    children: [
      Image.network("https://i.ibb.co/L8p61D5/premium-card.png", width: 180), // আসল লিঙ্ক বসাবেন
      const SizedBox(height: 15),
      const Text("Pagla Premium Card", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const Text("মুল্য: ৬,০০০ ডায়মন্ড", style: TextStyle(color: Colors.cyanAccent, fontSize: 16)),
      const SizedBox(height: 20),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, minimumSize: const Size(180, 45)),
        onPressed: () {
          if (diamonds >= 6000) {
            setState(() {
              diamonds -= 6000;
              hasPremiumCard = true;
              premiumExpiryDate = DateTime.now().add(const Duration(days: 30));
            });
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("অভিনন্দন! আপনি প্রিমিয়াম মেম্বার হলেন।")));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("পর্যাপ্ত ডায়মন্ড নেই!")));
          }
        },
        child: const Text("BUY NOW"),
      ),
    ],
  );
}
 
  void _openBackpack() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E1E2F),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => DefaultTabController(
      length: 4, // স্টোরের সাথে মিল রেখে ৪টি ট্যাব
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // উপরে ব্যাকপ্যাক ট্যাব বার
            const TabBar(
              isScrollable: true,
              indicatorColor: Colors.pinkAccent,
              labelColor: Colors.pinkAccent,
              unselectedLabelColor: Colors.white54,
              tabs: [
                Tab(text: "My Cards"),
                Tab(text: "My Frames"),
                Tab(text: "My Effects"),
                Tab(text: "Others"),
              ],
            ),
            const SizedBox(height: 20),
            // ট্যাবের ভেতরের কন্টেন্ট
            Expanded(
              child: TabBarView(
                children: [
                  // ১. আমার কার্ডসমূহ (এখানে আপনার কেনা কার্ডটি থাকবে)
                  _buildMyCardsTab(),
                  
                  // ২. আমার ফ্রেমসমূহ (ভবিষ্যতের জন্য)
                  const Center(child: Text("আপনার কোনো ফ্রেম নেই", style: TextStyle(color: Colors.white54))),
                  
                  // ৩. আমার ইফেক্টসমূহ
                  const Center(child: Text("আপনার কোনো ইফেক্ট নেই", style: TextStyle(color: Colors.white54))),
                  
                  // ৪. অন্যান্য
                  const Center(child: Text("ব্যাকপ্যাক খালি", style: TextStyle(color: Colors.white54))),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// কেনা কার্ড দেখানোর উইজেট
Widget _buildMyCardsTab() {
  if (!hasPremiumCard) {
    return const Center(child: Text("আপনার কাছে কোনো প্রিমিয়াম কার্ড নেই", style: TextStyle(color: Colors.white54)));
  }

  int daysLeft = premiumExpiryDate.difference(DateTime.now()).inDays;

  return ListView(
    children: [
      Card(
        color: const Color(0xFF2A2A3D),
        margin: const EdgeInsets.all(10),
        child: ListTile(
          leading: const Icon(Icons.card_membership, color: Colors.amber, size: 30),
          title: const Text("Pagla Chat Premium", style: TextStyle(color: Colors.white)),
          subtitle: Text("মেয়াদ: $daysLeft দিন বাকি", style: const TextStyle(color: Colors.orangeAccent)),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              setState(() {
                isVIP = true; // কার্ড পরলে ফ্রেম অন হবে
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("প্রিমিয়াম কার্ডটি পরিধান করা হয়েছে!"))
              );
            },
            child: const Text("Wear"),
          ),
        ),
      ),
    ],
  );
}
  
  @override
  Widget build(BuildContext context) {
    int vipLevel = getVipLevel();
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A), // প্রিমিয়াম ডার্ক কালার
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        // ১ নং দাবি: ডাইমন্ড আইকন সায়ান কালার
        leading: Row(children: [const SizedBox(width: 10), const Icon(Icons.diamond, color: Colors.cyanAccent, size: 18), Text(" $diamonds", style: const TextStyle(color: Colors.white, fontSize: 12))]),
        actions: [IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: _openSettings)],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // ৪ নং দাবি: ভিআইপি ফ্রেম
          Center(child: Stack(alignment: Alignment.center, children: [
            if (vipLevel > 0) Image.network("https://png.pngtree.com/png-clipart/20230501/original/pngtree-golden-vip-frame-png-image_9128509.png", width: 130, height: 130),
            GestureDetector(onTap: _pickProfileImage, child: CircleAvatar(radius: 50, backgroundImage: userImageURL.isEmpty ? NetworkImage(maleAvatars[0]) : (userImageURL.startsWith('http') ? NetworkImage(userImageURL) : FileImage(File(userImageURL)) as ImageProvider))),
          ])),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)), IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.pinkAccent), onPressed: _editName)]),
          Text("User ID: $uIDValue", style: const TextStyle(color: Colors.pinkAccent, fontSize: 13, fontWeight: FontWeight.bold)),
          Text("Room ID: $roomIDValue", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
          const SizedBox(height: 10),

          // ৪ নং দাবি: এক্সপি বারের দুই পাশে VIP ও Premium স্টিকার
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // বাম পাশে: ডায়নামিক VIP স্টিকার (লেভেল অনুযায়ী পাল্টাবে)
                if (vipLevel > 0)
                  Image.network(getVipBadge(vipLevel), width: 45, height: 45)
                else
                  const SizedBox(width: 45), // জায়গা ধরে রাখার জন্য

                const SizedBox(width: 12),

                // মাঝখানে: এক্সপি বার ও লেভেল টেক্সট
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        "VIP Level $vipLevel (XP: $xp / 25000)",
                        style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: xp / 25000,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // ডান পাশে: প্রিমিয়াম স্টিকার (কার্ড কেনা থাকলে শো করবে)
                if (hasPremiumCard)
                  Image.network(premiumBadgeUrl, width: 45, height: 45)
                else
                  const SizedBox(width: 45),
              ],
            ),
          ),
          // ৫ নং দাবি: ফলো ও মেসেজ লজিক
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildStat("Followers", followers),
            const SizedBox(width: 20),
            ElevatedButton(onPressed: () => setState(() { isFollowing = !isFollowing; followers = isFollowing ? 1 : 0; }), style: ElevatedButton.styleFrom(backgroundColor: isFollowing ? Colors.blueGrey : Colors.pinkAccent), child: Text(isFollowing ? "Friend" : "Follow")),
            const SizedBox(width: 10),
            IconButton(icon: const Icon(Icons.mail, color: Colors.white), onPressed: () {}),
            const SizedBox(width: 20),
            _buildStat("Following", following),
          ]),

          const SizedBox(height: 20),
          // ৭ ও ৯ নং দাবি: ছোট ৩টি বক্স
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _buildActionBox("Diamond", Icons.diamond, Colors.cyan, _openDiamondStore),
            // এখানে () {} বদলে ফাংশনের নাম বসিয়ে দিলাম
            _buildActionBox("Premium", Icons.card_membership, Colors.purple, _openPremiumStore),
            _buildActionBox("Backpack", Icons.backpack, Colors.orange, _openBackpack),
          ]),

          const Padding(padding: EdgeInsets.all(15), child: Align(alignment: Alignment.centerLeft, child: Text("অনলাইন রুমসমূহ", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
          
          // ৮ নং দাবি: স্ক্রলযোগ্য রুম
          SizedBox(height: 250, child: _buildOnlineRooms()),
        ]),
      ),
    );
  }

  Widget _buildStat(String label, int count) => Column(children: [Text("$count", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))]);
  
  Widget _buildActionBox(String title, IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap, child: Container(width: 100, height: 85, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.5))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 28), const SizedBox(height: 5), Text(title, style: const TextStyle(color: Colors.white, fontSize: 11))])),
  );

  Widget _buildOnlineRooms() => ListView.builder(
    padding: EdgeInsets.zero, itemCount: 5,
    itemBuilder: (context, index) => ListTile(
      leading: const CircleAvatar(backgroundColor: Colors.pinkAccent, child: Icon(Icons.mic, color: Colors.white)), 
      title: Text("আড্ডা রুম ${index + 1}", style: const TextStyle(color: Colors.white)), 
      subtitle: const Text("১০ জন মানুষ আড্ডা দিচ্ছে", style: TextStyle(color: Colors.white38, fontSize: 12)),
    ),
  );
// ব্যাকপ্যাকের ভেতর কার্ড দেখানোর উইজেট
  Widget _buildBackpackItem() {
    if (!hasPremiumCard) return const Center(child: Text("আপনার ব্যাকপ্যাক খালি", style: TextStyle(color: Colors.white54)));

    int daysLeft = premiumExpiryDate.difference(DateTime.now()).inDays;

    return Card(
      color: const Color(0xFF2A2A3D),
      margin: const EdgeInsets.all(10),
      child: ListTile(
        leading: Image.network("https://i.ibb.co/example/premium_card_small.png", width: 40),
        title: const Text("Pagla Chat Premium", style: TextStyle(color: Colors.white)),
        subtitle: Text("মেয়াদ শেষ: $daysLeft দিন বাকি", style: const TextStyle(color: Colors.orangeAccent)),
        trailing: ElevatedButton(
          onPressed: () {
            // কার্ড ব্যবহার করার লজিক এখানে হবে
          },
          child: const Text("Wear"),
        ),
      ),
    );
  }
}
