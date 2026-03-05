import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ফায়ারবেস কানেকশন
import 'story_section.dart'; 
import 'stories_service.dart'; 
import 'app_config.dart';
import 'post_card.dart'; // বড় পোস্ট ডিজাইনের জন্য

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

  // --- আপনার পুরাতন মোডাল ফিচার একদম ঠিক রাখা হয়েছে ---
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
                "নতুন স্টোরি দিন",
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
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 15),
              if (_pickedImage != null)
                Container(
                  height: 150,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _pickedImage!.path, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.white24),
                      ),
                    ),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.greenAccent),
                title: const Text("ছবি যোগ করুন", style: TextStyle(color: Colors.white)),
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
                    await StoriesService().uploadStory(
                      _pickedImage?.path ?? "",
                      text,
                    );

                    _captionController.clear();
                    setState(() {
                      _pickedImage = null;
                    });

                    if (mounted) Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("স্টোরি সফলভাবে পোস্ট হয়েছে! 🔥"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text(
                  "পোস্ট করুন",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
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
        actions: [
          // আপনার ওনার আইডি ভেরিফাইড আইকন ফিচার
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
      body: CustomScrollView(
        slivers: [
          // উপরে স্টোরি সেকশন
          const SliverToBoxAdapter(child: StorySection()),

          // 🔥 নিচে এখন ডাটাবেস থেকে রিয়েল টাইম পোস্ট আসবে (আপনার মার্ক করা সেই জায়গা)
          StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('stories')
      .orderBy('timestamp', descending: true) // রিসেন্টগুলো উপরে
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SliverToBoxAdapter(
        child: Center(child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        )),
      );
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("এখনও কোনো পোস্ট নেই", style: TextStyle(color: Colors.white24)),
          ),
        ),
      );
    }

    final docs = snapshot.data!.docs;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final doc = docs[index]; // পুরো ডকুমেন্টটি নেওয়া হলো
          final data = doc.data() as Map<String, dynamic>;
          
          // 🔥 এখানে postId: doc.id যোগ করা হয়েছে যাতে এরর না আসে
          return PostCard(
            data: data, 
            postId: doc.id,
          ); 
        },
        childCount: docs.length,
      ),
    );
  },
),

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }
}
