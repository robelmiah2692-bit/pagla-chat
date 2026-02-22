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
    if (xp >= 25000) return 8;
    if (xp >= 6000) return 3;
    if (xp >= 2000) return 1;
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
              Navigator.pop(context);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
          ),
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
      _buildDiamondOption("৬০০০ ডাইমন্ড", "১৫০ টাকা"),
      _buildDiamondOption("৫০০০০০ ডাইমন্ড", "৮০০ টাকা"),
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

          // ৪ নং দাবি: এক্সপি বারের দুই পাশে স্টিকার
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            vipLevel >= 1 ? const Icon(Icons.workspace_premium, color: Colors.amber, size: 24) : const SizedBox(width: 24),
            const SizedBox(width: 10),
            Column(children: [
              Text("VIP Level $vipLevel (XP: $xp / 25000)", style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Container(width: 180, height: 10, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: xp / 25000, valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber), backgroundColor: Colors.transparent))),
            ]),
            const SizedBox(width: 10),
            hasPremiumCard ? const Icon(Icons.stars, color: Colors.amber, size: 24) : const SizedBox(width: 24),
          ]),

          const SizedBox(height: 15),
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
            _buildActionBox("Premium", Icons.card_membership, Colors.purple, () {}),
            _buildActionBox("Backpack", Icons.backpack, Colors.orange, () {}),
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
}
