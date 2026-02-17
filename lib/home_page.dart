import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // লাইক হয়েছে কি না তা ট্র্যাক করার জন্য ডামি লিস্ট
  List<bool> isLikedList = List.generate(10, (index) => false);

  // ১. পোস্ট করার ফাংশন (গ্যালারি ও লেখালেখির পপ-আপ)
  void _showPostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // কিবোর্ড আসলে যেন ওপরে উঠে যায়
      backgroundColor: const Color(0xFF1E1E2F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
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
            // গ্যালারি বাটন
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.greenAccent),
              title: const Text("গ্যালারি থেকে ছবি নিন", style: TextStyle(color: Colors.white)),
              onTap: () {
                // এখানে গ্যালারির কোড বসবে (image_picker)
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, minimumSize: const Size(double.infinity, 45)),
              onPressed: () => Navigator.pop(context),
              child: const Text("পোস্ট করুন"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ২. কমেন্ট করার ফাংশন (কিবোর্ড ওপেন হবে)
  void _showCommentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2F),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 10, right: 10, top: 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                autofocus: true, // কিবোর্ড অটোমেটিক ওপেন হবে
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: "কমেন্ট লিখুন...", hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none),
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
      app_bar: AppBar(
        title: const Text("PAGLA CHAT", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      
      // প্লাস বাটন যা দিয়ে পোস্ট করা যাবে
      floatingActionButton: FloatingActionButton(
        onPressed: _showPostModal,
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.add, size: 30),
      ),

      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return _buildPostCard(index);
        },
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
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundColor: Colors.pinkAccent, child: Icon(Icons.person)),
            title: Text("পাগলা ইউজার", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text("১০ মিনিট আগে", style: TextStyle(color: Colors.white38, fontSize: 11)),
          ),
          const Text("আজকের Pagla Chat আড্ডাটা দারুণ হচ্ছে! 🔥", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network('https://via.placeholder.com/400x200', fit: BoxFit.cover),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // লাইক বাটন অ্যাকশন
              IconButton(
                icon: Icon(
                  isLikedList[index] ? Icons.favorite : Icons.favorite_border,
                  color: isLikedList[index] ? Colors.red : Colors.white54,
                ),
                onPressed: () {
                  setState(() {
                    isLikedList[index] = !isLikedList[index];
                  });
                },
              ),
              const Text("২৫", style: TextStyle(color: Colors.white54)),
              const SizedBox(width: 20),
              // কমেন্ট বাটন অ্যাকশন
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
