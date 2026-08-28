import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pagla_chat/lovely_couple_page.dart';
import 'agency_list_page.dart';

class BannerFeaturePage extends StatefulWidget {
  const BannerFeaturePage({Key? key}) : super(key: key);

  @override
  State<BannerFeaturePage> createState() => _BannerFeaturePageState();
}

class _BannerFeaturePageState extends State<BannerFeaturePage> {
  // প্রিমিয়াম ডাইনামিক কালার কম্বিনেশনের লিস্ট (প্রতিটি আইটেমে মিক্সড কালার রাখা হয়েছে)
  final List<Map<String, dynamic>> _dynamicColorThemes = [
    {
      'name': 'Neon Cyan & Purple',
      'theme': Colors.cyanAccent,
      'gradient': [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
    },
    {
      'name': 'Deep Magenta & Blue',
      'theme': Colors.pinkAccent,
      'gradient': [Color(0xFF232526), Color(0xFF414345), Color(0xFF8A2387)],
    },
    {
      'name': 'Electric Amber',
      'theme': Colors.amberAccent,
      'gradient': [Color(0xFF1F1C18), Color(0xFF2C1E0F), Color(0xFF422709)],
    },
    {
      'name': 'Matrix Green',
      'theme': Colors.greenAccent,
      'gradient': [Color(0xFF0F2012), Color(0xFF133B1D), Color(0xFF1F4D2B)],
    },
    {
      'name': 'Royal Purple',
      'theme': Colors.purpleAccent,
      'gradient': [Color(0xFF140C1C), Color(0xFF2A163B), Color(0xFF3D1E58)],
    },
    {
      'name': 'Sunset Orange',
      'theme': Colors.orangeAccent,
      'gradient': [Color(0xFF2B1410), Color(0xFF4D2216), Color(0xFF6B2D1B)],
    },
  ];

  late Map<String, dynamic> _currentTheme;

  @override
  void initState() {
    super.initState();
    // পেজ লোড হলে একটি রেন্ডম কালার থিম সিলেক্ট হবে
    _currentTheme = _dynamicColorThemes[Random().nextInt(_dynamicColorThemes.length)];
  }

  // নতুন ডাইনামিক মিক্স কালার সেট করার ফাংশন
  void _changeDynamicColor() {
    setState(() {
      _currentTheme = _dynamicColorThemes[Random().nextInt(_dynamicColorThemes.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = _currentTheme['theme'];
    List<Color> bgGradient = _currentTheme['gradient'];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        // ডাইনামিক গ্রেডিয়েন্ট ব্যাকগ্রাউন্ড
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: bgGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                backgroundColor: Colors.transparent, // ব্যাকগ্রাউন্ড গ্রেডিয়েন্ট দেখানোর জন্য ট্রান্সপারেন্ট
                elevation: 0,
                pinned: true,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Event & Agency Center",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    // ডাইনামিক কালার পরিবর্তনের বাটন
                    IconButton(
                      icon: Icon(Icons.color_lens, color: themeColor),
                      onPressed: _changeDynamicColor,
                      tooltip: "Change Dynamic Mix Color",
                    ),
                  ],
                ),
                iconTheme: const IconThemeData(color: Colors.white),
                bottom: TabBar(
                  indicatorColor: themeColor,
                  labelColor: themeColor,
                  unselectedLabelColor: Colors.white60,
                  tabs: const [
                    Tab(text: "Agency List"),
                    Tab(text: "Lovely Couple"),
                    Tab(text: "Super Event"),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              children: [
                const AgencyListPage(),
                const LovelyCouplePage(),
                _buildSimpleContentTab("Super Event Section", "এখানে সুপার ইভেন্ট সংক্রান্ত তথ্য থাকবে।", themeColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // সাধারণ কন্টেন্ট উইজেট (ডাইনামিক কালার সাপোর্টেড)
  Widget _buildSimpleContentTab(String title, String subtitle, Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: accentColor, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 5,
            ),
            onPressed: _changeDynamicColor,
            child: const Text("Mix New Color Theme", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}