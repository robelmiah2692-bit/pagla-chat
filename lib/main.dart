import 'package:flutter/material.dart';

// আমরা আর constants.dart এর ওপর ভরসা করছি না, সরাসরি এখানেই সব দিয়ে দিলাম
class AppConstants {
  static const Color primaryColor = Color(0xFF0F0F1E);
  static const Color accentColor = Color(0xFFE91E63);
  static const Color cardColor = Color(0xFF1A1A2E);
}

// নিচের এই ক্লাসগুলো এখানে থাকাতে গিটহাব আর এরর দিতে পারবে না
class VoiceRoomScreen extends StatelessWidget {
  const VoiceRoomScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("রুম লোড হচ্ছে...")));
}

class RealProfileScreen extends StatelessWidget {
  const RealProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("প্রোফাইল লোড হচ্ছে...")));
}

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
  int _currentIndex = 1; 

  final List<Widget> _pages = [
    const Center(child: Text("হোম ফিড", style: TextStyle(color: Colors.white54))), 
    const VoiceRoomScreen(), 
    const Center(child: Text("মেসেজ বক্স", style: TextStyle(color: Colors.white54))),
    const RealProfileScreen(), 
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
