import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  // --- ১. আপনার অরিজিনাল ডাটা (একদম অক্ষত) ---
  String userImageURL = ""; 
  List<String> maleAvatars = List.generate(10, (i) => "https://api.dicebear.com/7.x/avataaars/png?seed=male$i");
  List<String> femaleAvatars = List.generate(10, (i) => "https://api.dicebear.com/7.x/avataaars/png?seed=female$i");
  String userName = "পাগলা ইউজার";
  String uIDValue = "885522"; 
  String roomIDValue = "441100"; 
  String gender = "পুরুষ"; 
  int age = 22; // নতুন যুক্ত
  int diamonds = 200; 
  int xp = 0;
  int followers = 0;
  int following = 0;
  bool hasPremiumCard = false; 
  bool isVIP = false;         

  @override
  void initState() {
    super.initState();
    _syncUserData(); 
  }

  // --- ডাটাবেস লজিক (আপনার অরিজিনাল কোড অনুযায়ী) ---
  void _syncUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        setState(() {
          userName = userDoc.data()?['name'] ?? userName;
          diamonds = userDoc.data()?['diamonds'] ?? diamonds;
          xp = userDoc.data()?['xp'] ?? xp;
          uIDValue = userDoc.data()?['uID'] ?? "885522"; 
          roomIDValue = userDoc.data()?['roomID'] ?? "441100";
          userImageURL = userDoc.data()?['profilePic'] ?? "";
          gender = userDoc.data()?['gender'] ?? gender;
          age = userDoc.data()?['age'] ?? age;
        });
      } else {
        // আপনার অরিজিনাল আইডি জেনারেশন লজিক
        String newUID = (100000 + Random().nextInt(900000)).toString();
        String newRID = (100000 + Random().nextInt(900000)).toString();
        
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uID': newUID,
          'roomID': newRID,
          'name': userName,
          'diamonds': diamonds,
          'xp': xp,
          'gender': gender,
          'age': age,
          'status': 'active',
        });
        setState(() {
          uIDValue = newUID;
          roomIDValue = newRID;
        });
      }
    }
  }

  int getVipLevel() {
    if (xp >= 25000) return 8;
    if (xp >= 20000) return 7;
    if (xp >= 18000) return 6;
    if (xp >= 15000) return 5;
    if (xp >= 12000) return 4;
    if (xp >= 6000) return 3;
    if (xp >= 4000) return 2;
    if (xp >= 2000) return 1;
    return 0;
  }

  // --- নাম এডিট (আপনার অরিজিনাল লজিক) ---
  void _editName() {
    TextEditingController _nameController = TextEditingController(text: userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        title: const Text("নাম পরিবর্তন", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "নতুন নাম লিখুন", hintStyle: TextStyle(color: Colors.white24)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("বাতিল")),
          TextButton(
            onPressed: () async {
              setState(() => userName = _nameController.text);
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'name': userName});
              }
              Navigator.pop(context);
            }, 
            child: const Text("সেভ", style: TextStyle(color: Colors.pinkAccent))
          ),
        ],
      ),
    );
  }

  // --- বয়স পরিবর্তনের পপআপ ---
  void _showAgePicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        title: const Text("আপনার বয়স কত?", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          height: 200,
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: 40,
            itemBuilder: (context, index) => ListTile(
              title: Text("${index + 15} বছর", style: const TextStyle(color: Colors.white)),
              onTap: () async {
                setState(() => age = index + 15);
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'age': age});
                }
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- সেটিংস মেনু (আপনার কথামতো সব অপশন এর ভেতর) ---
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(padding: EdgeInsets.all(15), child: Text("সেটিংস", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          ListTile(leading: const Icon(Icons.language, color: Colors.blueAccent), title: const Text("ভাষা পরিবর্তন (বাংলা/English)", style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
          ListTile(
            leading: const Icon(Icons.wc, color: Colors.pinkAccent),
            title: Text("লিঙ্গ পরিবর্তন (বর্তমান: $gender)", style: const TextStyle(color: Colors.white)),
            onTap: () async {
              setState(() => gender = (gender == "পুরুষ") ? "নারী" : "পুরুষ");
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'gender': gender});
              }
              Navigator.pop(context);
            },
          ),
          ListTile(leading: const Icon(Icons.cake, color: Colors.orangeAccent), title: Text("বয়স পরিবর্তন (বর্তমান: $age)", style: const TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); _showAgePicker(); }),
          ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text("লগ আউট", style: TextStyle(color: Colors.redAccent)), onTap: () async { await FirebaseAuth.instance.signOut(); Navigator.pop(context); }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- অবতার ও ইমেজ পিকার (আপনার অরিজিনাল লজিক) ---
  void _showFreeAvatars() {
    List<String> avatars = (gender == "পুরুষ") ? maleAvatars : femaleAvatars;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (context) => GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10),
        itemCount: avatars.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () { setState(() => userImageURL = avatars[index]); Navigator.pop(context); Navigator.pop(context); },
          child: CircleAvatar(backgroundImage: NetworkImage(avatars[index])),
        ),
      ),
    );
  }

  void _pickProfileImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (context) => Wrap(
        children: [
          ListTile(leading: const Icon(Icons.face, color: Colors.blue), title: const Text("ডিফল্ট ছবি (ফ্রি)", style: TextStyle(color: Colors.white)), onTap: _showFreeAvatars),
          ListTile(
            leading: Icon(Icons.photo_library, color: (isVIP || hasPremiumCard) ? Colors.pinkAccent : Colors.grey),
            title: Text("গ্যালারি (VIP/Premium শুধু)", style: TextStyle(color: (isVIP || hasPremiumCard) ? Colors.white : Colors.grey)),
            onTap: () async {
              if (isVIP || hasPremiumCard) {
                final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() => userImageURL = image.path);
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'profileImage': image.path});
                  }
                }
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  // --- ডাইমন্ড স্টোর (অক্ষত) ---
  void _openDiamondStore() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2F),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(padding: EdgeInsets.all(15), child: Text("ডাইমন্ড কিনুন (বিকাশ/নগদ)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          _buildDiamondOption("৬০০০ ডাইমন্ড", "১৫০ টাকা"),
          _buildDiamondOption("১২০০০ ডাইমন্ড", "২৫০ টাকা"),
          _buildDiamondOption("২৪০০০ ডাইমন্ড", "৪৫০ টাকা"),
          _buildDiamondOption("৫০০০০০ ডাইমন্ড", "৮০০ টাকা"),
        ],
      ),
    );
  }

  Widget _buildDiamondOption(String amount, String price) => ListTile(
    leading: const Icon(Icons.diamond, color: Colors.cyanAccent),
    title: Text(amount, style: const TextStyle(color: Colors.white)),
    trailing: Text(price, style: const TextStyle(color: Colors.greenAccent)),
    onTap: () => Navigator.pop(context),
  );

  @override
  Widget build(BuildContext context) {
    int vipLevel = getVipLevel();
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: Row(children: [const SizedBox(width: 10), const Icon(Icons.diamond, color: Colors.amber, size: 16), Text(" $diamonds", style: const TextStyle(color: Colors.white, fontSize: 12))]),
        actions: [IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: _openSettings)],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickProfileImage,
                child: Stack(alignment: Alignment.center, children: [
                  Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: vipLevel > 0 ? Colors.amber : Colors.grey, width: 4))),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white10,
                    child: ClipOval(
                      child: userImageURL.isEmpty || userImageURL.startsWith('https')
                          ? Image.network(
                              userImageURL.isEmpty ? "https://api.dicebear.com/7.x/avataaars/png?seed=Felix" : userImageURL,
                              fit: BoxFit.cover, width: 100, height: 100,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white, size: 50),
                            )
                          : Image.file(
                              File(userImageURL),
                              fit: BoxFit.cover, width: 100, height: 100,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white, size: 50),
                            ),
                    ),
                  ),
                  if (vipLevel > 0) Positioned(bottom: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4), color: Colors.amber, child: Text(" VIP $vipLevel ", style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)))),
                  Positioned(bottom: 5, right: 5, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.pinkAccent, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, size: 15, color: Colors.white))),
                ]),
              ),   
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)), IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.pinkAccent), onPressed: _editName)]),
            Text("User ID: $uIDValue", style: const TextStyle(color: Colors.pinkAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            Text("Room ID: $roomIDValue", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
            const SizedBox(height: 10),
            // XP Bar
            Column(children: [
              Text("VIP Level $vipLevel (XP: $xp / 1000)", style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Container(width: 180, height: 10, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: (xp % 1000) / 1000, valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber), backgroundColor: Colors.transparent))),
            ]),
            const SizedBox(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildStat("ফলোয়ার", followers), const SizedBox(width: 30), _buildStat("ফলোয়িং", following)]),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _buildActionCard("ডাইমন্ড স্টোর", Icons.shopping_bag, Colors.blue, _openDiamondStore),
              _buildActionCard("প্রিমিয়াম বক্স", Icons.card_membership, Colors.purple, () {}),
            ]),
            const Padding(padding: EdgeInsets.all(15), child: Align(alignment: Alignment.centerLeft, child: Text("অনলাইন রুমসমূহ", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
            _buildOnlineRooms(),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int count) => Column(children: [Text("$count", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white54))]);
  
  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap, child: Container(width: 150, height: 100, decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(15), border: Border.all(color: color)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 30), const SizedBox(height: 5), Text(title, style: const TextStyle(color: Colors.white))])),
  );

  Widget _buildOnlineRooms() => ListView.builder(
    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: 5,
    itemBuilder: (context, index) => ListTile(
      leading: const CircleAvatar(backgroundColor: Colors.pinkAccent, child: Icon(Icons.mic, color: Colors.white)), 
      title: Text("আড্ডা রুম ${index + 1}", style: const TextStyle(color: Colors.white)), 
      subtitle: const Text("১০ জন মানুষ আড্ডা দিচ্ছে", style: TextStyle(color: Colors.white38, fontSize: 12)),
    ),
  );
}

