import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'story_section.dart'; // স্টোরি সেকশন ইমপোর্ট
import 'stories_service.dart'; // সার্ভিস ফাইল ইমপোর্ট
import 'app_config.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<bool> isLikedList = List.generate(10, (index) => false);
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage; 

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() { _pickedImage = image; });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // 🔥 এই ফাংশনটির ভেতরেই বাটনটি বসানো হয়েছে
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
              const Text("নতুন স্টোরি দিন", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              if (_pickedImage != null)
                Container(
                  height: 150, width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(_pickedImage!.path, fit: BoxFit.cover),
                  ),
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

              // 🔥 এই সেই বাটন যা রিয়েল-টাইম ডাটা পাঠাবে
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent, 
                  minimumSize: const Size(double.infinity, 45)
                ),
                onPressed: () async {
                  if (_pickedImage != null) {
                    // সার্ভিস কল করে ডাটাবেসে পাঠানো হচ্ছে
                    await StoriesService().uploadStory(_pickedImage!.path);
                    
                    setState(() { _pickedImage = null; });
                    if (mounted) Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("স্টোরি আপলোড সফল! ✅"))
                    );
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const Text("পোস্ট করুন", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
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
          // স্টোরি সেকশন সবার উপরে
          const SliverToBoxAdapter(
            child: StorySection(),
          ),
          
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildPostCard(index),
              childCount: 10,
            ),
          ),
        ],
      ),
    );
  }

  // নিউজফিড কার্ড ডিজাইন (আগের মতই আছে)
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
            child: Image.network('https://picsum.photos/id/${index + 10}/400/250', fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }
}
