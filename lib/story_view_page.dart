import 'package:flutter/material.dart';

class StoryViewPage extends StatelessWidget {
  final String image; 
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
    // ইমেজ আছে কি না তা চেক করা
    bool hasImage = image.isNotEmpty && image.startsWith('http');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ১. ব্যাকগ্রাউন্ড সেকশন (ছবি অথবা সুন্দর গ্রেডিয়েন্ট)
          Positioned.fill(
            child: hasImage
                ? Image.network(
                    image,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white24),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => _buildTextStoryBackground(),
                  )
                : _buildTextStoryBackground(),
          ),

          // ২. হালকা কালো শ্যাডো (যাতে উপরের নাম এবং নিচের ক্যাপশন পরিষ্কার বোঝা যায়)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.2, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // ৩. ছবি না থাকলে মাঝখানে বড় করে ক্যাপশন দেখানো
          if (!hasImage)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Text(
                  caption,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // ৪. উপরে ইউজারের প্রোফাইল ও নাম
          Positioned(
            top: 50,
            left: 20,
            right: 10,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "?",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      "Just now",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ৫. নিচে ক্যাপশন (যদি ছবি থাকে তবেই নিচে ছোট করে দেখাবে)
          if (hasImage && caption.isNotEmpty)
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  caption,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ছবি না থাকলে সুন্দর একটি রঙিন ব্যাকগ্রাউন্ড তৈরির জন্য উইজেট
  Widget _buildTextStoryBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF833ab4), Color(0xFFfd1d1d), Color(0xFFfcb045)], // ইন্সটাগ্রাম/ফেসবুক স্টাইল গ্রেডিয়েন্ট
        ),
      ),
    );
  }
}
