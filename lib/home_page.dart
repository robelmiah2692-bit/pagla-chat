import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'dart:io'; // 🔥 লোকাল ফাইল প্রিভিউ করার জন্য
import 'story_section.dart'; 
import 'stories_service.dart'; 
import 'app_config.dart';
import 'post_card.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  final TextEditingController _captionController = TextEditingController();

  // গ্যালারি থেকে ছবি সিলেক্ট করার ফাংশন
  Future<void> _pickImage(Function setModalState) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // মডেলের স্টেট আপডেট করার জন্য setModalState ব্যবহার করা হয়েছে
        setModalState(() {
          _pickedImage = image;
        });
        setState(() {}); // মেইন পেজের স্টেটও আপডেট রাখা
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showPostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 15),
              const Text(
                "নতুন পোস্ট দিন",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              
              // ১. টেক্সট ইনপুট
              TextField(
                controller: _captionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "আপনার মনের কথা লিখুন...",
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),

              // ২. 🔥 ইমেজ প্রিভিউ সেকশন
              if (_pickedImage != null)
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                        image: DecorationImage(
                          image: FileImage(File(_pickedImage!.path)), 
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8, top: 8,
                      child: GestureDetector(
                        onTap: () => setModalState(() => _pickedImage = null),
                        child: Container(
                          // 🔥 BoxType এর বদলে BoxShape ব্যবহার করা হয়েছে (ফিক্সড)
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    )
                  ],
                ),

              // ৩. গ্যালারি বাটন
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  // 🔥 BoxType এর বদলে BoxShape ব্যবহার করা হয়েছে (ফিক্সড)
                  decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library, color: Colors.greenAccent),
                ),
                title: const Text("গ্যালারি থেকে ছবি নিন", style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () => _pickImage(setModalState),
              ),

              const SizedBox(height: 15),

              // ৪. পোস্ট বাটন
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  String text = _captionController.text.trim();
                  if (_pickedImage != null || text.isNotEmpty) {
                    
                    showDialog(
                      context: context, 
                      barrierDismissible: false,
                      builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
                    );
                    
                    await StoriesService().uploadStory(
                      _pickedImage?.path ?? "",
                      text,
                    );

                    _captionController.clear();
                    setState(() => _pickedImage = null);

                    if (mounted) {
                      Navigator.pop(context); // ক্লোজ লোডিং
                      Navigator.pop(context); // ক্লোজ মডেল
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("পোস্ট সফলভাবে লাইভ হয়েছে! 🔥"), backgroundColor: Colors.green),
                    );
                  }
                },
                child: const Text("পোস্ট করুন", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 30),
            ],
          ),
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
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.white)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPostModal,
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: StorySection()),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('stories')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text("কোনো পোস্ট নেই", style: TextStyle(color: Colors.white24))),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PostCard(
                    data: docs[index].data() as Map<String, dynamic>, 
                    postId: docs[index].id
                  ),
                  childCount: docs.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
