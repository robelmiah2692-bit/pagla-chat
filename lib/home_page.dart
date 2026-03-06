import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'dart:io'; // 🔥 লোকাল ফাইল দেখানোর জন্য এটা লাগবে
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedImage = image;
        });
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
              const Text(
                "নতুন পোস্ট দিন",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _captionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "আপনার মনের কথা লিখুন...",
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              
              // 🔥 ফিক্সড ইমেজ প্রিভিউ (File ব্যবহার করে)
              if (_pickedImage != null)
                Stack(
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(File(_pickedImage!.path)), // লোকাল ফাইল দেখাবে
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 5, top: 5,
                      child: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => setModalState(() => _pickedImage = null),
                      ),
                    )
                  ],
                ),
                
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.greenAccent),
                title: const Text("গ্যালারি থেকে ছবি নিন", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  await _pickImage();
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  String text = _captionController.text.trim();
                  if (_pickedImage != null || text.isNotEmpty) {
                    // লোডিং ডায়ালগ
                    showDialog(context: context, builder: (c) => const Center(child: CircularProgressIndicator()));
                    
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
                      const SnackBar(content: Text("পোস্ট সফলভাবে লাইভ হয়েছে! 🔥"), backgroundColor: Colors.green),
                    );
                  }
                },
                child: const Text("পোস্ট করুন", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 25),
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
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PostCard(data: docs[index].data() as Map<String, dynamic>, postId: docs[index].id),
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
