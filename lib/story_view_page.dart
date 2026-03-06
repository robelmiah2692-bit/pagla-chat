import 'package:flutter/material.dart';

class StoryViewPage extends StatelessWidget {
  final String image; // এই 'image' ভেরিয়েবলে 'storyImage' এর লিংক পাঠাতে হবে
  final String name;
  final String caption;

  const StoryViewPage({
    super.key, 
    required this.image, 
    required this.name, 
    required this.caption
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ১. স্টোরি ইমেজ সেকশন (ফুল স্ক্রিন)
          Center(
            child: image.isNotEmpty 
              ? Image.network(
                  image, 
                  fit: BoxFit.contain,
                  width: double.infinity,
                  // ছবি লোড হওয়ার সময় একটি লোডার দেখাবে
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white24));
                  },
                  // যদি ইমেজের লিংকে ভুল থাকে তবে এরর দেখাবে না, শুধু টেক্সট দেখাবে
                  errorBuilder: (context, error, stackTrace) => _buildTextStory(),
                )
              : _buildTextStory(),
          ),

          // ২. উপরে ইউজারের প্রোফাইল ও নাম
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white24, 
                  child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text("Just now", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ৩. নিচে ক্যাপশন (যদি থাকে)
          if (caption.isNotEmpty && image.isNotEmpty)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  caption,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ছবি না থাকলে শুধু লেখা দেখানোর জন্য ছোট উইজেট
  Widget _buildTextStory() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Text(
        caption, 
        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500), 
        textAlign: TextAlign.center
      ),
    );
  }
}
