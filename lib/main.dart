import 'package:flutter/material.dart';
// পরবর্তী ধাপে আমরা এই ৪টি ফাইল তৈরি করবো
// import 'home_page.dart';
// import 'voice_room.dart';
// import 'inbox_page.dart';
// import 'profile_page.dart';

void main() {
  runApp(const PaglaChatApp());
}

class PaglaChatApp extends StatelessWidget {
  const PaglaChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // লাল ব্যানার সরানোর জন্য
      title: 'Pagla Chat',
      theme: ThemeData(
        brightness: Brightness.dark, // লাক্সারি ডার্ক থিম
        primaryColor: Colors.pinkAccent,
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0; // বর্তমানে কোন পেজে আছেন তা ট্র্যাক করার জন্য

  // আপনার চাহিদা মতো ৪টি পেজের জায়গা এখানে করে দিলাম
  final List<Widget> _pages = [
    const Center(child: Text("হোম পেজ", style: TextStyle(fontSize: 24))),    // ০ নম্বর
    const Center(child: Text("ভয়েস রুম", style: TextStyle(fontSize: 24))),   // ১ নম্বর
    const Center(child: Text("ইনবক্স", style: TextStyle(fontSize: 24))),     // ২ নম্বর
    const Center(child: Text("প্রোফাইল", style: TextStyle(fontSize: 24))),   // ৩ নম্বর
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // বাটন অনুযায়ী পেজ বদলাবে
      
      // নিচের নেভিগেশন বার (৪টি বাটন)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // বাটন ক্লিক করলে এখানে পেজ নাম্বার আপডেট হবে
          });
        },
        type: BottomNavigationBarType.fixed, // ৪টি বাটন যেন সুন্দরভাবে ফিট হয়
        selectedItemColor: Colors.pinkAccent, // সিলেক্ট করা আইকনের রঙ
        unselectedItemColor: Colors.grey,     // বাকি আইকনের রঙ
        backgroundColor: const Color(0xFF151525), // প্রিমিয়াম ডার্ক ব্যাকগ্রাউন্ড
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "হোম"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: "ইনবক্স"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}
