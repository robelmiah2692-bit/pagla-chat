import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'screens/profile_screen.dart'; // আমরা একটু পর এই ফাইলটি তৈরি করবো
import 'screens/room_screen.dart';    // আমরা একটু পর এই ফাইলটি তৈরি করবো

void main() {
  runApp(const PaglaChatApp());
}

class PaglaChatApp extends StatelessWidget {
  const PaglaChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'পাগলা চ্যাট',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: AppConstants.primaryColor,
      ),
      // অ্যাপটি ওপেন হলেই সরাসরি হোম বা রুম পেজে নিয়ে যাবে
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
  int _currentIndex = 0;

  // এখানে আপনার সেই ৪টি মেইন পেজ থাকবে
  final List<Widget> _pages = [
    const Center(child: Text("হোম পেজ (Coming Soon)")), // আপাতত টেক্সট
    const VoiceRoomScreen(), // ২০ সিটের রুম
    const Center(child: Text("ইনবক্স (Coming Soon)")),
    const RealProfileScreen(), // প্রোফাইল ও ভিআইপি লেভেল
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppConstants.cardColor,
        selectedItemColor: AppConstants.accentColor,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "হোম"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "ইনবক্স"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}
