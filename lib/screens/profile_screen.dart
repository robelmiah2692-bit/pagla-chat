import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../core/constants.dart';
import '../models/user_model.dart';

class RealProfileScreen extends StatefulWidget {
  const RealProfileScreen({super.key});

  @override
  State<RealProfileScreen> createState() => _RealProfileScreenState();
}

class _RealProfileScreenState extends State<RealProfileScreen> {
  // ১. প্রাথমিক ডাটা (১ লাখ ডায়মন্ডে VIP 1 লজিক এখানে আছে)
  UserModel user = UserModel(
    name: "Rss°Hridoy",
    bio: "আড্ডা দিতে ভালোবাসি",
    diamonds: 150000, // টেস্টের জন্য ১.৫ লাখ রাখা হলো যাতে VIP 1 দেখায়
  );
  
  File? _image;

  @override
  void initState() {
    super.initState();
    _loadData();
    user.calculateVipLevel(); // লেভেল হিসাব করা
  }

  // ২. ডাটা লোড ও রিয়েল-টাইম সেভ মেকানিজম
  _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      user.name = prefs.getString('name') ?? "Rss°Hridoy";
      user.bio = prefs.getString('bio') ?? "আড্ডা দিতে ভালোবাসি";
      user.diamonds = prefs.getInt('diamonds') ?? 150000;
      user.calculateVipLevel(); // লেভেল লোড হওয়া মাত্র আপডেট হবে
    });
  }

  _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('name', user.name);
    prefs.setString('bio', user.bio);
    // বাস্তবে ডায়মন্ড কেনা হলে এটি সেভ হবে
  }

  // ৩. প্রোফাইল সেটিংস প্যানেল (এখান থেকে নাম ও তথ্য চেঞ্জ হবে)
  void _showEditSheet() {
    TextEditingController nCtrl = TextEditingController(text: user.name);
    TextEditingController bCtrl = TextEditingController(text: user.bio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("প্রোফাইল সেটিংস", style: AppConstants.titleStyle),
            const SizedBox(height: 15),
            TextField(controller: nCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "নিকনেম", labelStyle: TextStyle(color: Colors.white38))),
            TextField(controller: bCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "বায়ো", labelStyle: TextStyle(color: Colors.white38))),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentColor, minimumSize: const Size(double.infinity, 45)),
              onPressed: () {
                setState(() {
                  user.name = nCtrl.text;
                  user.bio = bCtrl.text;
                });
                _saveData(); // রিয়েল ডাটাবেসে সেভ করা
                Navigator.pop(context);
              },
              child: const Text("সেভ করুন", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundImage), // HD ক্লিয়ার ব্যাকগ্রাউন্ড
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // টপ বার (ডায়মন্ড ও সেটিংস)
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppConstants.diamondColor, width: 0.5)),
                      child: Row(children: [
                        const Icon(Icons.diamond, color: AppConstants.diamondColor, size: 20),
                        Text(" ${user.diamonds}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    IconButton(icon: const Icon(Icons.settings, color: Colors.white, size: 28), onPressed: _showEditSheet),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              // প্রোফাইল ছবি ও VIP ব্যাজ (১-৩০ লেভেল)
              Stack(
                alignment: Alignment.center,
                children: [
                  // Soulmate এনিমেশন বা প্রিমিয়াম ফ্রেম এরিয়া
                  Container(width: 140, height: 140, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppConstants.accentColor.withOpacity(0.5), width: 3))),
                  const CircleAvatar(radius: 62, backgroundColor: Colors.white10, child: Icon(Icons.person, size: 60, color: Colors.white24)),
                  // VIP লেভেল ব্যাজ
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 5)],
                      ),
                      child: Text("VIP ${user.vipLevel}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),
              Text(user.name, style: AppConstants.titleStyle),
              const SizedBox(height: 5),
              Text(user.bio, style: const TextStyle(color: Colors.white70, fontSize: 14)),

              const SizedBox(height: 30),
              // ফলোয়ার ও অন্যান্য স্ট্যাটাস
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   _StatItem(label: "Followers", value: "1.2K"),
                   SizedBox(width: 50),
                   _StatItem(label: "Following", value: "340"),
                ],
              ),
              
              const Spacer(),
              const Text("My Story (+)", style: TextStyle(color: AppConstants.accentColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
    ]);
  }
}
