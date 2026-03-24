import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; // ✅FirebaseAuth যোগ করা হয়েছে
import 'package:flutter/foundation.dart'; 
import 'dart:io' as io; 

import 'story_section.dart'; 
import 'stories_service.dart'; 
import 'post_card.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// ✅ WidgetsBindingObserver যোগ করা হয়েছে অনলাইন স্ট্যাটাস ট্র্যাক করার জন্য
class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  Uint8List? _webImageBytes; 
  final TextEditingController _captionController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    // ✅ অ্যাপের লাইফসাইকেল পর্যবেক্ষণ শুরু
    WidgetsBinding.instance.addObserver(this);
    _updateStatus(true); // অ্যাপে ঢুকলেই অনলাইন
  }

  @override
  void dispose() {
    // ✅ পর্যবেক্ষণ বন্ধ করা
    WidgetsBinding.instance.removeObserver(this);
    _captionController.dispose();
    super.dispose();
  }

  // ✅ অ্যাপ মিনিমাইজ বা ক্লোজ করলে অনলাইন/অফলাইন হ্যান্ডেল করা
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateStatus(true); // অ্যাপে ফিরে আসলে অনলাইন
    } else {
      _updateStatus(false); // অ্যাপ থেকে বের হয়ে গেলে বা মিনিমাইজ করলে অফলাইন
    }
  }

  // ✅ ফায়ারস্টোরে অনলাইন স্ট্যাটাস আপডেট করার ফাংশন
  void _updateStatus(bool status) {
    if (currentUserId.isNotEmpty) {
      FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'isOnline': status,
        'lastSeen': FieldValue.serverTimestamp(),
      }).catchError((e) => debugPrint("Status Update Error: $e"));
    }
  }

  // গ্যালারি থেকে ছবি সিলেক্ট করার ফাংশন (আপনার আগের কোড)
  Future<void> _pickImage(Function setModalState) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, 
      );
      
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setModalState(() {
            _webImageBytes = bytes;
            _pickedImage = image;
          });
        } else {
          setModalState(() {
            _pickedImage = image;
          });
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showPostModal() {
    _captionController.clear();
    _pickedImage = null;
    _webImageBytes = null;

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
              
              TextField(
                controller: _captionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "আপনার মনের কথা লিখুন...",
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),

              if (_pickedImage != null)
                Stack(
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb 
                          ? Image.memory(_webImageBytes!, fit: BoxFit.cover) 
                          : Image.file(io.File(_pickedImage!.path), fit: BoxFit.cover), 
                      ),
                    ),
                    Positioned(
                      right: 8, top: 8,
                      child: GestureDetector(
                        onTap: () => setModalState(() {
                          _pickedImage = null;
                          _webImageBytes = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    )
                  ],
                ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library, color: Colors.greenAccent),
                ),
                title: const Text("ফটো যোগ করুন", style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () => _pickImage(setModalState),
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                onPressed: () async {
                  String text = _captionController.text.trim();
                  if (_pickedImage != null || text.isNotEmpty) {
                    showDialog(
                      context: context, 
                      barrierDismissible: false,
                      builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
                    );
                    
                    try {
                      await StoriesService().uploadStory(
                        _pickedImage?.path ?? "",
                        text,
                        webImageBytes: _webImageBytes, 
                      );

                      if (mounted) {
                        Navigator.pop(context); // ক্লোজ লোডিং
                        Navigator.pop(context); // ক্লোজ মডেল
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("পোস্ট সফলভাবে লাইভ হয়েছে! 🔥"), 
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) Navigator.pop(context);
                      debugPrint("Upload Error: $e");
                    }
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
        title: const Text(
          "PAGLA CHAT", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F0F1E),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {}, 
            icon: const Icon(Icons.notifications_none, color: Colors.white)
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPostModal,
        backgroundColor: Colors.pinkAccent,
        elevation: 10,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        color: Colors.pinkAccent,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: StorySection()),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stories')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Center(child: CircularProgressIndicator(color: Colors.white24)),
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: Center(
                        child: Text("এখনও কোনো পোস্ট নেই!", style: TextStyle(color: Colors.white24)),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return PostCard(
                        data: data, 
                        postId: docs[index].id,
                      );
                    },
                    childCount: docs.length,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}
