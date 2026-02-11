import 'package:flutter/material.dart';
// আপনার প্রজেক্টের প্যাকেজ পাথ অনুযায়ী ইমপোর্ট করা হলো
import 'package:pagla_app/core/constants.dart';
import 'package:pagla_app/screens/profile_screen.dart'; 
import 'package:pagla_app/screens/room_screen.dart';    

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.accentColor,
          brightness: Brightness.dark,
        ),
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
  int _currentIndex = 1; // সরাসরি 'রুম' পেজটি ওপেন হবে

  final List<Widget> _pages = [
    const Center(child: Text("হোম ফিড", style: TextStyle(color: Colors.white54))), 
    const VoiceRoomScreen(), // ২০ সিটের রুম (লিঙ্কড)
    const Center(child: Text("মেসেজ বক্স", style: TextStyle(color: Colors.white54))),
    const RealProfileScreen(), // প্রোফাইল সিস্টেম (লিঙ্কড)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppConstants.cardColor,
        selectedItemColor: AppConstants.accentColor,
        unselectedItemColor: Colors.white38,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: "হোম"),
          BottomNavigationBarItem(icon: Icon(Icons.mic_none_rounded), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: "চ্যাট"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}
