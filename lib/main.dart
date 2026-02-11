import 'package:flutter/material.dart';

// ১. অ্যাপের সব কালার ও সেটিংস (কোর)
class AppConstants {
  static const Color primaryColor = Color(0xFF0F0F1E);
  static const Color accentColor = Color(0xFFE91E63);
  static const Color cardColor = Color(0xFF1A1A2E);
}

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MainNavigation()));

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; 
  final List<Widget> _pages = [
    const Center(child: Text("হোম ফিড - নতুন পোস্ট দেখুন", style: TextStyle(color: Colors.white54))),
    const VoiceRoomScreen(),
    const Center(child: Text("মেসেজ বক্স - চ্যাট করুন", style: TextStyle(color: Colors.white54))),
    const RealProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppConstants.cardColor,
        selectedItemColor: AppConstants.accentColor,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "হোম"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "চ্যাট"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}

// ২. ২০ সিটের রুম ও সব ফিচারের বাটন
class VoiceRoomScreen extends StatelessWidget {
  const VoiceRoomScreen({super.key});

  // বাটন চাপলে কি হবে তার জন্য ছোট মেসেজ ফাংশন
  void _showAction(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$title ওপেন হচ্ছে..."), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: Column(
        children: [
          const SizedBox(height: 50),
          // ইউটিউব উইন্ডো (এটি চাপলে কাজ করবে)
          GestureDetector(
            onTap: () => _showAction(context, "ইউটিউব প্লেয়ার"),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 180,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppConstants.accentColor.withOpacity(0.5)),
                boxShadow: [BoxShadow(color: AppConstants.accentColor.withOpacity(0.2), blurRadius: 10)],
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_fill, color: Colors.red, size: 60),
                    Text("সবাই মিলে ইউটিউব দেখুন", style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ২০ সিটের গ্রিড (সিট চাপলে বসা যাবে)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, mainAxisSpacing: 10, crossAxisSpacing: 10,
              ),
              itemCount: 20,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => _showAction(context, "${index + 1} নম্বর সিটে"),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: index < 5 ? Colors.amber.withOpacity(0.1) : Colors.white10,
                      child: Icon(index < 5 ? Icons.star : Icons.person, color: index < 5 ? Colors.amber : Colors.white12, size: 20),
                    ),
                    Text("${index + 1}", style: const TextStyle(color: Colors.white30, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ),
          // মেইন ফিচার বাটন বার
          _buildFeatureBar(context),
        ],
      ),
    );
  }

  Widget _buildFeatureBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.black45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _featureIcon(context, Icons.music_note, "মিউজিক", Colors.blue),
          _featureIcon(context, Icons.videogame_asset, "গেমস/লুডু", Colors.orange),
          _featureIcon(context, Icons.bolt, "পিকে ব্যাটল", Colors.purple),
          _featureIcon(context, Icons.card_giftcard, "গিফট", Colors.teal),
        ],
      ),
    );
  }

  Widget _featureIcon(BuildContext context, IconData icon, String label, Color color) {
    return InkWell(
      onTap: () => _showAction(context, label),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }
}

// ৩. প্রোফাইল ও ওয়ালেট (ডায়মন্ড/কয়েন)
class RealProfileScreen extends StatelessWidget {
  const RealProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: Column(
        children: [
          const SizedBox(height: 80),
          const Center(child: CircleAvatar(radius: 50, backgroundColor: AppConstants.accentColor, child: Icon(Icons.person, size: 50, color: Colors.white))),
          const SizedBox(height: 15),
          const Text("পাগলা ইউজার", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("ID: 1032456", style: TextStyle(color: Colors.white38)),
          const SizedBox(height: 30),
          // ওয়ালেট সেকশন
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppConstants.cardColor, borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _walletItem("ডায়মন্ড", "৫০০", Icons.diamond, Colors.cyan),
                _walletItem("কয়েন", "১০কে", Icons.monetization_on, Colors.amber),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }
}
