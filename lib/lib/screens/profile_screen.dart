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
  // ১. প্রাথমিক ডাটা (বাস্তবে কাজ করার জন্য)
  UserModel user = UserModel(
    name: "Rss°Hridoy",
    bio: "আড্ডা দিতে ভালোবাসি",
    diamonds: 150000, // ১.৫ লাখ ডায়মন্ড (তার মানে LV 1)
  );
  File? _image;

  @override
  void initState() {
    super.initState();
    _loadData();
    user.calculateVipLevel(); // লেভেল হিসাব করা
  }

  // ২. ডাটা লোড ও সেভ করার বাস্তব মেকানিজম
  _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      user.name = prefs.getString('name') ?? "Rss°Hridoy";
      user.bio = prefs.getString('bio') ?? "আড্ডা দিতে ভালোবাসি";
      user.diamonds = prefs.getInt('diamonds') ?? 150000;
      user.calculateVipLevel();
    });
  }

  _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('name', user.name);
    prefs.setString('bio', user.bio);
  }

  // ৩. প্রোফাইল এডিট ডায়ালগ
  void _showEditSheet() {
    TextEditingController nCtrl = TextEditingController(text: user.name);
    TextEditingController bCtrl = TextEditingController(text: user.bio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.cardColor,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("এডিট প্রোফাইল", style: AppConstants.titleStyle),
            const SizedBox(height: 15),
            TextField(controller: nCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "নিকনেম")),
            TextField(controller: bCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "বায়ো")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  user.name = nCtrl.text;
                  user.bio = bCtrl.text;
                });
                _saveData();
                Navigator.pop(context);
              },
              child: const Text("সব সেভ করুন"),
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
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage(AppConstants.backgroundImage), fit: BoxFit.cover),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // টপ ডায়মন্ড বার
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [
                        const Icon(Icons.diamond, color: AppConstants.diamondColor, size: 20),
                        Text(" ${user.diamonds}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: _showEditSheet),
                  ],
                ),
              ),

              // এভার্টার ও ভিআইপি লেভেল (১-৩০)
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppConstants.accentColor, width: 2))),
                  const CircleAvatar(radius: 60, backgroundColor: Colors.white10, child: Icon(Icons.person, size: 60, color: Colors.white24)),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10)),
                      child: Text("VIP ${user.vipLevel}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(user.name, style: AppConstants.titleStyle),
              Text(user.bio, style: const TextStyle(color: Colors.white54)),

              const SizedBox(height: 30),
              // স্টোরি ও অনার ব্যাজ এরিয়া (খালি রাখা হয়েছে আপনার পরবর্তী ফিচারের জন্য)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   _BadgeItem(Icons.workspace_premium, "LV.13"),
                   SizedBox(width: 20),
                   _BadgeItem(Icons.favorite, "Soulmate"),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BadgeItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: Colors.pinkAccent, size: 30),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
    ]);
  }
}
