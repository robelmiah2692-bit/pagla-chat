import 'package:flutter/material.dart';

// সব সেটিংস এক জায়গায়
class AppConstants {
  static const Color primaryColor = Color(0xFF0F0F1E);
  static const Color accentColor = Color(0xFFE91E63);
  static const Color cardColor = Color(0xFF1A1A2E);
}

// আপনার ২০ সিটের রুম
class VoiceRoomScreen extends StatelessWidget {
  const VoiceRoomScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppConstants.primaryColor,
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Text("পাগলা চ্যাট লাইভ", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 10, crossAxisSpacing: 10),
              itemCount: 20,
              itemBuilder: (context, index) => Column(
                children: [
                  CircleAvatar(radius: 20, backgroundColor: Colors.white10, child: Icon(Icons.mic_none, size: 15, color: Colors.white38)),
                  Text("${index + 1}", style: TextStyle(color: Colors.white30, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// প্রোফাইল সেকশন
class RealProfileScreen extends StatelessWidget {
  const RealProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("প্রোফাইল পেজ", style: TextStyle(color: Colors.white)));
  }
}

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: MainNavigation()));

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1;
  final List<Widget> _pages = [
    Center(child: Text("হোম", style: TextStyle(color: Colors.white))),
    VoiceRoomScreen(),
    Center(child: Text("মেসেজ", style: TextStyle(color: Colors.white))),
    RealProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppConstants.cardColor,
        selectedItemColor: AppConstants.accentColor,
        unselectedItemColor: Colors.white30,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "হোম"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "চ্যাট"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}
