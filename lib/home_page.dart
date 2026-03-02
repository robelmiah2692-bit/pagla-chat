// ১. এখানে ডিরেক্ট dart:io এর বদলে কন্ডিশনাল ইম্পোর্ট ব্যবহার করা হয়েছে
import 'dart:io' if (dart.library.html) 'dart:html' as io; 
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_config.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<bool> isLikedList = List.generate(10, (index) => false);
  final ImagePicker _picker = ImagePicker();
  
  // ডিরেক্ট File না লিখে XFile বা dynamic ব্যবহার করা নিরাপদ
  dynamic _displayImage; 

  // ১. পোস্ট করার ফাংশন (গ্যালারি লজিক)
  Future<void> _pickImageForPost() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (kIsWeb) {
          _displayImage = image.path; // ওয়েবের জন্য পাথ
        } else {
          _displayImage = File(image.path); // মোবাইলের জন্য ফাইল অবজেক্ট
        }
      });
    }
  }

  void _showPostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("নতুন পোস্ট করুন", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "আপনার মনে কি আছে লিখুন...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              
              // ইমেজ প্রিভিউ লজিক (এরর ছাড়াই চলবে)
              if (_displayImage != null)
                Container(
                  height: 120,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  child: kIsWeb 
                    ? Image.network(_displayImage, fit: BoxFit.cover)
                    : Image.file(_displayImage as File, fit: BoxFit.cover),
                ),

              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.greenAccent),
                title: const Text("গ্যালারি থেকে ছবি নিন", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  await _pickImageForPost();
                  setModalState(() {}); 
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, minimumSize: const Size(double.infinity, 45)),
                onPressed: () {
                  _displayImage = null;
                  Navigator.pop(context);
                },
                child: const Text("পোস্ট করুন"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showCommentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 10, right: 10, top: 10),
        child: Row(
          children: [
            const Expanded(
              child: TextField(
                autofocus: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: "কমেন্ট লিখুন...", hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none),
              ),
            ),
            IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text("PAGLA CHAT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // আপনার ওনার আইডি চেক
          if (AppConfig.isHridoy("885522")) 
            const Padding(
              padding: EdgeInsets.only(right: 15),
              child: Icon(Icons.verified, color: Colors.amber, size: 28),
            ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: _showPostModal,
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),

      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => _buildPostCard(index),
      ),
    );
  }

  Widget _buildPostCard(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1E1E2F), borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundImage: NetworkImage(AppConfig.maleAvatars[index % 10]), 
            ),
            title: const Text("পাগলা ইউজার", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text("১০ মিনিট আগে", style: TextStyle(color: Colors.white38, fontSize: 11)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text("আজকের Pagla Chat আড্ডাটা দারুণ হচ্ছে! 🔥", style: TextStyle(color: Colors.white70)),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network('https://picsum.photos/id/${index + 50}/400/250', fit: BoxFit.cover),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isLikedList[index] ? Icons.favorite : Icons.favorite_border,
                  color: isLikedList[index] ? Colors.red : Colors.white54,
                ),
                onPressed: () => setState(() => isLikedList[index] = !isLikedList[index]),
              ),
              const Text("২৫", style: TextStyle(color: Colors.white54)),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.comment_outlined, color: Colors.white54),
                onPressed: _showCommentModal,
              ),
              const Text("১২", style: TextStyle(color: Colors.white54)),
            ],
          ),
        ],
      ),
    );
  }
}
