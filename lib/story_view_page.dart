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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // স্টোরি ইমেজ (যদি ইমেজ খালি থাকে তবে কালো ব্যাকগ্রাউন্ডে টেক্সট দেখাবে)
          Center(
            child: image.isNotEmpty 
              ? Image.network(image, fit: BoxFit.contain)
              : Text(caption, style: const TextStyle(color: Colors.white, fontSize: 20), textAlign: TextAlign.center),
          ),
          // উপরে ইউজারের নাম এবং ক্লোজ বাটন
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 10),
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
