import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; 
import 'dart:io'; // <--- এই লাইনটি অবশ্যই যোগ করুন, এটি ফাইল হ্যান্ডেল করার জন্য
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- ১. ইউজারের ডাটা (আগের ফিচারগুলো অক্ষত আছে) ---
  // ১০টি ছেলেদের এবং ১০টি মেয়েদের ছবির লিংক (আপনি আপনার পছন্দমতো পরিবর্তন করতে পারবেন)
  String userImageURL = ""; // এই লাইনটি যোগ করুন
  List<String> maleAvatars = List.generate(10, (i) => "https://api.dicebear.com/7.x/avataaars/png?seed=male$i");
  List<String> femaleAvatars = List.generate(10, (i) => "https://api.dicebear.com/7.x/avataaars/png?seed=female$i");
  String userName = "পাগলা ইউজার";
  String uIDValue = "885522"; // ডিফল্ট আইডি
  String roomIDValue = "441100"; // ডিফল্ট রুম আইডি
  String gender = "পুরুষ"; 
  int diamonds = 200; 
  int xp = 0;
  int followers = 0;
  int following = 0;
  bool hasPremiumCard = false; // এটি প্রিমিয়াম ইউজার কি না চেক করবে
  bool isVIP = false;         // এটি ভিআইপি কি না চেক করবে
// --- ডাটাবেস থেকে ডাটা আনা ও সেভ রাখা ---
  void _syncUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        // যদি ডাটাবেসে ডাটা থাকে, তবে সেগুলো লোড করো
        setState(() {
          userName = userDoc.data()?['name'] ?? userName;
          diamonds = userDoc.data()?['diamonds'] ?? diamonds;
          xp = userDoc.data()?['xp'] ?? xp;
          // তোমার UserModel এর uID এবং roomID এখানে সেট হবে
          uIDValue = userDoc.data()?['uID'] ?? "885522"; 
          roomIDValue = userDoc.data()?['roomID'] ?? "441100";
        });
      } else {
        userImageURL = userDoc.data()?['profileImage'] ?? "";
        // নতুন ইউজার হলে ডাটাবেসে প্রথমবার সেভ করো
        String newUID = (100000 + Random().nextInt(900000)).toString();
        String newRID = (100000 + Random().nextInt(900000)).toString();
        
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uID': newUID,
          'roomID': newRID,
          'name': userName,
          'diamonds': diamonds,
          'xp': xp,
          'status': 'active',
        });
        setState(() {
          uIDValue = newUID;
          roomIDValue = newRID;
        });
      }
    }
  }

  
  @override
  void initState() {
    super.initState();
    _syncUserData(); // পেজ ওপেন হলেই ডাটা সিঙ্ক হবে
  }
  
  // --- ২. ভিআইপি লেভেল ক্যালকুলেশন (অক্ষত আছে) ---
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

  // --- নতুন ফিচার: নাম এডিট করার ডায়ালগ ---
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
            onPressed: () {
              setState(() => userName = _nameController.text);
              Navigator.pop(context);
            }, 
            child: const Text("সেভ", style: TextStyle(color: Colors.pinkAccent))
          ),
        ],
      ),
    );
  }

  // --- নতুন ফিচার: ছবি সিলেকশন লজিক (৩টি অপশন) ---
  // এই ফাংশনটি আপনার প্রোফাইল পিকচার সিলেকশনে যোগ করুন
void _showFreeAvatars() {
  List<String> avatars = (gender == "পুরুষ") ? maleAvatars : femaleAvatars;

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1A2E),
    builder: (context) => GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // এক লাইনে ৪টি ছবি
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: avatars.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            setState(() => userImageURL = avatars[index]); // ছবি সেট হলো
            Navigator.pop(context); // অবতার লিস্ট বন্ধ
            Navigator.pop(context); // মেইন শিট বন্ধ
          },
          child: CircleAvatar(
            backgroundImage: NetworkImage(avatars[index]),
          ),
        );
      },
    ),
  );
}
  void _pickProfileImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(15.0),
              child: Text("প্রোফাইল পিকচার সেট করুন", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            // ১. নির্ধারিত ছবি (সবার জন্য)
            ListTile(
              leading: const Icon(Icons.face, color: Colors.blue),
              title: const Text("ডিফল্ট ছবি (ফ্রি)", style: TextStyle(color: Colors.white)),
              onTap: () {
                // এখানে ডিফল্ট ছবি সেভ করার লজিক হবে
                _showFreeAvatars();
              },
            ),
            // ২ ও ৩. গ্যালারি (ভিআইপি বা প্রিমিয়াম কার্ড থাকলে অটোমেটিক খুলবে)
            ListTile(
              leading: Icon(Icons.photo_library, 
                color: (isVIP || hasPremiumCard) ? Colors.pinkAccent : Colors.grey),
              title: Text(
                (isVIP || hasPremiumCard) ? "গ্যালারি থেকে আপলোড" : "গ্যালারি (VIP/Premium শুধু)",
                style: TextStyle(color: (isVIP || hasPremiumCard) ? Colors.white : Colors.grey),
              ),
              onTap: () async {
                if (isVIP || hasPremiumCard) {
                  final ImagePicker _picker = ImagePicker();
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  
                  if (image != null) {
                    setState(() {
                    userImageURL = image.path;
                  });
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) { 
                     await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                       'profileImage': image.path,
                     });
                   }
                 }
                 Navigator.pop(context);
               } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("দয়া করে ভিআইপি বা প্রিমিয়াম কার্ড কিনুন!"))
                  );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- ডাইমন্ড স্টোর পপ-আপ (অক্ষত আছে) ---
  void _openDiamondStore() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2F),
      builder: (context) => Container(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            const Text("ডাইমন্ড কিনুন (বিকাশ/নগদ)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white10),
            _buildDiamondOption("৬০০০ ডাইমন্ড", "১৫০ টাকা"),
            _buildDiamondOption("১২০০০ ডাইমন্ড", "২৫০ টাকা"),
            _buildDiamondOption("২৪০০০ ডাইমন্ড", "৪৫০ টাকা"),
            _buildDiamondOption("৫০০০০০ ডাইমন্ড", "৮০০ টাকা"),
          ],
        ),
      ),
    );
  }

  Widget _buildDiamondOption(String amount, String price) {
    return ListTile(
      leading: const Icon(Icons.diamond, color: Colors.cyanAccent),
      title: Text(amount, style: const TextStyle(color: Colors.white)),
      trailing: Text(price, style: const TextStyle(color: Colors.greenAccent)),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("পেমেন্ট সম্পন্ন হলে ফায়ারবেস থেকে ডাইমন্ড এড হবে")));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int vipLevel = getVipLevel();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 10),
          child: Row(children: [const Icon(Icons.diamond, color: Colors.amber, size: 16), Text(" $diamonds")]),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => _openSettings()),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ১. প্রোফাইল পিকচার ও ফ্রেম (ট্যাপ ফিচারসহ)
            Center(
              child: GestureDetector(
                onTap: _pickProfileImage, // ছবিতে চাপ দিলে অপশন আসবে
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: vipLevel > 0 ? Colors.amber : Colors.grey, width: 4),
                      ),
                    ),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white10,
                      backgroundImage: userImageURL.isEmpty
                        ? const NetworkImage("https://api.dicebear.com/7.x/avataaars/png?seed=Felix")
                        : (userImageURL.startsWith('http')
                            ? NetworkImage(userImageURL) as ImageProvider
                            : (File(userImageURL).existsSync()
                                ? FileImage(File(userImageURL)) as ImageProvider),
                                : const NetworkImage("https://api.dicebear.com/7.x/avataaars/png?seed=Felix"))),
                  
                    ),   
                    if (vipLevel > 0) Positioned(bottom: 0, child: Container(color: Colors.amber, child: Text(" VIP $vipLevel ", style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)))),
                    // ছোট ক্যামেরা আইকন
                    Positioned(bottom: 5, right: 5, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.pinkAccent, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, size: 15, color: Colors.white))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            // --- ১. নাম ও এডিট বাটন ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.pinkAccent), onPressed: _editName),
              ],
            ),

            const SizedBox(height: 10),

            // --- ২. ভিআইপি লেভেল এবং এক্সপি প্রগ্রেস বার (যা ০ থেকে বাড়বে) ---
            Column(
              children: [
                Text(
                  "VIP Level $vipLevel (XP: $xp / 1000)", 
                  style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 180, 
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24, width: 0.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (xp % 1000) / 1000, 
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 15), 

            // --- ৩. আইডি দেখানোর ডাইনামিক ঘর ---
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Text(
                    "User ID: $uIDValue", 
                    style: const TextStyle(color: Colors.pinkAccent, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Room ID: $roomIDValue", 
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            // ২. ফলোয়ার/ফলোয়িং সেকশন (অক্ষত আছে)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStat("ফলোয়ার", followers),
                const SizedBox(width: 30),
                _buildStat("ফলোয়িং", following),
              ],
            ),
            const SizedBox(height: 20),

            // ৩. ডিজাইন বোর্ড (অক্ষত আছে)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionCard("ডাইমন্ড স্টোর", Icons.shopping_bag, Colors.blue, _openDiamondStore),
                _buildActionCard("প্রিমিয়াম বক্স", Icons.card_membership, Colors.purple, () {}),
              ],
            ),

            // ৪. অনলাইন রুম লিস্ট (অক্ষত আছে)
            const Padding(
              padding: EdgeInsets.all(15.0),
              child: Align(alignment: Alignment.centerLeft, child: Text("অনলাইন রুমসমূহ", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            ),
            _buildOnlineRooms(),
          ],
        ),
      ),
    );
  }

  // --- সেটিংস মেনু (অক্ষত আছে) ---
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2F),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.language), title: const Text("ভাষা পরিবর্তন (বাংলা/English)"), onTap: () {}),
          ListTile(leading: const Icon(Icons.wc), title: const Text("লিঙ্গ পরিবর্তন"), onTap: () {}),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("লগ আউট"), onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int count) {
    return Column(children: [Text("$count", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white54))]);
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150, height: 100,
        decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(15), border: Border.all(color: color)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 30), const SizedBox(height: 5), Text(title, style: const TextStyle(color: Colors.white))]),
      ),
    );
  }

  Widget _buildOnlineRooms() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) => ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.pinkAccent, child: Icon(Icons.mic)),
        title: Text("আড্ডা রুম ${index + 1}", style: const TextStyle(color: Colors.white)),
        subtitle: const Text("১০ জন মানুষ আড্ডা দিচ্ছে", style: TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
        onTap: () { },
      ),
    );
  }
}
